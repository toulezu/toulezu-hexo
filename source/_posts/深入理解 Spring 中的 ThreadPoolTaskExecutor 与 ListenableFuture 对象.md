---
title: 深入理解 Spring 中的 ThreadPoolTaskExecutor 与 ListenableFuture 对象
title_url: understand-Spring-ThreadPoolTaskExecutor-ListenableFuture
date: 2019-08-22
tags: [Spring]
categories: Spring
description: 本文详细分析 Spring 中的 ThreadPoolTaskExecutor 与 ListenableFutureTask 对象；并且比较 ThreadPoolTaskExecutor 和 ThreadPoolExecutor 之间的区别；介绍 ThreadPoolTaskExecutor 的基本使用；比较 ListenableFuture 与 Future；深入解析 ListenableFuture 对象
---

## 1 概述

1. 本文详细分析 Spring 中的 ThreadPoolTaskExecutor 与 ListenableFutureTask 对象；并且比较 ThreadPoolTaskExecutor 和 ThreadPoolExecutor 之间的区别。
2. 介绍 ThreadPoolTaskExecutor 的基本使用
3. 比较 ListenableFuture 与 Future
4. 深入解析 ListenableFuture 对象

## 2 ThreadPoolTaskExecutor 对比 ThreadPoolExecutor

1. ThreadPoolExecutor 是 JDK 自带，ThreadPoolTaskExecutor 是 Spring 在 ThreadPoolExecutor 的基础上进行了一层封装。

- java.util.concurrent.ThreadPoolExecutor
- org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor

2. 相比 ThreadPoolExecutor，ThreadPoolTaskExecutor 增加了 submitListenable 方法，该方法返回 ListenableFuture 接口对象，该接口完全抄袭了 google 的 guava。
3. ListenableFuture 接口对象，增加了线程执行完毕后成功和失败的回调方法。从而避免了 Future 需要以阻塞的方式调用 get，然后再执行成功和失败的方法。

- ThreadPoolTaskExecutor 中具体的初始化线程池方法如下

```java
@Override
protected ExecutorService initializeExecutor(
		ThreadFactory threadFactory, RejectedExecutionHandler rejectedExecutionHandler) {

	BlockingQueue<Runnable> queue = createQueue(this.queueCapacity);

	ThreadPoolExecutor executor;
	if (this.taskDecorator != null) {
		executor = new ThreadPoolExecutor(
				this.corePoolSize, this.maxPoolSize, this.keepAliveSeconds, TimeUnit.SECONDS,
				queue, threadFactory, rejectedExecutionHandler) {
			@Override
			public void execute(Runnable command) {
				super.execute(taskDecorator.decorate(command));
			}
		};
	}
	else {
		executor = new ThreadPoolExecutor(
				this.corePoolSize, this.maxPoolSize, this.keepAliveSeconds, TimeUnit.SECONDS,
				queue, threadFactory, rejectedExecutionHandler);

	}

	if (this.allowCoreThreadTimeOut) {
		executor.allowCoreThreadTimeOut(true);
	}

	this.threadPoolExecutor = executor;
	return executor;
}
```

## 3 如何使用 ThreadPoolTaskExecutor

具体使用如下

```java
public static void main(String[] args) throws Exception {
    ThreadPoolTaskExecutor executorService = new ThreadPoolTaskExecutor();
    executorService.setCorePoolSize(2);
    executorService.setMaxPoolSize(2);
    executorService.setKeepAliveSeconds(60);
    executorService.setQueueCapacity(Integer.MAX_VALUE);
    executorService.initialize();

    executorService.submitListenable(() -> {

        // 休息 5 秒，模拟工作的情况
        TimeUnit.SECONDS.sleep(5);
        // 通过抛出 RuntimeException 异常来模拟异常
        //throw new RuntimeException("出现异常");
        return true;

    }).addCallback(data -> logger.info("success,result = {}", data), ex -> logger.info("**异常信息**：{}", ExceptionUtils.getExceptionMsg(ex)));
}
```

1. 通过 new 获取 ThreadPoolTaskExecutor 对象
2. 通过 setCorePoolSize 等方法可以配置线程池相关参数
3. 最重要的是通过 **initialize** 方法完成线程池初始化，否则抛出：`java.lang.IllegalStateException: ThreadPoolTaskExecutor not initialized` 异常
4. 调用 submitListenable 方法返回 ListenableFuture 对象
5. 调用 ListenableFuture 对象的 addCallback 方法增加 成功和失败的回调处理
6. 其中成功的回调对象实现了 SuccessCallback 接口，其中的方法为：`void onSuccess(T result)`
7. 其中失败的回调对象实现了 FailureCallback 接口，其中的方法为：`void onFailure(Throwable ex)`

## 4 比较 ListenableFuture 与 Future

- org.springframework.util.concurrent.ListenableFuture
- java.util.concurrent.Future

ListenableFuture 接口继承 Future 接口，并增加了如下两个方法

```java
void addCallback(ListenableFutureCallback<? super T> callback);

void addCallback(SuccessCallback<? super T> successCallback, FailureCallback failureCallback);
```

## 5 深入解析 ListenableFuture 对象

首先看看下面这张图

![ListenableFutureTask 类图](data:image/png;base64,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)

1. ThreadPoolTaskExecutor 的 submitListenable 方法，传入一个 Runnable 或者 Callable 对象，实际上 Runnable 或者 Callable 对象被包装到 ListenableFutureTask 对象中，然后提交到 ExecutorService 对象，最后返回的是 ListenableFutureTask 对象，具体如下

```java
@Override
public <T> ListenableFuture<T> submitListenable(Callable<T> task) {
	ExecutorService executor = getThreadPoolExecutor();
	try {
		ListenableFutureTask<T> future = new ListenableFutureTask<T>(task);
		executor.execute(future);
		return future;
	}
	catch (RejectedExecutionException ex) {
		throw new TaskRejectedException("Executor [" + executor + "] did not accept task: " + task, ex);
	}
}
```

2. 在 ListenableFutureTask 中可以发现其继承了 FutureTask 对象并实现了 ListenableFuture 对象， 其中 FutureTask 对象中的 run 是最终线程执行的方法，具体如下

```java
public void run() {
    if (state != NEW ||
        !UNSAFE.compareAndSwapObject(this, runnerOffset,
                                     null, Thread.currentThread()))
        return;
    try {
        Callable<V> c = callable;
        if (c != null && state == NEW) {
            V result;
            boolean ran;
            try {
                result = c.call();
                ran = true;
            } catch (Throwable ex) {
                result = null;
                ran = false;
                setException(ex);
            }
            if (ran)
                set(result);
        }
    } finally {
        // runner must be non-null until state is settled to
        // prevent concurrent calls to run()
        runner = null;
        // state must be re-read after nulling runner to prevent
        // leaked interrupts
        int s = state;
        if (s >= INTERRUPTING)
            handlePossibleCancellationInterrupt(s);
    }
}
```

3. 上面 run 方法中的 set 方法将线程的执行结果通知出去，在 set 方法中可以发现其调用了 finishCompletion 方法，finishCompletion 方法会一直循环判断线程池中的队列的任务是否执行完毕，一旦执行完毕就会调用 done 方法
4. ListenableFutureTask 重写了 done 方法, 在正常执行完毕的情况下通过 `this.callbacks.success(result)` 调用成功回调函数，在出现 InterruptedException 异常的情况下既不会调用 成功的回调，也不会调用失败的回调，其他类型的异常出现的时候才会通过 `this.callbacks.failure(cause)` 调用失败回调函数，ListenableFutureTask 中的 done 方法具体如下

```java
@Override
protected void done() {
	Throwable cause;
	try {
		T result = get();
		this.callbacks.success(result);
		return;
	}
	catch (InterruptedException ex) {
		Thread.currentThread().interrupt();
		return;
	}
	catch (ExecutionException ex) {
		cause = ex.getCause();
		if (cause == null) {
			cause = ex;
		}
	}
	catch (Throwable ex) {
		cause = ex;
	}
	this.callbacks.failure(cause);
}
```

- 从上面的流程分析中，可以发现：因为 FutureTask 中重写了 run 方法，所以才实现了线程执行完毕后可以执行回调方法，其中使用了模板方法设计模式。
- 模板方法设计模式的主要特点在于：在接口中定义方法，在抽象类中实现方法，并定义抽象方法，实现的方法中又调用抽象方法，最终的子类中重写抽象方法。
- Runnable 和 ListenableFuture 是接口， FutureTask 是抽象类，ListenableFutureTask 是最终的子类

## 6 ListenableFuture 的好处以及 Future 带来的阻塞问题

1. ListenableFuture 相比 Future 是不需要知道 执行结果的情况下就可以将 成功或者失败的业务代码 通过回调的方式 预埋，带来的好处就是异步，不需要阻塞当前线程，从而可以提高系统的吞吐量
2. Future 需要通过 get() 方法阻塞当前线程，在获取线程的执行结果后再根据执行结果编写相关的业务代码