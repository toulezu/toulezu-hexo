---
title: 详解 JUC 之 Exchanger
title_url: Java-JUC-Exchanger-understand-practice
date: 2020-07-29
tags: [Java,JUC,并发]
categories: [Java,JUC,并发]
description: 详解 JUC 之 Exchanger
---

## 1 概述

- java.util.concurrent.Exchanger

Exchanger 用于两个线程对之间的数据交换，通过 new 的方式构造一个 Exchanger 对象，参数为泛型。

Exchanger 对象只有两个参数不同的 exchange 方法，该方法会阻塞当前线程，直到方法返回结果。

举个例子：去食堂打饭的时候，你把空餐盘递给阿姨后，阿姨在餐盘上放上饭菜，然后再递给你。其中餐盘就好比 Exchanger 对象，饭菜好比 exchange 方法中的参数，整个过程只有 你 和 阿姨（两个线程），并且同步进行。


## 2 Exchanger 关键点

- 两个线程在某个时间点同步交换数据
- 内部还是通过 `sun.misc.Unsafe` 的 CAS 自旋锁来进行线程同步控制的

## 3 主要方法

- `Exchanger()` : 无参构造函数
- `public V exchange(V x) throws InterruptedException` ：交换，支持中断
- `public V exchange(V x, long timeout, TimeUnit unit) throws InterruptedException, TimeoutException`：交换，支持中断，支持超时

## 4 使用场景

以上面的打饭场景为例

- 餐盘对象 Plate

```java

/**
 * 餐盘
 */
public class Plate {

    private Float rice; // 米饭
    private Float soup; // 汤
    private Float greens; // 蔬菜
    private Float meat; // 肉类

    public Plate(Float rice, Float soup, Float greens, Float meat) {
        this.rice = rice;
        this.soup = soup;
        this.greens = greens;
        this.meat = meat;
    }

    public Plate() {
    }

    /**
     * 获取总金额
     *
     * @return Float
     */
    public Float getMoney() {
        return rice*1 + soup*0 + greens*2 + meat*5;
    }

    public Float getRice() {
        return rice;
    }

    public void setRice(Float rice) {
        this.rice = rice;
    }

    public Float getSoup() {
        return soup;
    }

    public void setSoup(Float soup) {
        this.soup = soup;
    }

    public Float getGreens() {
        return greens;
    }

    public void setGreens(Float greens) {
        this.greens = greens;
    }

    public Float getMeat() {
        return meat;
    }

    public void setMeat(Float meat) {
        this.meat = meat;
    }
}
```

- 打饭阿姨 AuntWorker

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Callable;
import java.util.concurrent.Exchanger;

public class AuntWorker implements Callable<Plate> {

    private static final Logger logger = LoggerFactory.getLogger(AuntWorker.class);

    private Exchanger<Plate> plateExchanger;
    private Plate plate;

    public AuntWorker(Exchanger<Plate> plateExchanger, Plate plate) {
        this.plateExchanger = plateExchanger;
        this.plate = plate;
    }
    @Override
    public Plate call() throws Exception {
        // 阿姨在餐盘放置食物
        logger.info("阿姨开始在餐盘放置食物");
        plate.setRice((float) 1.00);
        plate.setSoup((float) 0.55);
        plate.setGreens((float) 0.55);
        plate.setMeat((float) 0.55);
        // 模拟打饭
        WaitUtils.sleep(3000);
        logger.info("阿姨打饭完毕");

        // 递给吃客
        plate = plateExchanger.exchange(plate);
        //plate = plateExchanger.exchange(plate, 3, TimeUnit.SECONDS);
        logger.info("递给吃客");
        return plate;
    }
}
```

- 食客 EaterWorker

```java

import com.ckjava.synchronizeds.appCache.WaitUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Callable;
import java.util.concurrent.Exchanger;

public class EaterWorker implements Callable<Float> {

    private static final Logger logger = LoggerFactory.getLogger(EaterWorker.class);

    private Exchanger<Plate> plateExchanger;
    private Plate plate;

    public EaterWorker(Exchanger<Plate> plateExchanger, Plate plate) {
        this.plateExchanger = plateExchanger;
        this.plate = plate;
    }

    @Override
    public Float call() throws Exception {
        // 拿出空的餐盘, 递给阿姨
        logger.info("拿出空的餐盘, 递给阿姨打饭");
        plate = plateExchanger.exchange(plate);
        // plate = plateExchanger.exchange(plate, 3, TimeUnit.SECONDS);

        logger.info(String.format("刷卡给钱:%s", plate.getMoney()));
        WaitUtils.sleep(1000);
        // 刷卡给钱
        return plate.getMoney();
    }
}
```

- 测试，新建两个线程

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;

import java.util.concurrent.Exchanger;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

/**
 * 去食堂打饭的时候，你把空餐盘递给阿姨后，阿姨在餐盘上放上饭菜，然后再递给你。其中餐盘就好比 Exchanger 对象，饭菜好比 exchange 方法中的参数，整个过程只有 你 和 阿姨（两个线程），并且同步进行。
 */
public class TestExchanger {
    private static final Plate plate = new Plate();
    private static final Exchanger<Plate> exchanger = new Exchanger<>();

    public static void main(String[] args) {
        ExecutorService executorService = Executors.newFixedThreadPool(2);
        // 吃客开始打饭
        Future<Float> eaterFuture = executorService.submit(new EaterWorker(exchanger, plate));
        WaitUtils.sleep(500);
        // 打饭阿姨
        Future<Plate> auntFuture = executorService.submit(new AuntWorker(exchanger, plate));
        //Future<Float> eater2Future = executorService.submit(new EaterWorker(exchanger, plate));

        try {
            auntFuture.get();
            eaterFuture.get();
        } catch (Exception e) {
            e.printStackTrace();
        }

        executorService.shutdown();
        WaitUtils.waitUntil(() -> executorService.isTerminated(), 100000l);
    }
}
```

- 输出如下

```
12:21:19.771 [pool-1-thread-1] INFO  com.ckjava.Exchanger.EaterWorker - 拿出空的餐盘, 递给阿姨打饭
12:21:20.271 [pool-1-thread-2] INFO  com.ckjava.Exchanger.AuntWorker - 阿姨开始在餐盘放置食物
12:21:23.271 [pool-1-thread-2] INFO  com.ckjava.Exchanger.AuntWorker - 阿姨打饭完毕
12:21:23.271 [pool-1-thread-2] INFO  com.ckjava.Exchanger.AuntWorker - 递给吃客
12:21:23.283 [pool-1-thread-1] INFO  com.ckjava.Exchanger.EaterWorker - 刷卡给钱:4.85
```

## 5 其他场景

#### 5.1 中断的情况

比如吃客在递给阿姨餐盘后，发现没有带钱，主动中断。

- EaterInterruptWorker 吃客

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Callable;
import java.util.concurrent.Exchanger;

public class EaterInterruptWorker implements Callable<Float> {

    private static final Logger logger = LoggerFactory.getLogger(EaterInterruptWorker.class);

    private Exchanger<Plate> plateExchanger;
    private Plate plate;

    public EaterInterruptWorker(Exchanger<Plate> plateExchanger, Plate plate) {
        this.plateExchanger = plateExchanger;
        this.plate = plate;
    }

    @Override
    public Float call() throws Exception {
        // 拿出空的餐盘, 递给阿姨
        logger.info("拿出空的餐盘, 递给阿姨打饭");
        try {
            plate = plateExchanger.exchange(plate);
        } catch (InterruptedException e) {
            logger.info("发现没有带钱，中断");
        }
        return (float) 0;
    }
}
```

-  AuntInterruptWorker 阿姨

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Callable;
import java.util.concurrent.Exchanger;

public class AuntInterruptWorker implements Callable<Plate> {

    private static final Logger logger = LoggerFactory.getLogger(AuntInterruptWorker.class);

    private Exchanger<Plate> plateExchanger;
    private Plate plate;

    public AuntInterruptWorker(Exchanger<Plate> plateExchanger, Plate plate) {
        this.plateExchanger = plateExchanger;
        this.plate = plate;
    }
    @Override
    public Plate call() throws Exception {
        // 阿姨在餐盘放置食物
        logger.info("阿姨开始在餐盘放置食物");
        plate.setRice((float) 1.00);
        plate.setSoup((float) 0.55);
        plate.setGreens((float) 0.55);
        plate.setMeat((float) 0.55);
        logger.info("阿姨打饭完毕");

        // 递给吃客
        try {
            plate = plateExchanger.exchange(plate);

            logger.info("递给吃客");
            return plate;
        } catch (InterruptedException e) {
            logger.error(" 吃客没有给钱，返回空的餐盘");
            return new Plate();
        }
    }
}
```

- 测试

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;
import java.util.concurrent.Exchanger;

public class TestExchangerInterrupt {
    private static final Plate plate = new Plate();
    private static final Exchanger<Plate> exchanger = new Exchanger<>();

    public static void main(String[] args) {


        Thread auntThread = new Thread(() -> {
            AuntInterruptWorker auntWorker = new AuntInterruptWorker(exchanger, plate);
            try {
                auntWorker.call();
            } catch (Exception e) {
                e.printStackTrace();
            }
        });

        Thread eaterThread = new Thread(() -> {
            EaterInterruptWorker eaterWorker = new EaterInterruptWorker(exchanger, plate);
            try {
                eaterWorker.call();
            } catch (Exception e) {
                e.printStackTrace();
            }
        });

        // 吃客开始打饭
        eaterThread.start();
        WaitUtils.sleep(500);
        // 打饭阿姨
        auntThread.start();

        // 中断
        eaterThread.interrupt();
        auntThread.interrupt();

        WaitUtils.waitUntil(() -> !eaterThread.isAlive() && !auntThread.isAlive(), 10000l);
    }
}
```

- 输出如下

```
20:53:45.924 [main] INFO  c.c.Exchanger.EaterInterruptWorker - 拿出空的餐盘, 递给阿姨打饭
20:53:46.428 [Thread-1] INFO  c.c.Exchanger.EaterInterruptWorker - 发现没有带钱，中断
20:53:46.438 [Thread-0] INFO  c.c.Exchanger.AuntInterruptWorker - 阿姨开始在餐盘放置食物
20:53:46.439 [Thread-0] INFO  c.c.Exchanger.AuntInterruptWorker - 阿姨打饭完毕
20:53:46.441 [Thread-0] ERROR c.c.Exchanger.AuntInterruptWorker -  吃客没有给钱，返回空的餐盘
```

#### 5.2 超时的情况

使用 `public V exchange(V x, long timeout, TimeUnit unit) throws InterruptedException, TimeoutException` 方法，会出现 TimeoutException，具体测试如下

- 阿姨 AuntTimeoutWorker

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Callable;
import java.util.concurrent.Exchanger;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class AuntTimeoutWorker implements Callable<Plate> {

    private static final Logger logger = LoggerFactory.getLogger(AuntTimeoutWorker.class);

    private Exchanger<Plate> plateExchanger;
    private Plate plate;

    public AuntTimeoutWorker(Exchanger<Plate> plateExchanger, Plate plate) {
        this.plateExchanger = plateExchanger;
        this.plate = plate;
    }
    @Override
    public Plate call() throws Exception {
        // 阿姨在餐盘放置食物
        logger.info("阿姨开始在餐盘放置食物");
        plate.setRice((float) 1.00);
        plate.setSoup((float) 0.55);
        plate.setGreens((float) 0.55);
        plate.setMeat((float) 0.55);

        WaitUtils.sleep(3000);
        logger.info("阿姨打饭完毕");

        // 递给吃客
        try {
            plate = plateExchanger.exchange(plate, 4, TimeUnit.SECONDS);

            logger.info("递给吃客");
            return plate;
        } catch (InterruptedException e) {
            logger.error(this.getClass().getName().concat(" 吃客没有给钱，返回空的餐盘"));
            return new Plate();
        } catch (TimeoutException e) {
            logger.info("阿姨打饭超时");
            return new Plate();
        }
    }
}
```

- 吃客 EaterTimeoutWorker

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Callable;
import java.util.concurrent.Exchanger;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class EaterTimeoutWorker implements Callable<Float> {

    private static final Logger logger = LoggerFactory.getLogger(EaterTimeoutWorker.class);

    private Exchanger<Plate> plateExchanger;
    private Plate plate;

    public EaterTimeoutWorker(Exchanger<Plate> plateExchanger, Plate plate) {
        this.plateExchanger = plateExchanger;
        this.plate = plate;
    }

    @Override
    public Float call() throws Exception {
        // 拿出空的餐盘, 递给阿姨
        logger.info("拿出空的餐盘, 递给阿姨打饭");
        try {
            plate = plateExchanger.exchange(plate, 3, TimeUnit.SECONDS);
            logger.info(String.format("刷卡给钱:%s", plate.getMoney()));
            return plate.getMoney();
        } catch (InterruptedException e) {
            logger.info("发现没有带钱，中断");
            return (float) 0;
        } catch (TimeoutException e) {
            logger.info("吃客等待超时");
            return (float) 0;
        }

    }
}
```

- 测试

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;

import java.util.concurrent.Exchanger;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class TestExchangerTimeout {
    private static final Plate plate = new Plate();
    private static final Exchanger<Plate> exchanger = new Exchanger<>();

    public static void main(String[] args) {

        ExecutorService executorService = Executors.newFixedThreadPool(2);
        // 吃客开始打饭
        Future<Float> eaterFuture = executorService.submit(new EaterTimeoutWorker(exchanger, plate));
        WaitUtils.sleep(500);
        // 打饭阿姨
        Future<Plate> auntFuture = executorService.submit(new AuntTimeoutWorker(exchanger, plate));
        //Future<Float> eater2Future = executorService.submit(new EaterWorker(exchanger, plate));

        try {
            auntFuture.get();
            eaterFuture.get();
        } catch (Exception e) {
            e.printStackTrace();
        }

        executorService.shutdown();
        WaitUtils.waitUntil(() -> executorService.isTerminated(), 100000l);
    }
}
```

- 输出如下

```
21:11:48.179 [pool-1-thread-1] INFO  c.c.Exchanger.EaterTimeoutWorker - 拿出空的餐盘, 递给阿姨打饭
21:11:48.680 [pool-1-thread-2] INFO  c.ckjava.Exchanger.AuntTimeoutWorker - 阿姨开始在餐盘放置食物
21:11:51.181 [pool-1-thread-1] INFO  c.c.Exchanger.EaterTimeoutWorker - 吃客等待超时
21:11:51.681 [pool-1-thread-2] INFO  c.ckjava.Exchanger.AuntTimeoutWorker - 阿姨打饭完毕
21:11:55.682 [pool-1-thread-2] INFO  c.ckjava.Exchanger.AuntTimeoutWorker - 阿姨打饭超时，吃客已经离开
```