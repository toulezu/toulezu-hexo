---
title: 详解 JUC 之 DelayQueue
title_url: Java-JUC-DelayQueue-understand-practice
date: 2020-07-27
tags: [Java,JUC,并发]
categories: [Java,JUC,并发]
description: 详解 JUC 之 DelayQueue
---

## 1 概述

DelayQueue 用于在多线程环境下将并发对共享资源的访问转成串行访问。DelayQueue 中的元素可以设置有效时间，过期的元素才能被访问到。

## 2 DelayQueue 关键点

- `java.util.concurrent.DelayQueue` 实现了 BlockingQueue 接口
- 内部通过 PriorityQueue 和 ReentrantLock 实现元素的有序访问和并发控制
- BlockingQueue 队列用于多线程环境下的串行访问
- DelayQueue 中的元素对象必须实现 `java.util.concurrent.Delayed` 接口
- DelayQueue 中的元素对象必须重新 getDelay 方法和 compareTo 方法
- getDelay 方法返回 0 或者 -1 表示可以从队列中取出元素
- compareTo 方法用于队列中元素的排序
- 调用 DelayQueue 的 put, offer, take, poll 方法都会触发队列中的元素自动排序
- 调用 DelayQueue 的 put 方法会间接调用 PriorityQueue 的 offer 方法，再间接调用 siftUp 方法，siftUp 方法会通过元素中重写的 compareTo 方法进行排序
- 调用 DelayQueue 的 take 方法会间接调用元素中重写的 getDelay 方法，如果返回值 `<= 0` 就会间接调用 PriorityQueue 的 poll 方法，poll 方法 再间接调用 siftDown 方法，siftDown 方法会通过元素中重写的 compareTo 方法进行排序

## 3 消费者和使用者使用场景

这里以 消费者和使用者 多线程对临界区资源的共享访问为例。

#### 3.1 消费者线程实现

消费者线程向容器 消费 指定总量的任务

- DelayQueueConsumer

```java
import java.util.concurrent.BlockingQueue;
import java.util.stream.IntStream;

/**
 * 消费者线程向容器 消费 指定总量的任务
 *
 */
public class DelayQueueConsumer implements Runnable {

    private BlockingQueue<Task> queue;
    private Integer numberOfElementsToProduce;

    public DelayQueueConsumer(BlockingQueue<Task> queue, Integer numberOfElementsToProduce) {
        this.queue = queue;
        this.numberOfElementsToProduce = numberOfElementsToProduce;
    }

    @Override
    public void run() {
        IntStream.range(0, numberOfElementsToProduce).forEach(i -> {

            try {
                // 从队列中获取任务，并执行任务
                Task task = queue.take();
                task.doWork();
            } catch (Exception e) {
                e.printStackTrace();
            }

        });
    }
}
```

#### 3.2 生产者线程实现

生产者线程向容器存入指定总量的任务

- DelayQueueProducer

```java
import java.util.concurrent.BlockingQueue;
import java.util.stream.IntStream;

/**
 * 生产者线程向容器存入指定总量的 任务
 *
 */
public class DelayQueueProducer implements Runnable {

    // 容器
    private BlockingQueue<Task> queue;
    // 生产指定的数量
    private Integer numberOfElementsToProduce;
    private Long timeLeft;

    public DelayQueueProducer(BlockingQueue<Task> queue, Integer numberOfElementsToProduce, long timeLeft) {
        this.queue = queue;
        this.numberOfElementsToProduce = numberOfElementsToProduce;
        this.timeLeft = timeLeft;
    }

    @Override
    public void run() {
        IntStream.range(0, numberOfElementsToProduce).forEach(i -> {
            try {
                // 向队列中存入任务
                queue.put(new Task(timeLeft, String.format("task_%s", i)));
            } catch (Exception e) {
                e.printStackTrace();
            }
        });
    }
}
```

#### 3.3 队列中的任务对象

- Task

延迟执行的任务对象 

1. 实现 getDelay 方法，并重写 getDelay 方法 
2. 重写 compareTo 方法，确保到期的任务优先被执行

```java
import org.apache.commons.lang3.RandomUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.Delayed;
import java.util.concurrent.TimeUnit;

/**
 * 延迟执行的任务对象 <br>
 *     
 * 1. 实现 getDelay 方法，并重写 getDelay 方法<br>
 * 2. 重写 compareTo 方法，确保到期的任务优先被执行 <br>
 */
public class Task implements Delayed {

    private static final Logger logger = LoggerFactory.getLogger(Task.class);

    private String name;
    private long timeToRun;

    public Task(long timeLeft, String name) {
        this.name = name;
        this.timeToRun = timeLeft + System.currentTimeMillis();
        logger.info(String.format("%s init work, timeLeft:%s ms", name, timeLeft));
    }

    public void doWork() {
        try {
            logger.info(String.format("%s start work", name));
            // 模拟处理任务
            long workTime = RandomUtils.nextLong(1000, 9999);
            TimeUnit.MILLISECONDS.sleep(workTime);
            logger.info(String.format("%s finish work, workTime:%s ms", name, workTime));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    public long getDelay(TimeUnit unit) {
        long diff = timeToRun - System.currentTimeMillis();
        return unit.convert(diff, TimeUnit.MILLISECONDS);
    }

    @Override
    public int compareTo(Delayed o) {
        long gap = this.getDelay(TimeUnit.MILLISECONDS) - o.getDelay(TimeUnit.MILLISECONDS);
        return Long.valueOf(gap).intValue();
    }
}
```

#### 3.4 测试执行

1. 启动两个线程
2. 生产者生产 3 个 Task 任务
3. 消费者延迟执行这 3 个任务

- TestDelayedQueue

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;
import org.apache.commons.lang3.RandomUtils;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.DelayQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * 启动两个线程 <br>
 * 生产者生产 3 个 Task 任务 <br>
 * 消费者延迟执行这 3 个任务 <br>
 */
public class TestDelayedQueue {
    public static void main(String[] args) {

        BlockingQueue<Task> taskBlockingQueue = new DelayQueue<>();
        ExecutorService executorService = Executors.newFixedThreadPool(2);

        // 延迟执行的时间
        long time = RandomUtils.nextLong(1000, 5000);

        executorService.submit(new DelayQueueProducer(taskBlockingQueue, 3, time));
        executorService.submit(new DelayQueueConsumer(taskBlockingQueue, 3));

        executorService.shutdown();
        WaitUtils.waitUntil(() -> executorService.isTerminated(), 100000l);
    }
}
```

- 输出如下

```
15:40:26.056 [main] INFO  com.ckjava.delayQueue.Task - task_0 init work, timeLeft:4786 ms
15:40:26.058 [main] INFO  com.ckjava.delayQueue.Task - task_1 init work, timeLeft:4835 ms
15:40:26.058 [main] INFO  com.ckjava.delayQueue.Task - task_2 init work, timeLeft:3915 ms
15:40:29.815 [pool-1-thread-2] INFO  com.ckjava.delayQueue.Task - task_2 start work
15:40:32.484 [pool-1-thread-2] INFO  com.ckjava.delayQueue.Task - task_2 finish work, workTime:2669 ms
15:40:32.484 [pool-1-thread-2] INFO  com.ckjava.delayQueue.Task - task_0 start work
15:40:34.303 [pool-1-thread-2] INFO  com.ckjava.delayQueue.Task - task_0 finish work, workTime:1817 ms
15:40:34.303 [pool-1-thread-2] INFO  com.ckjava.delayQueue.Task - task_1 start work
15:40:37.763 [pool-1-thread-2] INFO  com.ckjava.delayQueue.Task - task_1 finish work, workTime:3459 ms
```

## 4 其他场景

#### 4.1 设置的延迟消费时间过长

1. 生产者线程向 DelayQueue 队列中存入一个 10s 后执行的任务
2. 消费者线程要求 5s 后获取到执行结果
3. 最终由于消费者线程超时无法从 DelayQueue 中获取到任务

- TestDelayedQueue2

```java
import java.util.concurrent.*;

/**
 * 生产者线程向 DelayQueue 队列中存入一个 10s 后执行的任务 <br>
 * 消费者线程要求 5s 后获取到执行结果 <br>
 */
public class TestDelayedQueue2 {
    public static void main(String[] args) {

        BlockingQueue<Task> taskBlockingQueue = new DelayQueue<>();

        ExecutorService executorService = Executors.newFixedThreadPool(2);

        // 生产者线程向 DelayQueue 队列中存入一个 10s 后执行的任务
        executorService.submit(new DelayQueueProducer(taskBlockingQueue, 1, 10_000));
        // 消费者线程要求 5s 后获取到执行结果
        Future<?> consumerFuture = executorService.submit(new DelayQueueConsumer(taskBlockingQueue, 1));

        // 停止接受新的任务，并在所有任务执行完毕后关闭
        executorService.shutdown();
        try {
            consumerFuture.get(5_000, TimeUnit.MILLISECONDS);
        } catch (Exception e) {
            // 如果出现异常，立即停止所有任务的执行
            executorService.shutdownNow();
        }
    }
}
```

- 输出如下

```
16:26:20.584 [pool-1-thread-1] INFO  com.ckjava.delayQueue.Task - task_0 init work, timeLeft:10000 ms
java.lang.InterruptedException
	at java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject.reportInterruptAfterWait(AbstractQueuedSynchronizer.java:2014)
	at java.util.concurrent.locks.AbstractQueuedSynchronizer$ConditionObject.awaitNanos(AbstractQueuedSynchronizer.java:2088)
	at java.util.concurrent.DelayQueue.take(DelayQueue.java:223)
	at java.util.concurrent.DelayQueue.take(DelayQueue.java:70)
	at com.ckjava.delayQueue.DelayQueueConsumer.lambda$run$0(DelayQueueConsumer.java:26)
	at java.util.stream.Streams$RangeIntSpliterator.forEachRemaining(Streams.java:110)
	at java.util.stream.IntPipeline$Head.forEach(IntPipeline.java:559)
	at com.ckjava.delayQueue.DelayQueueConsumer.run(DelayQueueConsumer.java:22)
	at java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)
	at java.util.concurrent.FutureTask.run$$$capture(FutureTask.java:266)
	at java.util.concurrent.FutureTask.run(FutureTask.java)
	at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1149)
	at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:624)
	at java.lang.Thread.run(Thread.java:748)
```

#### 4.2 设置的延迟消费时间为 0

1. 生产者线程向 DelayQueue 队列中存入一个 0s 后执行的任务
2. 消费者线程能够立即获取到任务并执行

```java

import com.ckjava.synchronizeds.appCache.WaitUtils;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.DelayQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * 生产者线程向 DelayQueue 队列中存入一个 0s 后执行的任务 <br>
 * 消费者线程能够立即获取到任务并执行<br>
 */
public class TestDelayedQueue3 {
    public static void main(String[] args) {

        BlockingQueue<Task> taskBlockingQueue = new DelayQueue<>();

        ExecutorService executorService = Executors.newFixedThreadPool(2);

        // 生产者线程向 DelayQueue 队列中存入一个 10s 后执行的任务
        executorService.submit(new DelayQueueProducer(taskBlockingQueue, 1, 0));
        executorService.submit(new DelayQueueConsumer(taskBlockingQueue, 1));

        // 停止接受新的任务，并在所有任务执行完毕后关闭
        executorService.shutdown();
        WaitUtils.waitUntil(() -> executorService.isTerminated(), 100000l);
    }
}
```

- 输出如下

```
17:09:54.959 [pool-1-thread-1] INFO  com.ckjava.delayQueue.Task - task_0 init work, timeLeft:0 ms
17:09:54.962 [pool-1-thread-2] INFO  com.ckjava.delayQueue.Task - task_0 start work
17:10:03.376 [pool-1-thread-2] INFO  com.ckjava.delayQueue.Task - task_0 finish work, workTime:8411 ms
```

## 5 参考

- [Guide to DelayQueue](https://www.baeldung.com/java-delay-queue)