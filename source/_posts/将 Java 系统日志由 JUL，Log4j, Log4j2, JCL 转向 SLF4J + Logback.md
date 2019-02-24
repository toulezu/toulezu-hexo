---
title: 将 Java 系统日志由 JUL，Log4j, Log4j2, JCL 转向 SLF4J + Logback
title_url: Java-SLF4J-Logback
date: 2019-02-24
tags: [Java,日志,SLF4J,Logback]
categories: 技术
description: Logback 性能比较好，在编译的时候绑定 slf4j 接口的实现。这里探讨将系统的日志实现由 JUL，Log4j, Log4j2, JCL 转向 slf4j + Logback 的方法。
---

## 前言

Logback 性能比较好，在编译的时候绑定 slf4j 接口的实现。这里探讨将系统的日志实现由 JUL，Log4j, Log4j2, JCL 转向 slf4j + Logback 的方法。

## 基本知识

- JCL 和 slf4j 是接口，日志门面，不负责具体的日志打印，输出等操作
- JUL，Log4j，Log4j2，Logback 是具体日志的实现

## JUL 转向 slf4j

JUL 就是 jdk 自带的日志系统，位于 `java.util.logging` 包下，使用如下

```java
import java.util.logging.Logger;

public class JDKLog {
    Logger logger = Logger.getLogger("JDKLog");

    public void log() {
        logger.info("jul log");
    }
}
```

- 通过 jul-to-slf4j 将其转向 slf4j

```
<!-- 从 jdk-logging到slf4j的桥梁 -->
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>jul-to-slf4j</artifactId>
    <version>1.7.9</version>
</dependency>
```

## Log4j 转向 slf4j

#### Log4j 的使用

Log4j 使用的时候引入 log4j 依赖，并在项目的 src\main\resources 目录下增加 log4j.xml 配置文件即可

- log4j 依赖

```xml
<dependency>
    <groupId>log4j</groupId>
    <artifactId>log4j</artifactId>
    <version>1.2.17</version>
</dependency>
```

- log4j.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE log4j:configuration SYSTEM "log4j.dtd">
<log4j:configuration xmlns:log4j='http://jakarta.apache.org/log4j/' >
    <appender name="myConsole" class="org.apache.log4j.ConsoleAppender">
        <layout class="org.apache.log4j.PatternLayout">
            <param name="ConversionPattern"
                   value="[%d{dd HH:mm:ss,SSS} %-5p] [%t] %c{2} - %m%n" />
        </layout>
        <!--过滤器设置输出的级别-->
        <filter class="org.apache.log4j.varia.LevelRangeFilter">
            <param name="levelMin" value="debug" />
            <param name="levelMax" value="error" />
            <param name="AcceptOnMatch" value="true" />
        </filter>
    </appender>
    <!-- 根logger的设置-->
    <root>
        <priority value ="debug"/>
        <appender-ref ref="myConsole"/>
    </root>
</log4j:configuration>
```

- 使用如下

```java
import org.apache.log4j.Logger;

public class Log4j {
    Logger logger= Logger.getLogger(Log4j.class);

    public void log() {
        logger.info("log4j1 log");
    }

    public static void main(String[] args) {
        Log4j log4j = new Log4j();
        log4j.log();

    }
}
```

输出如下

```
[15 16:01:40,977 INFO ] [main] ckjava.Log4j - log4j1 log
```

#### 转向 slf4j

- 去掉 log4j 依赖并删除 log4j.xml 配置文件
- 引入 log4j-over-slf4j 依赖

```
<!-- log4j1到slf4j的桥梁 -->
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>log4j-over-slf4j</artifactId>
    <version>1.7.9</version>
</dependency>
```

## Log4j2 转向 slf4j

#### Log4j2 的使用

- 依赖 log4j-api 和 log4j-core 

```xml
<!-- Log4J 2 -->
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-api</artifactId>
    <version>2.6.2</version>
</dependency>
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-core</artifactId>
    <version>2.6.2</version>
</dependency>
```

- 在 src\main\resources 目录增加 log4j2.xml 配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Configuration status="WARN">
    <Appenders>
        <Console name="Console" target="SYSTEM_OUT">
            <PatternLayout pattern="%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n"/>
        </Console>
    </Appenders>
    <Loggers>
        <Root level="info">
            <AppenderRef ref="Console"/>
        </Root>
    </Loggers>
</Configuration>
```

- 具体使用如下

```
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Log4j2 {
    private static final Logger logger = LogManager.getLogger(Log4j2.class);

    public void log() {
        logger.info("log4j2 log");
    }

    public static void main(String[] args) {
        Log4j2 log4j2 = new Log4j2();
        log4j2.log();
    }
}
```

- 输出如下

```
16:21:03.623 [main] INFO  com.ckjava.Log4j2 - log4j2 log
```

#### 转向 slf4j

- 去掉 log4j-api 和 log4j-core 依赖，删除 log4j2.xml 配置文件
- 增加 log4j-to-slf4j 依赖

```xml
<!-- 将 log4j2的日志桥接到 slf4j -->
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-to-slf4j</artifactId>
    <version>2.9.1</version>
</dependency>
```

## JCL 详解

#### 具体的使用

- JCL 是 jakarta.commons.logging，日志接口，需要绑定具体的日志框架才能使用
- 如果项目仅引入 commons-logging， 那么默认的日志框架就是 JUL。

```xml
<dependency>
    <groupId>commons-logging</groupId>
    <artifactId>commons-logging</artifactId>
    <version>1.2</version>
</dependency>
```

- 如果项目引入了 commons-logging + log4j， 那么 JCL 由 log4j 日志框架来实现，不需要桥接到 log4j

```xml
<dependency>
    <groupId>commons-logging</groupId>
    <artifactId>commons-logging</artifactId>
    <version>1.2</version>
</dependency>

<dependency>
    <groupId>log4j</groupId>
    <artifactId>log4j</artifactId>
    <version>1.2.17</version>
</dependency>
```

- 如果项目引入了 commons-logging + log4j-api + log4j-core, 那么 JCL 由 log4j2 日志框架来实现, 还需要再加入 log4j-jcl，将 jcl 桥接到 log4j 输出。

```xml
<dependency>
    <groupId>commons-logging</groupId>
    <artifactId>commons-logging</artifactId>
    <version>1.2</version>
</dependency>

<!-- Log4J 2 -->
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-api</artifactId>
    <version>2.6.2</version>
</dependency>
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-core</artifactId>
    <version>2.6.2</version>
</dependency>

<!-- Apache Commons Logging Bridge -->
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-jcl</artifactId>
    <version>2.3</version>
</dependency>
```

- 如果项目引入了 commons-logging + logback-classic + logback-core，那么 JCL 由 logback 日志框架来实现, 还需要再加入 jcl-over-slf4j，将 jcl 桥接到 logback 输出。

```xml
<dependency>
    <groupId>commons-logging</groupId>
    <artifactId>commons-logging</artifactId>
    <version>1.2</version>
</dependency>

<!-- commons-logging到slf4j的桥梁 -->
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>jcl-over-slf4j</artifactId>
    <version>1.7.9</version>
</dependency>

<!-- logback -->
<dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-classic</artifactId>
    <version>1.1.7</version>
</dependency>
<dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-core</artifactId>
    <version>1.1.7</version>
</dependency>
```

- 使用如下

```
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class CommonsLog {
    private static Log log = LogFactory.getLog(CommonsLog.class);

    public void log() {
        log.info("Commons Log ");
    }
    public static void main(String[] args) {
        CommonsLog commonsLog = new CommonsLog();
        commonsLog.log();
    }
}
```

- 输出如下

```
17:10:51.340 [main] INFO  com.ckjava.CommonsLog - Commons Log 
```

#### 转向 slf4j

- 通过 jcl-over-slf4j 将 commons-logging 转向 slf4j

```
<!-- commons-logging到slf4j的桥梁 -->
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>jcl-over-slf4j</artifactId>
    <version>1.7.9</version>
</dependency>
```

## slf4j + Logback 日志输出

slf4j 也是一个日志接口，默认由 Logback 日志框架来实现，并且它们是同一个作者开发的。

- slf4j + Logback 依赖如下

```xml
<!--SLF4J+LogBack-->
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-api</artifactId>
    <version>1.7.21</version>
</dependency>
<dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-classic</artifactId>
    <version>1.1.7</version>
</dependency>
<dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-core</artifactId>
    <version>1.1.7</version>
</dependency>
```

- 在 src\main\resources 目录增加 logback 配置文件 logback.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <layout class="ch.qos.logback.classic.PatternLayout">
            <Pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</Pattern>
        </layout>
    </appender>
    <logger name="com.ckjava" level="TRACE"/>
    <root level="trace">
        <appender-ref ref="STDOUT" />
    </root>
</configuration>
```

- 使用如下

```
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LogBack {
    static final Logger logger = LoggerFactory.getLogger(LogBack.class);

    public void log() {
        logger.info("LogBack log");
    }

    public static void main(String[] args) {
        LogBack logBack = new LogBack();
        logBack.log();
    }
}
```

- 输出如下

```
17:31:28.006 [main] INFO  com.ckjava.LogBack - LogBack log
```

## 混合使用

对于一些比较老的项目，经过了N多人的手，并且由于引入了很多三方依赖，目前项目中已经有了 JUL，Log4j, Log4j2, JCL和 SLF4J，既想输出三方依赖框架中的日志，又要保证项目中的日志正常输出，这个时候该怎么办？

具体如下

```xml
<!-- 从 jdk-logging到slf4j的桥梁 -->
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>jul-to-slf4j</artifactId>
    <version>1.7.9</version>
</dependency>

<!-- log4j1到slf4j的桥梁 -->
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>log4j-over-slf4j</artifactId>
    <version>1.7.9</version>
</dependency>
        
<!-- 将 log4j2的日志桥接到 slf4j -->
<dependency>
    <groupId>org.apache.logging.log4j</groupId>
    <artifactId>log4j-to-slf4j</artifactId>
    <version>2.9.1</version>
</dependency>

<!-- commons-logging -->
<dependency>
    <groupId>commons-logging</groupId>
    <artifactId>commons-logging</artifactId>
    <version>1.2</version>
</dependency>

<!-- commons-logging到slf4j的桥梁 -->
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>jcl-over-slf4j</artifactId>
    <version>1.7.9</version>
</dependency>

<!--SLF4J+LogBack-->
<dependency>
    <groupId>org.slf4j</groupId>
    <artifactId>slf4j-api</artifactId>
    <version>1.7.21</version>
</dependency>
<dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-classic</artifactId>
    <version>1.1.7</version>
</dependency>
<dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-core</artifactId>
    <version>1.1.7</version>
</dependency>
```

- 配置文件就是 logback.xml
- 测试如下

```
JDKLog jdkLog = new JDKLog();
jdkLog.log();

Log4J log4j = new Log4J();
log4j.log();

Log4J2 log4j2 = new Log4J2();
log4j2.log();

CommonsLog commonsLog = new CommonsLog();
commonsLog.log();

LogBack logBack = new LogBack();
logBack.log();
```

- 输出如下

```
一月 15, 2019 5:42:45 下午 com.ckjava.JDKLog log
信息: jul log
17:42:45.390 [main] INFO  com.ckjava.Log4J - log4j1 log
17:42:45.423 [main] INFO  com.ckjava.Log4J2 - log4j2 log
17:42:45.447 [main] INFO  com.ckjava.CommonsLog - Commons Log 
17:42:45.448 [main] INFO  com.ckjava.LogBack - LogBack log
```

- 注意：**同时需要排除 log4j，log4j-api 和 log4j-core 依赖**，否则会出现类似如下错误

```
log4j:WARN No appenders could be found for logger (org.apache.ibatis.thread.Runnable).
log4j:WARN Please initialize the log4j system properly.
log4j:WARN See http://logging.apache.org/log4j/1.2/faq.html#noconfig for more info.
```

## Java 日志最佳实践

在大型项目开发中系统往往会分成很多模块, 比如在使用 Maven 开发 Java Web 项目中通常会以 Dao, Service, Web 分成多个项目, 每个项目都会使用日志记录功能, 而项目之间又会产生依赖 Web->Service->Dao. 这个时候只需要在 Dao 和 Service 中增加日志门面依赖即可, 也就是引入 slf4j-api. 在 Web 中引入具体的日志框架.

而在分布式服务架构中 Service 会以单独的项目启动, 此时也要引入具体的日志框架.
