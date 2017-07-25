---
title: 在 Phabricator 项目列表中增加任务数和最新任务的链接
title_url: Phabricator-list-item-task
date: 2017-07-25
tags: Phabricator
categories: [Phabricator,PHP]
description: 在 Phabricator 项目列表中增加任务数和最新任务的链接
---


## 需求背景

在 Phabricator 项目和任务之间的衔接并不连贯,根据反馈需要在项目列表中增加显示任务数和最新任务的链接.

## Controller 间的跳转

根据 PhabricatorProjectApplication 中的路由配置,当访问默认的项目列表具体的 Controller 就是 PhabricatorProjectListController

PhabricatorProjectListController 中 handleRequest 方法如下

```php
  public function handleRequest(AphrontRequest $request) {
    return id(new PhabricatorProjectSearchEngine())
      ->setController($this)
      ->buildResponse();
  }
```

- 找到对应 PhabricatorProjectSearchEngine 的 buildResponse 方法如下

```php
  public function buildResponse() {
    $controller = $this->getController();
    $request = $controller->getRequest();

    $search = id(new PhabricatorApplicationSearchController())
      ->setQueryKey($request->getURIData('queryKey'))
      ->setSearchEngine($this);

    return $controller->delegateToController($search);
  }
```

其中 delegateToController 方法是由 AphrontController 定义的,具体的继承关系如下

```
PhabricatorProjectListController
	extends PhabricatorProjectController
		extends PhabricatorController
			extends AphrontController
```

delegateToController 方法具体定义如下

```php
  final public function delegateToController(AphrontController $controller) {
    $request = $this->getRequest();

    $controller->setDelegatingController($this);
    $controller->setRequest($request);

    $application = $this->getCurrentApplication();
    if ($application) {
      $controller->setCurrentApplication($application);
    }

    return $controller->handleRequest($request);
  }
```

- 其中传入的 $controller 对象是 PhabricatorApplicationSearchController, 由此我们可以知道 `$controller->handleRequest($request)` 是调用 PhabricatorApplicationSearchController 中的 handleRequest 方法, 
但是 PhabricatorApplicationSearchController 中并没有 handleRequest 方法, 说明调用的是 AphrontController 定义的

- 其中的 handleRequest 方法具体定义如下

```php
  public function handleRequest(AphrontRequest $request) {
    if (method_exists($this, 'processRequest')) {
      return $this->processRequest();
    }

    throw new PhutilMethodNotImplementedException(
      pht(
        'Controllers must implement either %s (recommended) '.
        'or %s (deprecated).',
        'handleRequest()',
        'processRequest()'));
  }
```

其中 method_exists 方法中第一个参数表示当前对象, 第二个参数表示对象里面的方法,如果当前对象中有该方法,返回true,随后执行 processRequest 方法

从上面的 Controller 继承关系中我们来一一查找下
	
```php
PhabricatorProjectListController // 没有 processRequest 方法
	extends PhabricatorProjectController // 没有 processRequest 方法
		extends PhabricatorController // 没有 processRequest 方法
			extends AphrontController // 没有 processRequest 方法
```

发现都没有 processRequest 方法, 再来看看 PhabricatorApplicationSearchController 继承关系

```php
PhabricatorApplicationSearchController  //有 processRequest 方法
	extends PhabricatorSearchBaseController // 没有 processRequest 方法
		extends PhabricatorController // 没有 processRequest 方法
			extends AphrontController // 没有 processRequest 方法
```

从上面的分析中可以得出的结论是 PhabricatorProjectListController 得到请求后经过 AphrontController 的 delegateToController 和 handleRequest 方法处理后最终是由 PhabricatorApplicationSearchController 的 processRequest 方法完成最终数据处理的.

## 数据渲染过程

在 PhabricatorApplicationSearchController 中的 processSearchRequest 方法中有如下关键的几行代码

```
$objects = $engine->executeQuery($query, $pager);
....
$list = $engine->renderResults($objects, $saved_query);
.....
if ($list->getTable()) {
	$box->setTable($list->getTable());
}
```

其中 $engine 对象就是 PhabricatorProjectListController 中传入的 PhabricatorProjectSearchEngine, 这里调用了 renderResults 方法返回了一个列表数据,这些数据就是页面上展示的项目列表. PhabricatorProjectSearchEngine 的继承关系如下

```php
PhabricatorProjectSearchEngine-> // 有 renderResultList 没有 executeQuery 和 renderResults
	extends PhabricatorApplicationSearchEngine // 有 executeQuery 和 renderResults , renderResultList 是 abstract 的,由子类实现
```

- 其中 executeQuery 用于执行具体的查询,将项目数据从数据库加载到应用中

- 其中 renderResultList 具体如下,方法中的 PhabricatorProjectListView 负责将数据渲染为 HTML

```php
  protected function renderResultList(
    array $projects,
    PhabricatorSavedQuery $query,
    array $handles) {
    assert_instances_of($projects, 'PhabricatorProject');
    $viewer = $this->requireViewer();

    $list = id(new PhabricatorProjectListView())
      ->setUser($viewer)
      ->setProjects($projects)
      ->setShowWatching(true)
      ->setShowMember(true)
      ->renderList();

    return id(new PhabricatorApplicationSearchResultView())
      ->setObjectList($list)
      ->setNoDataString(pht('No projects found.'));
  }
```

## 具体的修改

- 下面的这个方法根据项目的 phid 获取项目对应的 Edge 对象列表, 此时的 Edge 对象中的 src 字段表示 PhabricatorProject 对象中的 phid 字段, dst 字段表示 ManiphestTask 对象中的 phid 字段

- 具体位于 phabricator\src\infrastructure\edges\query\PhabricatorEdgeQuery.php

```php
  /**
   * 加载一组 Edge 数据
   * @param $src_phid
   * @param $edge_type
   * @return mixed
   */
  public static function loadEdgeDatas($src_phid, $edge_type) {
    $edges = id(new PhabricatorEdgeQuery())
        ->withSourcePHIDs(array($src_phid))
        ->withEdgeTypes(array($edge_type))
        ->execute();

    return $edges[$src_phid][$edge_type];
  }
```

- PhabricatorProjectListView 对象中的 renderList 方法修改如下

```php
  public function renderList() {
    $viewer = $this->getUser();
    $viewer_phid = $viewer->getPHID();
    $projects = $this->getProjects();

    $handles = $viewer->loadHandles(mpull($projects, 'getPHID'));

    $no_data = pht('No projects found.');
    if ($this->noDataString) {
      $no_data = $this->noDataString;
    }

    $list = id(new PHUIObjectItemListView())
      ->setUser($viewer)
      ->setNoDataString($no_data);

    foreach ($projects as $key => $project) {
      // 加载一个maniphest对象
      $taskEdge = PhabricatorEdgeQuery::loadEdgeDatas(
            $project->getPHID(),
            '42',
            '');

      $task = new ManiphestTask();

      $tasklink = "";
      if (!empty($taskEdge)) {
        foreach ($taskEdge as $key => $value) {
          $taskPHID = $key;
          $task = id(new ManiphestTask())->loadOneWhere("phid = '".$key."'");
          if ($task !== null) {
            // 任务的链接
            $tasklink = phutil_tag(
             'a',
             array(
              'href' => "/T".$task->getID(),
              'class' => 'phui-oi-link',
              'title' => $task->getTitle(),
             ),
             $task->getTitle());
            // 这里只要最新的一个任务
            break;
          }
        }
      }

      $id = $project->getID();

      $icon = $project->getDisplayIconIcon();
      $icon_icon = id(new PHUIIconView())
        ->setIcon($icon);

      $icon_name = $project->getDisplayIconName();

      // 这里加上任务数量和最新的任务链接
      $item = id(new PHUIObjectItemView())
        ->setHeader($project->getName())
        ->setHref("/project/view/{$id}/")
        ->setImageURI($project->getProfileImageURI())
        ->addAttribute(
          array(
            $icon_icon,
            ' ',
            $icon_name,
            ' ',
            count($taskEdge),
            ' ',
            $tasklink,
          ));

      if ($project->getStatus() == PhabricatorProjectStatus::STATUS_ARCHIVED) {
        $item->addIcon('fa-ban', pht('Archived'));
        $item->setDisabled(true);
      }

      if ($this->showMember) {
        $is_member = $project->isUserMember($viewer_phid);
        if ($is_member) {
          $item->addIcon('fa-user', pht('Member'));
        }
      }

      if ($this->showWatching) {
        $is_watcher = $project->isUserWatcher($viewer_phid);
        if ($is_watcher) {
          $item->addIcon('fa-eye', pht('Watching'));
        }
      }

      $list->addItem($item);
    }

    return $list;
  }
```

## 最终的效果

![project-maniphest](http://7xt8a6.com1.z0.glb.clouddn.com/project-1.PNG)

## 总结

通过做这个需求，了解了 Phabricator 如下的技术细节

- Controller 间的流转细节
- 每个应用之间通过 Edge 进行关系连接，一对一，一对多的关系
- 列表页面的渲染