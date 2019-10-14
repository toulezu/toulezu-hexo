---
title: JSON.stringify() 和 JSON.parse() 使用详解
title_url: JSON-stringify-parse-usage-practice
date: 2019-10-14
tags: [JavaScript]
categories: JavaScript
description: 本文将详解 JSON 中 `parse()` 和 `stringify()` 两个 JavaScript 函数的使用。
---

## 1 概述

本文将详解 JSON 中 `parse()` 和 `stringify()` 两个 JavaScript 函数的使用。

## 2 JSON.parse() 详解

#### 2.1 作用

JSON.parse() 方法用于将一个 JSON 字符串转换为对象。

#### 2.2 语法

```
JSON.parse(text[, reviver])
```

#### 2.3 参数说明：

1. text:必需， 一个有效的 JSON 字符串。
2. reviver: 可选，一个转换结果的函数， 将为对象的每个成员调用此函数。

#### 2.4 返回值

返回给定 JSON 字符串转换后的对象。

#### 2.5 实例

1. 返回给定 JSON 字符串转换后的对象。

- 代码如下

```html
<h2>从 JSON 字符串中创建一个对象</h2>
<p id="demo"></p>
<script>
var text = '{"employees":[' +
	'{"name":"Google","site":"http://www.Google.com" },' +
	'{"name":"Taobao","site":"http://www.taobao.com" }]}';
var jsonObj = JSON.parse(text);

document.getElementById("demo").innerHTML = jsonObj.employees[1].name + " " + jsonObj.employees[1].site;
</script>
```

- 输出如下

```
Taobao http://www.taobao.com
```

2. 可选参数为函数

- 代码如下

```html
<h2>使用可选参数，回调函数</h2>
<p id="demo"></p>
<script>
function replacer(name, val) {
    if ( val && val.constructor === RegExp ) { // 如果是 RegExp 对象，将其转成字符串
        return val.toString();
    } else if ( name === "2") { // 如果键值为 name 通过返回 undefined 将键值对移除
        return undefined;
    } else if ( name === "6") { // 如果键值为 name 通过返回 undefined 将键值对移除
        return val * 2;
    } else {
        return val; // 返回原值
    }
};

var jsonObj = JSON.parse('{"1": 1, "2": 2, "3": {"4": 4, "5": {"6": 6}}}', replacer);
	
document.write("<pre>" + JSON.stringify(jsonObj, null, 4) + "</pre>");// 输出当前属性，最后一个为 ""
document.write("<br>");
</script>
```

- 输出如下

```
{
    "1": 1,
    "3": {
        "4": 4,
        "5": {
            "6": 12
        }
    }
}
```

## 3 JSON.stringify() 详解

#### 3.1 作用

JSON.stringify() 方法用于将 JavaScript 值转换为 JSON 字符串。

#### 3.2 语法

```
JSON.stringify(value[, replacer[, space]])
```

#### 3.3 参数说明：

1. value: 必需， 要转换的 JavaScript 值（通常为对象或数组）。
2 replacer: 可选。用于转换结果的函数或数组。

- 如果 replacer 为函数，则 JSON.stringify 将调用该函数，并传入每个成员的键和值。函数的返回值为键对应的新值。如果此函数返回 undefined，则排除成员。根对象的键是一个空字符串：""。
- 如果 replacer 是一个数组，则仅转换该数组中具有键值的成员。成员的转换顺序与键在数组中的顺序一样。

3. space: 可选，文本添加缩进、空格和换行符，如果 space 是一个数字，则返回值文本在每个级别缩进指定数目的空格，如果 space 大于 10，则文本缩进 10 个空格。space 也可以使用非数字，如：\t。

#### 3.4 返回值：

返回包含 JSON 文本的字符串。

#### 3.5 实例

- 代码如下

```html
<script>
function replacer(name, val) {
    if ( val && val.constructor === RegExp ) { // 如果是 RegExp 对象，将其转成字符串
        return val.toString();
    } else if ( name === 'name' ) { // 如果键值为 name 通过返回 undefined 将键值对移除
        return undefined;
    } else {
        return val; // 返回原值
    }
};
	
var str = {"name":"test JSON", "site":"http://ckjava.com"}
str_pretty1 = JSON.stringify(str)
document.write( "1. 只有一个参数情况：" );
document.write( "<br>" );
document.write("<pre>" + str_pretty1 + "</pre>" );
document.write( "<br>" );
str_pretty2 = JSON.stringify(str, null, 4) //使用四个空格缩进
document.write( "2. 格式化显示 JSON 字符串：" );
document.write( "<br>" );
document.write("<pre>" + str_pretty2 + "</pre>" ); // pre 用于格式化输出
	
str_pretty3 = JSON.stringify(str, replacer, 4) //使用四个空格缩进
document.write( "3. replacer 为函数：" );
document.write( "<br>" );
document.write("<pre>" + str_pretty3 + "</pre>" ); // pre 用于格式化输出
	
str_pretty4 = JSON.stringify(str, ["name"], 4) //只显示 键为 name 的键值对
document.write( "4. replacer 为数组：" );
document.write( "<br>" );
document.write("<pre>" + str_pretty4 + "</pre>" ); // pre 用于格式化输出
</script>
```

- 输出如下

```
1. 只有一个参数情况：

{"name":"test JSON","site":"http://ckjava.com"}


2. 格式化显示 JSON 字符串：

{
    "name": "test JSON",
    "site": "http://ckjava.com"
}

3. replacer 为函数：

{
    "site": "http://ckjava.com"
}

4. replacer 为数组：

{
    "name": "test JSON"
}
```

## 4 参考

- [JavaScript JSON.stringify()](https://www.runoob.com/js/javascript-json-stringify.html)
- [Using a Replacer or Filter with JSON.stringify](https://www.dyn-web.com/tutorials/php-js/json/filter.php)