---
title: AngularJS 判断类型函数使用总结
title_url: AngularJS-function-practice
date: 2019-05-31
tags: [AngularJS,函数]
categories: AngularJS
description: AngularJS 中判断类型的函数共有 10 个，类似 9 个`angular.isXXX` 这种以及 `angular.equals`，这里将一一介绍这些函数的使用。
---

## 1 概述

AngularJS 中判断类型的函数共有 10 个，类似 9 个`angular.isXXX` 这种以及 `angular.equals`，这里将一一介绍这些函数的使用。

## 2 angular.isUndefined

- `angular.isUndefined(value);`

#### 2.1 概述

判断 value 是否是 undefined

- 参数 value 可以是任意类型
- 返回值 boolean 类型

#### 2.2 具体使用

```javascript
var a;
console.log("a:%s isUndefined:%s", a, angular.isUndefined(a)); // true
a = "vala";
console.log("a:%s isUndefined:%s", a, angular.isUndefined(a)); // false
a = null;
console.log("a:%s isUndefined:%s", a, angular.isUndefined(a)); // false
a = '';
console.log("a:%s isUndefined:%s", a, angular.isUndefined(a)); // false
a = "";
console.log("a:%s isUndefined:%s", a, angular.isUndefined(a)); // false
a = {};
console.log("a:%s isUndefined:%s", a, angular.isUndefined(a)); // false
console.log("a:%s isUndefined:%s", a, angular.isUndefined(a.name)); // true
a = [];
console.log("a:%s isUndefined:%s", a, angular.isUndefined(a)); // false
a = undefined;
console.log("a:%s isUndefined:%s", a, angular.isUndefined(a)); // true
```

## 3 angular.isDefined

- `angular.isDefined(value);`

#### 3.1 概述

判断参数 value 是否定义

- 参数 value 可以是任意类型
- 返回值 boolean 类型

#### 3.2 具体使用

```javascript
var b;
console.log("b:%s isDefined:%s", b, angular.isDefined(b)); // false
b = "vala";
console.log("b:%s isDefined:%s", b, angular.isDefined(b)); // true
b = null;
console.log("b:%s isDefined:%s", b, angular.isDefined(b)); // true
b = '';
console.log("b:%s isDefined:%s", b, angular.isDefined(b)); // true
b = "";
console.log("b:%s isDefined:%s", b, angular.isDefined(b)); // true
b = {};
console.log("b:%s isDefined:%s", b, angular.isDefined(b)); // true
console.log("b:%s isDefined:%s", b, angular.isDefined(b.name)); // false
b = [];
console.log("b:%s isDefined:%s", b, angular.isDefined(b)); // true
b = undefined;
console.log("b:%s isDefined:%s", b, angular.isDefined(b)); // false
```

## 4 angular.isObject

- `angular.isObject(value);`

#### 4.1 概述

判断 value 是否是 Object，注意数组也认为是 Object

- 参数 value 可以是任意类型
- 返回值 boolean 类型

#### 4.2 具体使用

```javascript
var c;
console.log("c:%s isObject:%s", c, angular.isObject(c)); // false
c = "vala";
console.log("c:%s isObject:%s", c, angular.isObject(c)); // false
c = null;
console.log("c:%s isObject:%s", c, angular.isObject(c)); // false
c = '';
console.log("c:%s isObject:%s", c, angular.isObject(c)); // false
c = "";
console.log("c:%s isObject:%s", c, angular.isObject(c)); // false
c = {};
console.log("c:%s isObject:%s", c, angular.isObject(c)); // true
c = [];
console.log("c:%s isObject:%s", c, angular.isObject(c)); // true
c = undefined;
console.log("c:%s isObject:%s", c, angular.isObject(c)); // false
```

## 5 angular.isString

- `angular.isString(value);`

#### 5.1 概述

判断 value 是否是 String

- 参数 value 可以是任意类型
- 返回值 boolean 类型，字符串，`''` 以及 `""` 都会返回 true

#### 5.2 具体使用

```javascript
var h;
console.log("h:%s isString:%s", h, angular.isString(h)); // false
h = "2014-12-14";
console.log("h:%s isString:%s", h, angular.isString(h)); // true
h = null;
console.log("h:%s isString:%s", h, angular.isString(h)); // false
h = '';
console.log("h:%s isString:%s", h, angular.isString(h)); // true
h = "";
console.log("h:%s isString:%s", h, angular.isString(h)); // true
h = {};
console.log("h:%s isString:%s", h, angular.isString(h)); // false
h = [];
console.log("h:%s isString:%s", h, angular.isString(h)); // false
h = undefined;
console.log("h:%s isString:%s", h, angular.isString(h)); // false
```

## 6 angular.isNumber

- `angular.isNumber(value);`

#### 6.1 概述

判断 value 是否是 Number 对象，注意 `NaN`, `+Infinity` and `-Infinity` 这些特殊的 Number，判断它们也会返回 true, 通过 isFinite 方法判断才返回 false

- 参数 value 可以是任意类型
- 返回值 boolean 类型

#### 6.2 具体使用

```javascript
var j;
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // false
j = "2014-12-14";
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // false
j = null;
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // false
j = '';
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // false
j = "";
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // false
j = {};
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // false
j = [];
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // false
j = undefined;
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // false
j = 12;
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // true
j = NaN;
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // true
j = +Infinity;
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // true
j = -Infinity;
console.log("j:%s isNumber:%s", j, angular.isNumber(j)); // true

console.log("NaN isNaN:%s", isNaN(NaN)); // true
console.log("NaN isFinite:%s", isFinite(NaN)); // false
console.log("+Infinity isFinite:%s", isFinite(+Infinity)); // false
console.log("-Infinity isFinite:%s", isFinite(-Infinity)); // false
```

## 7 angular.isArray

- `angular.isArray(value);`

#### 7.1 概述

判断 value 是否是 Array 对象

- 参数 value 可以是任意类型
- 返回值 boolean 类型

#### 7.2 具体使用

```javascript
var d;
console.log("d:%s isArray:%s", d, angular.isArray(d)); // false
d = "vala";
console.log("d:%s isArray:%s", d, angular.isArray(d)); // false
d = null;
console.log("d:%s isArray:%s", d, angular.isArray(d)); // false
d = '';
console.log("d:%s isArray:%s", d, angular.isArray(d)); // false
d = "";
console.log("d:%s isArray:%s", d, angular.isArray(d)); // false
d = {};
console.log("d:%s isArray:%s", d, angular.isArray(d)); // false
d = [];
console.log("d:%s isArray:%s", d, angular.isArray(d)); // true
d = undefined;
console.log("d:%s isArray:%s", d, angular.isArray(d)); // false
```

## 8 angular.isDate

- `angular.isDate(value);`

#### 8.1 概述

判断 value 是否是 Date 对象

- 参数 value 可以是任意类型
- 返回值 boolean 类型

#### 8.2 具体使用

```javascript
var e;
console.log("e:%s isDate:%s", e, angular.isDate(e)); // false
e = "2014-12-14";
console.log("e:%s isDate:%s", e, angular.isDate(e)); // false
e = new Date();
console.log("e:%s isDate:%s", e, angular.isDate(e)); // true
e = null;
console.log("e:%s isDate:%s", e, angular.isDate(e)); // false
e = '';
console.log("e:%s isDate:%s", e, angular.isDate(e)); // false
e = "";
console.log("e:%s isDate:%s", e, angular.isDate(e)); // false
e = {};
console.log("e:%s isDate:%s", e, angular.isDate(e)); // false
e = [];
console.log("e:%s isDate:%s", e, angular.isDate(e)); // false
e = undefined;
console.log("e:%s isDate:%s", e, angular.isDate(e)); // false
```

## 9 angular.isFunction

- `angular.isFunction(value);`

#### 9.1 概述

判断 value 是否是 Function 对象

- 参数 value 可以是任意类型
- 返回值 boolean 类型

#### 9.2 具体使用

```javascript
var f;
console.log("f:%s isFunction:%s", f, angular.isFunction(f)); // false
f = "2014-12-14";
console.log("f:%s isFunction:%s", f, angular.isFunction(f)); // false
f = function(){};
console.log("f:%s isFunction:%s", f, angular.isFunction(f)); // true
f = null;
console.log("f:%s isFunction:%s", f, angular.isFunction(f)); // false
f = '';
console.log("f:%s isFunction:%s", f, angular.isFunction(f)); // false
f = "";
console.log("f:%s isFunction:%s", f, angular.isFunction(f)); // false
f = {};
console.log("f:%s isFunction:%s", f, angular.isFunction(f)); // false
f = [];
console.log("f:%s isFunction:%s", f, angular.isFunction(f)); // false
f = undefined;
console.log("f:%s isFunction:%s", f, angular.isFunction(f)); // false
```

## 10 angular.isElement

- `angular.isElement(value);`

#### 10.1 概述

判断 value 是否是 DOM element 对象或者 jQuery 对象

- 参数 value 可以是任意类型
- 返回值 boolean 类型

#### 10.2 具体使用

```javascript
var g;
console.log("g:%s isElement:%s", g, angular.isElement(g)); // false
g = "2014-12-14";
console.log("g:%s isElement:%s", g, angular.isElement(g)); // false
g = document.getElementById('eleTest'); // 原生js
console.log("g:%s isElement:%s", g, angular.isElement(g)); // true
g = angular.element(document).find('#eleTest'); // angularJS 内置jQuery
console.log("g:%s isElement:%s", g, angular.isElement(g)); // true
g = $('#eleTest'); // jQuery 的方式
console.log("g:%s isElement:%s", g, angular.isElement(g)); // true
g = null;
console.log("g:%s isElement:%s", g, angular.isElement(g)); // false
g = '';
console.log("g:%s isElement:%s", g, angular.isElement(g)); // false
g = "";
console.log("g:%s isElement:%s", g, angular.isElement(g)); // false
g = {};
console.log("g:%s isElement:%s", g, angular.isElement(g)); // false
g = [];
console.log("g:%s isElement:%s", g, angular.isElement(g)); // false
g = undefined;
console.log("g:%s isElement:%s", g, angular.isElement(g)); // false
```

## 11 angular.equals

- `angular.equals(o1, o2);`

#### 11.1 概述

- 参数 o1 和 o2 可以是任意类型
- 返回值 boolean 类型

- 判断两个对象或者两个值是否相等，判断的对象或者类型包括：值对象，正则表达式，数组，对象
- 如果两个对象相等，那么必须至少满足下面任意一个条件
	1. 都是对象或者值，并且 `o1===o2`
	2. 如果是对象，那么对象中的所有属性一致，如果是值，那么值的类型必须一致并且相等（===）
	3. 都是 NaN
	4. 都是正则表达式，angular.equals(/abc/, /abc/) 返回值为 true
- 在比较中，对象中的方法属性或者属性以`$`开头将被忽略

#### 11.2 具体使用

```javascript
// angular.equals
var h;
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
h = "2014-12-14";
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
h = new Date();
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
h = function(){};
var h2 = function(){ var abc = 'abcd'; };
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
console.log("h:%s equals:%s", h2, angular.equals(h, h2)); // false
h = null;
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
h = '';
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
h = "";
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
h = {};
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
console.log("h:%s equals:%s", h, angular.equals(h, {'name':'joe'})); // false
h = [];
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
h = undefined;
console.log("h:%s equals:%s", h, angular.equals(h, h)); // true
```

## 12 参考

- [AngularJS 函数官方文档](https://docs.angularjs.org/api/ng/function)
- [plnkr 代码](https://embed.plnkr.co/UoISeN/)