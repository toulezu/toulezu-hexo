---
title: 对 AtomicReference 的理解和使用
title_url: Java-AtomicReference-understand-practice
date: 2020-05-08
tags: [Java]
categories: Java
description: 对 AtomicReference 的理解和使用
---


## 1 概述

- `java.util.concurrent.atomic.AtomicReference`

1. 自旋锁，乐观锁，CAS 类型
2. 在高并发环境下以原子的方式修改值

## 2 方法列表

1. public final V get() 以非原子的方式 返回当前值
2. public final void set(V newValue) 以非原子的方式 直接将值设置为预期值
3. public final void lazySet(V newValue) 以原子的方式 将值设置为预期值
4. public final boolean compareAndSet(V expect, V update) 以原子的方式 只有在当前值等于预期值的时候才会将值更新，返回是否更新成功
5. public final boolean weakCompareAndSet(V expect, V update) 以原子的方式 只有在当前值等于预期值的时候才会将值更新，返回是否更新成功
6. public final V getAndSet(V newValue) 以原子的方式修改后返回旧值
7. public final V getAndUpdate(UnaryOperator<V> updateFunction) 以原子的方式 修改后返回旧值
8. public final V updateAndGet(UnaryOperator<V> updateFunction) 以原子的方式 修改后返回新值
9. public final V getAndAccumulate(V x, BinaryOperator<V> accumulatorFunction) 以原子的方式 修改指定值后返回旧值
10. public final V accumulateAndGet(V x, BinaryOperator<V> accumulatorFunction) 以原子的方式 修改指定值后返回新值

## 3 构造函数

1. `public AtomicReference()`
2. `public AtomicReference(V initialValue)`

## 4 使用场景

#### 4.1 get()：以非原子的方式 获取当前值

`public final V get()`

1. 返回当前值

- 具体测试如下

```
@Test
public void get() {

    AtomicReference<String> str = new AtomicReference<>("hello");

    System.out.println(String.format("get result:%s", str.get())); // get result:hello world
    Assert.assertTrue(str.get().equals("hello"));

}
```

#### 4.2 set：以非原子的方式 直接将值设置为预期值

`public final void set(V newValue)`

1. 预期值

- 具体测试如下

```java
@Test
public void set() {

    AtomicReference<String> str = new AtomicReference<>("hello");

    str.set(str.get().concat(" world"));
    System.out.println(String.format("set result:%s", str.get())); // set result:hello world
    Assert.assertTrue(str.get().equals("hello world"));

}
```

#### 4.3 lazySet：以原子的方式 将值设置为预期值

`public final void lazySet(V newValue)`

1. 预期值

- 具体测试如下

```java
@Test
public void lazySet() {
    AtomicReference<String> str = new AtomicReference<>("hello");

    str.lazySet(str.get().concat(" world"));
    System.out.println(String.format("lazySet result:%s", str.get())); // lazySet result:hello
    Assert.assertTrue(str.get().equals("hello world"));
}
```

#### 4.4 compareAndSet：以原子的方式 只有在当前值等于预期值的时候才会将值更新，返回是否更新成功

`public final boolean compareAndSet(V expect, V update)`

1. 预期值
2. 更新值
3. 返回是否更新成功，false 表示实际值和预期值不一致

- 具体测试如下

```java
@Test
public void compareAndSet() throws Exception {
    AtomicReference<String> str = new AtomicReference<>("hello");

    // 线程池
    int threads = 10;
    ExecutorService executorService = Executors.newFixedThreadPool(threads);
    // 计数
    AtomicLong count = new AtomicLong();
    // 执行截止时间
    long finish = System.currentTimeMillis() + 2 * 1000;
    while (System.currentTimeMillis() <= finish) {

        List taskList = new ArrayList();
        LongStream.range(0, threads).forEach(i -> {
            taskList.add(new WriteTask(str));
        });

        executorService.invokeAll(taskList);
        count.getAndAdd(threads);
    }

    System.out.println(String.format("线程计数:%s", count.get()));
    executorService.shutdown();
}

private class WriteTask implements Callable<Boolean> {

    private AtomicReference<String> str;

    public WriteTask(AtomicReference<String> str) {
        this.str = str;
    }

    @Override
    public Boolean call() {
        boolean flag = str.compareAndSet(str.get(), str.get().concat(" world"));
        System.out.println(String.format("compareAndSet result:%s, data:%s", flag, str.get()));
        Assert.assertTrue(flag);
        Assert.assertTrue(str.get().equals("hello world"));
        return flag;
    }
}
```

- 在高并发的情况下对共享变量进行更新，不会进行重试，直接返回是否更新成功

#### 4.5 weakCompareAndSet：以原子的方式 只有在当前值等于预期值的时候才会将值更新，返回是否更新成功

`public final boolean weakCompareAndSet(V expect, V update)`

- 和 compareAndSet 方法类似

#### 4.6 getAndSet: 以原子的方式 修改后返回旧值

`public final V getAndSet(V newValue)`

1. newValue 修改后的值
2. 返回旧值

- 具体测试如下

```java
@Test
public void getAndSet() {

    AtomicReference<String> str = new AtomicReference<>("hello");

    String finalString = str.getAndSet(str.get().concat(" world"));
    System.out.println(String.format("getAndSet result:%s", finalString)); // getAndSet result:hello
    Assert.assertTrue(finalString.equals("hello"));
    Assert.assertTrue(str.get().equals("hello world"));

}
```

#### 4.7 getAndUpdate: 以原子的方式 修改后返回旧值

`public final V getAndUpdate(UnaryOperator<V> updateFunction)`

1. UnaryOperator 是接口对象，需要实现 `R apply(T t)` 方法，其中：t 表示修改前的值，R 表示修改后的值
2. 返回旧值

- 具体测试如下

```java
@Test
public void getAndUpdate() {

    AtomicReference<String> str = new AtomicReference<>("hello");

    String finalString = str.getAndUpdate(t -> t.concat(" world"));
    System.out.println(String.format("getAndUpdate result:%s", finalString)); // getAndUpdate result:hello
    Assert.assertTrue(finalString.equals("hello"));
    Assert.assertTrue(str.get().equals("hello world"));

}
```

#### 4.8 updateAndGet: 以原子的方式 修改后返回新值

`public final V updateAndGet(UnaryOperator<V> updateFunction)`

1. UnaryOperator 是接口对象，需要实现 `R apply(T t)` 方法，其中：t 表示修改前的值，R 表示修改后的值
2. 返回新值

- 具体测试如下

```java
@Test
public void updateAndGet() {

    AtomicReference<String> str = new AtomicReference<>("hello");

    String finalString = str.updateAndGet(t -> t.concat(" world"));
    System.out.println(String.format("updateAndGet result:%s", finalString)); // updateAndGet result:hello world
    Assert.assertTrue(finalString.equals("hello world"));

}
```

#### 4.9 getAndAccumulate：以原子的方式 修改指定值后返回旧值

- `public final V getAndAccumulate(V x, BinaryOperator<V> accumulatorFunction)`

1. 第一参数 x 表示在原来的基础上的变化值
2. 第二参数 BinaryOperator 是接口对象，需要实现 `R apply(T t, U u)` 方法，其中：t 表示修改前的值，u 表示增加的值，也就是第一个参数 x, R 表示修改后的值
3. 返回旧值

- 具体测试如下

```java
@Test
public void getAndAccumulate() {

    AtomicReference<String> str = new AtomicReference<>("hello");

    String finalString = str.getAndAccumulate(" world", (x,y) -> x.concat(y));
    System.out.println(String.format("getAndAccumulate result:%s", finalString)); // getAndAccumulate result:hello
    Assert.assertTrue(finalString.equals("hello"));
    Assert.assertTrue(str.get().equals("hello world"));

}
```

#### 4.10 accumulateAndGet：以原子的方式 修改指定值后返回新值

- `public final V accumulateAndGet(V x, BinaryOperator<V> accumulatorFunction)`

1. 第一参数 x 表示在原来的基础上的变化值
2. 第二参数 BinaryOperator 是接口对象，需要实现 `R apply(T t, U u)` 方法，其中：t 表示修改前的值，u 表示增加的值，也就是第一个参数 x, R 表示修改后的值
3. 返回新值

- 具体测试如下

```java
@Test
public void accumulateAndGet() {

    AtomicReference<String> str = new AtomicReference<>("hello");

    String finalString = str.accumulateAndGet(" world", (x,y) -> x.concat(y));
    System.out.println(String.format("accumulateAndGet result:%s", finalString)); // accumulateAndGet result:hello world
    Assert.assertTrue(finalString.equals("hello world"));


    AtomicReference<Integer> num = new AtomicReference<>(10);
    int sum = num.accumulateAndGet(2, Integer::sum);
    System.out.println(String.format("accumulateAndGet result:%s", sum)); // accumulateAndGet result:hello world
    Assert.assertTrue(sum == 12);
    
}
```

## 5 java.util.concurrent.atomic 包下其他类介绍

类 | 说明
---|---
AtomicBoolean | 以原子的方式更新 boolean 值
AtomicInteger | 以原子的方式更新 int 值
AtomicIntegerArray | 以原子的方式更新 int 数组
AtomicIntegerFieldUpdater<T> | 抽象类，以原子的方式更新某个对象中的 int 字段值
AtomicLong | 以原子的方式更新 long 值
AtomicLongArray | 以原子的方式更新 long 数组
AtomicLongFieldUpdater<T> |  抽象类，以原子的方式更新某个对象中的 long 字段值
AtomicMarkableReference<V> | 以原子的方式更新 带有标记的引用类型 对象
AtomicReference | 以原子的方式更新 引用类型 对象
AtomicReferenceArray<E> | 以原子的方式更新 数组
AtomicReferenceFieldUpdater<T,V> | 抽象类，以原子的方式更新对象的字段，T 为对象的类型，V 为对象字段的类型
AtomicStampedReference<V> | 通过 int 标记值来维持对某个对象的引用，能够以原子的方式更新这个对象
DoubleAccumulator | 通过自定义函数的方式来修改 double 值
DoubleAdder | 默认值为 0， 用于 double 类型的值增加以及求和
LongAccumulator | 通过自定义函数的方式来修改 long 值
LongAdder | 默认值为 0， 用于 long 类型的值增加以及求和