---
title: Phabricator 在创建项目的时候自动创建一个 Herald 规则
title_url: Phabricator-project-Herald
date: 2017-07-22
tags: [Phabricator]
categories: Phabricator
description: Phabricator 在创建项目的时候自动创建一个 Herald 规则
---

## 问题描述

Phabricator 默认在添加一个新的项目成员的时候是不会给新成员发生邮件的，需要手工创建一个 Herald 规则。
所以为了便于维护，需要扩展一个功能，具体就是：Phabricator 在创建项目的时候自动创建一个 Herald 规则。这个规则具体如下

![herald1](http://7xt8a6.com1.z0.glb.clouddn.com/herald1.PNG)

从代码角度理解如下

```php
// 手动插入规则信息, $object 是保存成功后的项目对象
$projectInfo = array($object->getPHID() => $object->getDisplayName());
$data['conditions'] = array(array("projects.exact","any",$projectInfo));
$data['actions'] = array(array("email.other", $projectInfo));
```

## 解决

- 具体就是要在项目保存成功后获取到新项目的id和名称，然后再保存一个 Herald 规则

- 并且项目更新的时候避免再新增 Herald 规则

在 Phabricator 现有的代码基础上新增的代码如下

![herald2](http://7xt8a6.com1.z0.glb.clouddn.com/herald3.PNG)

新增的 saveProjectNotificationRule 方法具体如下：

```php
/**
 * 新增加项目的时候自动增加一个通知规则 herald
 *
 * author ck
 *
 * @param AphrontRequest $request
 * @param PhabricatorUser $viewer
 * @param PhabricatorProject $object
 * @return array
 */
private function saveProjectNotificationRule(AphrontRequest $request, PhabricatorUser $viewer, PhabricatorProject $object) {
  $adapter = HeraldAdapter::getAdapterForContentType('PhabricatorProjectHeraldAdapter');

  // 手动构造一个form请求
  $request_data = array();
  $request_data['name'] = 'herald_rule_for_'.$object->getDisplayName();
  $request_data['must_match'] = 'all';
  $request_data['repetition_policy'] = 'every';
  $request_data['__csrf__'] = $request->getRequestData()['__csrf__']; //保留token否则添加失败

  // 手动构造一个通知规则
  $rule = new HeraldRule();
  $rule->setAuthorPHID($viewer->getPHID());
  $rule->setMustMatchAll(1);
  $rule->setContentType('PhabricatorProjectHeraldAdapter');
  $rule->setRuleType('global');
  $rule->setConfigVersion(38);

  $rule_conditions = $rule->loadConditions();
  $rule_actions = $rule->loadActions();

  $rule->attachConditions($rule_conditions);
  $rule->attachActions($rule_actions);
      
  $request->setRequestData($request_data);
  
  $new_name = $request->getStr('name');
  $match_all = ($request->getStr('must_match') == 'all');
  
  $repetition_policy_param = $request->getStr('repetition_policy');
  
  $e_name = true;
  $errors = array();

  // 手动插入规则信息
  $projectInfo = array($object->getPHID() => $object->getDisplayName());
  $data['conditions'] = array(array("projects.exact","any",$projectInfo));
  $data['actions'] = array(array("email.other", $projectInfo));

  $conditions = array();
  foreach ($data['conditions'] as $condition) {
      if ($condition === null) {
          // We manage this as a sparse array on the client, so may receive
          // NULL if conditions have been removed.
          continue;
      }

      $obj = new HeraldCondition();
      $obj->setFieldName($condition[0]);
      $obj->setFieldCondition($condition[1]);

      if (is_array($condition[2])) {
          $obj->setValue(array_keys($condition[2]));
      } else {
          $obj->setValue($condition[2]);
      }

      try {
          $adapter->willSaveCondition($obj);
      } catch (HeraldInvalidConditionException $ex) {
          $errors[] = $ex->getMessage();
      }

      $conditions[] = $obj;
  }

  $actions = array();
  foreach ($data['actions'] as $action) {
      if ($action === null) {
          // Sparse on the client; removals can give us NULLs.
          continue;
      }

      if (!isset($action[1])) {
          // Legitimate for any action which doesn't need a target, like
          // "Do nothing".
          $action[1] = null;
      }

      $obj = new HeraldActionRecord();
      $obj->setAction($action[0]);
      $obj->setTarget($action[1]);

      try {
          $adapter->willSaveAction($rule, $obj);
      } catch (HeraldInvalidActionException $ex) {
          $errors[] = $ex->getMessage();
      }

      $actions[] = $obj;
  }

  if (!$errors) {
      $new_state = id(new HeraldRuleSerializer())->serializeRuleComponents(
          $match_all,
          $conditions,
          $actions,
          $repetition_policy_param);

      $xactions = array();
      $xactions[] = id(new HeraldRuleTransaction())
      ->setTransactionType(HeraldRuleTransaction::TYPE_EDIT)
      ->setNewValue($new_state);
      $xactions[] = id(new HeraldRuleTransaction())
      ->setTransactionType(HeraldRuleTransaction::TYPE_NAME)
      ->setNewValue($new_name);

      try {
          id(new HeraldRuleEditor())
          ->setActor($viewer)
          ->setContinueOnNoEffect(true)
          ->setContentSourceFromRequest($request)
          ->applyTransactions($rule, $xactions);
          return array(null, null);
      } catch (Exception $ex) {
          $errors[] = $ex->getMessage();
      }
  }

  return array($e_name, $errors);
}
```

在完成这个功能的时候具体需要了解 Herald 规则的具体创建过程，具体参考 `phabricator\src\applications\herald\controller\HeraldRuleController.php` 中的 `saveRule` 方法。

## 遇到的问题

在所有的工作快完成的时候遇到了如下的一个问题

```
You are trying to save some data to Phabricator, but the request your browser made included an incorrect token. Reload the page and try again. You may need to clear your cookies.
This was a Web request.
This request had no CSRF token.
To avoid this error, use phabricator_form() to construct forms. If you are already using phabricator_form(), make sure the form 'action' uses a relative URI (i.e., begins with a '/'). Forms using absolute URIs do not include CSRF tokens, to prevent leaking tokens to external sites.

If this page performs writes which do not require CSRF protection (usually, filling caches or logging), you can use AphrontWriteGuard::beginScopedUnguardedWrites() to temporarily bypass CSRF protection while writing. You should use this only for writes which can not be protected with normal CSRF mechanisms.

Some UI elements (like PhabricatorActionListView) also have methods which will allow you to render links as forms (like setRenderAsForm(true)).
```

具体出现在

```php
try {
  id(new HeraldRuleEditor())
  ->setActor($viewer)
  ->setContinueOnNoEffect(true)
  ->setContentSourceFromRequest($request)
  ->applyTransactions($rule, $xactions);
  return array(null, null);
} catch (Exception $ex) {
  $errors[] = $ex->getMessage();
}
```

找了很多地方，最终发现 `$request` 对象的 `$request_data` 数组中缺少了 `__csrf__`, 通过如下的方式加上后不再报错

```php
$request_data['__csrf__'] = $request->getRequestData()['__csrf__']; //保留token否则添加失败
```

本人猜测这个属性在保存对象的时候与请求绑定，并不与具体的对象绑定，因为这个请求是本来是用来保存项目对象的。

## 具体的代码

- [提交](https://github.com/toulezu/phabricator/commit/99ac508712b39e316ce07597acc6208b3b6193dc)