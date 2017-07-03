---
title: PHP 基本语法
title_url: PHP-basic
date: 2017-07-03
tags: PHP
categories: PHP
description: PHP 基本语法
---


## => 含义

=> 是用来数组赋值时用的，例子：
```php
<?php
$arr = array("somearray" => array(6 => 5, 13 => 9, "a" => 42));
echo $arr["somearray"][6];    // 5
echo $arr["somearray"][13];   // 9
echo $arr["somearray"]["a"];  // 42
?> 

$_POST = array("Peter"=>"35","Ben"=>"37","Joe"=>"43");
foreach($_POST AS $key=>$value){
  echo "data is " . $key . $value;
}
// foreach是用来遍历数组的.这个是用来遍历$_POST数组.并把数组的键值放到$key中,值放到$value中
```

## -> 箭头操作符

箭头操作符 -> 是对象里面用的,表示调用，例子：

```php
<?php
class foo {
    function do_foo() {
        echo "Doing foo.";
    }
}
$bar = new foo();
$bar->do_foo();
?>
```

## 类型转换

```php
echo (int)'abc1';  //输出0 
echo (int)'1abc'; //输出1 
echo (int)'2abc'; //输出2 
echo (int)'22abc'; //输出22 
```

如果将一个字符串强制转换成一个数字.PHP会去搜索这个字符串的开头.如果开头是数字就转换.如果不是就直接返回0.

## . 点号

用于连接字符串,先连接字符串再运算

```php
echo '5+1=' . 1+5; //输出10 
echo '5+1=' . 5+1; //输出6 
echo '1+5=' . 1+5; //输出6 
echo '1+5=' . 5+1; //输出2 
```
具体是 `'5+1=' . 1` 连接字符串后变成 `5+11`, `5+11` 转成数字后变成 5, 最后 `5+5` 等于10

## , 逗号

用逗号是 `multiple parameters`. 也就是说是多参数.换句话说.
逗号分隔开的就相当于是N个参数.也就是说把echo当个函数用.这样的话 echo 会对每个参数先进行计算.最后再进行连接后输出

```php
echo '1+5=' . 1+5;  //输出 6
echo '1+5=' , 5+1;  //输出 1+5=6 
```

## @ at符号

当php解释器遇到@开头的语句时候，无论本行的语句是否执行成功，都会继续执行后续的语句，而且不会报错。

## :: 双冒号,两个冒号

用于访问静态、const和类中重写的属性与方法, 类不需要实例化, 用箭头操作符`->`必须要将类进行实例化（或者在类的内部调用也可以） 。

```php
<?php
class MyClass {
    const CONST_VALUE = 'A constant value';
}

$classname = 'MyClass';
echo $classname::CONST_VALUE; // 自 PHP 5.3.0 起

echo MyClass::CONST_VALUE;
?>
```

## 参考

- [php中双冒号的应用](http://blog.csdn.net/abandonship/article/details/6459370)