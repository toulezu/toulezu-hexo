---
title: 关于Java多线程在提升程序性能上的一些实践
title_url: Java-Thread-Runnable-Executor-Practice
date: 2016-08-30
tags: [Java,Thread,Runnable,Executor]
categories: [Java,并发]
description: 关于Java多线程在提升程序性能上的一些实践
---

## 需要使用多个线程的背景以及约束

- 多个任务并行，不分先后

- 对资源没有争抢

- 需要在所有任务都执行完毕后再返回给调用者

在以上条件下无需过多考虑同步问题，能使用的线程数只取决于机器的性能。

## 使用串行执行的方式带来的性能问题

程序的执行逻辑是从上到下，从左到右。长期的编程习惯使我们想当然的在日常开发中使用串行的开发思维来编写程序，使本来可以通过多线程并行的方式来执行任务，由于习惯还是通过单线程串行的方式。具体如下。
```java
// 假设有10个任务，每个任务花费的时间如下
private long[] spendTime = new long[] { 1000, 2000, 3000, 5000, 500, 100, 10, 9000, 1000, 6000 };

/**
 * 在单线程的情况下
 */
@SuppressWarnings("static-access")
@Test
public void TestWithoutExecuteService() {
	long begin = System.currentTimeMillis();
	for (long l : spendTime) {
		try {
			Thread.currentThread().sleep(l);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	System.out.println("total spend : " + (System.currentTimeMillis() - begin));
}
```

## 通过 Thread 和 Runnable 来实现

上面通过串行的方式执行任务，所花时间是所有任务执行时间之和。如果通过多个线程并行执行任务，那么在确保所有任务执行完毕，所花时间取决于耗时最长的那个任务。
通过 Thread 和 Runnable 来实现需要维持一个变量来确保所有的任务都执行完毕了，引入同步变量增加了程序的复杂度，具体实现如下。
```java
/**
 * 使用一般的多线程来完成并行任务，也就是 Thread,Runnable
 */
@Test
public void TestWithMultiThread() {
	long begin = System.currentTimeMillis();
	// 通过一个同步的Map来确保所有的任务都执行完毕
	Map<String, String> result = Collections.synchronizedMap(new HashMap<String, String>());

	List<Thread> taskList = new ArrayList<Thread>();
	for (long l : spendTime) {
		Thread taskThread = new Thread(new TaskThread2(l, result));
		taskList.add(taskThread);
		taskThread.start();
	}
	while (true) { // 这部分代码可以确保所有的线程都执行完毕了
		if (result.size() == taskList.size()) {
			break;
		}
	}
	for (Iterator<String> it = result.keySet().iterator(); it.hasNext();) {
		String key = it.next();
		System.out.println(key + result.get(key));
	}
	System.out.println("total spend : " + (System.currentTimeMillis() - begin));
}

/**
 * 使用Runnable来实现线程
 * 
 * @author ck
 *
 */
private class TaskThread2 implements Runnable {

	private long processTime;
	private Map<String, String> result;

	public TaskThread2(long processTime, Map<String, String> result) {
		this.processTime = processTime;
		this.result = result;
	}

	@SuppressWarnings("static-access")
	@Override
	public void run() {
		try {
			Thread.currentThread().sleep(processTime);
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
		result.put(Thread.currentThread().getName(), ": SUCCESS, spend: " + processTime);
	}

}
```

## 通过ExecutorService来实现

在传统的方法中需要引入同步的变量来确保所有的任务都执行完毕，增加了程序的复杂程度，因为线程在执行完毕后无法通知调用者是否执行完毕，缺少通知机制。如果通过ExecutorService来实现，那么在提交任务后，只需要调用invokeAll方法，调用者线程将会阻塞，直到所有的任务都执行完毕，调用者线程才能继续向下执行，大大简化了程度复杂度。具体如下。
```java
/**
 * 在使用 ExecuteService 的情况下，通过invokeAll确保所有的线程都执行完毕
 */
@Test
public void TestWithExecuteService() {
	long begin = System.currentTimeMillis();

	ExecutorService executorService = Executors.newCachedThreadPool();

	List<TaskThread> taskList = new ArrayList<TaskThread>();
	for (long l : spendTime) {
		taskList.add(new TaskThread(l));
	}
	try {
		List<Future<String>> taskResult = executorService.invokeAll(taskList); // 可以确保所有的线程都执行完成
		if (taskResult != null) {
			for (Future<String> future : taskResult) {
				System.out.println(future.get()); // 获取线程的执行结果
			}
		}
	} catch (Exception e) {
		e.printStackTrace();
	} finally {
		executorService.shutdown();
	}

	System.out.println("total spend : " + (System.currentTimeMillis() - begin));
}
```

## 总结

`java.util.concurrent` 包下面还有很多有意思的类和接口方便多线程的开发，以后还会继续探索，以具体的例子和对比来显示使用和不使用这些类和接口带来的好处。关于Java多线程方面的知识，最近在看一本书，强烈推荐=>《Java并发编程实践》。
关于本页面涉及到的所有的代码点击[这里](https://github.com/toulezu/play/tree/master/TestThread01)。

