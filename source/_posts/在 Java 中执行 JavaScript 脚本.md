---
title: 在 Java 中执行 JavaScript 脚本
title_url: understand-Java-JavaScript-Nashorn-Rhino-usage-practice
date: 2019-10-20
tags: [Java,JavaScript]
categories: [Java,JavaScript]
description: 本文介绍在 Java 环境中执行 JavaScript 脚本的简单使用，具体内容：1. Java 8 中的内置 Nashorn Javascript 引擎介绍；2. Rhino JavaScript 引擎介绍以及对 XML 的处理介绍
---

## 1 概述

本文介绍在 Java 环境中执行 JavaScript 脚本的简单使用，具体包含以下内容

1. Java 8 中的内置 Nashorn Javascript 引擎介绍
2. Rhino JavaScript 引擎介绍以及对 XML 的处理介绍

## 2 Java 8 中的内置 Nashorn Javascript 引擎介绍

Nashorn 是 Java 8 中内置的 JavaScript 引擎，无需加入任何依赖。

Nashorn 基本使用步骤如下

1. new 出 ScriptEngineManager 对象
2. 通过 ScriptEngineManager 对象中的 getEngineByName 方法获取指定的 JavaScript 引擎，返回 ScriptEngine 对象
3. Java 8 中的默认的 Javascript 引擎包括：`[nashorn, Nashorn, js, JS, JavaScript, javascript, ECMAScript, ecmascript]`
4. 通过 ScriptEngine 对象的 `eval` 方法来执行 JavaScript 脚本。

#### 2.1 通过 PrintWriter 对象获取脚本中的 print 输出

Javascript 脚本中没有函数，没有返回值，通过 print 输出内容，这时需要通过 PrintWriter 获取读取脚本中的 print 输出，具体如下

```java
@Test
    public void test_nashorn() {
        try {
            ScriptEngine engine = new ScriptEngineManager().getEngineByName("Nashorn");
            ScriptContext scriptContext = engine.getContext();
            StringWriter stringWriter = new StringWriter();
            PrintWriter printWriter = new PrintWriter(stringWriter);
            scriptContext.setWriter(printWriter);

            String jsString = "var obj=JSON.parse('{\\\"data\\\":\\\"7155\\\",\\\"sign\\\":\\\"success\\\",\\\"message\\\":null}');print(obj.sign==\"success\");";

            stringWriter = new StringWriter();
            printWriter = new PrintWriter(stringWriter);
            scriptContext.setWriter(printWriter);
            engine.eval(jsString);
            System.out.println(String.format("1 result = %s",stringWriter.toString()));

            jsString = "var obj=JSON.parse('{\\\"data\\\":\\\"7157\\\",\\\"sign\\\":\\\"success\\\",\\\"message\\\":null}');print((function getData() {  return obj.data;})())";
            stringWriter = new StringWriter();
            printWriter = new PrintWriter(stringWriter);
            scriptContext.setWriter(printWriter);
            engine.eval(jsString);
            System.out.println(String.format("2 result = %s",stringWriter.toString()));

            jsString = "var obj=JSON.parse('{\\\"data\\\":\\\"7157\\\",\\\"sign\\\":\\\"success\\\",\\\"message\\\":null}');print((function getData() {  return obj.data;})())";
            stringWriter = new StringWriter();
            printWriter = new PrintWriter(stringWriter);
            scriptContext.setWriter(printWriter);
            engine.eval(jsString);
            System.out.println(String.format("3 result = %s",stringWriter.toString()));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
```

#### 2.2 获取匿名函数的返回值

Javascript 脚本是一个匿名函数并且有返回值，通过 `eval` 函数可以直接

```java
@Test
public void test_js_function_return() {
    try {
        ScriptEngine engine = new ScriptEngineManager().getEngineByName("Nashorn");
        String jsFunction = "(function(){var obj=JSON.parse('{\\\"data\\\":\\\"7155\\\",\\\"sign\\\":\\\"success\\\",\\\"message\\\":null}');return obj.sign==\"success\"})();";
        Boolean result = (Boolean) engine.eval(jsFunction);
        System.out.println(result);
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

#### 2.3 调用 Javascript 脚本中指定的函数

Javascript 脚本中有变量，有多个函数，具体如下

```java
@Test
public void test_invoke_js_function() {
    try {
        ScriptEngine engine = new ScriptEngineManager().getEngineByName("Nashorn");
        /*
        var obj = JSON.parse('{\"data\":\"7155\",\"sign\":\"success\",\"message\":null}');
        function checkSign() {
            return obj.sign == 'success'
        }
        function getData() {
            return obj.data
        }
        function calculate(a, b) {
            return a + b
        }
         */
        String jsFunction = "var obj=JSON.parse('{\\\"data\\\":\\\"7155\\\",\\\"sign\\\":\\\"success\\\",\\\"message\\\":null}');function checkSign(){return obj.sign=='success'}function getData(){return obj.data}function calculate(a,b){return a+b}";

        engine.eval(jsFunction);
        Invocable invocable = (Invocable) engine;

        Object result = invocable.invokeFunction("checkSign", null);
        System.out.println(result);

        result = invocable.invokeFunction("getData", null);
        System.out.println(result);

        result = invocable.invokeFunction("calculate", 2, 5);
        System.out.println(result);
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

- 输出如下

```
true
7155
7.0
```

#### 2.4 读取 Javascript 文件并执行

这种情况是读取 Javascript 文件，并执行，具体如下

- src/test/resources/test.js

```java
@Test
public void test_invoke_js_file() {
    try {
        ScriptEngine engine = new ScriptEngineManager().getEngineByName("Nashorn");
        engine.eval(new FileReader(TestJSEngine.class.getResource("/test.js").getPath()));
        Invocable invocable = (Invocable) engine;

        Object result = invocable.invokeFunction("checkSign", null);
        System.out.println(result);

        result = invocable.invokeFunction("getData", null);
        System.out.println(result);

        result = invocable.invokeFunction("calculate", 2, 5);
        System.out.println(result);
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

文件内容和上面一样。

## 3 Rhino JavaScript 引擎介绍

默认的 Nashorn 引擎是无法解析 xml 的，像 DOMParser 这样的对象是浏览器内置的组件。

这里可以通过 Maven 依赖 Rhino 引擎来处理 xml。

- Rhino Maven 依赖如下

```xml
<dependency>
  <groupId>cat.inspiracio</groupId>
  <artifactId>rhino-js-engine</artifactId>
  <version>1.7.10</version>
</dependency>
```

使用的步骤和其他 JavaScript 引擎一样，引擎的名称为 `Rhino`.

#### 3.1 Rhino 对 xml 的解析

这里通过读取文件的方式来加载和解析 JavaScript 脚本，脚本中是对一段 xml 的解析的过程。

- src/test/resources/xml.js 文件内容如下

```
print("----------------------------------------");
var e = new XML('<employees> <employee id="1"><name>Joe</name><age>20</age></employee> <employee id="2"><name>Sue</name><age>30</age></employee>  </employees>');
// 获取所有的员工
print("获取所有的员工:\n" + e..name);
// 名字叫 Joe 的员工
print("名字叫 Joe 的员工:\n" + e.employee.(name == "Joe"));
// 员工的id 为 1 和 2
print("员工的id 为 1 和 2:\n" + e.employee.(@id == 1 || @id == 2));
// 员工的id 为 1
print("员工的id 为 1: " + e.employee.(@id == 1).name);
print("----------------------------------------");
```

- 执行如下

```java
@Test
public void test_rhino_file_js() {
    try {
        ScriptEngine engine = new ScriptEngineManager().getEngineByName("rhino");

        ScriptContext scriptContext = engine.getContext();

        StringWriter stringWriter = new StringWriter();
        PrintWriter printWriter = new PrintWriter(stringWriter);
        scriptContext.setWriter(printWriter);
        engine.eval(new FileReader(TestJSEngine.class.getResource("/xml.js").getPath()));

        System.out.println(String.format("xml result = %s",stringWriter.toString() ));

    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

- 输出如下

```
xml result = ----------------------------------------
All the employee names are:
<name>Joe</name>
<name>Sue</name>
The employee named Joe is:
<employee id="1">
  <name>Joe</name>
  <age>20</age>
</employee>
Employees with ids 1 & 2:
<employee id="1">
  <name>Joe</name>
  <age>20</age>
</employee>
<employee id="2">
  <name>Sue</name>
  <age>30</age>
</employee>
Name of the the employee with ID=1: Joe
----------------------------------------
```

#### 3.2 测试

- xml 内容如下

```xml
<CCardProcessSyncResponse>
    <RetCode>0</RetCode>
    <Message>操作成功！</Message>
    <RefundCycle />
    <EpayRefundCycleMin>1</EpayRefundCycleMin>
    <EpayRefundCycleMax>7</EpayRefundCycleMax>
    <EpayRefundCycleUnitF />
</CCardProcessSyncResponse>
```

- 具体测试如下

```java
@Test
public void test_rhino() {
    try {
        ScriptEngine engine = new ScriptEngineManager().getEngineByName("rhino");

        String jsString = jsString = "var obj=new XML('<CCardProcessSyncResponse>    <RetCode>0</RetCode>    <Message>操作成功！</Message>    <RefundCycle />    <EpayRefundCycleMin>1</EpayRefundCycleMin>    <EpayRefundCycleMax>7</EpayRefundCycleMax>    <EpayRefundCycleUnitF />  </CCardProcessSyncResponse>');print(obj.Message == '操作成功！');";
        ScriptContext scriptContext = engine.getContext();

        StringWriter stringWriter = new StringWriter();
        PrintWriter printWriter = new PrintWriter(stringWriter);
        scriptContext.setWriter(printWriter);
        engine.eval(jsString);

        System.out.println(String.format("xml result = %s",stringWriter.toString() ));

    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

上面的输出结果如下

```
xml result = true
```

## 4 参考

- [Java Scripting Programmer's Guide](https://docs.oracle.com/javase/6/docs/technotes/guides/scripting/programmer_guide/)
- [Rhino](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/Rhino)
- [Parse XML using Rhino included E4X. Much easier than using SAX or DOM.](https://forums.opentext.com/forums/discussion/61515/parse-xml-using-rhino-included-e4x-much-easier-than-using-sax-or-dom)
- [mozilla/rhino](https://github.com/mozilla/rhino/tree/master/xmlimplsrc/org/mozilla/javascript/xmlimpl)