---
title: 深入分析 AngularJS 中 href 属性值由 javascript_void(0) 自动转成 unsafe_javascript_void(0) 的问题
title_url: AngularJS-href-unsafe-javascript-void
date: 2019-07-22
tags: AngularJS
categories: AngularJS
description: 深入分析 AngularJS 中 href 属性值由 javascript_void(0) 自动转成 unsafe_javascript_void(0) 的问题，最后提出两个解决方法。
---

## 1 问题

原始的 html 如下

```html
<li><a href="javascript:void(0)" ng-click="selectPage(1)">首页</a></li>
```

AngularJS 编译后如下

```html
<a href="unsafe:javascript:void(0)" ng-click="selectPage(p)" class="ng-binding">1</a>
```

在 Firefox Quantum 68.0.1 (64 位) 中提示 `unsafe:javascript:void(0)`，点击后浏览器地址栏为：`unsafe:javascript:void(0)`，页面内容如下

```
无法理解该网址

Firefox 不知道如何打开这个地址，因为协议 (unsafe) 未与任何程序关联，或此环境下不可打开该协议的地址。

    您可能需要安装其他软件才能打开此网址。
```

## 2 原因

这里先思考一个问题：为什么 href 和 ng-click 中的表达式都会执行，有先后顺序吗？

- a 链接元素点击后通过 href 和 target 属性可以跳转到指定的页面，如果不需要跳转通过设置: `href="javascript:void(0)"` 即可
- `href="javascript:void(0)"` 表示不进行页面跳转而是执行 `void(0)` 的 javascript 方法，该方法只是用来计算一个空值，事情都不做
- ng-click 属性可以让点击 a 链接元素后触发一个点击事件，执行一个函数，其属性值为一个函数名称
- a 链接元素中 onclick、href、target 在不同浏览器下的处理顺序如下：
    - chrome 下是 onclick、href、target
    - ie和firefox 下是 onclick、target、href

再回到上面的问题，由于 AngularJS 编译后自动加上了 `unsafe:` 前缀，变成了 `unsafe:javascript:void(0)`，因此 Firefox 无法识别这个协议，所以无法执行 `void(0)` 这个函数，浏览器地址栏变成了：`unsafe:javascript:void(0)`，说明进行了跳转，这里可以通过加上 `target="_blank"` 属性验证这一点。

在 Chrome 上没有这个问题，是因为 Chrome 能够识别这个 unsafe 协议。

由此可见，Firefox 和 Chrome 在一些标准上开始出现了不一致的情况，以后这种情况可能会越来越多。

## 3 解决方法

根据上面的原因分析，我们可以通过两种方法来解决这个问题：

1. 方法一：直接去掉 href 属性
2. 方法二：让 AngularJS 不会修改 href 属性值

具体如下

#### 3.1 方法一：直接去掉 href 属性

直接去掉 href 属性，修改成如下的方式

```html
<li><a style="cursor: pointer" ng-click="selectPage(1)">首页</a></li>
```

其中 `style="cursor: pointer"` 可以让 a 链接元素拥有可点击样式，看起来的效果和 href 属性一样。

#### 3.2 让 AngularJS 不会修改 href 属性值

配置编译白名单，让 AngularJS 不会编译 href 属性值中含有正则表达式：`/^\s*(https?|ftp|mailto|tel|file|sms|javascript):/` 指定的内容，具体如下

```javascript
var firstApp = angular.module('firstApp', []);
firstApp.config(['$compileProvider',function ($compileProvider) {
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|tel|file|sms|javascript):/); // 此处是正则表达式
    // Angular v1.2 之前使用 $compileProvider.urlSanitizationWhitelist(...)
}]);
```

## 4 总结

- 实际上这里使用 a 链接元素的目的在于：让待点击的元素拥有一个 a 链接元素的可点击样式，在 css2 中通过 `style="cursor: hand"` 可以实现，在 css3 以上可以通过 `style="cursor: pointer"` 实现，也就是上面的方法一
- 如果依赖的框架中有些 a 链接元素中既有 href 和 ng-click，那么只能通过方法二来解决