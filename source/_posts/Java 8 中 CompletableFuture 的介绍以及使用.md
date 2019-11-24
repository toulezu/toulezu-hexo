---
title: Java 8 中 CompletableFuture 的介绍以及使用
title_url: understand-Java-8-CompletableFuture-usage-practice
date: 2019-11-24
tags: [Java,Java8]
categories: [Java]
description: 在 Java 8 中, 新增加了 CompletableFuture 类，实现了 Future 和 CompletionStage 接口，可以简化异步编程的复杂性，提供了函数式编程的能力，以类似回调的方式异步处理前后有依赖关系的任务，并且不会阻塞线程。
---

## 1 概述

- java.util.concurrent.CompletableFuture

在 Java 8 中, 新增加了 CompletableFuture 类，实现了 Future 和 CompletionStage 接口，可以简化异步编程的复杂性，提供了函数式编程的能力，以类似回调的方式异步处理前后有依赖关系的任务，并且不会阻塞线程。

## 2 关键特性

1. CompletableFuture 可以从全局的 `ForkJoinPool.commonPool()` 中获得一个线程执行异步任务。也可以创建一个线程池并传给 runAsync() 和 supplyAsync() 方法来让他们从线程池中获取一个线程执行它们的任务。
2. 以异步的方式顺序执行任务，如果依赖上一个任务的执行结果也不需要阻塞线程，以类似回调的方式得到上一个任务的执行结果后再异步继续执行下去。

## 3 方法

下面列出了 13 个常用的方法。

1. `public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier)` ：异步执行任务, 线程池为 `ForkJoinPool.commonPool()`
2. `public T get() throws InterruptedException, ExecutionException`: 以阻塞的方式获取结果
3. `public static <U> CompletableFuture<U> supplyAsync(Supplier<U> supplier, Executor executor)`: 通过自定义线程池执行异步任务
4. `public CompletableFuture<Void> thenAccept(Consumer<? super T> action)`： thenAccept 方法的参数是 Consumer 接口，参数为上一个任务的返回值，没有返回值
5. `public <U> CompletableFuture<U> thenApply(Function<? super T,? extends U> fn)`: thenApply 方法的参数是 Function 接口，参数为上一个任务的返回值, 有返回值
6. `public CompletableFuture<Void> thenRun(Runnable action)`: thenRun 方法的参数是 Runnable 接口，没有参数也没有返回值
7. `public CompletableFuture<Void> thenAccept(Consumer<? super T> action)`: 与 thenApply 方法不同的地方在于将会从 ForkJoinPool.commonPool() 中取出一个新的线程用于执行异步任务
8. `public <U> CompletableFuture<U> thenCompose(Function<? super T, ? extends CompletionStage<U>> fn)`: thenCompose 方法的参数是 Function 接口，参数为上一个任务的返回值，返回 CompletableFuture 对象
9. `public <U,V> CompletableFuture<V> thenCombine(CompletionStage<? extends U> other, BiFunction<? super T,? super U,? extends V> fn)`: thenCombine 用于组合两个 CompletableFuture 对象的执行结果，第一个参数为待组合的另一个 CompletableFuture 对象; 第二个参数为 BiFunction 对象，其中的 apply 参数为组合的两个 CompletableFuture 对象的执行结果
10. `public static CompletableFuture<Void> allOf(CompletableFuture<?>... cfs)`: allOf 可以确保参数中所有的 CompletableFuture 对象中的任务都执行完毕后再执行随后的 thenApplyAsync 方法中的异步任务
11. `public static CompletableFuture<Object> anyOf(CompletableFuture<?>... cfs)`: anyOf 可以确保参数中任意一个 CompletableFuture 对象中的任务执行完毕后就会执行随后的 thenApplyAsync 方法中的异步任务
12. `public CompletableFuture<T> exceptionally(Function<Throwable, ? extends T> fn)`: exceptionally 用于在 supplyAsync，thenApply 异步任务链上增加异常处理的功能, 一旦发生异常，后续的所有任务都不会执行了
13. `public <U> CompletableFuture<U> handle(BiFunction<? super T, Throwable, ? extends U> fn)`: handle 相比 exceptionally 不仅可以处理异常，还可以在异常发生后处理异常并继续处理: 1. 如果发生异常，根据异常信息进行重试或者其他处理，然后返回结果，让后续的异步任务能够继续进行下去; 2. 如果没有发生异常，异常对象 ex 为 null, 这时候只需要 return 上一步的处理结果.

## 4 测试

- 下面是对上面 13 个方法的测试以及理解。

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;
import com.ckjava.xutils.Constants;
import com.ckjava.xutils.DateUtils;
import org.apache.commons.lang3.RandomUtils;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.*;

public class TestCompletableFuture {
    private static final Logger logger = LoggerFactory.getLogger(TestCompletableFuture.class);

    private ExecutorService commonThreadPool = Executors.newFixedThreadPool(1);

    @Test
    public void test_get() throws Exception {
        // 1. 通过 supplyAsync 方法启动线程执行任务，并返回 CompletableFuture 对象
        // 任务执行在 ForkJoinPool.commonPool() 线程池中
        CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
            try {
                // 模拟执行任务
                TimeUnit.SECONDS.sleep(1);
                logger.info(String.format("%s finish work", Thread.currentThread().getName()));
            } catch (InterruptedException e) {
                throw new IllegalStateException(e);
            }
            return "Result of the asynchronous computation";
        });

        // 2. 阻塞当前线程直到 supplyAsync 中的线程结束执行
        String result = future.get();
        logger.info(result);
    }

    @Test
    public void test_thenApply() throws Exception {
        // 1. 异步执行一个任务后，自动通过 thenApply 方法启动另外一个异步任务，参数为上一个任务的返回值
        // 2. thenApply 方法的参数是 Function 接口，参数为上一个任务的返回值, 有返回值
        CompletableFuture.supplyAsync(() -> {
            try {
                // 模拟执行任务
                TimeUnit.SECONDS.sleep(1);
                logger.info(String.format("%s finish supplyAsync work", Thread.currentThread().getName()));
            } catch (InterruptedException e) {
                throw new IllegalStateException(e);
            }
            return "ck";
        }).thenApply(t -> {
            logger.info(t + "java");
            logger.info(String.format("%s finish thenApply work", Thread.currentThread().getName()));
            return t + "Java";
        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));
    }

    @Test
    public void test_thenApply_commonThreadPool() throws Exception {
        // 1. 异步执行一个任务后，自动通过 thenApply 方法启动另外一个异步任务，参数为上一个任务的返回值
        // 2. thenApply 方法的参数是 Function 接口，参数为上一个任务的返回值，有返回值
        CompletableFuture.supplyAsync(() -> {
            try {
                // 模拟执行任务
                TimeUnit.SECONDS.sleep(1);
                logger.info(String.format("%s finish supplyAsync work", Thread.currentThread().getName()));
            } catch (InterruptedException e) {
                throw new IllegalStateException(e);
            }
            return "ck";
        }, commonThreadPool).thenApplyAsync(t -> {
            logger.info(t + "java");
            logger.info(String.format("%s finish thenApply work", Thread.currentThread().getName()));
            return t + "Java";
        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        commonThreadPool.shutdown();
        WaitUtils.waitUntil(() -> commonThreadPool.isTerminated(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));
    }

    @Test
    public void test_thenAccept() throws Exception {
        // 1. 通过 supplyAsync 方法异步执行一个任务后，再通过 thenAccept 方法启动另外一个异步任务，参数为上一个任务的返回值
        // 2. thenAccept 方法的参数是 Consumer 接口，传入一个参数没有返回值
        CompletableFuture.supplyAsync(() -> {
            try {
                // 模拟执行任务
                TimeUnit.SECONDS.sleep(1);
                logger.info(String.format("%s finish supplyAsync work", Thread.currentThread().getName()));
            } catch (InterruptedException e) {
                throw new IllegalStateException(e);
            }
            return "ck";
        }).thenAccept(t -> {
            logger.info(t + "java");
            logger.info(String.format("%s finish thenAccept work", Thread.currentThread().getName()));
        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));
    }

    @Test
    public void test_thenRun() throws Exception {
        // 1. 通过 supplyAsync 方法异步执行一个任务后，自动通过 thenRun 方法启动另外一个异步任务
        // 2. thenRun 方法的参数是 Runnable 接口，没有参数也没有返回值
        CompletableFuture.supplyAsync(() -> {
            try {
                // 模拟执行任务
                TimeUnit.SECONDS.sleep(1);
                logger.info(String.format("%s finish supplyAsync work", Thread.currentThread().getName()));
            } catch (InterruptedException e) {
                throw new IllegalStateException(e);
            }
            return "ck";
        }).thenRun(() -> {
            logger.info("task finish");

            logger.info(String.format("%s finish thenRun work", Thread.currentThread().getName()));
        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));
    }

    @Test
    public void test_thenApplyAsync() throws Exception {
        // 1. 异步执行一个任务后，自动通过 thenApplyAsync 方法启动另外一个异步任务，参数为上一个任务的参数
        // 2. 与 thenApply 方法不同的地方在于将会从 ForkJoinPool.commonPool() 中取出一个新的线程用于执行异步任务
        // 3. thenApplyAsync 方法的参数是 Function 接口，参数为上一个任务的返回值，有返回值
        CompletableFuture.supplyAsync(() -> {
            try {
                // 模拟执行任务
                TimeUnit.SECONDS.sleep(RandomUtils.nextInt(1, 3));
                logger.info(String.format("%s finish supplyAsync work", Thread.currentThread().getName()));
            } catch (InterruptedException e) {
                throw new IllegalStateException(e);
            }
            return "ck";
        }).thenApplyAsync(t -> {
            logger.info(t + " java1 " + getNow());
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s finish thenApplyAsync 1 work", Thread.currentThread().getName()));
            return t + "java";
        }).thenApplyAsync(d -> {
            logger.info(d + " java2 " + getNow());
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s finish thenApplyAsync 2 work", Thread.currentThread().getName()));
            return null;
        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));
    }

    @Test
    public void test_thenCompose() throws Exception {
        // 1. 异步执行一个任务后，自动通过 thenCompose 方法启动另外一个异步任务，参数为上一个任务的参数，返回值为 CompletableFuture 对象
        // 3. thenCompose 方法的参数是 Function 接口，参数为上一个任务的返回值，返回 CompletableFuture 对象
        CompletableFuture.supplyAsync(() -> {
            try {
                // 模拟执行任务
                TimeUnit.SECONDS.sleep(1);
                logger.info(String.format("%s finish supplyAsync work", Thread.currentThread().getName()));
            } catch (InterruptedException e) {
                throw new IllegalStateException(e);
            }
            return "ck";
        }).thenCompose(t -> {
            logger.info(t + "java");
            logger.info(String.format("%s finish thenCompose work", Thread.currentThread().getName()));
            return CompletableFuture.completedFuture(t + "java");
        }).thenApplyAsync(t -> {
            logger.info(t + "java");
            logger.info(String.format("%s finish thenApplyAsync work", Thread.currentThread().getName()));
            return null;
        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));
    }

    @Test
    public void test_thenCombine() throws Exception {
        // 1. 异步执行一个任务后，自动通过 thenCombine 方法启动另外一个异步任务，参数为上一个任务的参数，返回值为 CompletableFuture 对象
        // 3. thenCombine 用于组合两个 CompletableFuture 对象的执行结果，第一个参数为待组合的另一个 CompletableFuture 对象
        // 第二个参数为 BiFunction 对象，其中的 apply 参数为组合的两个 CompletableFuture 对象的执行结果

        Integer userId = 1;
        CompletableFuture<String> userDetailFutrue = CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s finish userDetailFutrue work", Thread.currentThread().getName()));
            return "ck " + userId;
        });

        CompletableFuture<String> userLoginInfoFuture = CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务, 根据 userId 获取用户最近的登录记录
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s finish userLoginInfoFuture work", Thread.currentThread().getName()));
            return " last login at " + DateUtils.formatTime(System.currentTimeMillis(), Constants.TIMEFORMAT.DATETIME);
        });

        // 注意 BiFunction 接口中的第二个参数为 thenCombine 方法中的第一个参数的返回值
        userLoginInfoFuture.thenCombine(userDetailFutrue, (logInfo, userDetail) -> {
            logger.info(userDetail + logInfo);
            logger.info(String.format("%s finish thenCombine work", Thread.currentThread().getName()));
            return null;
        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));
    }

    @Test
    public void test_allOf() throws Exception {
        // 1. allOf 可以确保参数中所有的 CompletableFuture 对象中的任务都执行完毕后再执行随后的 thenApplyAsync 方法中的异步任务
        CompletableFuture<String> task_1 = CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s task_1 finish work", Thread.currentThread().getName()));
            return String.format("task_1 finish at %s", getNow());
        });

        CompletableFuture<String> task_2 = CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s task_2 finish work", Thread.currentThread().getName()));
            return String.format("task_2 finish at %s", getNow());
        });

        CompletableFuture<String> task_3 = CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s task_3 finish work", Thread.currentThread().getName()));
            return String.format("task_3 finish at %s", getNow());
        });

        CompletableFuture.allOf(task_1, task_2, task_3).thenApplyAsync(t -> {
            try {
                logger.info(task_1.get());
                logger.info(task_2.get());
                logger.info(task_3.get());
            } catch (Exception e) {
                logger.error("test_allOf has error", e);
            }
            return null;
        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));
    }

    @Test
    public void test_anyOf() throws Exception {
        // 1. anyOf 可以确保参数中任意一个 CompletableFuture 对象中的任务执行完毕后就会执行随后的 thenApplyAsync 方法中的异步任务
        CompletableFuture<String> task_1 = CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s task_1 finish work", Thread.currentThread().getName()));
            return String.format("task_1 finish at %s", getNow());
        });

        CompletableFuture<String> task_2 = CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s task_2 finish work", Thread.currentThread().getName()));
            return String.format("task_2 finish at %s", getNow());
        });

        CompletableFuture<String> task_3 = CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 5000));
            logger.info(String.format("%s task_3 finish work", Thread.currentThread().getName()));
            return String.format("task_3 finish at %s", getNow());
        });

        CompletableFuture.anyOf(task_1, task_2, task_3).thenApplyAsync(t -> {
            try {
                logger.info(task_1.isDone() ? task_1.get() : "no finish");
                logger.info(task_2.isDone() ? task_2.get() : "no finish");
                logger.info(task_3.isDone() ? task_3.get() : "no finish");
            } catch (Exception e) {
                logger.error("anyOf has error", e);
            }
            return null;
        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));
    }

    @Test
    public void test_exceptionally() throws Exception {

        // exceptionally 用于在 supplyAsync，thenApply 异步任务链上增加异常处理的功能
        // 一旦发生异常，后续的所有任务都不会执行了

        CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 3000));
            logger.info(String.format("%s supplyAsync finish work", Thread.currentThread().getName()));

            // 模拟异常
            if (true) {
                throw new RuntimeException("thenApply 2 has error");
            }

            return "supplyAsync result";
        }).thenApply(result -> {

            logger.info("last work result = {}", result);
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 3000));
            logger.info(String.format("%s thenApply 1 finish work", Thread.currentThread().getName()));

            return "thenApply 1 result";
        }).thenApply(result -> {

            logger.info("last work result = {}", result);
            // 模拟执行任务
            // WaitUtils.sleep(RandomUtils.nextLong(1000, 3000));
            // 模拟异常
            /*if (true) {
                throw new RuntimeException("thenApply 2 has error");
            }*/

            logger.info(String.format("%s thenApply 2 finish work", Thread.currentThread().getName()));

            return "thenApply 2 result";
        }).exceptionally(ex -> {
            logger.error("出现异常", ex);
            return "出现异常";
        }).thenAccept(result -> {

            logger.info("last work result = {}", result);
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 3000));
            logger.info(String.format("%s thenAccept finish work", Thread.currentThread().getName()));

        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));

    }

    @Test
    public void test_handle() throws Exception {

        // handle 相比 exceptionally 不仅可以处理异常，还可以在异常发生后处理异常并继续处理
        // 1. 如果发生异常，根据异常信息进行重试或者其他处理，然后返回结果，让后续的异步任务能够继续进行下去
        // 2. 如果没有发生异常，异常对象 ex 为 null, 这时候只需要 return 上一步的处理结果

        CompletableFuture.supplyAsync(() -> {
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 3000));
            logger.info(String.format("%s supplyAsync finish work", Thread.currentThread().getName()));

            // 模拟异常
            /*if (true) {
                throw new RuntimeException("thenApply 2 has error");
            }*/

            return "supplyAsync result";
        }).thenApply(result -> {

            logger.info("last work result = {}", result);
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 3000));
            logger.info(String.format("%s thenApply 1 finish work", Thread.currentThread().getName()));

            return "thenApply 1 result";
        }).thenApply(result -> {

            logger.info("last work result = {}", result);
            // 模拟执行任务
            // WaitUtils.sleep(RandomUtils.nextLong(1000, 3000));
            // 模拟异常
            /*if (true) {
                throw new RuntimeException("thenApply 2 has error");
            }*/

            logger.info(String.format("%s thenApply 2 finish work", Thread.currentThread().getName()));

            return "thenApply 2 result";
        }).handle((result, ex) -> {

            if (ex != null) {
                logger.info("last work result = {}", result);
                logger.error("出现异常", ex);
                return "出现异常";
            } else {
                logger.info("last work result = {}", result);
                return result;
            }

        }).thenAccept(result -> {

            logger.info("last work result = {}", result);
            // 模拟执行任务
            WaitUtils.sleep(RandomUtils.nextLong(1000, 3000));
            logger.info(String.format("%s thenAccept finish work", Thread.currentThread().getName()));

        });

        // 这里出于测试的目的，等待任务执行完毕后才推出
        WaitUtils.waitUntil(() -> ForkJoinPool.commonPool().isQuiescent(), 100000l);
        logger.info(String.format("%s test exit", Thread.currentThread().getName()));

    }

    private String getNow() {
        return DateUtils.formatTime(System.currentTimeMillis(), Constants.TIMEFORMAT.DATETIME);
    }

}
```

## 5 参考

- [Java CompletableFuture 详解](https://colobu.com/2016/02/29/Java-CompletableFuture/)
- [Java 8 CompletableFuture 教程](https://juejin.im/post/5adbf8226fb9a07aac240a67#heading-7)