---
title: 在 Phabricator 任务详情页右边增加创建子任务的快捷链接
title_url: Phabricator-subtask
date: 2017-08-01
tags: Phabricator
categories: [Phabricator,PHP]
description: 在 Phabricator 任务详情页右边增加创建子任务的快捷链接
---

## 需求背景

在使用 Phabricator 过程中需要创建不同的任务,又要确保这些任务之间有关联.比如在项目创建了一个主任务后,相关的测试任务和开发任务需要挂在该主任务下,默认情况下 Phabricator 只能在某个任务下创建子任务,不能创建不同的子任务,具体如下

![subtask](http://7xt8a6.com1.z0.glb.clouddn.com/subtask-1.PNG)

这个时候就需要创建不同的任务form(测试任务form和开发任务form),并将这些form的快捷链接放到任务详情页右边,同时将这些form设置为只能编辑,具体如下

![subtask](http://7xt8a6.com1.z0.glb.clouddn.com/subtask-2.PNG)

![subtask](http://7xt8a6.com1.z0.glb.clouddn.com/subtask-3.PNG)

限制 `TestTask` 和 `DevTask` 只能 Edit 不能 Create

![subtask](http://7xt8a6.com1.z0.glb.clouddn.com/subtask-4.PNG)

## 代码变更

根据需求,这里只需要将原来的 `Create Subtask` 链接修改成 `Create TestTask` 和 `Create DevTask` 即可.相关的代码在 `phabricator\src\applications\maniphest\controller\ManiphestTaskDetailController.php` 的 buildCurtain 方法中

具体如下

```php
  private function buildCurtain(
    ManiphestTask $task,
    PhabricatorEditEngine $edit_engine) {
    $viewer = $this->getViewer();

    $id = $task->getID();
    $phid = $task->getPHID();

    $can_edit = PhabricatorPolicyFilter::hasCapability(
      $viewer,
      $task,
      PhabricatorPolicyCapability::CAN_EDIT);

    $can_interact = PhabricatorPolicyFilter::canInteract($viewer, $task);

    // We expect a policy dialog if you can't edit the task, and expect a
    // lock override dialog if you can't interact with it.
    $workflow_edit = (!$can_edit || !$can_interact);

    $curtain = $this->newCurtainView($task);

    $curtain->addAction(
      id(new PhabricatorActionView())
        ->setName(pht('Edit Task'))
        ->setIcon('fa-pencil')
        ->setHref($this->getApplicationURI("/task/edit/{$id}/"))
        ->setDisabled(!$can_edit)
        ->setWorkflow($workflow_edit));

    $edit_config = $edit_engine->loadDefaultEditConfiguration($task);
    $can_create = (bool)$edit_config;

    $can_reassign = $edit_engine->hasEditAccessToTransaction(
      ManiphestTaskOwnerTransaction::TRANSACTIONTYPE);

    if ($can_create) {
      $form_key = $edit_config->getIdentifier();
      $edit_uri = id(new PhutilURI("/task/edit/form/{$form_key}/"))
        ->setQueryParam('parent', $id)
        ->setQueryParam('template', $id)
        ->setQueryParam('status', ManiphestTaskStatus::getDefaultStatus());
      $edit_uri = $this->getApplicationURI($edit_uri);

      // 这里将创建子任务修改成 Create TestTask
      $testtask_edit_uri = id(new PhutilURI("/task/edit/form/6/"))
       ->setQueryParam('parent', $id)
       ->setQueryParam('template', $id)
       ->setQueryParam('subtype', 'test')
       ->setQueryParam('status', ManiphestTaskStatus::getDefaultStatus());
      $testtask_edit_uri = $this->getApplicationURI($testtask_edit_uri);

      // 和 Create DevTask
      $devtask_edit_uri = id(new PhutilURI("/task/edit/form/1/"))
       ->setQueryParam('parent', $id)
       ->setQueryParam('template', $id)
       ->setQueryParam('subtype', 'dev')
       ->setQueryParam('status', ManiphestTaskStatus::getDefaultStatus());
      $devtask_edit_uri = $this->getApplicationURI($devtask_edit_uri);

    } else {
      // TODO: This will usually give us a somewhat-reasonable error page, but
      // could be a bit cleaner.
      $edit_uri = "/task/edit/{$id}/";
      $edit_uri = $this->getApplicationURI($edit_uri);

      $testtask_edit_uri = "/task/edit/6/";
      $testtask_edit_uri = $this->getApplicationURI($testtask_edit_uri);

      $devtask_edit_uri = "/task/edit/1/";
      $devtask_edit_uri = $this->getApplicationURI($devtask_edit_uri);
    }

    $subtask_item = id(new PhabricatorActionView())
      ->setName(pht('Create Subtask'))
      ->setHref($edit_uri)
      ->setIcon('fa-level-down')
      ->setDisabled(!$can_create)
      ->setWorkflow(!$can_create);

    // 测试子任务
    $testtask_item = id(new PhabricatorActionView())
     ->setName(pht('Create TestTask'))
     ->setHref($testtask_edit_uri)
     ->setIcon('fa-level-down')
     ->setDisabled(!$can_create)
     ->setWorkflow(!$can_create);

    // 开发子任务
    $devtask_item = id(new PhabricatorActionView())
     ->setName(pht('Create DevTask'))
     ->setHref($devtask_edit_uri)
     ->setIcon('fa-level-down')
     ->setDisabled(!$can_create)
     ->setWorkflow(!$can_create);

    $relationship_list = PhabricatorObjectRelationshipList::newForObject(
      $viewer,
      $task);

    $submenu_actions = array(
      //$subtask_item,
      $testtask_item,
      $devtask_item,
      ManiphestTaskHasParentRelationship::RELATIONSHIPKEY,
      ManiphestTaskHasSubtaskRelationship::RELATIONSHIPKEY,
      ManiphestTaskMergeInRelationship::RELATIONSHIPKEY,
      ManiphestTaskCloseAsDuplicateRelationship::RELATIONSHIPKEY,
    );

    $task_submenu = $relationship_list->newActionSubmenu($submenu_actions)
      ->setName(pht('Edit Related Tasks...'))
      ->setIcon('fa-anchor');

    $curtain->addAction($task_submenu);

    $relationship_submenu = $relationship_list->newActionMenu();
    if ($relationship_submenu) {
      $curtain->addAction($relationship_submenu);
    }

    $owner_phid = $task->getOwnerPHID();
    $author_phid = $task->getAuthorPHID();
    $handles = $viewer->loadHandles(array($owner_phid, $author_phid));

    if ($owner_phid) {
      $image_uri = $handles[$owner_phid]->getImageURI();
      $image_href = $handles[$owner_phid]->getURI();
      $owner = $viewer->renderHandle($owner_phid)->render();
      $content = phutil_tag('strong', array(), $owner);
      $assigned_to = id(new PHUIHeadThingView())
        ->setImage($image_uri)
        ->setImageHref($image_href)
        ->setContent($content);
    } else {
      $assigned_to = phutil_tag('em', array(), pht('None'));
    }

    $curtain->newPanel()
      ->setHeaderText(pht('Assigned To'))
      ->appendChild($assigned_to);

    $author_uri = $handles[$author_phid]->getImageURI();
    $author_href = $handles[$author_phid]->getURI();
    $author = $viewer->renderHandle($author_phid)->render();
    $content = phutil_tag('strong', array(), $author);
    $date = phabricator_date($task->getDateCreated(), $viewer);
    $content = pht('%s, %s', $content, $date);
    $authored_by = id(new PHUIHeadThingView())
      ->setImage($author_uri)
      ->setImageHref($author_href)
      ->setContent($content);

    $curtain->newPanel()
      ->setHeaderText(pht('Authored By'))
      ->appendChild($authored_by);

    return $curtain;
  }
```

其中的 "/task/edit/form/6/" 和 "/task/edit/form/1/" 链接中的数字 6 和 1 对应自定义form的编号

```php
// 这里将创建子任务修改成 Create TestTask
$testtask_edit_uri = id(new PhutilURI("/task/edit/form/6/"))
->setQueryParam('parent', $id)
->setQueryParam('template', $id)
->setQueryParam('subtype', 'test')
->setQueryParam('status', ManiphestTaskStatus::getDefaultStatus());
$testtask_edit_uri = $this->getApplicationURI($testtask_edit_uri);

// 和 Create DevTask
$devtask_edit_uri = id(new PhutilURI("/task/edit/form/1/"))
->setQueryParam('parent', $id)
->setQueryParam('template', $id)
->setQueryParam('subtype', 'dev')
->setQueryParam('status', ManiphestTaskStatus::getDefaultStatus());
$devtask_edit_uri = $this->getApplicationURI($devtask_edit_uri);
```

具体的替换 `Create Subtask` 链接的代码如下

```php
$subtask_item = id(new PhabricatorActionView())
  ->setName(pht('Create Subtask'))
  ->setHref($edit_uri)
  ->setIcon('fa-level-down')
  ->setDisabled(!$can_create)
  ->setWorkflow(!$can_create);

// 测试子任务
$testtask_item = id(new PhabricatorActionView())
 ->setName(pht('Create TestTask'))
 ->setHref($testtask_edit_uri)
 ->setIcon('fa-level-down')
 ->setDisabled(!$can_create)
 ->setWorkflow(!$can_create);

// 开发子任务
$devtask_item = id(new PhabricatorActionView())
 ->setName(pht('Create DevTask'))
 ->setHref($devtask_edit_uri)
 ->setIcon('fa-level-down')
 ->setDisabled(!$can_create)
 ->setWorkflow(!$can_create);

$relationship_list = PhabricatorObjectRelationshipList::newForObject(
  $viewer,
  $task);

$submenu_actions = array(
  //$subtask_item,
  $testtask_item,
  $devtask_item,
  ManiphestTaskHasParentRelationship::RELATIONSHIPKEY,
  ManiphestTaskHasSubtaskRelationship::RELATIONSHIPKEY,
  ManiphestTaskMergeInRelationship::RELATIONSHIPKEY,
  ManiphestTaskCloseAsDuplicateRelationship::RELATIONSHIPKEY,
);
```

## 具体提交

[提交](https://github.com/toulezu/phabricator/pull/3)

## 总结

通过实现这个需求,可以了解到如下 Phabricator 技术细节

- `PHUICurtainView` 对象用来构建右边的操作菜单.
- 通过 subType 字段来区分不同的 Task 对象
- Task 对象之间的依赖关系