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

## .= 的意思

表示字符串累加,类似于 +=，-=

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

## 构造函数和析构函数

```php
<?php
class MyDestructableClass {
   function __construct() { // 构造函数
       print "In constructor\n";
       $this->name = "MyDestructableClass";
   }

   function __destruct() { // 析构函数
       print "Destroying " . $this->name . "\n";
   }
}

$obj = new MyDestructableClass();
?>
```

## 命名空间 和 use

```php
namespace Album\Model;
use Zend\InputFilter\Factory as InputFactory;
use Zend\InputFilter\InputFilter;
use Zend\InputFilter\InputFilterAwareInterface;
use Zend\InputFilter\InputFilterInterface;
class Album implements InputFilterAwareInterface {

}
```

## include 和 include_once

使用方法：include "文件路径";

函数作用：引入另一个php脚本文件，并执行里面的代码

推荐使用：include_once "文件路径";

```php
// 自动加载控制器和模型类 
public static function loadClass($class) {
    $frameworks = __DIR__ . '/' . $class . '.php';
    $controllers = APP_PATH . 'application/controllers/' . $class . '.php';
    $models = APP_PATH . 'application/models/' . $class . '.php';

    if (file_exists($frameworks)) {
        // 加载框架核心类
        include $frameworks;
    } elseif (file_exists($controllers)) {
        // 加载应用控制器类
        include $controllers;
    } elseif (file_exists($models)) {
        //加载应用模型类
        include $models;
    } else {
        // 错误代码
    }
}
```

## require 和 require_once

>最大的区别就是：include在引入不存文件时产生一个警告且脚本还会继续执行，require则会导致一个致命性错误且脚本停止执行。

```php
<?php  
include_once '1.php';  
require_once '1.php';  
include '1.php';  
require '1.php';  
?>  
```

## 以下划线(_)开头的变量和方法

加一个为私有的, 加两个一般都是系统默认的，系统预定义的.

```php
__LINE__ 表示文件中的当前行号。

__FILE__ 表示文件的完整路径和文件名。

__DIR__ 表示文件所在的目录。如果用在被包括文件中，则返回被包括的文件所在的目录。它等价于 dirname(__FILE__)。除非是根目录，否则目录中名不包括末尾的斜杠
```

另外 php规定以两个下划线（__）开头的方法都保留为**魔术方法**，

PHP中的魔术方法有

```php
__construct,
__destruct ,
__call,
__callStatic,
__get, 
__set,
__isset, 
__unset , 
__sleep,
__wakeup, 
__toString,
__set_state, 
__clone, 
__autoload
```

## array_merge和数组相加（+）

- 键名是字符串：

```php
$arr1=array('a'=>'PHP');
$arr2=array('a'=>'JAVA');
//如果键名为字符，且键名相同，array_merge()后面数组元素值会覆盖前面数组元素值
print_r(array_merge($arr1,$arr2));//Array ( [a] => JAVA )
//如果键名为字符，且键名相同，数组相加会将最先出现的值作为结果
print_r($arr1+$arr2);//Array ( [a] => PHP )
```

- 键名是数字：

```php
$arr1=array("C","PHP");
$arr2=array("JAVA","PHP");
//如果键名为数字，array_merge()不会进行覆盖
print_r(array_merge($arr1,$arr2));//Array ( [0] => C [1] => PHP [2] => JAVA [3] => PHP )
//如果键名为数字，数组相加会将最先出现的值作为结果，后面键名相同的会被抛弃
print_r($arr1+$arr2);//Array ( [0] => C [1] => PHP )
```

## clone 关键字与 __clone() 方法

- `clone` 关键字用于克隆一个完全一样的对象,而且克隆以后，两个对象互不干扰。

- `__clone()` 如果想在克隆后改变克隆对象的内容，需要在类中添加一个特殊的 `__clone()` 方法来重写原本的属性和方法。`__clone()` 方法只会在对象被克隆的时候自动调用。

```php
<?php
class Person {
    private $name;
    private $age;

    function __construct($name, $age) {
        $this->name = $name;
        $this->age = $age;
    }

    function say() {
        echo "我的名字叫：".$this->name;
	    echo "我的年龄是：".$this->age."<br />";
    }
    function __clone() {
        $this->name = "我是假的".$this->name;
        $this->age = 30;
    }
}

$p1 = new Person("张三", 20);
$p1->say();
$p2 = clone $p1;
$p2->say();
?>
```

运行例子，输出：

```
我的名字叫：张三 我的年龄是：20
我的名字叫：我是假的张三 我的年龄是：30
```

## 参考

- [php中双冒号的应用](http://blog.csdn.net/abandonship/article/details/6459370)
- [构造函数和析构函数](http://php.net/manual/zh/language.oop5.decon.php#language.oop5.decon)
- [PHP中用下划线开头的变量含义](http://blog.csdn.net/zlking02/article/details/6752256)
- [PHP 1、array_merge和数组相加（+）](http://www.jianshu.com/p/43e9263f82c1)
- [PHP 对象克隆 clone 关键字与 __clone() 方法](http://www.5idev.com/p-php_object_clone.shtml)
- [PHP基础教程](http://www.5idev.com/php-phpbase.shtml)