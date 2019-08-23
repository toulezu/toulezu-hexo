---
title: 解决 Mysql 在 Delete 语句中使用子查询时遇到的问题
title_url: Mysql-Delete-error-you-cant-specify-target-table-x-for-update-in-from
date: 2019-08-23
tags: MySql
categories: MySql
description: 解决 Mysql 在 Delete 语句中使用子查询时遇到的问题
---

## 1 问题

错误提示如下

```
You can't specify target table 'x' for update in FROM clause
```

出现问题的语句如下

```
DELETE FROM publish_plan_log WHERE id IN (
SELECT l.id FROM publish_plan_log l WHERE NOT EXISTS (SELECT 1 FROM publish_plan pp WHERE pp.id = l.plan_id)
)
```

## 2 原因

原因是 Mysql 不允许在更新一个表的同时又查询了该表。

解决的方法也很简单：在查询的时候包裹一层。具体如下

```
DELETE FROM publish_plan_log WHERE id IN (
SELECT l.id FROM (SELECT * FROM publish_plan_log) l WHERE NOT EXISTS (SELECT 1 FROM publish_plan pp WHERE pp.id = l.plan_id)
)
```

## 3 参考

- [How to resolve MySQL error “You can't specify target table X for update in FROM clause”? [duplicate]](https://stackoverflow.com/questions/37251621/how-to-resolve-mysql-error-you-cant-specify-target-table-x-for-update-in-from)