---
title: 在 Java 中如何将一个集合分隔成若干个子集合
title_url: Java-split-list-practice
date: 2020-04-30
tags: [Java]
categories: Java
description: 在 Java 中如何将一个集合分隔成若干个子集合
---

## 1 概述

本文介绍 5 种在 Java 中如何将一个集合分隔成若干个子集合的方法，并通过阅读源码的方式认知 AbstractList 抽象类的使用。

1. 直接在 for 循环中分隔
2. Java 8 Stream api 中的 Collectors.groupingBy(Function classifier) 方法
3. Apache Commons Collections 的 ListUtils.partition(List list, int size) 方法
4. Google Guava 的 Lists.partition(List list, int size)
5. 继承 AbstractList 抽象类

## 2 直接在 for 循环中分隔

```java
@Test
public void forLoop() {
    List<List<Integer>> result = new ArrayList<>();
    final List<Integer> numbers = Arrays.asList(1,2,3,4,5,6,7);
    final int chunkSize = 3;
    final AtomicInteger counter = new AtomicInteger();

    for (int number : numbers) {
        if (counter.getAndIncrement() % chunkSize == 0) {
            result.add(new ArrayList<>());
        }
        result.get(result.size() - 1).add(number);
    }

    result.forEach(list -> {
        System.out.println(String.format("subList size:%s", list.size()));
        System.out.println(String.format("list:%s", list.toString()));
    });
}
```

- 输出如下

```
subList size:3
list:[1, 2, 3]
subList size:3
list:[4, 5, 6]
subList size:1
list:[7]
```

## 3 Java 8 Stream api 中的 Collectors.groupingBy(Function classifier) 方法

#### 3.1 测试代码

```java
// 分隔集合
@Test
public void testGroupBySplitList() {
    List<Integer> dataList = new ArrayList<>();
    IntStream.range(0, 100).forEach(dataList::add);

    AtomicInteger counter = new AtomicInteger();
    Map<Integer, List<Integer>> result = dataList.stream().collect(Collectors.groupingBy(i -> counter.getAndIncrement() / 30));

    result.forEach((key, list) -> {
        System.out.println(String.format("key:%s", key));
        System.out.println(String.format("subList size:%s", list.size()));
        System.out.println(String.format("list:%s", list.toString()));
    });
}
```

- 输出如下

```
key:0
subList size:30
list:[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]
key:1
subList size:30
list:[30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]
key:2
subList size:30
list:[60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89]
key:3
subList size:10
list:[90, 91, 92, 93, 94, 95, 96, 97, 98, 99]
```

#### 3.2 Collectors.groupingBy(Function classifier) 详解

用于将集合根据 Function 接口参数分隔成若干个子集合

```
AtomicInteger counter = new AtomicInteger();
Collectors.groupingBy(it -> counter.getAndIncrement() / 30)
```

- groupingBy 的参数为 Function 接口，参数为集合中的值，返回值为 map 中的 key
- it 表示集合中的值
- counter 表示对集合中的数据进行计数
- 0 到 29 除以 30 为 0，表示 map 中的 key 为 0，value 为集合中索引 0 到 29 的数据
- 类似的 30 到 59 除以 30 为 1， 表示 map 中的 key 为 1，value 为集合中索引 30 到 59 的数据

## 4 Google Guava 的 Lists.partition(List list, int size)

#### 4.1 Maven 依赖

```xml
<dependency>
	<groupId>com.google.guava</groupId>
	<artifactId>guava</artifactId>
	<version>29.0-jre</version>
</dependency>
```

#### 4.2 测试

```java
@Test
public void Lists_partition() {
    List<Integer> dataList = new ArrayList<>();
    IntStream.range(0, 100).forEach(dataList::add);

    List<List<Integer>> subList = Lists.partition(dataList, 30);
    subList.forEach(list -> {
        System.out.println(String.format("subList size:%s", list.size()));
        System.out.println(String.format("list:%s", list.toString()));
    });
}
```

- 输出

```
subList size:30
list:[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]
subList size:30
list:[30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]
subList size:30
list:[60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89]
subList size:10
list:[90, 91, 92, 93, 94, 95, 96, 97, 98, 99]
```

#### 4.3 源码分析

- com.google.common.collect.Lists

从源码上看 Lists 是继承了 AbstractList 抽象类，重写 get 和 size 方法，具体如下

```java
private static class Partition<T> extends AbstractList<List<T>> {
    final List<T> list;
    final int size;

    Partition(List<T> list, int size) {
        this.list = list;
        this.size = size;
    }

    public List<T> get(int index) {
        Preconditions.checkElementIndex(index, this.size());
        int start = index * this.size;
        int end = Math.min(start + this.size, this.list.size());
        return this.list.subList(start, end);
    }

    public int size() {
        return IntMath.divide(this.list.size(), this.size, RoundingMode.CEILING);
    }

    public boolean isEmpty() {
        return this.list.isEmpty();
    }
}
```

## 5 Apache Commons Collections 的 ListUtils.partition(List list, int size)

#### 5.1 Maven 依赖

```xml
<dependency>
	<groupId>org.apache.commons</groupId>
	<artifactId>commons-collections4</artifactId>
	<version>4.4</version>
</dependency>
```

#### 5.2 测试

```java
@Test
public void ListUtils_partition() {
    List<Integer> dataList = new ArrayList<>();
    IntStream.range(0, 100).forEach(dataList::add);

    List<List<Integer>> subList = ListUtils.partition(dataList, 30);
    subList.forEach(list -> {
        System.out.println(String.format("subList size:%s", list.size()));
        System.out.println(String.format("list:%s", list.toString()));
    });
}
```

- 输出

```
subList size:30
list:[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29]
subList size:30
list:[30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59]
subList size:30
list:[60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89]
subList size:10
list:[90, 91, 92, 93, 94, 95, 96, 97, 98, 99]
```

#### 5.3 源码分析

- org.apache.commons.collections4.ListUtils

从源码上看 ListUtils 也是继承了 AbstractList 抽象类，重写 get 和 size 方法，具体如下

```java
private static class Partition<T> extends AbstractList<List<T>> {
    private final List<T> list;
    private final int size;

    private Partition(List<T> list, int size) {
        this.list = list;
        this.size = size;
    }

    public List<T> get(int index) {
        int listSize = this.size();
        if (index < 0) {
            throw new IndexOutOfBoundsException("Index " + index + " must not be negative");
        } else if (index >= listSize) {
            throw new IndexOutOfBoundsException("Index " + index + " must be less than size " + listSize);
        } else {
            int start = index * this.size;
            int end = Math.min(start + this.size, this.list.size());
            return this.list.subList(start, end);
        }
    }

    public int size() {
        return (int)Math.ceil((double)this.list.size() / (double)this.size);
    }

    public boolean isEmpty() {
        return this.list.isEmpty();
    }
}
```

## 6 继承 AbstractList 抽象类

AbstractList 是一个实现自定义集合类的框架类，只读的情况下只需要重写 get 和 size 方法 

1. 通过 构造函数 传入 待分隔的 list 和 分隔后每个 list 的大小 
2. 重新 get 方法，根据 index 返回分隔后的 list 
3. 重写 size 方法，返回能够分隔的 list 数

```java
import java.util.AbstractList;
import java.util.ArrayList;
import java.util.List;

/**
 * AbstractList 是一个实现自定义集合类的框架类，只读的情况下只需要重写 get 和 size 方法 <br>
 *
 * 1. 通过 构造函数 传入 待分隔的 list 和 分隔后每个 list 的大小 <br>
 * 2. 重新 get 方法，根据 index 返回分隔后的 list <br>
 * 3. 重写 size 方法，返回能够分隔的 list 数 <br>
 *
 * @param <T>
 */
public class ListPartition<T> extends AbstractList<List<T>> {

    private final List<T> list;
    private final int chunkSize;

    public ListPartition(List<T> list, int chunkSize) {
        this.list = new ArrayList<>(list);
        this.chunkSize = chunkSize;
    }

    public static <T> ListPartition<T> ofSize(List<T> list, int chunkSize) {
        return new ListPartition<>(list, chunkSize);
    }

    @Override
    public List<T> remove(int index) {
        List<T> dataList = get(index);
        list.removeAll(dataList);
        return dataList;
    }

    @Override
    public List<T> get(int index) {
        int start = index * chunkSize;
        int end = Math.min(start + chunkSize, list.size());

        if (start > end) {
            throw new IndexOutOfBoundsException("Index " + index + " is out of the list range <0," + (size() - 1) + ">");
        }

        return new ArrayList<>(list.subList(start, end));
    }

    @Override
    public int size() {
        return (int) Math.ceil((double) list.size() / (double) chunkSize);
    }
}
```

```java
@Test
public void Partition() {
    final List<Integer> numbers = Arrays.asList(1,2,3,4,5,6,7);

    ListPartition<Integer> partition = ListPartition.ofSize(numbers, 3);

    partition.stream().forEach(list -> {
        System.out.println(String.format("list:%s", list.toString()));
    });
}
```

- 输出入如下

```
list:[1, 2, 3]
list:[4, 5, 6]
list:[7]
```

## 7 参考

- [Divide a list to lists of n size in Java 8](https://e.printstacktrace.blog/divide-a-list-to-lists-of-n-size-in-Java-8/)