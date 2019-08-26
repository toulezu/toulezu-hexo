---
title: 总结 Java8 中的 @FunctionalInterface 函数接口对象
title_url: summary-Java-8-FunctionalInterface
date: 2019-08-26
tags: [Java,Java8]
categories: Java
description: 在 java.util.function 包下，都是带有 `@FunctionalInterface` 注解的接口类型. 这里简要介绍一下函数接口的基本特点以及具体的使用.
---

## 1 概述

在 java.util.function 包下，都是带有 `@FunctionalInterface` 注解的接口类型。

这里简要介绍一下函数接口的基本特点以及具体的使用。

## 2 特点

#### 2.1 如果有参数，带有 1 个参数

基本的如下

1. Function：主要功能是传入 1 个参数返回结果，具体如下
```
R apply(T t);
```

2. Consumer：主要功能是接收 1 个参数，没有返回，具体如下
```
void accept(T t);
```

3. Predicate：主要功能是接收 1 个参数，返回 boolean 类型，具体如下
```
boolean test(T t);
```

4. Supplier：主要功能是没有参数，返回结果，具体如下
```
T get();
```

#### 2.2 带有 2 个参数

1. Bi*，Bi 是 Binary（二元的）单词的简写，比如：BiConsumer，BiFunction，BiPredicate

#### 2.3 double 类型的参数和返回值

1. Double*，比如：DoubleConsumer，DoubleFunction，DoublePredicate，DoubleSupplier

#### 2.4 int 类型的参数和返回值

1. Int*, 比如：IntConsumer，IntFunction，IntPredicate，IntSupplier

#### 2.5 long 类型的参数和返回值

1. Long*, 比如：LongConsumer，LongFunction，LongPredicate，LongSupplier 

#### 2.6 参数是泛型，返回值类型固定

1. To*，比如：ToDoubleFunction，ToIntBiFunction，ToLongFunction

#### 2.7 没有返回值，两个参数，其中一个是泛型，一个是具体的类型

1. Obj*，比如：ObjDoubleConsumer，ObjIntConsumer，ObjLongConsumer

## 3 举例使用

#### 3.1 Predicate 函数接口

Collection 接口在 jdk1.8 后新增了一个 `default boolean removeIf(Predicate<? super E> filter)` 

现在有一个需求：集合 c 中有一些字符串，给定一个字符串 a，如果 a 在集合 c 中存在，就将集合中的 a 删除，传统的实现如下

```java
List<String> dataList = new ArrayList<>();
@Before
public void init() {
    dataList.add("a");
    dataList.add("b");
    dataList.add("c");
}

@Test
public void test_7() {
    // 遍历集合，如果发现集合中存在就删除
    String str = "a";
    for (int i = 0; i < dataList.size(); i++) {
        if (dataList.get(i).equals(str)) {
            dataList.remove(i);
        }
    }

    // 打印
    for (int i = 0; i < dataList.size(); i++) {
        System.out.println(dataList.get(i));
    }
}
```
如果在 Java 8 中，通过 removeIf 方法实现如下

```java
@Test
public void test_8() {
    // 遍历集合，如果发现集合中存在就删除
    String str = "a";
    dataList.removeIf(data -> data.equals(str));

    // 打印
    dataList.forEach(System.out::println);
}
```

从上面对比可以发现，代码大大简化。

#### 3.2 Consumer 函数接口

Iterable 接口在 jdk1.8 后新增了一个 `default void forEach(Consumer<? super T> action)` 方法，而且 Collection 接口继承了 Iterable 接口。

需求：迭代集合中的元素，并打印出来

传统的实现如下

```java
@Test
public void testForeach() {
    List<Integer> dataList = new ArrayList<>();
    dataList.add(1);
    dataList.add(2);
    dataList.add(3);

    for (int i = 0; i < dataList.size(); i++) {
        System.out.println(dataList.get(i).toString());
    }
}
```

如果在 Java 8 中，通过 forEach 方法实现如下

```java
@Test
public void testForeach() {
    List<Integer> dataList = new ArrayList<>();
    dataList.add(1);
    dataList.add(2);
    dataList.add(3);

    dataList.forEach(System.out::println);
}
```

#### 3.3 Function 函数接口

比如 Stream 接口中的 map 方法：`<R> Stream<R> map(Function<? super T, ? extends R> mapper)`，功能是将 stream 中的元素进行加工然后返回新的结果。

需求：将集合中的 int 数据乘以 2，具体如下

```java
@Test
public void testMap() {
    List<Integer> dataList = new ArrayList<>();
    dataList.add(2);
    dataList.add(3);
    dataList.add(4);

    /*for (int i = 0; i < dataList.size(); i++) {
            dataList.set(i, dataList.get(i) * 2);
    }*/

    dataList = dataList.stream().map(data -> data*2).collect(Collectors.toList());

    dataList.forEach(System.out::println);
}
```

#### 3.4 Supplier 函数接口

比如 java.util.Objects 类中的 `public static <T> T requireNonNull(T obj, Supplier<String> messageSupplier)`，功能是让使用者提供对象为空的错误信息。

具体使用如下

```java
@Test
public void testSuplier() {
    String data = null;
    String notNullData = Objects.requireNonNull(data, () -> data == null ? "数据不能为空" : null);
}
```

#### 3.5 BiFunction 函数接口

比如 java.util.concurrent.atomic.AtomicReference 的 `public final V accumulateAndGet(V x, BinaryOperator<V> accumulatorFunction)` 方法，其中 BinaryOperator 是继承 BiFunction 的，抽象接口不变。

这个方法的意思是先变化 x，再返回变化后的值，BinaryOperator 接口中的 `R apply(T t, U u)` 方法，第一个参数 t 表示变化前的值，第二个参数 u 表示变化的值，R 表示返回的值。

下面举一个加法的例子，具体如下

```java
@Test
public void testBiFunciton() {
    AtomicReference<Integer> atomicReference = new AtomicReference<>(1);
    // 1 先返回老的值，再增加
    int current = atomicReference.getAndAccumulate(2, (t1, t2) -> t1 + t2);
    Assert.assertTrue(current == 1);
    Assert.assertTrue(atomicReference.get() == 3);

    atomicReference = new AtomicReference<>(1);
    // 1 先增加，再返回新的值
    int after = atomicReference.accumulateAndGet(2, (t1, t2) -> t1 + t2);
    Assert.assertTrue(after == 3);
    Assert.assertTrue(atomicReference.get() == 3);
}
```

#### 3.6 ToDoubleFunction 函数接口

比如 `java.util.stream.Collectors` 中的 `public static <T> Collector<T, ?, Double> averagingDouble(ToDoubleFunction<? super T> mapper)` 方法，该方法搭配 Stream api 中的 collect 方法，用于集合中的元素求平均值。

需求：求一组用户中 18 岁以下平均年龄，具体如下

```java
private static List<User> userList = new ArrayList<>();

/**
 * 初始化 user 集合
 */
@Before
public void initEveryTestBefore() {
    userList.add(new User(22, "王旭", "wang.xu","123456", '1', true));
    userList.add(new User(22, "王旭", "wang.xu","123456", '1', true));
    userList.add(new User(21, "孙萍", "sun.ping","a123456", '2', false));
    userList.add(new User(23, "步传宇", "bu.zhuan.yu", "b123456", '1', false));
    userList.add(new User(18, "蔡明浩",  "cai.ming.hao","c123456", '1', true));
    userList.add(new User(17, "郭林杰", "guo.lin.jie", "d123456", '1', false));
    userList.add(new User(29, "韩凯", "han.kai", "e123456", '1', true));
    userList.add(new User(22, "韩天琪",  "han.tian.qi","f123456", '2', false));
    userList.add(new User(21, "郝玮",  "hao.wei","g123456", '2', false));
    userList.add(new User(19, "胡亚强",  "hu.ya.qing","h123456", '1', false));
    userList.add(new User(14, "季恺",  "ji.kai","i123456", '1', false));
    userList.add(new User(17, "荆帅",  "jing.shuai","j123456", '1', true));
    userList.add(new User(16, "姜有琪",  "jiang.you.qi","k123456", '1', false));
    logger.info("initEveryTestBefore, size {}", userList.size());
}
    
@Test
public void testAverage() {
    double average = userList
            .stream()
            .filter(data -> data.getAge() < 18)
            .collect(Collectors.averagingDouble(data -> data.getAge()));
    System.out.println(String.format("18岁以下用户平均年龄：%s", average)); // 平均年龄：16.0
}
```