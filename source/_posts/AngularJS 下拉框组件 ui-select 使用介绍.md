---
title: AngularJS 下拉框组件 ui-select 使用介绍
title_url: AngularJS-ui-select-practice
date: 2019-06-27
tags: [AngularJS,ui-select]
categories: AngularJS
description: AngularJS 下拉框组件 ui-select 使用介绍
---

## 1 概述

一般情况下在 AngularJS 中使用 select 的方式如下

1. 在 Controller 中定义下拉框选项值

```javascript
$scope.envOptions = [
    { key: 'fat', value: 'FAT'},
    { key: 'fws', value: 'FWS'},
    { key: 'uat', value: 'UAT'},
    { key: 'prd', value: 'PRD'}
];

$scope.onEnvChange = function() {
    // 处理
};
```

2. 在页面上使用如下

```html
<div class="form-group">
    <label>环境</label>
    <select ng-model="increment.env" ng-change="onEnvChange()" class="form-control input-group-sm" ng-init="increment.env = 'fat'">
        <option ng-repeat="item in envOptions" value="{{item.key}}">{{item.value}}</option>
    </select>
</div>
```

如果要更加复杂的效果怎么办，比如输入一个字符自动加载相关的选项？下面来一一介绍 ui-select 的安装与具体的使用。

## 2 安装

- npm 依赖 [AngularJS ui-select](https://www.npmjs.com/package/ui-select)
- npm 安装： `npm i ui-select -S`
- 复制到 `app\lib` 目录下
- index.html 引入: 
    - `<script src="lib/ui-select/dist/select.js"></script>`
    - `<link rel="stylesheet" href="lib/ui-select/dist/select.css">`
- js 的 module 中引入

```javascript
angular.module('myApp', [
    'ui.select'
])
```

## 3 基本使用

ui-select 指令包含了如下几个指令

```
ui-select
ui-select-match
ui-select-header
ui-select-choices
ui-select-no-choice
ui-select-footer
uis-open-close
```

基本的使用格式如下

```xml
<ui-select>
  <ui-select-match></ui-select-match>
  <ui-select-header>Top of the list!</ui-select-header>
  <ui-select-choices><ui-select-choices>
  <ui-select-footer>Bottom of the list.</ui-select-footer>
</ui-select>
```

#### 3.1 ui-select

- 使用 `theme="select2"` 主题

#### 3.2 ui-select-choices

- 通过 `refresh="searchApp($select)"` 和 `refresh-delay="300"` 动态从后端 api 搜索下拉选项

#### 3.3 设置通用属性

- 通过 uiSelectConfig 对象

```javascript
(function () {
    'use strict';

    angular.module('myApp.pages.index', ['ui.router', 'daterangepicker', 'angular-uuid', 'ui.select', 'ngSanitize'])
        .config(pageConfig);
    /** @ngInject */
    function pageConfig($stateProvider, uiSelectConfig) {
        $stateProvider.state('index', {
            url: '/index',
            templateUrl: 'pages/index/manage/searchIndex.html',
            controller: 'MyAppCtrl'
        });

        // 设置 ui.select 的通用属性
        uiSelectConfig.theme = 'select2';
        uiSelectConfig.resetSearchInput = false;
        uiSelectConfig.appendToBody = true;
        uiSelectConfig.searchEnabled = true;
    }

})();
```

#### 3.4 html 部分

```html
<div class="form-group">
    <label>appId</label>
    <div class="input-group">
        <ui-select
                ng-model="myApp.app"
                name="app"
                theme="select2"
                append-to-body="true"
                search-enabled="true"
                reset-search-input="false"
                ng-disabled="false"
                style="width: 300px;"
                title="选择一个app"
                required>
            <ui-select-match placeholder="按照 app 的 id，名称，描述进行搜索">
                {{$select.selected.appId}}
            </ui-select-match>
            <ui-select-choices refresh="searchApp($select)" refresh-delay="300" repeat="app in searchRes track by $index">
                <div ng-bind-html="app.appId | highlight: $select.search"></div>
                <h6>
                    appName: {{app.appName}}<br>
                    description: <span ng-bind-html="app.description | highlight: $select.search"></span>
                </h6>
            </ui-select-choices>
        </ui-select>
    </div>
</div>
```

- append-to-body="true" 将下拉列表框追加到输入框下面
- search-enabled="true" 支持搜索下拉框中的内容
- reset-search-input="false" 选择一个选项后清除搜索输入框中的内容
- 其中 `ng-bind-html` 需要依赖 ngSanitize 模块

#### 3.5 js 部分

```javascript
// 默认选择
$scope.searchRes = [{"appId":"123456","appName":"userService","name":"用户信息服务","description":"用户信息服务"}];
$scope.myApp.app = $scope.searchRes[0];

$scope.searchApp = function($select) {
    if (!$select.search) {
        return;
    }
    MyAppService.doSearchApp($select.search)
        .then(
            function (value) {
                $scope.searchRes = value.data;
            },function (value) {
                console.error('searchApp has error, value:' + JSON.stringify(value));
                toastr.error('searchApp has error', '提示', $scope.notificationConfig);
            }
        )
        .catch(function (e) {
            console.error("searchApp has error" + e.toString());
        })
        .finally(function (value) {
            console.log('searchApp finally');
        });
};

function doSearchApp(keyword) {
    var deferred = $q.defer();

    $http.get($localStorage.sysInfo['api_base'] + urls.SLASH + urls.APP_SEARCH, { params : {'keyword': keyword } })
        .then(
            function (response) {
                console.log('doSearchApp successfully');
                deferred.resolve({
                    data: response.data.data
                });
            },
            function (errResponse) {
                console.error('error doSearchApp, errResponse = ' + JSON.stringify(errResponse));
                deferred.reject(errResponse);
            }
        );

    return deferred.promise;
}
```

## 4 使用场景

#### 4.1 如何清空已经选择的选项

1. 如果使用的是 `select2` 主题，可以在 `ui-select-match` 元素中增加 `allow-clear="true"` 属性，选择选项后右边会增加一个 `x` 图标，点击该图标就会清空已经选择的选项，具体如下

```javascript
<ui-select-match allow-clear="true" placeholder="Select or search a country in the list...">
	<span>{{$select.selected.name}}</span>
</ui-select-match>
```

注意：**点击 `x` 图标后会触发 ui-select 的 on-select 事件**
    
2. 手动在 `ui-select-match` 元素内增加一个 `x` 图标，并定义处理逻辑，具体如下
    
```javascript
<ui-select-match placeholder="Select or search a country in the list...">
	<span>{{$select.selected.name}}</span>
	<button class="clear" ng-click="clear($event)"><span class="fa fa-remove"></span></button>
</ui-select-match>
```

3. clear 函数如下

```javascript
$scope.clear = function($event) {
   $event.stopPropagation(); 
   $scope.country.selected = undefined;
};
```

- 参考 [Clear selected option in ui-select angular](https://stackoverflow.com/questions/26389542/clear-selected-option-in-ui-select-angular)    

#### 4.2 搜索选项的时候从 http api 获取数据

1. 在 `ui-select-choices` 元素中增加 `refresh="searchApp($select)"` 和 `refresh-delay="300"` 属性，具体如下

```html
<ui-select-choices refresh="searchApp($select)" refresh-delay="300" repeat="app in searchRes track by $index">
	<div ng-bind-html="app.appId | highlight: $select.search"></div>
	<h6>
		appName: {{app.appName}}<br>
		description: <span ng-bind-html="app.description | highlight: $select.search"></span>
	</h6>
</ui-select-choices>
```

2. searchApp 函数如下

```javascript
$scope.searchApp = function($select) {
	if (!$select.search) {
		return;
	}
	MyAppService.doSearchApp($select.search)
		.then(
			function (value) {
				$scope.searchAppRes = value.data;
			},function (value) {
				console.error('searchApp has error, value:' + JSON.stringify(value));
				toastr.error('searchApp has error', '提示', $scope.notificationConfig);
			}
		)
		.catch(function (e) {
			console.error("searchApp has error" + e.toString());
		})
		.finally(function (value) {
			console.log('searchApp finally');
		});
};
```
    
#### 4.3 搜索选项的时候从数组中筛选数据

通过系统自带的 filter 函数：`mtd in searchAppRes | filter:$select.search track by $index`, 具体使用如下

1. js 如下

```javascript
$scope.searchAppRes = [];
```
    
2. html如下

```html
<div class="form-group">
	<label>方法</label>
	<div class="input-group">
		<ui-select
				ng-model="increment.method"
				name="method"
				ng-disabled="false"
				style="width: 400px;"
				title="选择一个App"
				on-select="submit()">
			<ui-select-match allow-clear="true" placeholder="按照 app 名称进行搜索">
				{{$select.selected}}
			</ui-select-match>
			<ui-select-choices repeat="mtd in searchAppRes | filter:$select.search track by $index">
				<h6><div ng-bind-html="mtd | highlight: $select.search"></div></h6>
				<h5>
					Method: <strong><span ng-bind-html="mtd | serviceOrMethod:1 | highlight: $select.search" /></strong><br>
					Service: <span ng-bind-html="mtd | serviceOrMethod:0 | highlight: $select.search" />
				</h5>
			</ui-select-choices>
			<ui-select-no-choice>
				404: 搜索不到结果
			</ui-select-no-choice>
		</ui-select>
	</div>
</div>
```

## 5 依赖

#### 5.1 [npm textAngular](https://www.npmjs.com/package/textangular) 或者 [npm angular-sanitize](https://www.npmjs.com/package/angular-sanitize)

- 引入 `<script src="lib/angular-sanitize/angular-sanitize.js"></script>`
- 引入 ngSanitize 模块

```
angular.module('ngTest', [
    'ui.select', 'ngSanitize'
])
```

#### 5.2 [npm select2](https://www.npmjs.com/package/select2)

- 使用 `select2@3.4.5` 的版本
- 引入 `<link rel="stylesheet" href="lib/select2/select2.css">`

## 6 参考

- [UI Select 官网](https://angular-ui.github.io/ui-select/)
- [ui-select wiki](https://github.com/angular-ui/ui-select/wiki)