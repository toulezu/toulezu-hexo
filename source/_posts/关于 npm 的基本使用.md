---
title: 关于 npm 的基本使用
title_url: npm-registry-proxy-install-usage
date: 2019-07-22
tags: npm
categories: npm
description: 本文介绍 npm 依赖的安装，卸载。以及通过设置镜像和代理来安装。
---

## 1 概述

本文介绍 npm 依赖的安装，卸载。以及通过设置镜像和代理来安装。

## 2 镜像 registry

#### 2.1 全局镜像维护

1. 获取当前镜像，默认是: https://registry.npmjs.org

```
npm config get registry
```

2. 设置镜像为 https://registry.npm.taobao.org

```
npm config set registry https://registry.npm.taobao.org
```

3. 删除镜像 https://registry.npm.taobao.org

```
npm config delete registry https://registry.npm.taobao.org
```

#### 2.2 局部镜像

局部镜像是指在安装某个依赖的时候临时使用镜像

1. 下面通过淘宝的 NPM 镜像 `https://registry.npm.taobao.org` 来安装 `node-sass` 组件

```
npm install node-sass --registry=https://registry.npm.taobao.org
```

#### 2.3 镜像地址

- 淘宝 npm 镜像

1. 搜索地址：http://npm.taobao.org/
2. registry 地址：http://registry.npm.taobao.org/

- cnpmjs 镜像

1. 搜索地址：http://cnpmjs.org/
2. registry地址：http://r.cnpmjs.org/

## 3 代理 proxy

1. 设置代理

```
npm config set proxy=http://127.0.0.1:8087
npm config set https-proxy http://server:port
```

2. 使用用户名和密码设置代理

```
npm config set proxy http://username:password@server:port
npm confit set https-proxy http://username:password@server:port
```

3. 删除代理

```
npm config delete proxy
npm config delete https-proxy
```

4. 获取当前代理

```
npm config get proxy
npm config get https-proxy
```

## 4 依赖的安装和卸载

#### 4.1 安装依赖

基本安装命令如下

```
npm i angular-ui-select
```

1. `i` 或者 `install` 表示安装
2. `-g` 或者 `--global` 选项表示全局安装： `npm i -g angular-ui-select` 
    - 带上表示会安装到 npm 组件所在的目录下的 node_modules 文件夹下
    - 不带表示仅安装到当前目录的 node_modules 文件夹下
3. 带上 angular-ui-select@0.19.8 表示安装指定版本的包
4. `-S` 或者 `--save` 选项表示增加在 package.json 中 dependencies 下的对应信息
5. `-D` 或者 `--save-dev` 选项表示增加在 package.json 中 devDependencies 下的对应信息
6. `-O` 或者 `--save-optional` 选项表示增加在 package.json 中 optionalDependencies 下的对应信息
7. `-B` 或者 `--save-bundle` 选项表示增加在 package.json 中 bundleDependencies 下的对应信息

#### 4.2 卸载依赖

基本删除命令如下

```
npm uni angular-ui-select
```

删除本地模块时你应该思考的问题：是否将在 package.json 上的相应依赖信息也消除？

1. `uni` 或者 `uninstall` 选项表示默认删除模块，但不删除留在 package.json 中的对应信息
2. `-g` 或者 `--global` 选项表示全局删除
3. `-S` 或者 `--save` 选项表示删除在 package.json 中 dependencies 下的对应信息
4. `-D` 或者 `--save-dev` 选项表示删除在 package.json 中 devDependencies 下的对应信息
5. `-O` 或者 `--save-optional` 选项表示删除在 package.json 中 optionalDependencies 下的对应信息
6. `-B` 或者 `--save-bundle` 选项表示删除在 package.json 中 bundleDependencies 下的对应信息

## 5 参考

- [npmjs 官网](https://www.npmjs.com/)
- [【npm】利用npm安装/删除/发布/更新/撤销发布包](http://www.cnblogs.com/penghuwan/p/6973702.html)