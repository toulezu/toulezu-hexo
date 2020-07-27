---
title: 对 JUC 中 CyclicBarrier 的理解和使用
title_url: JUC-CyclicBarrier-understand-practice
date: 2018-09-13
tags: [并发,Java,JUC,CyclicBarrier]
categories: [Java,JUC,并发]
description: 对 JUC 中 CyclicBarrier 的理解和使用
---

## CyclicBarrier 基本概念

字面意思循环栅栏，它要做的事情是，让一组线程到达一个屏障（也可以叫同步点）时被阻塞，直到最后一个线程到达屏障时，屏障才会开门，所有被屏障拦截的线程才会继续干活.

CyclicBarrier 默认的构造方法是 `CyclicBarrier(int parties)`，其参数表示屏障拦截的线程数量，每个线程调用 await 方法告诉 `CyclicBarrier` 我已经到达了屏障，然后当前线程被阻塞。

## 使用场景

CyclicBarrier 可以用于多线程计算数据，最后合并计算结果的应用场景。

- 场景1: 我们用一个Excel保存了用户所有银行流水，每个Sheet保存一个帐户近一年的每笔银行流水，现在需要统计用户的日均银行流水，先用多线程处理每个sheet里的银行流水，都执行完之后，得到每个sheet的日均银行流水，最后，再用barrierAction用这些线程的计算结果，计算出整个Excel的日均银行流水。
- 场景2: 有一亿条数据需要处理, 需要控制线程的数量和内存使用率不要太高, 只能并行10个线程每次处理1千万条后再处理下一个1千万条, 每次处理1千万条后还要发邮件通知一下.

## 场景1: 实现代码

```java
import org.apache.commons.lang3.RandomUtils;

import java.text.MessageFormat;
import java.util.Iterator;
import java.util.concurrent.*;

// 只有所有线程的 await() 方法阻塞时, totalRunner 线程才开始执行
// 被 await() 方法阻塞的线程, 在 totalRunner 线程执行完毕后才能继续执行
// CyclicBarrier 中的第一个参数表示被 await() 方法阻塞的线程的数目
public class SyclicBarrierTestBarrierAction {

    public static void main(String[] args) {
        // 1. 首先获取excel sheet 的个数
        int sheetSize = 3;
        // 2. 初始化队列, 并设置大小, 和 sheet 数目一致, 用于存储每个线程获取到的数据
        ArrayBlockingQueue arrayBlockingQueue = new ArrayBlockingQueue(sheetSize);

        TotalRunner totalRunner = new TotalRunner("total", arrayBlockingQueue);
        // 3. 创建 CyclicBarrier 对象, await 线程数目和 sheet 数目一致
        // totalRunner 用于等所有 await 线程执行完毕后优先执行的逻辑
        CyclicBarrier cyclicBarrier = new CyclicBarrier(sheetSize, totalRunner);

        // 4. 创建线程池, 并设置大小, 和 sheet 数目一致, 用于 await 线程执行
        ExecutorService executorService = Executors.newFixedThreadPool(sheetSize);

        // 5. 提交到线程池中执行
        for (int i = 0; i < sheetSize; i++) {
            executorService.submit(new ExcelRunner(cyclicBarrier, arrayBlockingQueue, String.valueOf(i+1)));
        }
        executorService.shutdown();
    }

    /**
     * 多个线程并行计算数据
     */
    public static class ExcelRunner implements Runnable {

        private CyclicBarrier cyclicBarrier;
        private ArrayBlockingQueue arrayBlockingQueue;
        private String name;

        public ExcelRunner(CyclicBarrier cyclicBarrier, ArrayBlockingQueue arrayBlockingQueue, String name) {
            this.cyclicBarrier = cyclicBarrier;
            this.arrayBlockingQueue = arrayBlockingQueue;
            this.name = name;
        }

        @Override
        public void run() {
            Integer data = RandomUtils.nextInt(100, 5000);
            try {
                arrayBlockingQueue.put(data);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            try {
                //
                cyclicBarrier.await();
                System.out.println(MessageFormat.format("{0} produce data is {1}", new Object[]{name, data}));
            } catch (InterruptedException e) {
                e.printStackTrace();
            } catch (BrokenBarrierException e) {
                e.printStackTrace();
            }

        }
    }

    /**
     * 等所有线程执行完毕后, 这个线程统计最终数据
     */
    public static class TotalRunner implements Runnable {

        private String name;
        private ArrayBlockingQueue arrayBlockingQueue;

        public TotalRunner(String name, ArrayBlockingQueue arrayBlockingQueue) {
            this.name = name;
            this.arrayBlockingQueue = arrayBlockingQueue;
        }

        @Override
        public void run() {
            System.out.println(MessageFormat.format("{0} start ...", new Object[]{name}));
            Integer t = 0;
            for (Iterator it = arrayBlockingQueue.iterator(); it.hasNext();) {
                Object object = it.next();
                t += Integer.parseInt(object.toString());
            }
            System.out.println(MessageFormat.format("{0} sum is {1}", new Object[]{name, t}));
        }
    }
}
```

输出如下

```
total start ...
total sum is 7,545
1 produce data is 3,879
3 produce data is 1,585
2 produce data is 2,081
```

其中需要注意的地方如下

- 只有所有线程的 await() 方法阻塞时, totalRunner 线程才开始执行.
- 被 await() 方法阻塞的线程, 在 totalRunner 线程执行完毕后才能继续执行.
- CyclicBarrier 中的第一个参数表示被 await() 方法阻塞的线程的数目.

## 场景2: 实现代码

```java

import org.apache.commons.lang3.RandomUtils;

import java.text.MessageFormat;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 这里假设 startRow 是从数据库中读取数据的起始行数 mysql 中相当于 limit 中的第一个参数
 * 使用 AtomicInteger 确保每个并行线程从数据库中可以读取到自己唯一的100万数据
 * do...while 循环可以确保 10个线程同时到达 await() 方法后可以循环执行,直到达到某个条件
 * 这里才能最能体现 CyclicBarrier 对象的含义:循环栅栏, 所有线程都到达  await() 方法后(到达栅栏后)又可以回过头继续重复执行
 */
public class SyclicBarrierTestBarrierActionPlus {

    private static final int threadNumber = 10;
    private static AtomicInteger startRow = new AtomicInteger();
    private static CyclicBarrier cyclicBarrier = new CyclicBarrier(threadNumber, new SendEmailRunner("total"));

    public static void main(String[] args) {

        ExecutorService executorService = Executors.newFixedThreadPool(threadNumber);

        for (int i = 0; i < threadNumber; i++) {
            executorService.submit(new DataProcessRunner(String.valueOf(i + 1)));
        }
        executorService.shutdown();

        // 通过 ExecutorService 对象的 shutdown() 方法 和 isTerminated() 方法组合判断 1 亿数据是否全部处理完毕
        while (true) {
            if (executorService.isTerminated()) {
                System.out.println(MessageFormat.format("{0} finish, total {1}", new Object[]{"main", startRow.get()}));
                break;
            }
        }
    }

    /**
     * 多个线程并行计算数据
     */
    public static class DataProcessRunner implements Runnable {

        private String name;

        public DataProcessRunner(String name) {
            this.name = name;
        }

        @Override
        public void run() {
            // do while 循环可以确保循环执行,直到达到某个条件
            do {
                // 获取读取的起始记录和记录数
                Integer rows = 100;
                Integer start = startRow.getAndAdd(rows);

                // 模拟读取和处理的过程
                try {
                    TimeUnit.SECONDS.sleep(RandomUtils.nextInt(1, 5));
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }

                try {
                    System.out.println(MessageFormat.format("{0} process data limit {1},{2}", new Object[]{name, start, rows}));
                    // 等所有10个线程全部处理完各自的 100 万数据后再会进入下一次循环
                    // 这里才能最能体现 CyclicBarrier 对象的含义:循环栅栏, 所有线程都到达  await() 方法后(到达栅栏后)又可以回过头继续重复执行
                    cyclicBarrier.await();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (BrokenBarrierException e) {
                    e.printStackTrace();
                }
            } while (startRow.get() < 10000); // 循环处理到达了某个条件, 这里是处理完了 1 亿数据

            // CycBarrier 的模板代码
            /*do {
                // doing work
                cyclicBarrier.await();
            } while (condition_true);*/

        }
    }

    /**
     * 等所有线程到达 await() 方法后, 这个线程统计最终数据
     */
    public static class SendEmailRunner implements Runnable {

        private String name;

        public SendEmailRunner(String name) {
            this.name = name;
        }

        @Override
        public void run() {
            System.out.println(MessageFormat.format("{0} process finish, total {1}, sendEmail success", new Object[]{name, startRow.get()}));
        }
    }
}
```

其中关键点如下

- 这里假设 startRow 是从数据库中读取数据的起始行数, 在 mysql 中相当于 limit 中的第一个参数
- 使用 AtomicInteger 确保每个并行线程从数据库中可以读取到自己唯一的100万数据
- `do...while` 循环可以确保 10个线程同时到达 await() 方法后可以循环执行,直到达到某个条件
- 这里才能最能体现 CyclicBarrier 对象的含义:循环栅栏, 所有线程都到达  await() 方法后(到达栅栏后)又可以回过头继续重复执行
- CyclicBarrier 需要配合 while 循环才能实现 Cyclic 功能,模板代码如下

```
do {
    // doing work
    cyclicBarrier.await();
} while (condition);
```

结果如下

```
7 process data limit 600,100
5 process data limit 400,100
10 process data limit 900,100
2 process data limit 100,100
1 process data limit 0,100
8 process data limit 700,100
9 process data limit 800,100
4 process data limit 300,100
3 process data limit 200,100
6 process data limit 500,100
total process finish, total 1,000, sendEmail success
1 process data limit 1,500,100
9 process data limit 1,700,100
6 process data limit 1,000,100
4 process data limit 1,800,100
7 process data limit 1,100,100
10 process data limit 1,300,100
8 process data limit 1,600,100
3 process data limit 1,900,100
2 process data limit 1,400,100
5 process data limit 1,200,100
total process finish, total 2,000, sendEmail success
3 process data limit 2,800,100
2 process data limit 2,900,100
10 process data limit 2,600,100
4 process data limit 2,400,100
5 process data limit 2,000,100
9 process data limit 2,200,100
6 process data limit 2,300,100
7 process data limit 2,500,100
1 process data limit 2,100,100
8 process data limit 2,700,100
total process finish, total 3,000, sendEmail success
5 process data limit 3,500,100
6 process data limit 3,700,100
2 process data limit 3,200,100
10 process data limit 3,300,100
7 process data limit 3,800,100
9 process data limit 3,600,100
4 process data limit 3,400,100
3 process data limit 3,100,100
8 process data limit 3,000,100
1 process data limit 3,900,100
total process finish, total 4,000, sendEmail success
8 process data limit 4,900,100
9 process data limit 4,600,100
4 process data limit 4,800,100
7 process data limit 4,500,100
2 process data limit 4,300,100
5 process data limit 4,100,100
1 process data limit 4,000,100
10 process data limit 4,400,100
6 process data limit 4,200,100
3 process data limit 4,700,100
total process finish, total 5,000, sendEmail success
2 process data limit 5,500,100
5 process data limit 5,600,100
4 process data limit 5,200,100
8 process data limit 5,100,100
9 process data limit 5,300,100
3 process data limit 5,000,100
7 process data limit 5,400,100
10 process data limit 5,800,100
6 process data limit 5,900,100
1 process data limit 5,700,100
total process finish, total 6,000, sendEmail success
2 process data limit 6,100,100
5 process data limit 6,200,100
1 process data limit 6,000,100
10 process data limit 6,800,100
9 process data limit 6,500,100
7 process data limit 6,700,100
3 process data limit 6,600,100
8 process data limit 6,400,100
6 process data limit 6,900,100
4 process data limit 6,300,100
total process finish, total 7,000, sendEmail success
10 process data limit 7,400,100
7 process data limit 7,600,100
1 process data limit 7,300,100
9 process data limit 7,500,100
8 process data limit 7,800,100
6 process data limit 7,900,100
3 process data limit 7,700,100
4 process data limit 7,000,100
5 process data limit 7,200,100
2 process data limit 7,100,100
total process finish, total 8,000, sendEmail success
6 process data limit 8,600,100
10 process data limit 8,100,100
5 process data limit 8,900,100
2 process data limit 8,000,100
8 process data limit 8,500,100
9 process data limit 8,400,100
1 process data limit 8,300,100
7 process data limit 8,200,100
3 process data limit 8,700,100
4 process data limit 8,800,100
total process finish, total 9,000, sendEmail success
1 process data limit 9,700,100
6 process data limit 9,100,100
10 process data limit 9,200,100
4 process data limit 9,000,100
2 process data limit 9,400,100
9 process data limit 9,600,100
3 process data limit 9,900,100
5 process data limit 9,300,100
7 process data limit 9,800,100
8 process data limit 9,500,100
total process finish, total 10,000, sendEmail success
main finish, total 10,000
```

## 常用的方法

- `public CyclicBarrier(int parties)` 带有 await() 方法的线程数目的构造函数.
- `public CyclicBarrier(int parties, Runnable barrierAction)` 带有 barrierAction 对象的构造函数, 所有线程到达 await() 方法后才会执行.
- `public void reset()` 触发带有 await() 方法的线程抛出 `java.util.concurrent.BrokenBarrierException` 异常, 退出阻塞状态, 并且不再循环执行, 相当于将循环栅栏破坏了.
- `public int getNumberWaiting()` 获取当前到达 await() 方法的线程数目, 用于调试.
- `public int await()` 阻塞当前线程
- ` public int await(long timeout, TimeUnit unit)` 阻塞当前线程, 当超时的时候抛出 `java.util.concurrent.BrokenBarrierException` 异常
- `public boolean isBroken()` 判断循环栅栏是否被破坏

## 中断

`await()` 方法会阻塞当前线程, 如果其他线程调用当前线程的 `interrupt()` 方法或者 `await(long timeout, TimeUnit unit)` 方法抛出 `java.util.concurrent.TimeoutException` 异常都会破坏循环栅栏, 这时可以通过 `isBroken()` 方法判断循环栅栏是否被破坏.

```
public static class DataProcessRunner implements Runnable {

    private String name;
    private CyclicBarrier cyclicBarrier;

    public DataProcessRunner(String name, CyclicBarrier cyclicBarrier) {
        this.name = name;
        this.cyclicBarrier = cyclicBarrier;
    }

    @Override
    public void run() {
        // do while 循环可以确保循环执行,直到达到某个条件
        do {
            // 获取读取的起始记录和记录数
            Integer rows = 100;
            Integer start = startRow.getAndAdd(rows);

            // 模拟读取和处理的过程
            try {
                TimeUnit.SECONDS.sleep(RandomUtils.nextInt(1, 5));
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            try {
                System.out.println(MessageFormat.format("{0} process data limit {1},{2}", new Object[]{name, start, rows}));
                // 等所有10个线程全部处理完各自的 100 万数据后再会进入下一次循环
                // 这里才能最能体现 CyclicBarrier 对象的含义:循环栅栏, 所有线程都到达  await() 方法后(到达栅栏后)又可以回过头继续重复执行
                cyclicBarrier.await(1, TimeUnit.SECONDS);
            } catch (TimeoutException e) {
                e.printStackTrace();
            } catch (InterruptedException e) {
                e.printStackTrace();
            } catch (BrokenBarrierException e) {
                System.out.println("BrokenBarrierException");
            }

            if (cyclicBarrier.isBroken()) {
                // do....
            }
        } while (startRow.get() < 10000 && !cyclicBarrier.isBroken()); // 循环处理到达了某个条件, 这里是处理完了 1 亿数据
    }
}
```

上面这个 Runnable 对象在循环栅栏被破坏后会主动退出执行, 并且可以做一些回滚操作.

## 实现原理

ReentrantLock

## 参考

- [并发工具类（二）同步屏障CyclicBarrier](http://ifeve.com/concurrency-cyclicbarrier/)