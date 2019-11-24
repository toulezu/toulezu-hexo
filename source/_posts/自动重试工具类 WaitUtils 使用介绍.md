---
title: 自动重试工具类 WaitUtils 使用介绍
title_url: WaitUtils-xutils-Java-usage-practice
date: 2019-10-29
tags: [Java,xutils]
categories: [Java,xutils]
description: 在日常开发中经常会遇到通过 http 请求获取接口数据，由于网络问题导致请求失败，这时需要重试机制在请求失败后自动重试。
---

## 1 概述 

在日常开发中经常会遇到通过 http 请求获取接口数据，由于网络问题导致请求失败，这时需要重试机制在请求失败后自动重试。

比如：给用户发送确认邮件失败，需要自动重试；发送短信失败，需要自动重试等场景。

## 2 Maven 依赖

```xml
<dependency>
    <groupId>com.ckjava</groupId>
    <artifactId>xutils</artifactId>
    <version>1.0.6</version>
</dependency>
```

- com.ckjava.xutils.WaitUtils

## 3 方法介绍

等待工具类，以 阻塞/非阻塞的方式 通过在 while 中的循环次数或者超时时间来控制程序的执行。

1. waitThen(Predicate, long, Runnable, Runnable): 当 Predicate 对象在超时前满足 某个条件 的时候才会执行 successRunnable 对象的 run 方法, 否则执行 failRunnable 对象的 run 方法
2. waitThenAsync(Predicate, long, Runnable, Runnable, ExecutorService): 以异步的方式， 当 Predicate 对象在超时前满足 某个条件 的时候才会执行 successRunnable 对象的 run 方法, 否则执行 failRunnable 对象的 run 方法
3. waitThen(Predicate, int, Runnable, Runnable): 当 Predicate 对象在 重试次数大于 0 前 的时候才会执行 successRunnable 对象的 run 方法，否则执行 failRunnable 对象的 run 方法
4. waitThenAsync(Predicate, int, Runnable, Runnable, ExecutorService): 以非阻塞的方式，当 Predicate 对象在 重试次数大于 0 前 的时候才会执行 successRunnable 对象的 run 方法，否则执行 failRunnable 对象的 run 方法
5. waitUntil(Predicate, long): Predicate 对象必须在 超时前 满足某个条件 否则退出阻塞
6. waitUntilAsync(Predicate, long, ExecutorService): 以异步的方式， Predicate 对象必须在 超时前 满足某个条件 否则退出阻塞
7. waitUntil(Predicate, int): Predicate 对象必须在 重试次数大于 0 前 满足某个条件 否则退出阻塞
8. waitUntilAsync(Predicate, int, ExecutorService): 以非阻塞的方式, Predicate 对象必须在 重试次数大于 0 前 满足某个条件 否则退出阻塞

## 测试

- 在 Predicate 对象中自动生成数字，满足条件后再返回 true 并退出 while 循环，针对 WaitUtils 工具类中的 8 个方法测试如下

```java
import com.ckjava.synchronizeds.appCache.WaitUtils;
import org.apache.commons.lang3.RandomUtils;
import org.junit.Test;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicReference;

public class TestWaitUtils extends WaitUtils {

    /**
     * 1. waitThen(Predicate, long, Runnable, Runnable)
     */
    @Test
    public void test_waitThen_timeOut() {

        // 重试 3 秒钟，直到找到 大于 5 的数字，然后打印数据
        AtomicReference<Integer> atomicReference = new AtomicReference<>();
        waitThen(() -> {

            int data = RandomUtils.nextInt(0, 8);
            System.out.println(data);
            atomicReference.set(data);
            return data > 5;

        }, 3000l, () -> {
            System.out.println("data is " + atomicReference.get());
        }, () -> {
            System.out.println("数据找不到");
        });
    }

    /**
     * 2. aitThen(Predicate, long, Runnable, Runnable, ExecutorService)
     */
    @Test
    public void test_waitThen_timeOut_async() {
        ExecutorService executorService = Executors.newCachedThreadPool();

        // 重试 3 秒钟，直到找到 大于 5 的数字，然后打印数据
        AtomicReference<Integer> atomicReference = new AtomicReference<>();
        waitThenAsync(() -> {

            int data = RandomUtils.nextInt(0, 8);
            System.out.println(data);
            atomicReference.set(data);
            return data > 5;

        }, 3000l, () -> {
            System.out.println("data is " + atomicReference.get());
        }, () -> {
            System.out.println("数据找不到");
        }, executorService);

        // 这里出于测试的目的将线程池关闭，并等待任务执行完毕后才推出
        executorService.shutdown();
        waitUntil(() -> executorService.isTerminated(), 100000l);
    }

    /**
     * 3. waitThen(Predicate, int, Runnable, Runnable)
     */
    @Test
    public void test_waitThen_times() {

        // 重试 3 次，直到找到 大于 5 的数字，然后打印数据
        AtomicReference<Integer> atomicReference = new AtomicReference<>();
        waitThen(() -> {

            int data = RandomUtils.nextInt(0, 8);
            System.out.println(data);
            atomicReference.set(data);
            return data > 5;

        }, 3, () -> {
            System.out.println("data is " + atomicReference.get());
        }, () -> {
            System.out.println("数据找不到");
        });
    }

    /**
     * 4. waitThenAsync(Predicate, int, Runnable, Runnable, ExecutorService)
     */
    @Test
    public void test_waitThen_times_async() {
        ExecutorService executorService = Executors.newCachedThreadPool();

        // 以非阻塞的方式重试 3 秒钟，直到找到 大于 5 的数字，然后打印数据
        AtomicReference<Integer> atomicReference = new AtomicReference<>();
        waitThenAsync(() -> {

            int data = RandomUtils.nextInt(0, 8);
            System.out.println(String.format("data is %s", data));
            atomicReference.set(data);
            return data > 5;

        }, 3, () -> {
            System.out.println("data is " + atomicReference.get());
        }, () -> {
            System.out.println("数据找不到");
        }, executorService);

        // 这里出于测试的目的将线程池关闭，并等待任务执行完毕后才推出
        executorService.shutdown();
        waitUntil(() -> executorService.isTerminated(), 100000l);
    }

    /**
     * 5. waitUntil(Predicate, long)
     */
    @Test
    public void test_waitUntil_timeOut() {

        // 重试 3 秒钟，直到找到 大于 5 的数字
        waitUntil(() -> {

            int data = RandomUtils.nextInt(0, 8);
            System.out.println(data);
            return data > 5;

        },  3000l);
    }


    /**
     * 6. waitUntilAsync(Predicate, long, ExecutorService)
     */
    @Test
    public void test_waitUntil_timeout_async() {
        ExecutorService executorService = Executors.newCachedThreadPool();

        // 以异步的方式， 重试3次，直到找到 大于 5 的数字
        waitUntilAsync(() -> {

            int data = RandomUtils.nextInt(0, 10);
            System.out.println(String.format("data is %s", data));
            return data > 5;

        }, 3000l, executorService);

        // 这里出于测试的目的将线程池关闭，并等待任务执行完毕后才推出
        executorService.shutdown();
        waitUntil(() -> executorService.isTerminated(), 100000l);
    }

    /**
     * 7. waitUntil(Predicate, int)
     */
    @Test
    public void test_waitUntil_times() {

        // 重试3次，直到找到 大于 5 的数字
        waitUntil(() -> {

            int data = RandomUtils.nextInt(0, 10);
            System.out.println(data);
            return data > 5;

        },  3);
    }

    /**
     * 8. waitUntilAsync(Predicate, int, ExecutorService)
     */
    @Test
    public void test_waitUntil_times_async() {
        ExecutorService executorService = Executors.newCachedThreadPool();

        // 以异步的方式， 重试3次，直到找到 大于 5 的数字
        waitUntilAsync(() -> {

            int data = RandomUtils.nextInt(0, 10);
            System.out.println(String.format("data is %s", data));
            return data > 5;

        }, 3, executorService);

        // 这里出于测试的目的将线程池关闭，并等待任务执行完毕后才推出
        executorService.shutdown();
        waitUntil(() -> executorService.isTerminated(), 100000l);
    }
}
```

## 4 使用场景

#### 1. waitUntil(Predicate, int) 方法：通过 api 获取数据，如果失败，最多重试 3 次；利用 AtomicReference 对象存储方法的执行结果

- 以阻塞的方式从 api 获取数据，如果 出错 或者 不能获取到数据 重试 3 次

```java
AtomicReference<JSONObject> atomicReference = new AtomicReference<>();
WaitUtils.waitUntil(() -> getAppData(atomicReference), 3);

if (atomicReference.get() != null) {
    JSONArray dataArr = atomicReference.get().getJSONArray("data");
    for (int i = 0, c = dataArr.size(); i < c; i++) {
        JSONObject data = dataArr.getJSONObject(i);
        String appId = data.getString("appId");
        add(appId, data);
    }
}
```

- 封装 getAppData 方法，如果成功将数据存储到 AtomicReference 对象中并返回，具体如下

```java
private boolean getAppData(AtomicReference<JSONObject> atomicReference) {
    String url = "http://localhost:8011/api/user";
    Map<String, String> headers = new HashMap<>();
    headers.put("Content-Type", "application/json");

    JSONObject jsonBody = new JSONObject();
    jsonBody.put("id", "1");
    jsonBody.put("appId", "ckjava");

    try {
        HttpResult result = HttpClientUtils.post(url, headers, null, jsonBody.toJSONString());
        JSONObject jsonObject = JSONObject.parseObject(result.getBodyString());
        if (jsonObject != null) {
            atomicReference.set(jsonObject);
            return true;
        } else {
            logger.warn("响应内容为空");
            return false;
        }
    } catch (Exception e) {
        logger.error(this.getClass().getName().concat(".getAppData has error"), e);
        return false;
    }

}
```

#### 2. waitUntilAsync(Predicate, int, ExecutorService) 方法：发送邮件，如果失败，在一个独立的线程内自动重试 10 次

- 新增缓存类型的线程池如下

```java
@Bean("commonThreadService")
public ExecutorService commonThreadService() {
	return Executors.newCachedThreadPool(new ThreadFactory() {

		private final SecurityManager s = System.getSecurityManager();
		private final AtomicInteger poolNumber = new AtomicInteger(1);
		private final ThreadGroup group = (s != null) ? s.getThreadGroup() : Thread.currentThread().getThreadGroup();
		private final AtomicInteger threadNumber = new AtomicInteger(1);
		private final String namePrefix = "commonThreadService-pool-" + poolNumber.getAndIncrement() + "-thread-";

		public Thread newThread(Runnable r) {
			Thread t = new Thread(group, r,namePrefix + threadNumber.getAndIncrement(), 0);
			if (t.isDaemon())
				t.setDaemon(false);
			if (t.getPriority() != Thread.NORM_PRIORITY)
				t.setPriority(Thread.NORM_PRIORITY);
			return t;
		}
	});
}
```

- 通过 waitUntilAsync 方法，并且使用 commonThreadService 线程池，并封装 doSendMail 方法作为 Predicate 对象的实现，doSendMail 将会以异步的方式执行，如果出错将会重试 10 次。

```java
@Qualifier("commonThreadService")
@Autowired
private ExecutorService executorService;

/**
 * 邮件发送, 默认重试 5 次
 * 
 * @param mailSender 发送人
 * @param mailReceiver 收件人 用 ; 分隔多个
 * @param mailCc 抄送 用 ; 分隔多个
 * @param subject 主题
 * @param content 内容 
 * @return true:成功 false:失败
 */
public void sendEmail(String mailSender, String mailReceiver, String mailCc, String mailBcc, String subject, String content) {
	WaitUtils.waitUntilAsync(() -> doSendMail(mailSender, mailReceiver, mailCc, mailBcc, subject, content), 10, executorService);
}

private boolean doSendMail(String mailSender, String mailReceiver, String mailCc, String mailBcc, String subject, String content) {
	Map<String, String> headers = new HashMap<>();
	headers.put("Content-Type", "application/json;charset=utf-8");

	JSONObject body = new JSONObject();
	body.put("subject", subject);
	body.put("content", content);
	body.put("mailSender", mailSender);
	body.put("mailSenderName", mailSender);
	body.put("mailReceiver", mailReceiver);
	body.put("mailCc", mailCc);
	body.put("mailBcc", mailBcc);

	try {
		HttpResult result = HttpClientUtils.post(MAILAPI.SOAMAIL_PRD.concat("/mail"), headers, null, body.toJSONString());
		if (StringUtils.isNotBlank(result.getBodyString())) {
			JSONObject resultObj = JSONObject.parseObject(result.getBodyString());
			boolean flag = resultObj.getBoolean("data");
			logger.info("mail send result:{}", flag);
			if (!flag) {
				logger.error(String.format("sendEmail error, subject:%s, content:%s", subject, content));
			}
			return flag;
		} else {
			return false;
		}
	} catch (Exception e) {
		logger.error(this.getClass().getName().concat(".sendEmail has error"), e);
		return false;
	}
}
```