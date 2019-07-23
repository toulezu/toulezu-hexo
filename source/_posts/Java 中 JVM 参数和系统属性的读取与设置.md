---
title: Java 中 JVM 参数和系统属性的读取与设置
title_url: Java-jvm-system-properties-read-write-practice
date: 2019-07-23
tags: Java
categories: Java
description: Java 中 JVM 参数和系统属性的读取与设置
---

## 1 概述

打开 Java VisualVM，在每个 JVM 中都可以发现 JVM 参数和系统属性两个 tab 视图，信息非常丰富，这里介绍一下如何在程序中获取这些内容，以及如何设置新的内容。

## 2 JVM 参数

#### 2.1 获取

这里通过 `java.lang.management.ManagementFactory` 对象来获取，具体如下

```java
List<String> inputArguments = ManagementFactory.getRuntimeMXBean().getInputArguments();
inputArguments.forEach(str -> System.out.println(str));
```

部分内容如下

```
-agentlib:jdwp=transport=dt_socket,address=127.0.0.1:65016,suspend=y,server=n
-Dfile.encoding=UTF-8
```

#### 2.2 设置

1. 在 IDE 的 VM options 中输入如下内容

```
-Xmx1024m
-Xms1024m
-Dspring.profiles.active=dev
```

2. 或者在用 java 命令启动可执行 jar 的时候指定

```
java -Xmx1024m -Xms1024m -Dspring.profiles.active=pro -jar userProject.jar
```

都可以修改 JVM 参数。

## 3 系统属性

#### 3.1 获取

通过 `java.lang.System` 对象来获取，具体如下

```
System.getProperties().forEach((key, value) -> System.out.println(String.format("%s=%s", key, value)));
```

部分内容如下

```
os.name=Windows 10
user.variant=
java.vm.specification.vendor=Oracle Corporation
line.separator=

java.endorsed.dirs=C:\Program Files\Java\jdk1.8.0_121\jre\lib\endorsed
user.country=CN
user.script=
sun.java.launcher=SUN_STANDARD
sun.os.patch.level=
java.vm.name=Java HotSpot(TM) 64-Bit Server VM
file.encoding.pkg=sun.io
path.separator=;
java.vm.vendor=Oracle Corporation
java.vendor.url=http://java.oracle.com/
sun.boot.library.path=C:\Program Files\Java\jdk1.8.0_121\jre\bin
java.vm.version=25.121-b13
java.runtime.name=Java(TM) SE Runtime Environment
```

#### 3.2 设置

设置系统属性如下

```java
Properties properties = System.getProperties();
properties.put("user.env", "FAT");
properties.forEach((key, value) -> System.out.println(String.format("%s=%s", key, value)));
```

打印后的内容中会多出 

```
user.env=FAT
```