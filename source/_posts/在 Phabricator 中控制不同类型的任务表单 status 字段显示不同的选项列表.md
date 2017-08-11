---
title: 在 Phabricator 中控制不同类型的任务表单 status 字段显示不同的选项列表
title_url: Phabricator-task-subType
date: 2017-08-11
tags: Phabricator
categories: [Phabricator,PHP]
description: 在 Phabricator 中控制不同类型的任务表单 status 字段显示不同的选项列表
---

## 需求背景

在使用 Phabricator 过程中,会有不同的任务类型:主任务,开发子任务,测试子任务,Bug, 通过现有的配置,所有的任务表单的 status 字段的选项列表都是一样的.所以需要通过修改代码来实现这一功能.

## 具体实现

在修改过程中具体要注意两点:新建任务和修改任务.

1. 新建任务的地方修改如下

- PhabricatorEditEngine.php 的 buildEditResponse 方法

```php
private function buildEditResponse($object) {
    $viewer = $this->getViewer();
    $controller = $this->getController();
    $request = $controller->getRequest();

    $fields = $this->buildEditFields($object);
    $template = $object->getApplicationTransactionTemplate();

    if ($this->getIsCreate()) {
      $cancel_uri = $this->getObjectCreateCancelURI($object);
      $submit_button = $this->getObjectCreateButtonText($object);
    } else {
      $cancel_uri = $this->getEffectiveObjectEditCancelURI($object);
      $submit_button = $this->getObjectEditButtonText($object);
    }

    $config = $this->getEditEngineConfiguration()
      ->attachEngine($this);

    // 新增任务的时候根据form的配置来手动定义status下拉框的值
    $status_editfield = $fields['status'];
    if ($object instanceof ManiphestTask &&
      $status_editfield instanceof PhabricatorSelectEditField) {

      $status_option = array();
      if ($config->getSubtype() === 'default') {
        $status_option = array(
         'open' => 'Open',
         'test' => 'Test',
         'closed' => 'Closed',
        );
      }
      if ($config->getSubtype() === 'test') {
        $status_option = array(
         'open' => 'Open',
         'closed' => 'Closed',
        );
      }
      if ($config->getSubtype() === 'dev') {
        $status_option = array(
         'open' => 'Open',
         'closed' => 'Closed',
        );
      }
      if ($config->getSubtype() === 'bug') {
        $status_option = array(
         'open' => 'Open',
         'resolved' => 'Resolved',
         'wontfix' => 'Wontfix',
         'invalid' => 'Invalid',
         'closed' => 'Closed',
        );
      }

      $status_editfield->setOptions($status_option);
    }
    
    //...
}
```

新建任务的时候,任务对象的 subtype 字段默认为 'default',这时只能根据 PhabricatorEditEngineConfiguration 对象的 subtype 字段来判断新建的任务使用的是那种表单类型.

这里根据 `$status_editfield = $fields['status'];` 来获取 status 下拉框对象,然后重置选项列表.

2. 修改任务的地方修改如下

- PhabricatorSelectEditField.php 的 getOptions 方法

```php
  public function getOptions() {
    if ($this->options === null) {
      throw new PhutilInvalidStateException('setOptions');
    }
    // 编辑任务对象,任务对象必须存在,根据不同类型的任务对象来设置不同的 status 选项
    if ($this->getObject() !== null &&
        $this->getObject()->getPHID() !== null &&
        $this->getObject() instanceof ManiphestTask &&
        $this->getKey() === 'status') {
      if ($this->getObject()->getEditEngineSubtype() === 'default') {
        return array(
         'open' => 'Open',
         'test' => 'Test',
         'closed' => 'Closed',
        );
      }
      if ($this->getObject()->getEditEngineSubtype() === 'test') {
        return array(
         'open' => 'Open',
         'closed' => 'Closed',
        );
      }
      if ($this->getObject()->getEditEngineSubtype() === 'dev') {
        return array(
         'open' => 'Open',
         'closed' => 'Closed',
        );
      }
      if ($this->getObject()->getEditEngineSubtype() === 'bug') {
        return array(
         'open' => 'Open',
         'resolved' => 'Resolved',
         'wontfix' => 'Wontfix',
         'invalid' => 'Invalid',
         'closed' => 'Closed',
        );
      }
    }

    return $this->options;
  }
```

修改任务的时候已经可以根据任务对象的 getEditEngineSubtype() 字段来区分不同的表单,随后就重置选项列表.