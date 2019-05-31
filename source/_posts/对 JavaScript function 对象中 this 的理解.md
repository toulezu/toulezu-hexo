---
title: 对 JavaScript function 对象中 this 的理解
title_url: understand-JavaScript-function-this
date: 2019-05-31
tags: [JavaScript,this]
categories: JavaScript
description: 由 angular.bind 函数联想到有关 JavaScript function 对象中 this 的作用域问题。
---

## 1 概述

最近看到了 [angular.bind](https://docs.angularjs.org/api/ng/function/angular.bind) 函数，其中有个地方吸引了我的注意：函数修改了 function 对象中的 this 和参数。

## 2 angular.bind 的使用

#### 2.1 函数说明

angular.bind 函数具体使用如下

`angular.bind(self, fn, args);`：将 self 对象绑定到 fn 中，通过 args 给 fn 传入参数

- self：Object 类型，在 fn 中通过 this 关键字引用；
- fn: `function()` 类型，最后的返回值也是该 fn 对象
- args: 任意类型，可选，通过 args 给 fn 传入参数

angular.bind 函数从本质上改变了 function 对象中的 this 作用域和参数

#### 2.2 具体使用

```javascript
var self = {
  name: 'boyi'
};

//示例1--带参数
var f = angular.bind(self, // 绑定对象，作为函数的上下文
  // 被绑定的函数
  function(age) {
    console.log(this.name + ' is ' + age + ' !')
  },
  //绑定的参数，可省略
  '15'
);
f(); //调用绑定之后的function

//示例2--不带参数
var m = angular.bind(self, //绑定对象，作为函数的上下文
  //被绑定的函数
  function(age) {
    console.log(this.name + ' is ' + age + ' !')
  }
  //省略参数
);

m(3); //调用传参的函数
```

## 3 JavaScript 中的 this

#### 3.1 表示全局对象

默认情况下 this 是指 全局对象

- `全局对象.fn();`

```javascript
var x = 1;
function test() {
   console.log(this.x);
}
test();  // 1
```

#### 3.2 表示对象本身

对象中的 function 是对象本身，

- `对象.fn();`

```javascript
function test() {
  console.log(this.x);
}

var obj = {};
obj.x = 1;
obj.m = test;

obj.m(); // 1
```

#### 3.3 指定对象

- `apply()` 是函数的一个方法，作用是改变函数的调用对象，通过 `apply()` 可以修改 this 的引用
- 只有一个参数，可以为空，如果为空表示全局对象，如果传入参数 obj, 那么函数中的 this 的引用就指向 obj

```javascript
var x = 0;
function test() {
　console.log(this.x);
}

var obj = {};
obj.x = 1;
obj.m = test;
obj.m.apply() // 0
```

`apply()` 的参数为空时，表示全局对象调用函数。因此，这时的运行结果为 0，证明 this 指的是全局对象。

如果把最后一行代码修改为

```javascript
obj.m.apply(obj); //1
```

运行结果就变成了1，证明了这时this代表的是对象obj。

## 4 参考

- [JavaScript 的 this 用法](http://www.ruanyifeng.com/blog/2010/04/using_this_keyword_in_javascript.html)