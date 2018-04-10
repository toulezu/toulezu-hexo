---
title: 总结 git 中有关远端仓库和本地仓库的命令
title_url: git-remote-branch-command
date: 2018-04-10
tags: git
categories: [git]
description: 总结 git 中有关远端仓库和本地仓库的命令
---

## 创建空的 git 本地仓库

在一个空的目录下面通过

```
git init
```

来创建一个空的 git 本地仓库, 随后下面有关远端仓库和本地仓库的命令可以用来完成 git 开发环境或者发布环境的搭建.

## 远端仓库相关

- 查看当前所有的远端仓库详情

```
git remote -v
```

- 添加一个 远端仓库

```
git remote add toulezu_pha git@github.com:toulezu/phabricator.git
```

其中 `origin` 是远端的名称, 可以自己起一个, `git@github.com:toulezu/phabricator.git` 远端仓库地址

- 删除一个 远端仓库

```
git remote rm origin
```

- 修改 远端仓库 的名称

```
git remote rename toulezu_pha origin
```

其中 `toulezu_pha` 是现在的名称, `origin` 是修改后的名称

- 查看 远端仓库 的详细信息

```
git remote show origin
```

- 添加远端仓库后, 将所有数据同步到本地

```
git fetch toulezu_pha
```

- 将远端仓库的所有数据同步到本地后, 检出远端仓库的某个分支, 并且该分支追踪远端仓库

```
git checkout -b toulezu_pha_master toulezu_pha/master
```

## 本地仓库相关

- 查看本地仓库的详细信息

```
git branch -vv
```

- 修改本地仓库分支名称

```
git branch -m toulezu_pha_master master
```

其中 `toulezu_pha_master` 是现在的名称, `master` 是修改后的名称

- 修改本地仓库分支名称后设置与远程分支关联

```
git branch master --set-upstream-to origin/master
```

- 删除本地仓库分支

```
git branch -D master
```