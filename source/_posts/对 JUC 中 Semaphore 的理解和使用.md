---
title: 对 JUC 中 Semaphore 的理解和使用
title_url: JUC-CyclicBarrier-understand-practice
date: 2018-09-17
tags: [并发,Java,JUC,Semaphore]
categories: [并发,Java,JUC]
description: 对 JUC 中 Semaphore 的理解和使用
---

## Semaphore 的基本概念

Semaphore 翻译成字面意思为**信号量**，Semaphore 可以控制同时访问共享资源的线程个数，通过 `acquire()` 获取一个许可，如果没有就等待，而 `release()` 释放一个许可。

>一个计数信号量。从概念上讲，信号量维护了一个许可集。如有必要，在许可可用前会阻塞每一个 `acquire()`，然后再获取该许可。每个 `release()` 添加一个许可，从而可能释放一个正在阻塞的获取者。拿到信号量的线程可以进入代码，否则就等待。通过 `acquire()` 和 `release()` 获取和释放访问许可。

从使用的目的上来讲和 `synchronized` 非常相似: 同一个时间点只能有一个线程能够访问共享资源. 

- 区别在于 Semaphore 可以让一组线程同时访问共享资源, 让另一组线程等待, 在一个时间点有N个线程能够访问共享资源.
- Semaphore 的构造函数 `Semaphore(int permits)` 可以控制具体多少个线程可以同时访问共享资源, 最少1个, 最多应该和共享资源个数一致.

## 使用场景

配合 `synchronized` 或者 Atomic 来控制一次只有一个线程可以**获取**共享资源, Semaphore 用于协调线程对资源的**占用**和**释放**.

- 系统中最多有10个 Connection 对象, 那么最多只能允许 10 个线程同时使用, 只有当其中一个线程使用完一个 Connection 对象后, 其他等待的线程才能使用.
- 数据库中有1亿数据需要处理, 最多只能 10 个线程同时处理, 只有当某个线程处理完自己的 1 千万数据后才能从数据库中取出另 1 千万数据继续处理, 直到 1亿数据全部处理完.
- 当 Semaphore 对象中只有一个许可的时候, 可以实现和 `synchronized` 类似的效果, 而且支持公平锁和非公平锁.

## 场景1代码

```java

import org.apache.commons.lang3.RandomUtils;

import java.text.MessageFormat;
import java.util.concurrent.*;

public class TestSemaphore {
    public static void main(String[] args) {
        // 1. 初始化 10 个连接
        int avaCount = 10;
        BlockingQueue<String> connectionBlockingQueue = new ArrayBlockingQueue<>(avaCount);
        for (int i = 0; i < 10; i++) {
            try {
                connectionBlockingQueue.put(String.valueOf(i));
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        // 2. 只能 10 个线程同时访问, 控制线程数和资源数保持一致.
        Semaphore semaphore = new Semaphore(avaCount);

        // 3. 线程池中有 15 个线程可用, 15 个线程共享 10 个数据库连接
        ExecutorService executorService = Executors.newFixedThreadPool(15);

        // 4. 提交线程执行任务
        for (int i = 0; i < 15; i++) {
            executorService.submit(new SemaphoreWorker(String.valueOf(i+1), semaphore, connectionBlockingQueue));
        }

        executorService.shutdown();
    }

    public static class SemaphoreWorker implements Runnable {

        private String name;
        private Semaphore semaphore;
        private BlockingQueue<String> connectionBlockingQueue;

        public SemaphoreWorker(String name, Semaphore semaphore, BlockingQueue<String> connectionBlockingQueue) {
            this.name = name;
            this.semaphore = semaphore;
            this.connectionBlockingQueue = connectionBlockingQueue;
        }

        @Override
        public void run() {
            // 线程会在这里阻塞, 直到获取到许可
            try {
                semaphore.acquire();
                System.out.println(MessageFormat.format("thread {0} acquire, availablePermits {1}", new Object[]{name, semaphore.availablePermits()}));
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            // 获取数据库连接
            String connection = null;
            try {
                connection = connectionBlockingQueue.take();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            if (connection != null) {
                // 执行一些操作
                long s = RandomUtils.nextLong(1, 3);
                try {
                    TimeUnit.SECONDS.sleep(s);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(MessageFormat.format("thread {0} acquire, work {1} s", new Object[]{name, s}));

                // 还回数据库连接
                connectionBlockingQueue.offer(connection);
            }

            // 线程在这里释放许可
            semaphore.release();
            System.out.println(MessageFormat.format("thread {0} release, availablePermits {1}", new Object[]{name, semaphore.availablePermits() }));
        }
    }
}
```

输出如下

```
thread 11 acquire, availablePermits 0
thread 7 acquire, availablePermits 3
thread 6 acquire, availablePermits 4
thread 9 acquire, availablePermits 1
thread 1 acquire, availablePermits 8
thread 4 acquire, availablePermits 6
thread 8 acquire, availablePermits 2
thread 2 acquire, availablePermits 8
thread 5 acquire, availablePermits 5
thread 3 acquire, availablePermits 7
thread 1 acquire, work 1 s
thread 1 release, availablePermits 1
thread 10 acquire, availablePermits 0
thread 3 acquire, work 1 s
thread 6 acquire, work 1 s
thread 7 acquire, work 1 s
thread 6 release, availablePermits 1
thread 7 release, availablePermits 2
thread 12 acquire, availablePermits 0
thread 14 acquire, availablePermits 0
thread 13 acquire, availablePermits 1
thread 3 release, availablePermits 0
thread 11 acquire, work 2 s
thread 15 acquire, availablePermits 0
thread 11 release, availablePermits 1
thread 4 acquire, work 2 s
thread 8 acquire, work 2 s
thread 9 acquire, work 2 s
thread 5 acquire, work 2 s
thread 9 release, availablePermits 2
thread 5 release, availablePermits 3
thread 8 release, availablePermits 4
thread 4 release, availablePermits 1
thread 2 acquire, work 2 s
thread 2 release, availablePermits 5
thread 10 acquire, work 2 s
thread 10 release, availablePermits 6
thread 12 acquire, work 2 s
thread 14 acquire, work 2 s
thread 13 acquire, work 2 s
thread 14 release, availablePermits 7
thread 13 release, availablePermits 8
thread 12 release, availablePermits 9
thread 15 acquire, work 2 s
thread 15 release, availablePermits 10
```

对于输出结果可以得出的结论为:

- 15个并行的线程最后都执行完毕了, 每个线程的执行顺序为: 获取许可 -> 获取数据库连接 -> 执行任务 -> 还回数据库连接 -> 释放许可.
- 可用许可最多为 10, 最少为0, 当所有线程都执行完毕后, 许可为 10.

## 场景2代码

```java

import org.apache.commons.lang3.RandomUtils;

import java.text.MessageFormat;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicLong;

public class TestSemaphoreAtomicLong {
    public static void main(String[] args) {
        // 1. 通过 AtomicLong 对象记录每个线程处理的起始行
        AtomicLong currentRow = new AtomicLong();

        // 2. 只能 10 个线程同时访问, 控制线程数和资源数保持一致.
        int avaCount = 10;
        Semaphore semaphore = new Semaphore(avaCount);

        // 3. 线程池中有 15 个线程可用, 15 个线程共享 10 个数据库连接
        ExecutorService executorService = Executors.newFixedThreadPool(15);

        // 4. 提交线程执行任务
        for (int i = 0; i < 15; i++) {
            executorService.submit(new SemaphoreDbWorker(String.valueOf(i+1), semaphore, currentRow));
        }

        executorService.shutdown();
    }

    public static class SemaphoreDbWorker implements Runnable {

        private String name;
        private Semaphore semaphore;
        private AtomicLong currentRow;

        public SemaphoreDbWorker(String name, Semaphore semaphore, AtomicLong currentRow) {
            this.name = name;
            this.semaphore = semaphore;
            this.currentRow = currentRow;
        }

        @Override
        public void run() {
            while (true) {
                // 线程会在这里阻塞, 直到获取到许可
                try {
                    semaphore.acquire();
                    System.out.println(MessageFormat.format("thread {0} acquire, availablePermits {1}", new Object[]{name, semaphore.availablePermits()}));
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

                long statRow = currentRow.getAndAdd(1000);
                if (statRow > 10000) {
                    semaphore.release();
                    break;
                }

                // 执行一些操作
                long s = RandomUtils.nextLong(1, 3);
                try {
                    TimeUnit.SECONDS.sleep(s);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(MessageFormat.format("thread {0} acquire, work {1} s, {2} - {3}", new Object[]{name, s, statRow, 1000}));

                // 线程在这里释放许可
                semaphore.release();
                System.out.println(MessageFormat.format("thread {0} release, availablePermits {1}", new Object[]{name, semaphore.availablePermits() }));
            }

            System.out.println(MessageFormat.format("thread {0} exit, availablePermits {1}", new Object[]{name, semaphore.availablePermits() }));
        }
    }
}
```

在场景2代码中线程获取到许可后判断有没有处理完毕: 

- 如果全部处理完毕就可以释放许可,退出 while 循环; 
- 如果没有全部处理完毕, 继续执行, 然后释放许可, 继续 while 循环, 获得许可...

## 场景3代码

```java

import java.text.MessageFormat;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Semaphore;

public class TestSemaphoreSynchronized {
    public static void main(String[] args) {
        // 1, 多个线程访问公共变量, 在一个时间点只有一个线程能够获得许可
        // 使用公平锁, 先到的线程优先获得许可
        Semaphore semaphore = new Semaphore(1, true);

        // 2. 初始化 Calculator 对象
        Calculator calculator = new Calculator();

        // 3. 线程池中有 15 个线程可用, 15 个线程并发访问 Calculator 对象
        ExecutorService executorService = Executors.newFixedThreadPool(15);

        // 4. 提交线程执行任务
        for (int i = 0; i < 15; i++) {
            executorService.submit(new CalculatorWorker(String.valueOf(i+1), semaphore, calculator));
        }

        executorService.shutdown();
    }

    /**
     * 这是一个线程不安全的对象, 本身没有做同步处理
     */
    public static class Calculator {

        private int i = 0;

        private int get() {
            return i;
        }

        public int add(int a) {
            return i += a;
        }
    }

    public static class CalculatorWorker implements Runnable {

        private String name;
        private Semaphore semaphore;
        private Calculator calculator;

        public CalculatorWorker(String name, Semaphore semaphore, Calculator calculator) {
            this.name = name;
            this.semaphore = semaphore;
            this.calculator = calculator;
        }

        @Override
        public void run() {
            // 线程会在这里阻塞, 直到获取到许可
            try {
                semaphore.acquire();
                System.out.println(MessageFormat.format("thread {0} acquire", new Object[]{name}));
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            calculator.add(1);
            int a = calculator.get();

            // 线程在这里释放许可
            semaphore.release();
            System.out.println(MessageFormat.format("thread {0} release, a = {1}", new Object[]{name, a }));
        }
    }
}
```

## 常用的方法

- `Semaphore(int permits)` 构造函数, permits 参数表示许可数量
- `Semaphore(int permits, boolean fair)` 构造函数, permits 参数表示许可数量,  fair 表示线程获取许可的方式: 为 true 表示谁先到谁获得, 为 false 表示随机.
- `void acquire() throws InterruptedException` 线程以阻塞的方式获得许可, 被中断后抛出 InterruptedException 异常.
- `void release()` 线程释放获得的许可.
- `int availablePermits()` 当前 Semaphore 对象可用许可的数量

## 中断

```java
import java.text.MessageFormat;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

public class TestSemaphoreInterrupt {
    public static void main(String[] args) {
        // 1, 多个线程访问公共变量, 在一个时间点只有一个线程能够获得许可
        // 使用公平锁, 先到的线程优先获得许可
        Semaphore semaphore = new Semaphore(1, true);

        // 2. 初始化 Calculator 对象
        Calculator calculator = new Calculator();

        Thread thread1 = new Thread(new CalculatorWorker("1", semaphore, calculator));
        thread1.start();

        try {
            TimeUnit.SECONDS.sleep(2);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        Thread thread2 = new Thread(new CalculatorWorker("2", semaphore, calculator));
        thread2.start();

        // 在 main 线程中将 thread2 线程中断
        thread2.interrupt();
    }

    /**
     * 这是一个线程不安全的对象, 本身没有做同步处理
     */
    public static class Calculator {

        private int i = 0;

        private int get() {
            return i;
        }

        public int add(int a) {
            return i += a;
        }
    }

    public static class CalculatorWorker implements Runnable {

        private String name;
        private Semaphore semaphore;
        private Calculator calculator;

        public CalculatorWorker(String name, Semaphore semaphore, Calculator calculator) {
            this.name = name;
            this.semaphore = semaphore;
            this.calculator = calculator;
        }

        @Override
        public void run() {
            // 线程会在这里阻塞, 直到获取到许可
            boolean interruptFlag = false;
            try {
                semaphore.acquire();
                System.out.println(MessageFormat.format("thread {0} acquire", new Object[]{name}));
            } catch (InterruptedException e) {
                e.printStackTrace();
                interruptFlag = true;
                System.out.println(MessageFormat.format("thread {0} InterruptedException, availablePermits {1}", new Object[]{name, semaphore.availablePermits()}));
            }

            // 通过对 acquire() 方法抛出的 InterruptedException 做处理, 
            // 如果发生 InterruptedException 就不再调用  release() 方法
            if (!interruptFlag) {
                calculator.add(1);
                int a = calculator.get();

                try {
                    TimeUnit.SECONDS.sleep(10);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

                // 线程在这里释放许可
                semaphore.release();
                System.out.println(MessageFormat.format("thread {0} release, a = {1}, availablePermits {2}", new Object[]{name, a, semaphore.availablePermits() }));
            }

        }
    }
}
```

输出如下

```
thread 1 acquire
java.lang.InterruptedException
	at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireSharedInterruptibly(AbstractQueuedSynchronizer.java:1302)
	at java.util.concurrent.Semaphore.acquire(Semaphore.java:312)
	at com.ckjava.semaphore.TestSemaphoreInterrupt$CalculatorWorker.run(TestSemaphoreInterrupt.java:67)
	at java.lang.Thread.run(Thread.java:745)
thread 2 InterruptedException, availablePermits 0
thread 1 release, a = 1, availablePermits 1
```

在 Main 函数中启动了两个线程, 只有一个许可, 手动触发 thread2 线程的 `interrupt()` 方法, 线程中判断是否发生 InterruptedException 异常, 如果发生 InterruptedException 就不再调用 `release()` 方法.

## 没有成功调用 acquire() 方法然后调用了 release() 方法的问题

在场景3代码中, 如果在发生 InterruptedException 后还调用了 release() 方法会发生什么事情呢?

修改 CalculatorWorker 代码如下

```java
//if (!interruptFlag) {
    calculator.add(1);
    int a = calculator.get();

    try {
        TimeUnit.SECONDS.sleep(10);
    } catch (InterruptedException e) {
        e.printStackTrace();
    }

    // 线程在这里释放许可
    semaphore.release();
    System.out.println(MessageFormat.format("thread {0} release, a = {1}, availablePermits {2}", new Object[]{name, a, semaphore.availablePermits() }));
//}
```

输出如下

```
thread 1 acquire
java.lang.InterruptedException
	at java.util.concurrent.locks.AbstractQueuedSynchronizer.acquireSharedInterruptibly(AbstractQueuedSynchronizer.java:1302)
	at java.util.concurrent.Semaphore.acquire(Semaphore.java:312)
	at com.ckjava.semaphore.TestSemaphoreInterrupt$CalculatorWorker.run(TestSemaphoreInterrupt.java:65)
	at java.lang.Thread.run(Thread.java:745)
thread 2 InterruptedException, availablePermits 0
thread 1 release, a = 1, availablePermits 1
thread 2 release, a = 2, availablePermits 2
```

最后发现可用许可为2, 这与 Semaphore 构造函数中的许可数不一致, 这里可以得出

- `release()` 方法调用前不一定要调用 `acquire()` 方法
- `release()` 方法会增加许可数, 不会考虑 Semaphore 构造函数中的初始许可数
- 在调用 `acquire()` 方法发生 InterruptedException 异常后最好不要调用 `release()` 方法

## 实现原理

基于 CAS.