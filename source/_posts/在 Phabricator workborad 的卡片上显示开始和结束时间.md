---
title: 在 Phabricator workborad 的卡片上显示开始和结束时间
title_url: Phabricator-workborad-card-task
date: 2017-07-25
tags: Phabricator
categories: [Phabricator,PHP]
description: 在 Phabricator workborad 的卡片上显示开始和结束时间
---

## 需求背景

在 Phabricator workborad 的卡片上需要显示更多的信息,比如任务的开始和结束时间等等.

## workboard 的渲染过程

根据项目 workboard 的访问路径 `http://test.pha.com/project/board/9/` 和 PhabricatorProjectApplication 中定义的路由规则,可以找到 workboard 对应的 Controller 为 PhabricatorProjectBoardViewController. 

由此找到具体渲染 workboard 上卡片的具体过程如下

```php
PhabricatorProjectBoardViewController 362
	PhabricatorBoardRenderingEngine ->renderCard 56
		ProjectBoardTaskCard ->getItem 
```

在 getItem 方法中可以发现每个 workboard 卡片对应一个 PHUIObjectItemView 对象

## 具体的修改

其中 getItem 方法对应的修改如下

```php
public function getItem() {
    $task = $this->getTask();
    $owner = $this->getOwner();
    $can_edit = $this->getCanEdit();
    $viewer = $this->getViewer();

    $color_map = ManiphestTaskPriority::getColorMap();
    $bar_color = idx($color_map, $task->getPriority(), 'grey');

    // 获取每个任务对象的完整字段
    $maniphest_fields = id(new ManiphestEditEngine())
     ->setViewer($viewer)
     ->loadObjectFields($task);

    // 获取每个任务对象的自定义字段的 开始时间 和 结束时间
    $start_date = '';
    $end_date = '';
    foreach ($maniphest_fields as $key => $field) {
      if (strstr($key, 'start date')) {
        $start_date = $field->getValueForDefaults();
      }
      if (strstr($key, 'finish-date')) {
        $end_date = $field->getValueForDefaults();
      }
    }

    $start = '';
    if ($start_date !== '') {
      $start = date("m-d H:i", $start_date);
    }

    $end = '';
    if ($end_date !== '') {
      $end = date("m-d H:i", $end_date);
    }

    $card = id(new PHUIObjectItemView())
      ->setObject($task)
      ->setUser($viewer)
      ->setObjectName('T'.$task->getID())
      ->setHeader($task->getTitle().' '.$start.'-'.$end)
      ->setGrippable($can_edit)
      ->setHref('/T'.$task->getID())
      ->addSigil('project-card')
      ->setDisabled($task->isClosed())
      ->addAction(
        id(new PHUIListItemView())
        ->setName(pht('Edit'))
        ->setIcon('fa-pencil')
        ->addSigil('edit-project-card')
        ->setHref('/maniphest/task/edit/'.$task->getID().'/'))
      ->setBarColor($bar_color);

    if ($owner) {
      $card->addHandleIcon($owner, $owner->getName());
    }

    $cover_file = $this->getCoverImageFile();
    if ($cover_file) {
      $card->setCoverImage($cover_file->getBestURI());
    }

    if (ManiphestTaskPoints::getIsEnabled()) {
      $points = $task->getPoints();
      if ($points !== null) {
        $points_tag = id(new PHUITagView())
          ->setType(PHUITagView::TYPE_SHADE)
          ->setColor(PHUITagView::COLOR_GREY)
          ->setSlimShady(true)
          ->setName($points)
          ->addClass('phui-workcard-points');
        $card->addAttribute($points_tag);
      }
    }

    $subtype = $task->newSubtypeObject();
    if ($subtype && $subtype->hasTagView()) {
      $subtype_tag = $subtype->newTagView()
        ->setSlimShady(true);
      $card->addAttribute($subtype_tag);
    }

    if ($task->isClosed()) {
      $icon = ManiphestTaskStatus::getStatusIcon($task->getStatus());
      $icon = id(new PHUIIconView())
        ->setIcon($icon.' grey');
      $card->addAttribute($icon);
      $card->setBarColor('grey');
    }

    $project_handles = $this->getProjectHandles();

    // Remove any archived projects from the list.
    if ($project_handles) {
      foreach ($project_handles as $key => $handle) {
        if ($handle->getStatus() == PhabricatorObjectHandle::STATUS_CLOSED) {
          unset($project_handles[$key]);
        }
      }
    }

    if ($project_handles) {
      $project_handles = array_reverse($project_handles);
      $tag_list = id(new PHUIHandleTagListView())
        ->setSlim(true)
        ->setHandles($project_handles);
      $card->addAttribute($tag_list);
    }

    $card->addClass('phui-workcard');

    return $card;
  }
```

上面方法中的 $task 由于默认没有自定义字段,并且开始时间和结束时间是定义在自定义字段中的,这里通过如下方式获取到任务对象 $task 的完整字段

```php
// 获取每个任务对象的完整字段
$maniphest_fields = id(new ManiphestEditEngine())
 ->setViewer($viewer)
 ->loadObjectFields($task);
```

其中的 loadObjectFields 方法定义在 ManiphestEditEngine 的父类 PhabricatorEditEngine 中,具体如下

```php
  /**
   * 获取对象的所有字段对象(PhabricatorCustomFieldEditField)
   *
   * author ck
   *
   * @param $object
   * @return array|dict
   */
  public function loadObjectFields($object) {
    $this->loadDefaultConfiguration();
    return $this->buildEditFields($object);
  }
```

## 参考加载编辑任务的流程

这里获取到任务对象 $task 所有的字段,具体参考到了点击编辑任务到加载一个任务的编辑页面的流程,具体如下

```php
ManiphestTaskEditController
	ManiphestEditEngine
		extends PhabricatorEditEngine -> buildResponse -> buildEditResponse -> buildEditFields
```

- 其中 buildEditFields 方法可以拿到一个任务对象的所有字段,包括自定义字段		

- 其中 buildResponse 方法中根据从请求对象 $request 中获取一个 $task 对象的id 获取了一个 $task 对象

```php
$capabilities = array();
...
$id = $request->getURIData('id');
....
$object = $this->newObjectFromID($id, $capabilities);
```

## 总结

通过做这个需求，了解了 Phabricator 如下的技术细节

- workboard 的渲染过程
- PhabricatorEditEngine 加载一个对象的过程