---
title: SpringBoot 中异步执行任务的 2 种方式
title_url: Spring-Boot-EnableAsync-Async-ExecutorService-usage-practice
date: 2019-08-07
tags: [SpringBoot]
categories: SpringBoot
description: 本文探讨在 SpringBoot 中通过线程池来异步执行任务的两种方法：1. 通过 Spring 自带的 `@EnableAsync` 和 `@Async` 两个注解实现异步执行任务功能；2. 通过自定义的方式
---

## 1 概述

本文探讨在 SpringBoot 中通过线程池来异步执行任务的两种方法：

1. 通过 Spring 自带的 `@EnableAsync` 和 `@Async` 两个注解实现异步执行任务功能
2. 通过自定义的方式

在通过 `@EnableAsync` 和 `@Async` 两个注解实现异步执行任务中会进一步分析 `@Async` 的局限性，自定义 `@Async` 注解的线程池，以及异常的处理。

## 2 使用 spring boot 异步注解 `@EnableAsync` 和 `@Async`

#### 2.1 `@Async` 的局限性

1. 只能作用于 *public* 方法上
2. 方法不能自己调自己，也就是说不能迭代调用

#### 2.2 基本使用

1. 增加如下的配置类 AsyncConfig

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;

@Configuration
@EnableAsync
public class AsyncConfig {
}
```

2. 在 AsyncService 中增加两个方法：一个有返回值，返回值为 `Future` 对象；一个没有，都通过 api 调用，具体如下

```java
import com.ckjava.test.properties.DbProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.AsyncResult;
import org.springframework.stereotype.Service;

import java.util.concurrent.Future;

@Service
public class AsyncService {

    private Logger logger = LoggerFactory.getLogger(this.getClass());

    @Autowired
    private DbProperties dbProperties;

    public String getDbProperties() {
        return dbProperties.toString();
    }

    @Async
    public void asyncData() {
        try {
            Thread.sleep(5000);
        } catch (InterruptedException e) {
            e.toString();
        }
        logger.info("Execute method asynchronously, thread name = {}", Thread.currentThread().getName());
    }

    @Async
    public Future<String> asyncGetData() {
        logger.info("Execute method asynchronously, thread name = {}", Thread.currentThread().getName());
        try {
            Thread.sleep(5000);
            return new AsyncResult("执行结果");
        } catch (Exception e) {
            logger.error("");
            return new AsyncResult(null);
        }
    }
}
```

- 其中 `org.springframework.scheduling.annotation.AsyncResult` 实现了 `java.util.concurrent.Future` 接口，并增加了一些额外有用的功能。

3. AsyncController 如下

```java
import com.ckjava.test.service.AsyncService;
import com.ckjava.xutils.Constants;
import com.ckjava.xutils.http.HttpResponse;
import io.swagger.annotations.Api;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Api
@RestController
@RequestMapping(value = "/api/async", produces = "application/json;charset=utf-8")
public class AsyncController implements Constants {

	@Autowired
    private AsyncService dbService;

    /**
     * 请求，立即返回，但是不是具体的执行结果，具体的任务在线程池中慢慢的执行
     */
	@GetMapping("/asyncData")
    public HttpResponse<String> asyncData() {
        dbService.asyncData();
	    return HttpResponse.getReturn(null, HTTPCODE.code_200, STATUS.SUCCESS);
    }

    /**
     * 请求，执行完毕后再返回具体的结果，具体的任务在线程池中执行
     */
    @GetMapping("/asyncGetData")
    public HttpResponse<String> asyncGetData() throws Exception {
        return HttpResponse.getReturn(dbService.asyncGetData().get(), HTTPCODE.code_200, STATUS.SUCCESS);
    }
}
```

4. 对于 `/api/async/asyncData` 请求，立即返回，但是不是具体的执行结果，具体的任务在线程池中慢慢的执行，具体如下

```
2019-08-06 20:32:09.476  INFO 461964 --- [cTaskExecutor-3] com.ckjava.test.service.AsyncService     : Execute method asynchronously, thread name = SimpleAsyncTaskExecutor-3
```

5. 对于 `/api/async/asyncGetData` 请求，执行完毕后再返回具体的结果，具体的任务在线程池中执行，具体如下

```
2019-08-06 20:32:59.958  INFO 461964 --- [cTaskExecutor-5] com.ckjava.test.service.AsyncService     : Execute method asynchronously, thread name = SimpleAsyncTaskExecutor-5
```

这两种情况可以根据业务情况来决定。

6. 从执行结果来看，AsyncService 中的 asyncData 方法和 asyncGetData 方法都执行在 SimpleAsyncTaskExecutor 线程池中

#### 2.3 自定义 `@Async` 注解的线程池

从上面的例子中可见默认的线程池为 SimpleAsyncTaskExecutor，如何自定义自己的线程池呢？

下面介绍两种自定义异步执行线程池的方法：

1. 在方法级别上自定义执行线程池
2. 在应用级别上自定义执行线程池

#### 2.4 在方法级别上自定义执行线程池

自定义线程池如下

- SelfAsyncConfig

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

@Configuration
@EnableAsync
public class SelfAsyncConfig {

    @Bean(name = "selfConfigThreadPool")
    public ExecutorService threadPoolTaskExecutor() {
        /**
         * corePoolSize: 线程池中至少有多少个线程，即使没有任何任务需要执行的情况下仍然需要保留
         * maximumPoolSize：线程池中最多有多少个线程
         * keepAliveTime：除了 corePoolSize 数量的线程，其他线程最大的空闲时间，超过空闲时间后会被回收
         * unit：keepAliveTime 的时间单位，毫秒，秒等
         * workQueue：等待执行任务的队列，里面的对象需要实现 Runnable 或者 Callable 接口
         */
        return new ThreadPoolExecutor(1, 1,
                60L, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<>());
    }
}
```

- 具体的使用，指定 bean name，具体如下

```
@Async("selfConfigThreadPool")
public void asyncSelfData() {
    try {
        Thread.sleep(5000);
    } catch (InterruptedException e) {
        e.toString();
    }
    logger.info("Execute method asynchronously, thread name = {}", Thread.currentThread().getName());
}
```

执行的输出如下

```
2019-08-07 10:25:59.113  INFO 648696 --- [pool-1-thread-1] com.ckjava.test.service.AsyncService     : Execute method asynchronously, thread name = pool-1-thread-1
```

根据输出可见，线程名为：pool-1-thread-1，和默认的线程 SimpleAsyncTaskExecutor-5 不在同一个线程池中。

#### 2.5 在应用级别上自定义执行线程池

通过在 `@EnableAsync` 配置类中实现 AsyncConfigurer 接口，并重写 getAsyncExecutor 方法。

- GlobalAsyncConfig

```java
import org.springframework.aop.interceptor.AsyncUncaughtExceptionHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.AsyncConfigurer;
import org.springframework.scheduling.annotation.EnableAsync;

import java.util.concurrent.Executor;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

@Configuration
@EnableAsync
public class GlobalAsyncConfig implements AsyncConfigurer {
    @Override
    public Executor getAsyncExecutor() {
        return new ThreadPoolExecutor(5, 5,
                60L, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<>());
    }

    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return new CustomAsyncExceptionHandler();
    }
    
    /**
     * 对于没有返回值的 带有 `@Async` 注解的方法的异常处理
     */
    private class CustomAsyncExceptionHandler implements AsyncUncaughtExceptionHandler {

        private Logger logger = LoggerFactory.getLogger(this.getClass());

        @Override
        public void handleUncaughtException (Throwable throwable, Method method, Object... obj) {
            logger.info("Exception message - {}", throwable.getMessage());
            logger.info("Method name - {}", method.getName());
            for (Object param : obj) {
                logger.info("Parameter value - {}", param);
            }
        }
    }

}
```

再次请求上面的 `/api/async/asyncData` 和 `/api/async/asyncGetData` api，后台输出如下

```
2019-08-07 14:36:23.992  INFO 13296 --- [pool-1-thread-1] com.ckjava.test.service.AsyncService     : Execute method asynchronously, thread name = pool-1-thread-1
2019-08-07 14:36:28.524  INFO 13296 --- [pool-1-thread-2] com.ckjava.test.service.AsyncService     : Execute method asynchronously, thread name = pool-1-thread-2
2019-08-07 14:36:29.346  INFO 13296 --- [pool-1-thread-5] com.ckjava.test.service.AsyncService     : Execute method asynchronously, thread name = pool-1-thread-5
```

从输出可见，任务执行的线程都在同一个线程池中。

#### 2.6 异常处理

- 当带有 `@Async` 注解的方法返回类型是 *Future* 对象，异常的处理非常简单，调用 *Future.get()* 将会抛出异常，在外面进行 `try...catch` 即可。
- 如果带有 `@Async` 注解的方法返回类型是 *void*, 那么如何处理异常呢？
- 解决起来也很简单：在实现 AsyncConfigurer 接口时，同时重写 getAsyncExecutor 和 getAsyncUncaughtExceptionHandler 两个方法，比如上面的 CustomAsyncExceptionHandler 处理类

出现异常如下：

```java
@Async
public void asyncData() {
    logger.info("Execute method asynchronously, thread name = {}", Thread.currentThread().getName());
    throw new RuntimeException("异常");
}
```

输出如下

```
2019-08-07 15:50:51.326  INFO 13420 --- [pool-1-thread-1] lAsyncConfig$CustomAsyncExceptionHandler : Exception message - 异常
2019-08-07 15:50:51.326  INFO 13420 --- [pool-1-thread-1] lAsyncConfig$CustomAsyncExceptionHandler : Method name - asyncData
2019-08-07 15:50:51.326  INFO 13420 --- [pool-1-thread-1] lAsyncConfig$CustomAsyncExceptionHandler : Parameter value - test
```

## 3 自定义

1. 新增配置类 ThreadConfig，通过 `@Bean` 来配置单个或者多个线程池。

- ThreadConfig 配置类，定义了两个线程池，一个用来发送邮件，一个用来处理心跳服务

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

@Configuration
public class ThreadConfig {

    /**
     * 邮件服务
     * @return
     */
    @Bean("sendMailExecutorService")
    public ExecutorService sendMailExecutorService() {
        return new ThreadPoolExecutor(2, 2,
                60L, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<>());
    }

    /**
     * 心跳服务
     * @return
     */
    @Bean("heartbeatExecutorService")
    public ExecutorService heartbeatExecutorService() {
        return new ThreadPoolExecutor(1, 1,
                60L, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<>());
    }
}
```

2. 通过 `@Qualifier("sendMailExecutorService")` 和 `@Autowired` 注入

- ThreadService

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

@Service
public class ThreadService {

    private Logger logger = LoggerFactory.getLogger(this.getClass());

    @Qualifier("sendMailExecutorService")
    @Autowired
    private ExecutorService sendMailExecutorService;

    @Qualifier("heartbeatExecutorService")
    @Autowired
    private ExecutorService heartbeatExecutorService;


    public void heartbeatService() {
        heartbeatExecutorService.submit(() -> {

            // TODO 负责心跳有关的工作
            logger.info("Execute heartbeatService asynchronously, thread name = {}", Thread.currentThread().getName());

        });
    }

    public Future<Boolean> sendMailService() {
        return sendMailExecutorService.submit(() -> {

            logger.info("Execute sendMailService asynchronously, thread name = {}", Thread.currentThread().getName());

            // 休息1秒，模拟邮件发送过程
            TimeUnit.SECONDS.sleep(1);
            return true;
        });
    }
} 
```

3. 注意 ThreadConfig 中配置了多个线程池，由于 ExecutorService 类型相同，因此需要加上 Bean 的名称以及在注入的时候需要加上 `@Qualifier`
4. 通过 ThreadController 调用服务，具体如下

- ThreadController 中 `/api/asyncThread/heartbeat` api 执行不需要返回，`/api/asyncThread/sendMail` api 需要返回结果

```java
import com.ckjava.test.service.ThreadService;
import com.ckjava.xutils.Constants;
import com.ckjava.xutils.http.HttpResponse;
import io.swagger.annotations.Api;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Api
@RestController
@RequestMapping(value = "/api/asyncThread", produces = "application/json;charset=utf-8")
public class ThreadController implements Constants {

    @Autowired
    private ThreadService threadService;

    /**
     * 请求，立即返回，但是不是具体的执行结果，具体的任务在线程池中慢慢的执行
     */
    @GetMapping("/heartbeat")
    public HttpResponse<String> asyncData() {
        threadService.heartbeatService();
        return HttpResponse.getReturn(null, HTTPCODE.code_200, STATUS.SUCCESS);
    }

    /**
     * 请求，执行完毕后再返回具体的结果，具体的任务在线程池中执行
     */
    @GetMapping("/sendMail")
    public HttpResponse<Boolean> asyncGetData() throws Exception {
        return HttpResponse.getReturn(threadService.sendMailService().get(), HTTPCODE.code_200, STATUS.SUCCESS);
    }

}
```
5. 具体的输出输出如下

```
2019-08-07 14:58:16.417  INFO 9500 --- [pool-3-thread-1] com.ckjava.test.service.ThreadService    : Execute heartbeatService asynchronously, thread name = pool-3-thread-1
2019-08-07 14:58:16.599  INFO 9500 --- [pool-3-thread-1] com.ckjava.test.service.ThreadService    : Execute heartbeatService asynchronously, thread name = pool-3-thread-1
2019-08-07 14:58:22.059  INFO 9500 --- [pool-2-thread-1] com.ckjava.test.service.ThreadService    : Execute sendMailService asynchronously, thread name = pool-2-thread-1
```

从输出可以看出，heartbeatService 的线程执行在 `pool-3` 线程池中，sendMailService 的线程执行在 `pool-2` 线程池中

## 4 总结

- 通过上面两种方式比较，可以发现 Spring 自带的 `@EnableAsync` 和 `@Async` 两个注解本质上也是基于 Java 自身的 Executor 线程池的，这种方式比较简单
- 自定义的方式可以带来更大的灵活性，以及可控性

## 5 参考

- [How To Do @Async in Spring](https://www.baeldung.com/spring-async)