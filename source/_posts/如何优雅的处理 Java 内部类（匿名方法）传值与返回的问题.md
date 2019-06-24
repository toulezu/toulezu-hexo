---
title: 如何优雅的处理 Java 内部类（匿名方法）传值与返回的问题
title_url: Java-innerclass-value-propagation-practice
date: 2019-06-24
tags: [Java,innerclass]
categories: Java
description: 传入 Java 内部类的对象必须是 final 的，如何将内部类中计算的结果返回呢？
---

## 1 问题

传入 Java 内部类的对象必须是 final 的，如何将内部类中计算的结果返回呢？比如下面这个，如何将最终的 total 返回到外面？

```java
List<Integer> numberList = new ArrayList<>();
    numberList.add(1);
    numberList.add(2);
    numberList.add(3);
    numberList.forEach(n -> {
        int total = 0;
        total += n;
    });
```

## 2 解决方法

#### 2.1 通过 AtomicReference 包裹最终返回的对象

```java
AtomicReference<Integer> atomicReference = new AtomicReference<>(0);

numberList.forEach(n -> atomicReference.set(n + atomicReference.get()));

System.out.println(atomicReference.get());
Assert.assertTrue(atomicReference.get() == 6);
```

#### 2.2 通过 ThreadLocal 包裹最终返回的对象

```java
ThreadLocal<Integer> threadLocal = ThreadLocal.withInitial(() -> 0);
numberList.forEach(n -> threadLocal.set(n + threadLocal.get()));

System.out.println(threadLocal.get());
Assert.assertTrue(threadLocal.get() == 6);
```

## 3 总结

#### 3.1 共同点：

1. 包裹最终返回的对象
2. 通过 get 方法可以获取，通过 set 方法保存

#### 3.2 不同点：
        
1. AtomicReference 有带参数的构造方法，ThreadLocal 没有


## 4 自定义一个包裹类

根据上面的总结，自定义的包裹类类有以下两个特征：

1. 通过 get 方法可以获取，通过 set 方法保存
2. 通过构造函数设置初始值

具体如下

```java
public class WrapperUtils<T> {

    private T t;

    public WrapperUtils() {
    }

    public WrapperUtils init(T t) {
        this.t = t;
        return this;
    }

    public WrapperUtils(T t) {
        this.t = t;
    }

    public T get() {
        return t;
    }

    public void set(T t) {
        this.t = t;
    }
}
```

测试如下

```java
WrapperUtils<Integer> wrapperUtils = new WrapperUtils<>(0);
numberList.forEach(t -> wrapperUtils.set(wrapperUtils.get()+t));
Assert.assertTrue(wrapperUtils.get() == 6);
```