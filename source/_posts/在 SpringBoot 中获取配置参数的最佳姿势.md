---
title: 在 SpringBoot 中获取配置参数的最佳姿势
title_url: SpringBoot-yml-properties-config-usage-practice
date: 2019-07-25
tags: [SpringBoot]
categories: SpringBoot
description: 在 SpringBoot 中的配置文件通常为 yml 或者 properties 文件，本文将介绍几种从这些文件中读取配置的方法，并推荐最佳的使用方案。
---

## 1 概述

在 SpringBoot 中的配置文件通常为 yml 或者 properties 文件，本文将介绍几种从这些文件中读取配置的方法，并推荐最佳的使用方案。

具体如下

1. 通过 `@PropertySource` 和 `@Value` 注解
2. 通过 Environment 对象
3. 通过 `@ConfigurationProperties` 注解

## 2 方法1：通过 `@PropertySource` 和 `@Value` 注解

1. 在类上通过 `@PropertySource(value = { "classpath:META-INF/application.properties" })` 引入 properties 文件，同时要配置该类在包扫描范围内
2. application.properties 文件中如果有变量 `server.name=userApi`
3. 在类中使用如下

```java
@Component
@PropertySource(value = { "classpath:META-INF/application.properties" })
public class MyService {
	
	@Value("${server.name}")
	private String serverName;
}
```

## 3 方法2：通过 Environment 对象

- org.springframework.core.env.Environment

1. 通过 `@Autowired` 注入 Spring 的 Environment 对象
2. 通过该对象的 `getRequiredProperty("key")` 方法可以获取到配置文件中对应 key 的 value
3. Environment 的使用具体如下

```java
import org.springframework.core.env.Environment;

@Configuration
public class JpaConfig {

    @Autowired
    private Environment environment;

    /*
     * 从 application.yml 中读取 hibernate 相关配置
     */
    private Properties jpaProperties() {
        Properties properties = new Properties();
        properties.put("hibernate.dialect", environment.getRequiredProperty("datasource.sampleapp.hibernate.dialect"));
        properties.put("hibernate.hbm2ddl.auto", environment.getRequiredProperty("datasource.sampleapp.hibernate.hbm2ddl.auto"));
        properties.put("hibernate.show_sql", environment.getRequiredProperty("datasource.sampleapp.hibernate.show_sql"));
        properties.put("hibernate.format_sql", environment.getRequiredProperty("datasource.sampleapp.hibernate.format_sql"));
        if (StringUtils.isNotEmpty(environment.getRequiredProperty("datasource.sampleapp.defaultSchema"))) {
            properties.put("hibernate.default_schema", environment.getRequiredProperty("datasource.sampleapp.defaultSchema"));
        }
        return properties;
    }
}
```

4. `src\main\resources\application.yml` 内容如下

```xml
datasource:
  sampleapp:
    url: jdbc:mysql://localhost:3306/jpaTest
    username: root
    password: root
    driverClassName: com.mysql.jdbc.Driver
    defaultSchema:
    maxPoolSize: 20
    hibernate:
      hbm2ddl.auto: update
      show_sql: true
      format_sql: true
      dialect: org.hibernate.dialect.MySQLDialect
```

## 4 方法3：通过 `@ConfigurationProperties` 注解

- org.springframework.boot.context.properties.ConfigurationProperties

该注解可将配置转换成 Spring 的 Bean 对象，其他 Bean 中通过 `@Autowired` 注解注入。具体如下

1. 新建 com.ckjava.test.properties 包, 所有的 properties 配置类都放在该包下
2. application-dev.yml 文件内容如下

```xml
datasource:
  url: jdbc:mysql://localhost:3306/jpatest?DB_CLOSE_ON_EXIT=FALSE&createDatabaseIfNotExist=TRUE&useUnicode=TRUE&characterEncoding=utf8&autoReconnect=TRUE
  username: root
  password: root
  driverClassName: com.mysql.jdbc.Driver
  defaultSchema:
  maxPoolSize: 20
  hibernate:
    hbm2ddl_auto: update
    show_sql: true
    format_sql: true
    dialect: org.hibernate.dialect.MySQLDialect
```

3. 新建 com.ckjava.test.properties.DataSourceProperties 配置类，具体内容如下

```java
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "datasource")
public class DataSourceProperties {

    private String url;
    private String username;
    private String password;
    private String driverClassName;
    private String defaultSchema;
    private Integer maxPoolSize;
    private ClassLoader classLoader;
    // 忽略 get set
```

- 其中 prefix 定义了 url, username, password 等属性的前缀

4. 新建 com.ckjava.test.properties.HibernateProperties 配置类，具体内容如下
    
```java
@Component
@ConfigurationProperties(prefix = "datasource.hibernate")
public class HibernateProperties {

    private String hbm2ddl_auto;
    private String show_sql;
    private String format_sql;
    private String dialect;
    // 忽略 get set
```

5. 系统启动的时候可以通过指定 VM options: `-Dspring.profiles.active=dev` 启用 application-dev.yml 配置文件
6. 其他 Bean 中通过 @Autowired 注入配置类

```java
@Autowired
private DataSourceProperties dataSourceProperties;
@Autowired
private HibernateProperties hibernateProperties;
```

## 5 总结

1. 对于简单的参数获取，`@Value` 注解还是不错的
2. 如果是复杂类型的参数，比如数据库或者其他一些对象类型的参数配置，`@ConfigurationProperties` 注解无疑是最佳的选择

## 6 参考

- [在Spring Boot中使用 @ConfigurationProperties 注解](https://www.jianshu.com/p/df57fefe0ab7)