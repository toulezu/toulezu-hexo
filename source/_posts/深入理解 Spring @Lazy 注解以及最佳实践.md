---
title: 深入理解 Spring @Lazy 注解以及最佳实践
title_url: understand-Spring-Lazy-annotation-practice
date: 2019-10-11
tags: [Spring]
categories: Spring
description: 深入理解 Spring @Lazy 注解以及最佳实践
---

## 1 概述

- org.springframework.context.annotation.Lazy

`@Lazy` 注解可以提高系统加载速度，`@Component` 注解的 Bean，在启动的时候不会被初始化，只有通过 ApplicationContext 对象的 getBean 方法获取的时候才会初始化；或者其他 Bean 通过 `@Autowired` 注入的时候也会初始化。

#### 1.1 作用范围

- 可以作用于在类上和 `@Component` 注解搭配使用
- 也可以作用在方法上和 `@Bean` 注解搭配使用
- 当作用在类上和 `@Configuration` 注解搭配使用的情况下，该类下面所有带有 `@Bean` 注解的对象都将受到同样的影响

#### 1.2 属性功能

- value 的默认值为 true
- 如果为 true 并且在其他 Bean 没有对其依赖或者没有使用的情况下将不会初始化
- 如果为 false，跟其他的 Bean 一样正常加载

## 2 实例验证

#### 2.1 测试代码

- com.ckjava.spring.lazyannotation.Com_1

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;

@Component
@Lazy
public class Com_1 {

    private static final Logger logger = LoggerFactory.getLogger(Com_1.class);

    @Value("${name}")
    private String name;

    @PostConstruct
    public void init() {
        logger.info("init");
    }

    public void work() {
        logger.info(this.getClass().getName() + "do work");
    }
}
```

- com.ckjava.spring.lazyannotation.Com_2

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;

@Component
public class Com_2 {

    private static final Logger logger = LoggerFactory.getLogger(Com_2.class);

    @Autowired
    private Com_1 com_1;

    @PostConstruct
    public void init() {
        logger.info("init");
    }

    public void work() {
        logger.info(this.getClass().getName() + "do work");
    }
}
```

- com.ckjava.spring.lazyannotation.Com_3

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;

import javax.annotation.PostConstruct;

public class Com_3 {

    private static final Logger logger = LoggerFactory.getLogger(Com_3.class);

    @Value("${name}")
    private String name;

    @PostConstruct
    public void init() {
        logger.info("init");
    }

    public void work() {
        logger.info(this.getClass().getName() + "do work");
    }
}
```

- com.ckjava.spring.lazyannotation.Com_4

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;

import javax.annotation.PostConstruct;

public class Com_4 {

    private static final Logger logger = LoggerFactory.getLogger(Com_4.class);

    @Value("${name}")
    private String name;

    @PostConstruct
    public void init() {
        logger.info("init");
    }

    public void work() {
        logger.info(this.getClass().getName() + "do work");
    }
}
```

- com.ckjava.spring.lazyannotation.ConfigBean

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Lazy;

@Configuration
@Lazy
public class ConfigBean {
    @Bean
    public Com_3 initCom_3() {
        return new Com_3();
    }

    @Bean
    @Lazy(value = false)
    public Com_4 initCom_4() {
        return new Com_4();
    }
}
```

- com.ckjava.spring.lazyannotation.Main 启动 Spring 应用环境

```java
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

public class Main {
    public static void main(String[] args) {
        ApplicationContext appc = new AnnotationConfigApplicationContext("com.ckjava.spring.lazyannotation");
        Com_1 com_1 = appc.getBean(Com_1.class);
    }
}
```

#### 2.2 `@Lazy` 和 `@Component` 一起的情况

`Com_1` 类注解为 `@Component` 加 `@Lazy`，在 `Com_2` 中通过 `@Autowired` 注解注入 `Com_1` 依赖，可以初始化 `Com_1`。

或者在 Main 类中通过 `Com_1 com_1 = appc.getBean(Com_1.class)` 也可以初始化 `Com_1`。

如果没有上述两种情况，`Com_1` 无法初始化

#### 2.3 `@Lazy` 和 `@Configuration` 一起的情况

`Com_3` 和 `Com_4` 通过 `@Configuration` 和 `@Bean` 注解进行初始化，由于 ConfigBean 类上的 `@Lazy` 注解，默认情况下 `Com_3` 和 `Com_4` 都无法初始化。

可以通过在 `initCom_4` 方法上增加 `@Lazy(value = false)` 使 `Com_4` 类初始化。

或者在 Main 类中通过 `Com_4 com_4 = appc.getBean(Com_4.class)` 也可以初始化 `Com_4`。

## 3 最佳实践

在某些情况下需要通过异步的方式执行任务，通过编写了一个 Runner 对象实现了 Runnable 接口，在 Runner 对象中需要使用到很多 `@Component` 或者 `@Service` Bean。

而且 `@Component` 类型的 Bean 并不需要在系统启动的时候启动, 如果通过 Runner 对象的构造函数方式来传入如这些 Bean 对象，将会造成构造函数参数非常复杂。

下面介绍通过注入 ApplicationContext 对象的方式通过 getBean 方法来获取 Bean 的方法来简化 Runner 对象的构造函数，并且能够优化系统的启动速度。

- com.ckjava.spring.lazyannotation.Runner 对象如下，通过在构造函数参数中传入 ApplicationContext 对象，并在实例化的时候通过 getBean 方法初始化 `Com_3` 和 `Com_4`，这两个 Bean 可以为 `@Lazy` 的。

```java
import org.springframework.context.ApplicationContext;

public class Runner implements Runnable {

    private Com_3 com_3;
    private Com_4 com_4;

    public Runner(ApplicationContext applicationContext) {
        com_3 = applicationContext.getBean(Com_3.class);
        com_4 = applicationContext.getBean(Com_4.class);
    }

    @Override
    public void run() {
        com_3.work();
        com_4.work();
    }
}
```

- com.ckjava.spring.lazyannotation.Com_5 中需要异步执行任务，具体如下

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Service;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Service
public class Com_5 {

    private static final Logger logger = LoggerFactory.getLogger(Com_5.class);
    private static ExecutorService executorService = Executors.newFixedThreadPool(1);

    @Autowired
    private ApplicationContext applicationContext;

    public void work() {
        executorService.submit(new Runner(applicationContext));
    }
}
```

- com.ckjava.spring.lazyannotation.Main 使用如下

```java
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

public class Main {
    public static void main(String[] args) {
        ApplicationContext appc = new AnnotationConfigApplicationContext("com.ckjava.spring.lazyannotation");
        Com_5 com_5 = appc.getBean(Com_5.class);
        com_5.work();
    }
}
```