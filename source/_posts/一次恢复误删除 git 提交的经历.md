---
title: 一次恢复误删除 git 提交的经历
title_url: git-commit-recovery
date: 2018-01-11
tags: git
categories: [git]
description: 一次恢复误删除 git 提交的经历
---

## 情况

在 SourceTree 中代码 commit 到了本地仓库，没有 push 到远端, 此时不小心把 commit 到本地的那次提交给删除了或者弄丢了.

## 具体操作

使用命令行模式进入到项目所在路径, 然后执行如下命令:

- `git log -g` 找到丢失代码的分支的 commit_id

- `git branch recover_branch commit_id` 使用 commit_id 来创建分支 recover_branch, 这样丢失的代码就在 recover_branch 分支上了.

## 如何回退 commit

在 SourceTree 中代码 commit 到了本地仓库，没有 push 到远端, 可以在想回退的 commit 上面

```
右键 -> 选择(重置当前分支到此次提交) -> 选择(混合合并 - 保持工作副本并重置索引)
```

点击确定即可.

## 参考

- [从Git仓库中恢复已删除的分支、文件或丢失的commit](http://sumsung753.blog.163.com/blog/static/146364501201301711943864/)