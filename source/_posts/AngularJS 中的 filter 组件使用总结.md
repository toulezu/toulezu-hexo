---
title: AngularJS 中的 filter 组件使用总结
title_url: AngularJS-filter-practice
date: 2019-03-26
tags: [AngularJS,filter]
categories: AngularJS
description: AngularJS 中的 filter 组件使用总结：包含系统自带 Filter 使用和自定义 Filter 的使用，以及一些使用场景的举例。
---

## 基本使用

#### 1. 两种使用方法

1. html 中使用：`{% raw %}{{ currency_expression | currency : symbol : fractionSize}}{% endraw %}`
    * `|` 左边的 `currency_expression` 为 源，右边使用 `:` 分隔，第一个参数表示 filter 名称，后面 `symbol` 和 `fractionSize` 是参数
2. JavaScript 中使用：`$filter('currency')(amount, symbol, fractionSize)`
    * 首先方法中引入 `$filter` 依赖
    * `currency` 表示 filter 名称， `amount` 表示 源，`symbol`, `fractionSize` 表示其他参数

#### 2. 系统自带 Filter 组件介绍

1. filter 从数组对象中获取新的数组：`{% raw %}{{ filter_expression | filter : expression : comparator : anyPropertyKey}}{% endraw %}`，使用如下
    - friends 为静态的数组， searchText 为用户的输入，根据用户的输入过滤将返回数组中所有 like `%searchText%` 的内容，并返回新的数组
    ```html
    <div ng-init="friends = [{name:'John', phone:'555-1276'},
                         {name:'Mary', phone:'800-BIG-MARY'},
                         {name:'Mike', phone:'555-4321'},
                         {name:'Adam', phone:'555-5678'},
                         {name:'Julie', phone:'555-8765'},
                         {name:'Juliette', phone:'555-5678'}]"></div>
    <label>Search: <input ng-model="searchText"></label>
    <table id="searchTextResults">
      <tr><th>Name</th><th>Phone</th></tr>
      <tr ng-repeat="friend in friends | filter:searchText">
        <td>{{friend.name}}</td>
        <td>{{friend.phone}}</td>
      </tr>
    </table>
    ```

2. currency 格式化金额：  `{% raw %}{{ currency_expression | currency : symbol : fractionSize}}{% endraw %}`，使用如下
    - amount 为 1234.56
    - `{% raw %}{{amount | currency:"USD$ ":2}}{% endraw %}`，返回 `USD$ 1,234.56`
    - `{% raw %}{{amount | currency:"￥":2}}{% endraw %}`，返回 `￥1,234.56`
    - `{% raw %}{{amount | currency:"￥":0}}{% endraw %}`，返回 `￥1,234`

3. date 格式化日期 `{% raw %}{{ date_expression | date : format : timezone}}{% endraw %}`
    - val 为 1288323623006 
    - `{% raw %}{{val | date:'medium'}}{% endraw %}`，返回 Oct 29, 2010 11:40:23 AM
    - `{% raw %}{{val | date:'yyyy-MM-dd HH:mm:ss Z'}}{% endraw %}`，返回 2010-10-29 11:40:23 +0800
    - `{% raw %}{{val | date:'MM/dd/yyyy @ h:mma'}}{% endraw %}`，返回 10/29/2010 @ 11:40AM
    - `{% raw %}{{val | date:"MM/dd/yyyy 'at' h:mma"}}{% endraw %}`，返回 10/29/2010 at 11:40AM

4. number 格式化小数 `{% raw %}{{ number_expression | number : fractionSize}}{% endraw %}`
    - val 为 1234.56789
    -  `{% raw %}{{val | number}}{% endraw %}`，返回 1,234.568
    -  `{% raw %}{{val | number:0}}{% endraw %}`，返回 1,235
    -  `{% raw %}{{val | number:0}}{% endraw %}`，返回 -1,234.5679

5. json 格式化 JSON 对象 `{% raw %}{{ json_expression | json : spacing}}{% endraw %}`, spacing 表示次行的缩进的空格数，默认2个
    - val 为 `{'name':'value'}`
    - `{% raw %}{{val | json}}{% endraw %}`，返回如下
    ```json
    {
      "name": "value"
    }
    ```
    -  `{% raw %}{{val | json:4}}{% endraw %}`，返回如下
    ```
    {
        "name": "value"
    }
    ```
    
6. lowercase 转成小写格式 `{% raw %}{{ lowercase_expression | lowercase}}{% endraw %}`
    - val 为 abc
    -  `{% raw %}{{val | lowercase}}{% endraw %}`，返回 abc

7. uppercase 转成大写格式 `{% raw %}{{ uppercase_expression | uppercase}}{% endraw %}`
    - val 为 abc
    -  `{% raw %}{{val | uppercase}}{% endraw %}`，返回 ABC

8. limitTo 截取字符串或者元素 `{% raw %}{{ limitTo_expression | limitTo : limit : begin}}{% endraw %}`
    - str 为 abcdefghi 
    -  `{% raw %}{{str | limitTo:3}}{% endraw %}`，返回 abc
    - numbers 为 [1,2,3,4,5,6,7,8,9]
    -  `{% raw %}{{numbers | number:3}}{% endraw %}`，返回 [1,2,3]

9. orderBy 数组排序 `{% raw %}{{ orderBy_expression | orderBy : expression : reverse : comparator}}{% endraw %}`
    - expression 数组中的键, comparator 函数对象
    - js 如下
    ```javascript
    $scope.friends = [
        {name: 'John',   favoriteLetter: 'Ä'},
        {name: 'Mary',   favoriteLetter: 'Ü'},
        {name: 'Mike',   favoriteLetter: 'Ö'},
        {name: 'Adam',   favoriteLetter: 'H'},
        {name: 'Julie',  favoriteLetter: 'Z'}
      ];
    
    $scope.localeSensitiveComparator = function(v1, v2) {
        // If we don't get strings, just compare by index
        if (v1.type !== 'string' || v2.type !== 'string') {
          return (v1.index < v2.index) ? -1 : 1;
        }
    
        // Compare strings alphabetically, taking locale into account
        return v1.value.localeCompare(v2.value);
      };
    ```
    - html 如下
    ```html
    <table class="friends">
      <tr>
        <th>Name</th>
        <th>Favorite Letter</th>
      </tr>
      <tr ng-repeat="friend in friends | orderBy:'favoriteLetter':false:localeSensitiveComparator">
        <td>{{friend.name}}</td>
        <td>{{friend.favoriteLetter}}</td>
      </tr>
    </table>
    ```
## 自定义使用

- 根据系统自带的 filter 函数在 JavaScript 中的使用方式：`$filter('currency')(amount, symbol, fractionSize)`, 可以得出如下结论
    1. `$filter('currency')`: $filter 本身是一个函数，传入一个字符串 `currency`, 然后再返回一个函数，名称叫 `currency`
    2. `currency` 函数的参数就是 `amount`, `symbol`, `fractionSize`
    3. 最后执行
    
- 自定义 filter 函数 methodLink 如下
    - 功能：字符串之间通过 `\n` 分隔，通过 methodLink 函数返回字符串数组
    - `input` 参数为待分隔的字符串
    - js 如下
    ```javascript
    (function () {
        'use strict';
    
        angular.module('ngApp', [])
            .filter('methodLink', function () {
                return function(input) {
                    var methodLinkArr = [];
                    var methodArr = input.split("\n");
                    angular.forEach(methodArr, function (data) {
                        if (data != '') {
                            methodLinkArr.push(data);
                        }
                    });
                    return methodLinkArr;
                };
            });
            
    })();    
    ```

    - html 中使用如下
    ```html
    <span ng-repeat="method in rowData.localMethod | methodLink">
        {{method}}
    </span>
    ```

## 使用场景

#### 1. 截取字符串长度

- 在模块中定义 cut filter
    - `cut` 参数表示自定义 filter 名称
    - `wordwise (boolean)` 参数表示是否截取，true 表示截取
    - `max (integer)` 参数表示保留字符串的长度
    - `tail (string, default: ' …')` 参数表示字符串截取后用 `' …'` 替换
    - js 定义如下
    ```javascript
    angular.module('ngApp')
        .filter('cut', function () {
            return function (value, wordwise, max, tail) {
                if (!value) return '';
    
                max = parseInt(max, 10);
                if (!max) return value;
                if (value.length <= max) return value;
    
                value = value.substr(0, max);
                if (wordwise) {
                    var lastspace = value.lastIndexOf(' ');
                    if (lastspace !== -1) {
                      //Also remove . and , so its gives a cleaner result.
                      if (value.charAt(lastspace-1) === '.' || value.charAt(lastspace-1) === ',') {
                        lastspace = lastspace - 1;
                      }
                      value = value.substr(0, lastspace);
                    }
                }
    
                return value + (tail || ' …');
            };
        });
    ```
	- html 中使用如下
    ```html
    {{some_text | cut:true:100:' ...'}}
    ```
    
#### 2. 将字符串分隔成数组

- 字符串为 `com.ckjava.service.AnalysisStockService.doAnalysis`, 通过 javascript 的 `substring` 和 `lastIndexOf` 函数将服务名和方法分隔到一个数组中

- filter 名为 `serviceOrMethod`
    - `input` 参数为待分隔的字符串
    - `index` 参数为数组中的索引
    - js 定义如下

    ```javascript
    angular.module('ngApp')
        .filter('serviceOrMethod', function () {
                return function(input,index) {
                    var serviceMethodArr = [];
                    if (!input) {
                        return '';
                    }
    
                    serviceMethodArr.push(input.substring(0, input.lastIndexOf(".")));
                    serviceMethodArr.push(input.substring(input.lastIndexOf(".")+1));
                    return serviceMethodArr[index];
                };
            });
    ```
- 这里在 `ui-select-choices` 中使用，具体如下

    ```html
    <ui-select-choices refresh="searchMethod($select)" refresh-delay="300" repeat="mtd in searchMethodBuffer track by $index">
        <h6><div ng-bind-html="mtd | highlight: $select.search"></div></h6>
        <h5>
            Method: <strong><span ng-bind-html="mtd | serviceOrMethod:1 | highlight: $select.search" /></strong><br>
            Service: <span ng-bind-html="mtd | serviceOrMethod:0 | highlight: $select.search" />
        </h5>
    </ui-select-choices>
    ```

#### 3. 将字符串分隔成数组并直接使用

- 将通过 `\n` 换行符的字符串，具体如下
    
    ```
    com.ckjava.service.AnalysisStockService.doAnalysis
    com.ckjava.service.AnalysisStockService.findLastNUp
    com.ckjava.service.AnalysisStockService.getIsAnalysis
    ```
    
- filter 定义如下
    - `input` 参数为函数输入值
    - js 定义如下

    ```javascript
    angular.module('ngApp')
        .filter('methodLink', function () {
            return function(input) {
                var methodLinkArr = [];
                var methodArr = input.split("\n");
                angular.forEach(methodArr, function (data) {
                    if (data != '') {
                        methodLinkArr.push(data);
                    }
                });
                return methodLinkArr;
            };
        });
    ```
    
- 具体使用如下
    ```html
    <span ng-repeat="method in rowData.localMethod | methodLink">
        {{method}}
    </span>
    ```

#### 4. 根据值的不同返回不同的颜色

- filter 定义如下
    - `input` 参数为函数输入值
    - js 定义如下

    ```javascript
    angular.module('ngApp')
        .filter('colorType', function() {
            return function(input) {
                if (input === 'ERROR') {
                    return '#C9302C';
                } else if (input === 'EXECUTING') {
                    return '#FFFF01';
                } else if (input === 'COMPLETED') {
                    return '#63BBB2';
                } else {
                    return ''
                }
            };
        });
    ```
    
- 具体使用如下
    ```html
    <td style="background-color: {{ item.status | colorType }}">{{item.status}}</td>
    ```

## 参考

- [Filter components in ng](https://docs.angularjs.org/api/ng/filter);