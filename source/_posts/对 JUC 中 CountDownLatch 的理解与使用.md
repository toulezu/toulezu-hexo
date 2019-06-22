---
title: 对 JUC 中 CountDownLatch 的理解与使用
title_url: JUC-CountDownLatch-understand-practice
date: 2018-09-13
tags: [并发,Java,JUC,CountDownLatch]
categories: [Java,并发]
description: 对 JUC 中 CountDownLatch 的理解与使用
---

## CountDownLatch 的基本概念

CountDownLatch 类位于 java.util.concurrent 包下，利用它可以实现类似计数器的功能。比如有一个任务A，它要等待其他4个任务执行完毕之后才能执行，此时就可以利用 CountDownLatch 来实现这种功能了。

简单的说就是要等其他任务执行完毕后当前任务才能执行.

## 使用场景

- 场景1. 只有当前线程A从DB加载数据, 线程B进行处理分析, 线程C生成统计文件全部执行完毕后, 线程D才能将统计文件以邮件发送出去.
- 场景2. 线程A,B,C都要等线程D执行完毕后才能同时执行, 这时可以设置 `CountDownLatch(int count)` 构造函数中的 count 为1, 这样可以最大实现线程的并行性.

## 场景1 实现代码

```
import org.apache.commons.lang3.RandomUtils;

import java.text.MessageFormat;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * CountDownLatch 的构造函数 count 表示其他线程的个数
 * 当前线程和其他线程共享一个 CountDownLatch 对象
 * 当前线程调用 await() 方法阻塞
 * 其他线程在执行完毕后调用 countDown() 方法进行倒计时(count --)
 */
public class TestCountDownLatch {
    public static void main(String[] args) {

        // 这里的线程池中至少要有两个线程, 1个给当前Runner(在其他Runner执行完毕后才执行), 1个给其他Runner.
        ExecutorService executorService  = Executors.newFixedThreadPool(2);

        // CountDownLatch 构造参数表示 其他Runner 的个数, 不包含当前Runner
        CountDownLatch countDownLatch = new CountDownLatch(3);

        // 当前Runner 也需要 CountDownLatch 对象, 通过 await() 方法阻塞 当前Runner 的线程.
        executorService.submit(new MainRunner(countDownLatch));

        // 这里提交了3个Runner
        for (int i = 1; i <= 3; i++) {
            executorService.submit(new WorkRunner(String.valueOf(i), countDownLatch));
        }
        
    }

    public static class WorkRunner implements Runnable {

        private String RunnerName;
        private CountDownLatch countDownLatch;

        public WorkRunner(String runnerName, CountDownLatch countDownLatch) {
            RunnerName = runnerName;
            this.countDownLatch = countDownLatch;
        }

        @Override
        public void run() {
            try {
                int time = RandomUtils.nextInt(1, 5);
                TimeUnit.SECONDS.sleep(time);

                System.out.println(MessageFormat.format("WorkRunner {0} work {1} s", new Object[]{RunnerName, time}));
                countDownLatch.countDown();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }

    public static class MainRunner implements Runnable {

        private CountDownLatch countDownLatch;

        public MainRunner(CountDownLatch countDownLatch) {
            this.countDownLatch = countDownLatch;
        }

        @Override
        public void run() {
            try {
                countDownLatch.await();

                TimeUnit.SECONDS.sleep(2);

                System.out.println("MainRunner finish");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}

```

执行结果如下

```
WorkRunner 2 work 2 s
WorkRunner 1 work 2 s
WorkRunner 3 work 3 s
MainRunner finish
```

其中的关键点如下:

 - CountDownLatch 的构造函数 count 表示其他线程的个数
 - 当前线程和其他线程共享一个 CountDownLatch 对象
 - 当前线程调用 await() 方法阻塞
 - 其他线程在执行完毕后调用 countDown() 方法进行倒计时(count --)

## 场景2 实现代码

```java
/**
 * 三个线程等待一个线程执行完毕后才能并行执行.
 */
public class TestCountDownLatch1 {
    public static void main(String[] args) {

        // 这里的线程池中至少要有4个线程, 3个给被阻塞的线程, 1 给优先执行的线程.
        ExecutorService executorService = Executors.newFixedThreadPool(4);

        CountDownLatch countDownLatch = new CountDownLatch(1);

        executorService.submit(new TestCountDownLatch.MainRunner(countDownLatch));
        executorService.submit(new TestCountDownLatch.MainRunner(countDownLatch));
        executorService.submit(new TestCountDownLatch.MainRunner(countDownLatch));

        executorService.submit(new TestCountDownLatch.WorkRunner(String.valueOf(1), countDownLatch));
    }
}
```

执行结果如下

```
WorkRunner 1 work 4 s
MainRunner finish
MainRunner finish
MainRunner finish
```

## 常用的方法

- CountDownLatch(int count) CountDownLatch 的构造函数, count 表示其他线程的数量.
- countDown() 其他线程使用.
- await() 被阻塞的线程使用.
- await(long timeout, TimeUnit unit) 被阻塞的线程使用, 等待的时间超过 timeout 后继续执行.

## 中断

`await()` 方法会导致当前线程阻塞, 如果其他线程的 `countDown()` 方法一直没有调用会导致当前线程一直阻塞下去. 当有其他线程调用当前线程对象的 `interrupt()` 方法可以使 `await()` 方法抛出 InterruptedException 异常结束阻塞状态.

代码如下

```java
import java.text.MessageFormat;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/**
 * await() 方法使当前线程A 阻塞, 其他线程c 调用 线程A 对象的 interrupt() 方法使其从阻塞状态退出, 此时 await() 方法抛出 java.lang.InterruptedException
 * 线程B 在调用 countDown() 方法后正常退出
 */
public class TestCountDownLatchInterrupt {
    public static void main(String[] args) {

        // 这里的线程池中至少要有4个线程, 3个给被阻塞的线程, 1 给优先执行的线程.
        CountDownLatch countDownLatch = new CountDownLatch(1);
        Thread workThreaad = new Thread(new WorkRunner("workThreaad", countDownLatch));
        Thread awaitThreaad = new Thread(new AwaitRunner("awaitThreaad", countDownLatch));
        Thread interruptThreaad = new Thread(new InterruptRunner(awaitThreaad));

        workThreaad.start();
        awaitThreaad.start();
        interruptThreaad.start();
    }

    public static class WorkRunner implements Runnable {

        private String RunnerName;
        private CountDownLatch countDownLatch;

        public WorkRunner(String runnerName, CountDownLatch countDownLatch) {
            RunnerName = runnerName;
            this.countDownLatch = countDownLatch;
        }

        @Override
        public void run() {
            try {
                TimeUnit.MILLISECONDS.sleep(6000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            System.out.println(MessageFormat.format("{0} finish", new Object[]{RunnerName}));
            countDownLatch.countDown();
        }
    }

    public static class AwaitRunner implements Runnable {

        private String RunnerName;
        private CountDownLatch countDownLatch;

        public AwaitRunner(String runnerName, CountDownLatch countDownLatch) {
            RunnerName = runnerName;
            this.countDownLatch = countDownLatch;
        }

        @Override
        public void run() {
            try {
                // await() 方法使当前线程阻塞,
                countDownLatch.await();
            } catch (InterruptedException e) {
                System.err.print(MessageFormat.format("AwaitRunner {0} has InterruptedException:\n", new Object[]{RunnerName}));
                e.printStackTrace();
            }
            System.out.println(MessageFormat.format("{0} finish", new Object[]{RunnerName}));
        }
    }

    public static class InterruptRunner implements Runnable {

        private Thread targetThread;

        public InterruptRunner(Thread targetThread) {
            this.targetThread = targetThread;
        }

        @Override
        public void run() {
            try {
                TimeUnit.MILLISECONDS.sleep(2000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println("interrupt targetThread");
            targetThread.interrupt();
        }
    }
}
```

## 实现原理

基于 CAS.