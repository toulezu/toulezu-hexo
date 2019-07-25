---
title: SpringBoot 中执行定时任务配置和使用的 2 种方式
title_url: SpringBoot-cron-usage-practice
date: 2019-07-25
tags: [SpringBoot,cron]
categories: SpringBoot
description: 如何在 Spring 中优雅的执行定时任务，这里将探讨两种方法
---

## 1 概述

如何在 Spring 中优雅的执行定时任务，这里将探讨两种方法，具体如下

1. 通过 `@EnableScheduling` 和 `@Scheduled` 注解实现
2. 通过 ScheduledExecutorService 对象

## 2 方法1：通过 `@EnableScheduling` 和 `@Scheduled` 注解实现

- org.springframework.scheduling.annotation.EnableScheduling
- org.springframework.scheduling.annotation.Scheduled

1. 在 `@Configuration` 配置类中再增加 `@EnableScheduling`，并实现 SchedulingConfigurer 接口，具体如下

```java
import com.toulezu.test.task.MyTask;
import com.toulezu.test.trigger.CustomTrigger;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.SchedulingConfigurer;
import org.springframework.scheduling.config.ScheduledTaskRegistrar;

import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

@Configuration
@EnableScheduling // 标注启动定时任务
public class SpringScheduleWithSchedulingConfigurer implements SchedulingConfigurer {

	private final String cron = "*/1 * * * * ?";

	@Override
	public void configureTasks(ScheduledTaskRegistrar taskRegistrar) {
		// 自定义定时任务的执行线程池
		taskRegistrar.setScheduler(taskScheduler());
		// 具体的任务
		taskRegistrar.addTriggerTask(() -> myTask().work(), new CustomTrigger(cron));
	}

	@Bean(destroyMethod = "shutdown")
	public Executor taskScheduler() {
		return Executors.newScheduledThreadPool(5);
	}

	@Bean
	public MyTask myTask() {
		return new MyTask();
	}
}
```

- MyTask

```java
import com.ckjava.xutils.Constants;
import com.ckjava.xutils.DateUtils;

import java.util.Date;

public class MyTask {
    public void work() {
        System.out.println(String.format("do work at:%s", DateUtils.formatTime(new Date().getTime(), Constants.TIMEFORMAT.DATETIME)));
    }
}
```

- CustomTrigger

```java
import org.springframework.scheduling.support.CronTrigger;

/**
 * 自定义 trigger
 */
public class CustomTrigger extends CronTrigger {
    public CustomTrigger(String expression) {
        super(expression);
    }
}
```

2. 也可以直接通过 `@EnableScheduling` 和 `@Scheduled` 注解，使用系统自带的线程池，这样就不用实现 SchedulingConfigurer 接口了

```java
import com.ckjava.xutils.Constants;
import com.ckjava.xutils.DateUtils;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Date;

@Component
@EnableScheduling // 标注启动定时任务
public class SpringSchedule {

	@Scheduled(fixedRate = 1000 * 30) // 30秒执行一次
	public void reportCurrentTime() {
		System.out.println("Scheduling Tasks Examples reportCurrentTime: The time is now " + DateUtils.formatTime(new Date().getTime(), Constants.TIMEFORMAT.DATETIME));
	}

	@Scheduled(cron="*/10 * * * * ?") // 每10秒执行一次
	public void reportCurrentTimeByCron() {
		System.out.println("Scheduling Tasks Examples reportCurrentTimeByCron: The time is now " + DateUtils.formatTime(new Date().getTime(), Constants.TIMEFORMAT.DATETIME));
	}
}
```

如果在 xml 中，可以通过下面的方式配置

```xml
<beans>

 <task:annotation-driven scheduler="taskScheduler"/>

 <task:scheduler id="taskScheduler" pool-size="42"/>

 <task:scheduled-tasks scheduler="taskScheduler">
     <task:scheduled ref="myTask" method="work" fixed-rate="1000"/>
 </task:scheduled-tasks>

 <bean id="myTask" class="com.foo.MyTask"/>

</beans>
```

## 3 方法2：通过 ScheduledExecutorService 对象

1. 在某个 Bean 中增加下面 static 代码块
2. 或者将 static 代码块中的代码放到含有 `@PostConstruct` 注解的方法中，具体如下

```java
import com.ckjava.xutils.Constants;
import com.toulezu.test.properties.JdbcProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.annotation.PostConstruct;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Component
public class CustomSchedule implements Constants {

    private static Logger logger = LoggerFactory.getLogger(CustomSchedule.class);

    public static ScheduledExecutorService scheduledExecutorService = Executors.newScheduledThreadPool(1);

    @Autowired
    private JdbcProperties jdbcProperties;

    /**
     * 系统启动的时候自动启动
     */
    /*static {
        scheduledExecutorService.scheduleAtFixedRate(() -> {
            try {
                // 业务逻辑
                System.out.println(String.format("CustomSchedule work at:%s", DateUtils.formatTime(new Date().getTime(), Constants.TIMEFORMAT.DATETIME)));
            } catch (Throwable e) {
                logger.error("scheduleAtFixedRate has error", e);
            }

        }, 10, 10, TimeUnit.SECONDS);
    }*/

    @PostConstruct
    public void init() {
        logger.info(this.getClass() + "begin init");
        try {

            scheduledExecutorService.scheduleAtFixedRate(() -> {
                try {
                    // 业务逻辑
                    System.out.println(jdbcProperties.toString());
                } catch (Throwable e) {
                    logger.error("scheduleAtFixedRate has error", e);
                }

            }, 10, 10, TimeUnit.SECONDS);

        } catch (Exception e) {
            logger.error(this.getClass().getName().concat(".init has error"), e);
        }
        logger.info(this.getClass() + "end init");
    }
}
```

## 4 代码

- [spring-boot-cron](https://gitee.com/toulezucom/spring-boot-learning/tree/master/spring-boot-cron)