---
title: Promise 的设计理念在 Java 编程中的应用
title_url: Promise-design-in-Java-understand-practice
date: 2020-12-26
tags: [Promise,Java]
categories: [Java]
description: 仔细看了下 ES6 中的 Promise 的设计理念，感觉不错，本文就将其中的设计理念在 Java 中实现下
---

## 1 概述

仔细看了下 ES6 中的 Promise 的设计理念，感觉不错，本文就将其中的设计理念在 Java 中实现下。

Promise 用于将程序中的 正常处理结果，异常，finally 代码库中的执行封装到 Promise 中并返回，可以避免通过在方法上传入回调函数的方式处理，能够带来如下好处：

1. 以优雅的方式对 方法 的返回结果进行处理
2. 减少 try...catch...finally 重复代码
3. 避免大量的回调函数
4. 完美的处理全局异常
5. 方便的将方法的 处理结果，异常信息 进行传递以及处理

## 2 古典的做法

- 古典的做法是一个方法有或者没有返回值，有或者没有参数，抛出异常或者本身进行 try...catch...finally 处理，
- 其他的方法再对当前的方法进行 try...catch...finally 处理，如果有返回值，再对返回值进行处理

- 一个普通的方法

```javascript
public class Person {
    public String workOldStyle(final String param) throws Exception {
        // 模拟处理
        WaitUtils.sleep(1000);
        if (param.equals("a")) {
            throw new MyException(Person.class, "work", new RuntimeException());
        }
        return "work:" + param;
    }
}
```

- 古典的处理

```javascript
@Test
public void test_workOldStyle() {
    final Person person = new Person();
    try {
        final String result = person.workOldStyle("test");
        System.out.printf("处理方法的返回:%s%n", result);
    } catch (final Exception e) {
        GlobalExceptionHandler.handleException(e);
    } finally {
        System.out.println("最后执行");
    }
}
```

## 3 Promise 的做法

Promise 会对 方法的 返回值，方法的异常进行封装，然后：

1. 通过 Promise 的 then 方法对 原来的方法返回结果 进行处理
2. 通过 Promise 的 thenCatch 方法对 原来的方法的异常 进行处理
3. 通过 Promise 的 thenFinally 方法在 原来的方法 执行完毕后（无论有无异常） 进行处理

## 4 Promise 的 Java 实现

1. Promise 类

```javascript
import java.util.concurrent.Callable;

/**
 * Function: promise
 *
 * @author ckjava
 * @date 2020/12/25
 */
public class Promise<T> {

    // 封装方法返回的数据
    private T data;
    // 封装方法的异常
    private Throwable mThrowable;

    public Promise() {
    }

    /**
     * 通过构造函数
     *
     * @param callable 参数
     */
    public Promise(final Callable<T> callable) {
        try {
            this.data = callable.call();
        } catch (final Exception e) {
            this.mThrowable = e;
        }
    }
    
    /**
     * 通过 of 静态方法返回 Promise 对象
     * @param callable 参数
     * @param <T> 泛型
     * @return 对象
     */
    public static <T> Promise<T> of(final Callable<T> callable) {
        Promise<T> promise = new Promise<>();
        try {
            promise.data = callable.call();
        } catch (final Exception e) {
            promise.mThrowable = e;
        }
        return promise;
    }

    /**
     * 方法执行完毕后，对方法返回结果的处理
     *
     * @param resolve 具体的处理
     * @return Promise 对象
     */
    public Promise<T> then(final Resolve<T> resolve) {
        if (data != null) {
            resolve.resolve(data);
        }
        return this;
    }

    /**
     * 方法出现异常的处理
     *
     * @param reject 具体的处理
     * @return Promise 对象
     */
    public Promise<T> thenCatch(final Reject reject) {
        if (mThrowable != null) {
            reject.reject(mThrowable);
        }
        return this;
    }

    /**
     * 方法最终的 finally 代码块
     *
     * @param runnable 具体的处理
     * @return Promise 对象
     */
    public Promise<T> thenFinally(final Runnable runnable) {
        runnable.run();
        return this;
    }

    public void setData(final T data) {
        this.data = data;
    }

    public void setException(final Throwable exception) {
        mThrowable = exception;
    }

    public static <T> Builder<T> newBuilder() {
        return new Builder<>();
    }

    /**
     * Promise 对象构造器
     *
     * @param <T> 方法的返回类型
     */
    public static class Builder<T> {
        private final Promise<T> mTPromise = new Promise<>();

        public Builder<T> of(final Callable<T> callable) {
            try {
                mTPromise.data = callable.call();
            } catch (final Exception e) {
                mTPromise.mThrowable = e;
            }
            return this;
        }

        public Promise<T> build() {
            return mTPromise;
        }
    }
}
```

- Resolve 接口方法

```javascript
/**
 * Function: resolve
 *
 * @author ckjava
 * @date 2020/12/25
 */
@FunctionalInterface
public interface Resolve<T> {

    /**
     * 正常返回的处理
     *
     * @param data 方法的返回值
     */
    void resolve(T data);
}

```

- Reject 接口方法

```javascript
/**
 * Function: resolve
 *
 * @author ckjava
 * @date 2020/12/25
 */
@FunctionalInterface
public interface Reject {

    /**
     * 异常的处理
     *
     * @param throwable 方法的异常
     */
    void reject(Throwable throwable);
}
```

## 5 获取 Promise 的4种方法

1. 和原来的方法融合，方法直接返回 Promise 对象
2. 通过 Promise 的构造方法 `public Promise(final Callable<T> callable)`
3. 通过 Promise 内置的构造器
4. 通过 Promise 的静态方法 Of

#### 5.1 方法1：目标方法直接返回 Promise 对象
 
目标方法直接返回 Promise 对象

```javascript
/**
 * 目标方法直接返回 Promise 对象
 */
@Test
public void test1() {
    final Person person = new Person();
    final Promise<String> promise = person.work("test");

    promise.then(data -> {
        System.out.printf("处理方法的返回:%s%n", data);
    })
            .thenCatch(GlobalExceptionHandler::handleException)
            .thenFinally(() -> System.out.println("执行完毕"));

    promise.then(data -> {
        System.out.printf("对结果的处理方式2", data);
    });
}
```

- 输出如下

```
处理方法的返回:worktest
执行完毕
对结果的处理方式2
```

#### 5.2 方法2：通过 Promise 的构造方法返回一个 Promise 对象

通过 Promise 的构造方法返回一个 Promise 对象，构造方法的参数是一个 Callable 对象

```javascript
/**
 * 通过 Promise 的构造方法返回一个 Promise 对象
 */
@Test
public void test2() {
    final Person person = new Person();
    final Promise<String> promise = new Promise<>(() -> person.workOldStyle("a"));

    promise.then(data -> {
        System.out.println(data);
    })
            .thenCatch(GlobalExceptionHandler::handleException)
            .thenFinally(() -> System.out.println("执行完毕"));


    promise.then(data -> {
        System.out.printf("对结果的处理方式2", data);
    });
}
```

- 输出如下

```
work:ab
执行完毕
对结果的处理方式2
```

#### 5.3 方法3：通过 Promise 内置的构造器构造

通过 Promise 内置的构造器构造，原理上和方法2 类似。

```javascript
/**
 * 通过构造器构造
 */
@Test
public void test3() {
    final Person person = new Person();
    final Promise<String> promise =
            Promise.<String>newBuilder()
                    .of(() -> person.workOldStyle("test"))
                    .build();

    promise.then(data -> {
        System.out.println(String.format("对结果的处理方式1:%s", data));
    }).then(data -> {
        System.out.println(String.format("对结果的处理方式2:%s", data));
    }).thenCatch(GlobalExceptionHandler::handleException)
            .thenFinally(() -> System.out.println("执行完毕后处理1"))
            .thenFinally(() -> System.out.println("执行完毕后处理2"));


    promise.then(data -> {
        System.out.println(String.format("对结果的处理方式3:%s", data));
    }).then(data -> {
        System.out.println(String.format("对结果的处理方式4:%s", data));
    });
}
```

- 输出如下

```
对结果的处理方式1:work:test
对结果的处理方式2:work:test
执行完毕后处理1
执行完毕后处理2
对结果的处理方式3:work:test
对结果的处理方式4:work:test
```

#### 5.4 方法4：通过 Promise 的静态方法 Of

```javascript
@Test
public void test1_of() {
    final Person person = new Person();
    final Promise<String> promise = Promise.of(() -> {
        person.workVoid("test");
        return null;
    });

    promise.then(data -> {
        System.out.printf("处理方法的返回:%s%n", data);
    })
            .thenCatch(GlobalExceptionHandler::handleException)
            .thenFinally(() -> System.out.println("执行完毕"));

    promise.then(data -> {
        System.out.printf("对结果的处理方式2", data);
    });
}
```

- 输出如下

```
执行完毕
```

**注意：如果目标方法的返回值为 null，那么 then 方法其实并没有执行 Resolve 对象的 resolve 方法**

## 6 通过 Promise 完美的处理全局异常

由于 Promise 对象中的 thenCatch 方法可以处理异常，如果系统中需要全局异常处理的方法返回的是 Promise 对象，那么就可以轻松的实现 全局异常 处理。

1. MyException 自定义全局异常类如下

```javascript
/**
 * Function: 自定义异常
 *
 * @author ckjava
 * @date 2020/12/25
 */
public class MyException extends Exception {

    public MyException(final Class<?> clazz, final String message, final Exception e) {
        super(String.format("%s 出现异常，message:%s", clazz.getName(), message), e);
    }
}
```

2. GlobalExceptionHandler 全局异常处理

```javascript
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Function: 全局异常处理
 *
 * @author ckjava
 * @date 2020/12/25
 */
public class GlobalExceptionHandler {

    private static final Logger logger = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    public static void handleException(final Throwable throwable) {
        logger.error("出现异常", throwable);
    }
}
```

3. 测试如下

```javascript
/**
 * 通过 Promise 的构造方法返回一个 Promise 对象
 */
@Test
public void test2() {
    final Person person = new Person();
    final Promise<String> promise = new Promise<>(() -> person.workOldStyle("a"));

    promise.then(data -> {
        System.out.println(data);
    })
            .thenCatch(GlobalExceptionHandler::handleException)
            .thenFinally(() -> System.out.println("执行完毕"));


    promise.then(data -> {
        System.out.printf("对结果的处理方式2", data);
    }).thenCatch(GlobalExceptionHandler::handleException);
}
```

- 输出

```
18:57:01.329 [main] ERROR c.c.async.GlobalExceptionHandler - 出现异常
com.ckjava.async.MyException: com.ckjava.async.Person 出现异常，message:work
	at com.ckjava.async.Person.workOldStyle(Person.java:26)
	at com.ckjava.async.TestPromise.lambda$test2$3(TestPromise.java:51)
	at com.ckjava.async.Promise.<init>(Promise.java:28)
	at com.ckjava.async.TestPromise.test2(TestPromise.java:51)
	
Caused by: java.lang.RuntimeException: null
	... 69 common frames omitted
执行完毕
18:57:01.332 [main] ERROR c.c.async.GlobalExceptionHandler - 出现异常
com.ckjava.async.MyException: com.ckjava.async.Person 出现异常，message:work
	at com.ckjava.async.Person.workOldStyle(Person.java:26)
	at com.ckjava.async.TestPromise.lambda$test2$3(TestPromise.java:51)
	at com.ckjava.async.Promise.<init>(Promise.java:28)
	at com.ckjava.async.TestPromise.test2(TestPromise.java:51)
Caused by: java.lang.RuntimeException: null
	... 69 common frames omitted
```

## 7 避免大量的回调函数

如何避免？可以看看现有的做法是怎么样的，以及 Promise 是怎么做的，对比之后一目了既然。

#### 7.1 通过回调函数的方式来处理 方法 的返回值和异常

通过在参数中增加 successConsumer 成功处理的回调，throwableConsumer 异常处理的回调，runnable finally 处理的回调，具体如下


```javascript
/**
 * 通过会回调函数的方式
 *
 * @param param 方法参数
 * @param successConsumer 成功处理的回调
 * @param throwableConsumer 异常处理的回调
 * @param runnable finally 处理的回调
 */
public void work(final String param, final Consumer<String> successConsumer,
        final Consumer<Throwable> throwableConsumer, final Runnable runnable) {
    try {
        WaitUtils.sleep(1000);
        final String result = "work";
        successConsumer.accept(result);
    } catch (final Exception e) {
        throwableConsumer.accept(e);
    } finally {
        runnable.run();
    }
}
```

- 测试

```javascript
@Test
public void testCallback_1() {
    final Person person = new Person();
    person.work("bc", data -> {
        System.out.printf("work result:%s%n",data);
    }, GlobalExceptionHandler::handleException, () ->{
        System.out.println("处理完毕");
    });
}
```

- 输出

```
work result:work
处理完毕
```

#### 7.2 回调函数方式的坏处

1. 需要修改原来方法的参数
2. 如果要增加对方法返回值的处理逻辑，就需要改成 `final List<Consumer<String>> successConsumerList`，具体如下

```javascript
/**
 * 通过 回调函数的方式处理返回结果，回调函数有多个
 *
 * @param param 方法参数
 * @param successConsumerList 成功处理的回调，有多个回调函数
 * @param throwableConsumer 异常处理的回调
 * @param runnable finally 处理的回调
 */
public void work(final String param, final List<Consumer<String>> successConsumerList,
        final Consumer<Throwable> throwableConsumer, final Runnable runnable) {
    try {
        WaitUtils.sleep(1000);
        final String result = "work"+param;
        successConsumerList.forEach(consumer -> consumer.accept(result));
    } catch (final Exception e) {
        throwableConsumer.accept(e);
    } finally {
        runnable.run();
    }
}
```

#### 7.3 如何通过 Promise 来避免大量的回调函数

- 通过 Promise 封装后的方法，再调用 then，thenCatch，thenFinally 方法后返回的仍然是 Promise 对象
- 这就意味着可以重复调用 then，thenCatch，thenFinally 方法，具体如下

```javascript
@Test
public void test3() {
    final Person person = new Person();
    final Promise<String> promise =
            Promise.<String>newBuilder()
                    .of(() -> person.workOldStyle("test"))
                    .build();

    promise.then(data -> {
        System.out.println(String.format("对结果的处理方式1:%s", data));
    }).then(data -> {
        System.out.println(String.format("对结果的处理方式2:%s", data));
    }).thenCatch(GlobalExceptionHandler::handleException)
            .thenFinally(() -> System.out.println("执行完毕后处理1"))
            .thenFinally(() -> System.out.println("执行完毕后处理2"));


    promise.then(data -> {
        System.out.println(String.format("对结果的处理方式3:%s", data));
    }).then(data -> {
        System.out.println(String.format("对结果的处理方式4:%s", data));
    });
}
```

- 执行如下

```
对结果的处理方式1:work:test
对结果的处理方式2:work:test
执行完毕后处理1
执行完毕后处理2
对结果的处理方式3:work:test
对结果的处理方式4:work:test
```

## 8 使用

引入 xutils 工具包 1.0.9 版本，在 com.ckjava.xutils.promise 包下

```xml
<dependency>
    <groupId>com.ckjava</groupId>
    <artifactId>xutils</artifactId>
    <version>1.0.9</version>
</dependency>
```

## 9 参考

- [Promises/A+](https://promisesaplus.com/)