---
title: 在 JavaScript 中执行 Java 代码
title_url: understand-JavaScript-Java-Rhino-usage-practice
date: 2019-10-29
tags: [Java,JavaScript]
categories: [Java,JavaScript]
description: 本文介绍在 JavaScript 环境中如何执行 Java 代码，使用 Rhino JavaScript 引擎。
---

## 1 概述

本文介绍在 JavaScript 环境中如何执行 Java 代码，使用 Rhino JavaScript 引擎。

JavaScript 作为脚本语言非常灵活，不需要编译即可执行，通过 Rhino JavaScript 引擎可以让用户在页面上配置 JavaScript 函数，在函数中调用工具类方法实现相关的功能，从而提供更高的灵活性。

## 2 Maven 依赖

- Rhino JavaScript 引擎的 Maven 依赖如下

```xml
<dependency>
  <groupId>cat.inspiracio</groupId>
  <artifactId>rhino-js-engine</artifactId>
  <version>1.7.10</version>
</dependency>
```

- 下面例子中的 HttpClientUtils 工具类需要引入 xutils Maven 依赖，具体如下

```xml
 <dependency>
    <groupId>com.ckjava</groupId>
    <artifactId>xutils</artifactId>
    <version>1.0.6</version>
</dependency>
```

## 3 使用

具体使用的知识点如下

1. 通过 importClass 导入具体的类
2. 通过 importPackage 导入包下所有的类
3. 通过 `new` 关键字初始化对象
4. 通过 `类名.方法名` 调用静态方法

#### 3.1 调用 HttpClientUtils 中的 get 方法

- ajax.js

```javascript
importClass(Packages.com.ckjava.xutils.HttpClientUtils);
importClass(Packages.java.util.HashMap);

function httpGet() {
    var url = "http://localhost:8011/api/user/20180";

    var headerMap = new HashMap();

    var parameterMap = new HashMap();

    var httpResult = HttpClientUtils.get(url, headerMap, parameterMap);
    if (httpResult != null && httpResult.bodyString != null) {
        var json = JSON.parse(httpResult.bodyString);
        return json.data.displayName;
    } else {
        return null;
    }
}
```

```json
{
  "data": {
    "id": "20180",
    "phid": null,
    "displayName": "柴颅墟渔炕嗜汲痴庐鹰",
    "groupId": null,
    "delFlag": "0",
    "buType": null,
    "phaUrl": null,
    "phaToken": null
  },
  "sign": "success",
  "message": null
}
```

- 测试如下

```java
@Test
public void test_invoke_js_file_ajax() {
    try {
        ScriptEngine engine = new ScriptEngineManager().getEngineByName("rhino");
        engine.eval(new FileReader(TestJSEngine.class.getResource("/ajax.js").getPath()));
        Invocable invocable = (Invocable) engine;

        Object result = invocable.invokeFunction("httpGet");
        System.out.println(result);

    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

- 输出：`柴颅墟渔炕嗜汲痴庐鹰`

#### 3.2 调用 HttpClientUtils 中的 get 方法，并传入参数

- ajax_2.js

```javascript
importClass(Packages.com.ckjava.xutils.HttpClientUtils);
importPackage(Packages.java.util);

function httpGet(headerMap, parameterMap) {
    var url = "http://localhost:8011/api/user/20180";

    var httpResult = HttpClientUtils.get(url, headerMap, parameterMap);
    if (httpResult != null && httpResult.bodyString != null) {
        var json = JSON.parse(httpResult.bodyString);
        return json.data.displayName;
    } else {
        return null;
    }
}
```

- java 测试如下

```java
@Test
public void test_invoke_js_file_ajax_2() {
    try {
        ScriptEngine engine = new ScriptEngineManager().getEngineByName("rhino");
        engine.eval(new FileReader(TestJSEngine.class.getResource("/ajax_2.js").getPath()));
        Invocable invocable = (Invocable) engine;

        Map<String, String> headers = new HashMap<>();
        headers.put("content-type", "application/json");
        Object result = invocable.invokeFunction("httpGet", headers, null);

        System.out.println(result);

    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

- 输出 `柴颅墟渔炕嗜汲痴庐鹰`

#### 3.3 调用 HttpClientUtils 中的 post 方法

- ajax_3.js 如下

```javascript
function httpPost() {
    importClass(Packages.com.ckjava.xutils.HttpClientUtils);
    importClass(Packages.com.alibaba.fastjson.JSONObject);
    importClass(Packages.test.service.RandomData);
    importPackage(Packages.java.util);

    var randomData = new RandomData();
    var url = "http://localhost:8011/api/user";

    var headerMap = new java.util.HashMap();
    headerMap.put("Content-type", "application/json");

    var bodyMap = new java.util.HashMap();
    bodyMap.put("buType", "test");
    bodyMap.put("delFlag", "0");
    bodyMap.put("displayName", randomData.getRandomLengthChinese(1, 10));

    var httpResult = HttpClientUtils.post(url, headerMap, null, JSONObject.toJSONString(bodyMap));
    if (httpResult != null && httpResult.bodyString != null) {
        var json = JSON.parse(httpResult.bodyString);
        return json.data;
    } else {
        return null;
    }
}
```

- 测试如下

```java
@Test
public void test_invoke_js_file_ajax_3() {
    try {
        ScriptEngine engine = new ScriptEngineManager().getEngineByName("rhino");
        engine.eval(new FileReader(TestJSEngine.class.getResource("/ajax_3.js").getPath()));
        Invocable invocable = (Invocable) engine;

        Object result = invocable.invokeFunction("httpPost");
        System.out.println(result);

    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

#### 3.4 调用 new 关键字生成的对象的方法

- test.service.RandomData 类如下

```java
package test.service;

import java.io.UnsupportedEncodingException;
import java.util.Random;

public class RandomData {

    /**
     * 生成一个中文
     *
     * @return
     */
    public String getChinese() {
        String str = null;
        int highPos, lowPos;
        Random random = new Random();
        highPos = (176 + Math.abs(random.nextInt(39)));
        lowPos = 161 + Math.abs(random.nextInt(93));
        byte[] b = new byte[2];
        b[0] = (new Integer(highPos)).byteValue();
        b[1] = (new Integer(lowPos)).byteValue();
        try {
            str = new String(b, "GB2312");
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return str;
    }

    /**
     * 生成一定长度范围的中文
     *
     * @param start
     * @param end
     * @return
     */
    public String getRandomLengthChinese(int start, int end) {
        String str = "";
        int length = new Random().nextInt(end + 1);
        if (length < start) {
            str = getRandomLengthChinese(start, end);
        } else {
            for (int i = 0; i < length; i++) {
                str = str + getChinese();
            }
        }
        return str;
    }
}

```

- ajax_4.js 定义如下

```javascript
function getRandomLengthChinese() {
    importClass(Packages.test.service.RandomData);

    var randomData = new RandomData();
    return randomData.getRandomLengthChinese(1, 100);
}
```

- 测试如下

```java
@Test
public void test_invoke_js_file_ajax_4() {
    try {
        ScriptEngine engine = new ScriptEngineManager().getEngineByName("rhino");
        engine.eval(new FileReader(TestJSEngine.class.getResource("/ajax_4.js").getPath()));
        Invocable invocable = (Invocable) engine;

        Object result = invocable.invokeFunction("getRandomLengthChinese");
        System.out.println(result);

    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

- 输出：`晒妥蹋苦宴初滔粟溉和惦哲兴拌簇豁峡谬琅辟药硅延混背联耗硒厢沦社胯剑炼工览蝇门臻怪僵锋缕美肾聊版锤趁巫操璃瘟嫂份歉奖憾冻醛买港许镀`

## 4 拓展

- [在 Java 中执行 JavaScript 脚本](http://ckjava.com/2019/10/20/understand-Java-JavaScript-Nashorn-Rhino-usage-practice/)

## 5 参考

- [Rhino Scripting_Java](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/Rhino/Scripting_Java)