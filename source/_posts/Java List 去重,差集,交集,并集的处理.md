---
title: Java List 去重,差集,交集,并集的处理
title_url: Java-list-retainAll-addAll-removeAll
date: 2019-04-25
tags: [Java,集合,List]
categories: [Java,集合]
description: Java List 去重,差集,交集,并集的处理
---

## 1 List 去重

list1 中的元素不会有重复

```java
@Test
public void test5() {
    List<String> list1 = new ArrayList<>();
    list1.add("1111");
    list1.add("2222");
    list1.add("2222");
    list1.add("3333");

    List<String> list2 = new ArrayList<>();
    list2.add("3333");
    list2.add("4444");
    list2.add("5555");

    // 单个List去重复
    list1.addAll(list2);
    list1 = new ArrayList<>(new HashSet<>(list1));

    System.out.println("list1:");
    printList(list1);

    System.out.println("list2:");
    printList(list2);
}
```

- 输出如下

```
list1:
1111  2222  3333  4444  5555
list2:
3333  4444  5555
```

## 2 List 差集

- removeAll

从 list1 中去掉 list1 和 list2 相同的元素

```java
@Test
public void test3() {
    List<String> list1 = new ArrayList<>();
    list1.add("1111");
    list1.add("2222");
    list1.add("3333");

    List<String> list2 = new ArrayList<>();
    list2.add("3333");
    list2.add("4444");
    list2.add("5555");

    // 差集, 从list1中去掉 list1 和 list2 相同的元素
    list1.removeAll(list2);

    System.out.println("list1:");
    printList(list1);

    System.out.println("list2:");
    printList(list2);
}
```

- 输出如下

```
list1:
1111  2222
list2:
3333  4444  5555
```

## 3 List 交集

- retainAll

list1 中只剩下 list1 和 list2 中相同的元素

```java
@Test
public void test2() {
    List<String> list1 = new ArrayList<>();
    list1.add("1111");
    list1.add("2222");
    list1.add("3333");

    List<String> list2 = new ArrayList<>();
    list2.add("3333");
    list2.add("4444");
    list2.add("5555");

    // 交集, 两个list中相同的元素
    list1.retainAll(list2);

    System.out.println("list1:");
    printList(list1);

    System.out.println("list2:");
    printList(list2);
}
```

- 输出如下

```
list1:
3333
list2:
3333  4444  5555
```

## 4 List 并集

- addAll

list1 中包含原来 list1 和 list2 中的所有元素

```java
@Test
public void test1() {
    List<String> list1 = new ArrayList<>();
    list1.add("1111");
    list1.add("2222");
    list1.add("3333");

    List<String> list2 = new ArrayList<>();
    list2.add("3333");
    list2.add("4444");
    list2.add("5555");

    // 并集, 可能会有重复
    list1.addAll(list2);
    System.out.println("list1:");
    printList(list1);

    System.out.println("list2:");
    printList(list2);
}
```

- 输出如下

```
list1:
1111  2222  3333  3333  4444  5555
list2:
3333  4444  5555
```

## 5 打印方法

```java
private void printList(List<String> dataList) {
    for (String str : dataList) {
        System.out.print(str.concat("  "));
    }
    System.out.println();
}
```