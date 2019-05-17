---
title: Java 8 Lambda 表达式介绍
title_url: understand-Java-8-Lambda
date: 2019-05-17
tags: [Java,Lambda]
categories: 技术
description: Java 8 Lambda 表达式介绍
---

## 1 概要

- Lambda 表达式，也可称为闭包或者内部类，返回的是一个接口的实例，是 Java 8 的最重要新特性。
- 使用 Lambda 表达式可以使代码变的更加简洁紧凑。

## 2 语法

lambda 表达式的语法格式如下：

```
(parameters) -> expression
```
或
```
(parameters) -> { statements; }
```

以下是 lambda 表达式的重要特征:

1. 可选类型声明：不需要声明参数类型，编译器可以统一识别参数值。
2. 可选的参数圆括号：一个参数无需定义圆括号，但多个参数需要定义圆括号。
3. 可选的大括号：如果主体包含了一个语句，就不需要使用大括号。
4. 可选的返回关键字：如果主体只有一个表达式返回值则编译器会自动返回值，大括号需要指定明表达式返回了一个数值。

#### 2.1 可选类型声明

```java
@FunctionalInterface
public interface Append<T> {

    String doAppend(T t1, T t2);
}
```

```java
public class AppendUtils {

    public static <T> String append(T t1, T t2, Append<T> append) {
        return append.doAppend(t1, t2);
    }
}
```

```java
@Test
public void test1 () {
    String str = AppendUtils.append(1, 2, (Integer t1, Integer t2) -> {return t1.toString() + t2.toString();});
    System.out.println(str);
    str = AppendUtils.append(1, 2, (t1, t2) -> {return t1.toString() + t2.toString();});
    System.out.println(str);
}
```

- `(Integer t1, Integer t2) -> {return t1.toString() + t2.toString();}`
- `(t1, t2) -> {return t1.toString() + t2.toString();}`

上面的 Lambda 表达式实现的效果是一样的。

#### 2.2 可选的参数圆括号

```java
@FunctionalInterface
public interface StringParse<T> {
    String parseString(T t);
}
```

```java
public class StringParseUtils {

    public static <T> String parse(T t, StringParse<T> stringParse) {
        return stringParse.parseString(t);
    }
}
```

```java
@Test
public void test4() {
    String str = StringParseUtils.parse(1, (t) -> t.toString());
    System.out.println(str);
    str = StringParseUtils.parse(1, t -> t.toString());
    System.out.println(str);
}
```

- `(t) -> t.toString()`
- `t -> t.toString()`

上面的 Lambda 表达式实现的效果是一样的。

#### 2.3 可选的大括号

```
@Test
public void test2 () {
    String str = AppendUtils.append(1, 2, (Integer t1, Integer t2) -> {return t1.toString() + t2.toString();});
    System.out.println(str);
    str = AppendUtils.append(1, 2, (t1, t2) -> t1.toString() + t2.toString());
    System.out.println(str);
}
```

- `(Integer t1, Integer t2) -> {return t1.toString() + t2.toString();}`
- `(t1, t2) -> t1.toString() + t2.toString()`

上面的 Lambda 表达式实现的效果是一样的, 并且忽略了 return 关键字

#### 2.4 可选的返回关键字

```
@Test
public void test5() throws Exception {
    ExecutorService executorService = Executors.newFixedThreadPool(1);
    /*Future<String> future = executorService.submit(new Callable<String>() {
        @Override
        public String call() throws Exception {
            return "success";
        }
    });*/

    Future<String> future = executorService.submit(() -> "success");
    executorService.shutdown();
    System.out.println(future.get());
}
```

- `() -> "success"` 是 `Callable` 的实例
- 如果没有参数必须要使用 `()`
- 忽略了 return 关键字

## 3 需要注意的问题

1. Lambda 表达式主要用来定义行内执行的方法类型接口，例如，一个简单方法接口。
2. Lambda 表达式免去了使用匿名方法的麻烦，并且给予 Java 简单但是强大的函数化的编程能力。

## 4 变量作用域

1. Lambda 表达式本质上类似于内部类，跟 JavaScript 闭包一样，在 Java 中只能引用标记了 final 的外层局部变量，这就是说不能在 lambda 内部修改定义在域外的局部变量，否则会编译错误。

定义接口

```
public interface Converter<T> {
    String convert(T t1, T t2);
}
```

下面的 c 变量在 Lambda 表达式中不能被修改。

```
@Test
public void test6() {
    int a = 10;
    int b = 10;
    int c = 10;

    Converter<Integer> converter = (t1, t2) -> {
        // c += 10; 编译的时候报错
        return String.valueOf(t1+t2+c);
    };

    System.out.println(converter.convert(a, b));
}
```

## 5 参考

- [Java 8 Lambda 表达式](https://www.runoob.com/java/java8-lambda-expressions.html)
- [深入浅出 Java 8 Lambda 表达式](http://blog.oneapm.com/apm-tech/226.html)
- [深入理解Java 8 Lambda（语言篇——lambda，方法引用，目标类型和默认方法）](https://www.cnblogs.com/figure9/p/java-8-lambdas-insideout-language-features.html)