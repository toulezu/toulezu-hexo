---
title: Java 8 中的 Optional 使用详解
title_url: understand-Java-8-Optional
date: 2019-06-22
tags: [Java8,Optional]
categories: Java
description: Optional 的完整路径是 java.util.Optional，使用它是为了避免代码中的 if (obj != null) { } 这样范式的代码，可以采用链式编程的风格。而且通过 Optional 中提供的 filter 方法可以判断对象是否符合条件，在符合条件的情况下才会返回；map 方法可以在返回对象前修改对象中的属性
---

## 1 概述

- Optional 的完整路径是 `java.util.Optional`，使用它是为了避免代码中的 `if (obj != null) { }` 这样范式的代码，可以采用链式编程的风格
- 而且通过 Optional 中提供的 filter 方法可以判断对象是否符合条件，在符合条件的情况下才会返回；map 方法可以在返回对象前修改对象中的属性
- 下面将一一分析这些方法的用法

## 2 方法列表

1. `public<U> Optional<U> map(Function<? super T, ? extends U> mapper)`: 将 Optional 中的对象转成 其他对象，或者修改对象中的属性
2. `public<U> Optional<U> flatMap(Function<? super T, Optional<U>> mapper)`：将 Optional 中的对象转成 Optional 对象，或者修改对象中的属性
3. `public T orElse(T other)`: 在构造 Optional 的时候，如果其中的对象为 null, 通过 orElse 方法可以给定一个默认值
4. `public T orElseGet(Supplier<? extends T> other)`：在构造 Optional 的时候，如果其中的对象为 null, 通过 orElseGet 方法可以动态构造一个对象;与 orElse 相比，orElseGet 的参数是 Supplier 接口对象
5. `public void ifPresent(Consumer<? super T> consumer)`：ifPresent 表示 Optional 中的对象存在才会执行 Consumer 接口对象中的方法
6. `public Optional<T> filter(Predicate<? super T> predicate)`：Optional 中的对象在不为空，并且满足某个条件的时候才会返回
7. `public <X extends Throwable> T orElseThrow(Supplier<? extends X> exceptionSupplier) throws X`：在使用 Optional 包装的对象前，如果对象为 null 抛出自定义的异常

## 3 构造函数

Optional 的三种构造方式: Optional.of(obj),  Optional.ofNullable(obj) 和明确的 Optional.empty()

1. `Optional.of(obj)`: 它要求传入的 obj 不能是 null 值的, 否则直接报 NullPointerException 异常。
2. `Optional.ofNullable(obj)`: 它以一种智能的, 宽容的方式来构造一个 Optional 实例. 来者不拒, 传 null 进到就得到 Optional.empty(), 非 null 就调用 Optional.of(obj).
3. `Optional.empty()`：返回一个空的 Optional 对象

具体测试如下

```java
/**
 * 1. empty() 返回一个空的 Optional 对象
 * 2. ofNullable 传入的对象可以是 null, 如果为 null 返回一个空的 Optional 对象
 * 3. of 传入的对象一定不能为 null
 */
@Test
public void test1() {
    // 1. empty() 返回一个空的 Optional 对象
    Assert.assertTrue(Optional.empty().isPresent() == false);

    // 2. of 里面如果为 null 直接抛出 NullPointerException 异常
    try {
        Optional.of(null);
    } catch (Exception e) {
        Assert.assertTrue(e instanceof NullPointerException);
    }

    // 3. ofNullable 如果参数为 null，返回空的集合
    Assert.assertFalse(Optional.ofNullable(null).isPresent());
}
```

## 4 使用场景

这里结合具体的使用场景来使用 Optional 中的方法

#### 4.1 ifPresent：调用其他方法返回一个集合，在不通过 if 判断是否为 null 就可以放心的遍历

- 通过 Optional 的 ofNullable 构造函数封装
- 然后通过其中的 ifPresent 方法：如果对象不为 null, 才会执行 Consumer 接口对象中的方法
- 使用范式如下

```
Optional.ofNullable(userList)
        .ifPresent()
```

- 具体测试如下

```java
@Test
public void testIfPresent() {
    // ifPresent 表示 Optional 中的对象存在才会执行 Consumer 接口对象中的方法

    List<String> dataList = new ArrayList<>();

    // 1. 不为空没有值的集合
    Optional.ofNullable(dataList)
            .ifPresent(t -> {
                System.out.println("1"); // 输出 1
                t.forEach(a -> System.out.println(a));
            });

    // 2. 为 null 的集合, 自动判断为 null, 没有执行 Consumer 接口对象中的方法
    dataList = null;
    Optional.ofNullable(dataList)
            .ifPresent(t -> {
                System.out.println("2"); // 没有执行
                t.forEach(a -> System.out.println(a));
            });

    // 3. 有值的集合
    dataList = new ArrayList<>();
    dataList.add("a");
    Optional.ofNullable(dataList)
            .ifPresent(t -> {
                System.out.println("3"); // 输出 3
                t.forEach(a -> System.out.println(a));
            });

    // 4. 过去的方式, 多了 if 判断
    if (CollectionUtils.getSize(dataList) > 0) {
        dataList.forEach(a -> System.out.println(a));
    }

}
```

#### 4.2 filter：在判断是否为 null 后，仅遍历集合中符合条件的对象

- 在通过 ifPresent 方法返回对象前通过 filter 方法设置过滤条件
- filter 不会减少集合中对象的数量，只要集合中的任意一个对象满足条件就会返回整个集合，否则返回空集合
- 使用范式如下

```
Optional.ofNullable(userList)
        .filter()
        .ifPresent()
```

- 具体测试如下

```java
private static List<User> userList = new ArrayList<>();

/**
 * 初始化 user 集合
 */
@Before
public void initEveryTestBefore() {
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

// filter: optional 中的对象在不为空，并且满足某个条件的时候才会返回
@Test
public void testFilter() {
    // 1. 在集合中有年龄大于 18 岁的才会返回所有对象
    Optional.ofNullable(userList)
            .filter(t -> t.stream().anyMatch(u -> u.getAge() > 18))
            .ifPresent(t -> {
                t.forEach(u -> {
                    System.out.println("1:" + u.toString());
                });
            });

    // 2. 因为集合中没有年龄大于 50 岁的，因此不会返回任何对象
    Optional.ofNullable(userList)
            .filter(t -> t.stream().anyMatch(u -> u.getAge() > 50))
            .ifPresent(t -> {
                t.forEach(u -> {
                    System.out.println("2:" + u.toString());
                });
            });
}
```

输出如下

```
22:24:31.666 [main] INFO  c.toulezu.test.optional.TestOptional - initEveryTestBefore, size 12
1:User{age=22, name='王旭', enName='wang.xu', password='123456', gender=1, hasMarried=true}
1:User{age=21, name='孙萍', enName='sun.ping', password='a123456', gender=2, hasMarried=false}
1:User{age=23, name='步传宇', enName='bu.zhuan.yu', password='b123456', gender=1, hasMarried=false}
1:User{age=18, name='蔡明浩', enName='cai.ming.hao', password='c123456', gender=1, hasMarried=true}
1:User{age=17, name='郭林杰', enName='guo.lin.jie', password='d123456', gender=1, hasMarried=false}
1:User{age=29, name='韩凯', enName='han.kai', password='e123456', gender=1, hasMarried=true}
1:User{age=22, name='韩天琪', enName='han.tian.qi', password='f123456', gender=2, hasMarried=false}
1:User{age=21, name='郝玮', enName='hao.wei', password='g123456', gender=2, hasMarried=false}
1:User{age=19, name='胡亚强', enName='hu.ya.qing', password='h123456', gender=1, hasMarried=false}
1:User{age=14, name='季恺', enName='ji.kai', password='i123456', gender=1, hasMarried=false}
1:User{age=17, name='荆帅', enName='jing.shuai', password='j123456', gender=1, hasMarried=true}
1:User{age=16, name='姜有琪', enName='jiang.you.qi', password='k123456', gender=1, hasMarried=false}
```

#### 4.3 orElse：在目标集合对象为 null 的时候可以设定默认值

- 通过 orElse 函数设定默认值
- ofNullable 函数为目标集合对象，如果为 null, 才会使用 orElse 函数设定的默认值
- 使用范式如下

```
Optional.ofNullable()
        .orElse()
```

- 具体测试如下

```java
// 在构造 Optional 的时候，如果其中的对象为 null, 通过 orElse 方法可以给定一个默认值
@Test
public void testOrElse() {
    List<String> tempList = new ArrayList<>();
    tempList.add("a");
    tempList.add("b");
    tempList.add("c");
    tempList.add("d");

    // 1. 给定的对象为 null, 将会返回 orElse 方法提供的对象
    List<String> dataList = null;
    Optional.ofNullable(dataList)
            .orElse(tempList)
            .forEach(t -> System.out.println("1:" + t));

    // 2. 给定的对象不为 null, 不会返回 orElse 方法提供的对象
    dataList = new ArrayList<>();
    dataList.add("aa");
    dataList.add("ab");
    dataList.add("ac");

    Optional.ofNullable(dataList)
            .orElse(tempList)
            .forEach(t -> System.out.println("2:" + t));

    // 3. 给定的对象不为 null 但是为 empty, 不会返回 orElse 方法提供的对象
    dataList = new ArrayList<>();
    Optional.ofNullable(dataList)
            .orElse(tempList)
            .forEach(t -> System.out.println("3:" + t));
}
```

- 输出如下

```
1:a
1:b
1:c
1:d
2:aa
2:ab
2:ac
```

#### 4.4 orElseGet：在目标集合对象为 null 的时候，可以动态从其他地方加载集合

- 在构造 Optional 的时候，如果其中的对象为 null, 通过 orElseGet 方法可以动态构造一个对象，比如可以再从数据库中加载
- orElseGet 直接返回的是 Optional 中的对象
- 与 orElse 相比，orElseGet 的参数是 Supplier 接口对象
- 使用范式如下

```
Optional.ofNullable()
        .orElseGet()
```

- 具体测试如下

```java
@Test
public void testOrElseGet() {
    List<String> tempList = new ArrayList<>();
    tempList.add("a");
    tempList.add("b");
    tempList.add("c");
    tempList.add("d");

    // 1. 给定的对象为 null, 将会执行 orElseGet 方法提供的 Supplier 接口对象中的方法
    List<String> dataList = null;

    Optional.ofNullable(dataList)
            .orElseGet(() -> tempList)
            .forEach(t -> System.out.println("1:" + t));

    // 2. 给定的对象不为 null, 不会执行 orElseGet 方法提供的 Supplier 接口对象中的方法
    dataList = new ArrayList<>();
    dataList.add("aa");
    dataList.add("ab");
    dataList.add("ac");

    Optional.ofNullable(dataList)
            .orElseGet(() -> tempList)
            .forEach(t -> System.out.println("2:" + t));

    // 3. 给定的对象不为 null 但是 empty, 不会执行 orElseGet 方法提供的 Supplier 接口对象中的方法
    dataList = new ArrayList<>();
    Optional.ofNullable(dataList)
            .orElseGet(() -> tempList)
            .forEach(t -> System.out.println("3:" + t));
}
```

#### 4.5 orElseThrow：如果目标对象为 null， 抛出自定义的异常

- 在使用 optional 包装的对象前，如果对象为 null 抛出自定义的异常
- 使用范式如下

```
Optional.ofNullable()
        .orElseThrow()
```

- 具体测试如下

```java 
@Test
public void testOrElseThrow() {
    List<String> tempList = new ArrayList<>();
    tempList.add("a");
    tempList.add("b");
    tempList.add("c");
    tempList.add("d");

    RuntimeException runtimeException = new RuntimeException("dataList 对象为空");

    // 1. 给定的对象为 null, 将会抛出异常
    List<String> dataList = null;
    try {
        Optional.ofNullable(dataList)
                .orElseThrow(() -> runtimeException)
                .forEach(t -> System.out.println("1:" + t));
    } catch (Exception e) {
        Assert.assertTrue(e instanceof RuntimeException);
    }

    // 2. 给定的对象不为 null, 不会抛出异常
    dataList = tempList;
    Optional.ofNullable(dataList)
            .orElseThrow(() -> runtimeException)
            .forEach(t -> System.out.println("2:" + t));
}
```

#### 4.6 map：将 optional 中的对象转成 其他对象，或者修改对象中的属性

- 用于修改 Optional 中的对象，并返回对象
- 使用范式如下

```
Optional.ofNullable()
        .map()
```

- 具体测试如下

```java
@Test
public void testMap() {
    // 1. 返回 optional 中的对象年龄在 18 岁以上的
    Optional.ofNullable(userList)
            .map(t -> {
                List<User> tempList = new ArrayList<>();
                t.forEach(u -> {
                    if (u.getAge() > 18) {
                        tempList.add(u);
                    }
                });
                return tempList;
            })
            .ifPresent(t -> {
                t.forEach(u -> {
                    System.out.println("1:" + u.toString());
                });
            });

    // 2. 将 optional 中的 User 对象的英文名改成大写
    Optional.ofNullable(userList)
            .map(t -> {
                t.forEach(u -> {
                    u.setEnName(u.getEnName().toUpperCase());
                });
                return t;
            })
            .ifPresent(t -> {
                t.forEach(u -> {
                    System.out.println("2:" + u.toString());
                });
            });


}
```

#### 4.7 flatMap：将 optional 中的对象转成 optional 对象，或者修改对象中的属性

- 用于修改 Optional 中的对象，并返回 Optional 对象
- 使用范式如下

```
Optional.ofNullable()
        .flatMap()
```

- 具体测试如下

```java
@Test
public void testFlatMap() {
    // 1. 返回 Optional 中的对象年龄在 18 岁以上的
    Optional.ofNullable(userList)
            .flatMap(t -> {
                List<User> tempList = new ArrayList<>();
                t.forEach(u -> {
                    if (u.getAge() > 18) {
                        tempList.add(u);
                    }
                });
                return Optional.of(tempList);
            })
            .ifPresent(t -> {
                t.forEach(u -> {
                    System.out.println("1:" + u.toString());
                });
            });

    // 2. 将 optional 中的 User 对象的英文名改成大写
    Optional.ofNullable(userList)
            .flatMap(t -> {
                t.forEach(u -> {
                    u.setEnName(u.getEnName().toUpperCase());
                });
                return Optional.of(t);
            })
            .ifPresent(t -> {
                t.forEach(u -> {
                    System.out.println("2:" + u.toString());
                });
            });
}
```

## 5 基于 Optional 设计一个 CRUD 的接口

- 在接口中定义返回 Optional 包裹的对象

```java
import com.toulezu.test.stream.api.User;

import java.util.List;
import java.util.Optional;

public interface BaseService<T> {

    public Optional<User> getUser(Long id);

    public Optional<List<T>> findAll();

    public Optional<List<T>> search(String keyword);
}
```

- 在假设数据库中查询返回为 null 的情况

```java
import com.toulezu.test.stream.api.User;

import java.util.List;
import java.util.Optional;

public class UserService implements BaseService<User> {

    @Override
    public Optional<User> getUser(Long id) {
        User user = null;
        return Optional.ofNullable(user);
    }

    @Override
    public Optional<List<User>> findAll() {
        List<User> userList = null;
        return Optional.ofNullable(userList);
    }

    @Override
    public Optional<List<User>> search(String keyword) {
        List<User> userList = null;
        return Optional.ofNullable(userList);
    }
}
```

- 通过 ifPresent 方法可以避免 null 判断，具体测试如下

```java
@Test
public void testUserService() {
    UserService userService = new UserService();
    userService.getUser(1l)
            .ifPresent(t -> {
                Assert.assertTrue(t != null);
            });


    userService.findAll()
            .ifPresent(t -> {
                Assert.assertTrue(userList != null);
            });

    userService.search("a")
            .ifPresent(t -> {
                Assert.assertTrue(userList != null);
            });

}
```