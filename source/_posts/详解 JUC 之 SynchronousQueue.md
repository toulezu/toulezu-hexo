---
title: 详解 JUC 之 SynchronousQueue
title_url: JUC-SynchronousQueue-understand-practice
date: 2020-09-03
tags: [JUC,BlockingQueue,SynchronousQueue]
categories: [JUC,BlockingQueue,SynchronousQueue]
description: 详解 JUC 之 SynchronousQueue
---

## 1 概述

- java.util.concurrent.SynchronousQueue

![SynchronousQueue](data:image/png;base64,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)

- SynchronousQueue 是一种阻塞队列，其实现了 BlockingQueue 接口。
- 容量为 0，该队列仅用于数据的交换，比如有两个线程，一个新增数据，另一个必须删除数据，否则就会阻塞新增或者删除的线程。
- 非常适合切换设计，在该设计中，一个线程中运行的对象必须与在另一个线程中运行的对象同步，以便向其传递一些信息，事件或任务。
- 尽管 SynchronousQueue 也实现了 Queue 接口，但是真正有用的就只有 take 和 put 这两个方法，并且都会阻塞调用这两个方法的线程。
- 功能上和 TransferQueue 以及 Exchanger 非常类似。
- 线程池工具类 Executors 的 newCachedThreadPool 就是用 SynchronousQueue 作为任务队列的。

## 2 关键点

1. 用于两个线程间以同步的方式来交换一些信息，事件或任务
2. 内部通过 TransferQueue 来实现
3. 容量为 0，调用其中的 size 和 remainingCapacity 方法都返回为 0，isEmpty 方法永远返回 true.

## 3 举例说明

比如去食堂打饭的时候，你把空餐盘递给阿姨后，阿姨在餐盘上放上饭菜，然后再递给你。

这里把打饭窗口比作 SynchronousQueue 队列，食客先将餐盘放到队列中，阿姨才能取出餐盘，阿姨打饭后将餐盘放到队列，食客才能取出。

#### 3.1 餐盘对象 Plate

```java
/**
 * 餐盘，存储食物，根据食物进行结算
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

    /**
     * 获取食物明细
     *
     * @return String
     */
    public String getFood() {
        return String.format("rice=%s, soup=%s, greens=%s, meat=%s", rice, soup, greens, meat);
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

#### 3.2 食客线程对象 EaterWorker

1. 食客线程先将餐盘交给阿姨，在队列上 put
2. 阿姨打饭完毕后，食客从队列中 take 出食物

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.SynchronousQueue;

/**
 * 食客线程先将餐盘交给阿姨，在队列上 put <br>
 * 阿姨打饭完毕后，食客从队列中 take 出食物 <br>
 */
public class EaterWorker implements Runnable {

    private static final Logger logger = LoggerFactory.getLogger(EaterWorker.class);

    private SynchronousQueue<Plate> foodQueue;
    private Plate plate;

    public EaterWorker(SynchronousQueue<Plate> foodQueue, Plate plate) {
        this.foodQueue = foodQueue;
        this.plate = plate;
    }

    public void run() {
        try {
            // 食客在窗口上放上餐盘，等待阿姨打饭
            logger.info("食客在窗口上放上餐盘，等待阿姨打饭");
            foodQueue.put(plate);

            // 拿到食物
            Plate plate = foodQueue.take();
            logger.info("拿回餐盘，刷钱离开, 食物: {}, 共计: {}", plate.getFood(), plate.getMoney());
        } catch (Exception e) {
            logger.error(this.getClass().getName().concat("has error"), e);
        }

    }
}
```

#### 3.3 打饭阿姨线程对象 AuntWorker

1. 阿姨线程先从队列中拿到食客的餐盘 take
2. 在餐盘上放置食物后，在把餐盘 put 到队列中

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.SynchronousQueue;

/**
 * 阿姨线程先拿到食客的餐盘 take
 * 在餐盘上放置食物后，在把餐盘 put 到队列中
 */
public class AuntWorker implements Runnable {

    private static final Logger logger = LoggerFactory.getLogger(AuntWorker.class);

    private SynchronousQueue<Plate> foodQueue;

    public AuntWorker(SynchronousQueue<Plate> foodQueue) {
        this.foodQueue = foodQueue;
    }

    public void run() {
        try {
            Plate plate = foodQueue.take();
            logger.info("阿姨拿到餐盘");

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

            logger.info("递给吃客");
            foodQueue.put(plate);

        } catch (Exception e) {
            logger.error(this.getClass().getName().concat("has error"), e);
        }
    }
}
```

#### 3.4 测试

在线程池中启动了两个线程，一个是阿姨线程，一个是吃客线程

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.SynchronousQueue;

/**
 * 1. 在线程池中启动了两个线程，一个是阿姨线程，一个是吃客线程
 * 2. 吃客线程将餐盘 put 到队列
 * 3. 阿姨线程从队列中取出 take 餐盘
 * 4. 阿姨向餐盘中放置食物，然后 put 到队列
 * 5. 食客线程从队列中 take 含有食物的餐盘，并结算
 */
public class TestSynchronizedQueue {

    private static final SynchronousQueue<Plate> foodQueue = new SynchronousQueue<>();

    public static void main(String[] args) {
        ExecutorService executorService = Executors.newFixedThreadPool(2);
        // 吃客开始打饭
        executorService.submit(new EaterWorker(foodQueue, new Plate()));
        // 打饭阿姨
        executorService.submit(new AuntWorker(foodQueue));

        executorService.shutdown();
        WaitUtils.waitUntil(() -> executorService.isTerminated(), 100000l);
    }
}
```

- 输出如下

```
11:33:08.510 [pool-1-thread-1] INFO  c.c.SynchronizedQueue.EaterWorker - 食客在窗口上放上餐盘，等待阿姨打饭
11:33:08.514 [pool-1-thread-2] INFO  c.c.SynchronizedQueue.AuntWorker - 阿姨拿到餐盘
11:33:08.514 [pool-1-thread-2] INFO  c.c.SynchronizedQueue.AuntWorker - 阿姨开始在餐盘放置食物
11:33:11.515 [pool-1-thread-2] INFO  c.c.SynchronizedQueue.AuntWorker - 阿姨打饭完毕
11:33:11.515 [pool-1-thread-2] INFO  c.c.SynchronizedQueue.AuntWorker - 递给吃客
11:33:11.526 [pool-1-thread-1] INFO  c.c.SynchronizedQueue.EaterWorker - 拿回餐盘，刷钱离开, 食物=rice=1.0, soup=0.55, greens=0.55, meat=0.55, 共计=4.85
```