---
title: SpringBoot 属性配置类 @ConfigurationProperties 在单元测试中不生效的问题
title_url: SpringBoot-ConfigurationProperties-not-working
date: 2019-08-07
tags: [SpringBoot]
categories: SpringBoot
description: 在 SpringBoot 中通过 `@ConfigurationProperties` 注解将 application.properties 中的配置生成配置类，程序启动的时候可以读取到配置，但是在单元测试中无法读取配置。
---

## 1 问题

在 SpringBoot 中通过 `@ConfigurationProperties` 注解将 application.properties 中的配置生成配置类，程序启动的时候可以读取到配置，但是在单元测试中无法读取配置。

- application.properties 配置如下

```
jdbc.driverClassName=com.mysql.jdbc.Driver
jdbc.url=jdbc:mysql://localhost:3306/test?createDatabaseIfNotExist=true&useUnicode=true&characterEncoding=utf8&autoReconnect=true
jdbc.username=root
jdbc.password=root
```

- DbProperties 配置类如下

```java

import org.apache.commons.lang3.builder.ToStringBuilder;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "jdbc")
public class DbProperties {
    private String driverClassName;
    private String url;
    private String username;
    private String password;

    // 忽略 get set

    @Override
    public String toString() {
        return new ToStringBuilder(this)
                .append("driverClassName", driverClassName)
                .append("url", url)
                .append("username", username)
                .append("password", password)
                .toString();
    }
}
```

- 单元测试配置如下

```java
import com.ckjava.test.config.DataSourceConfig;
import com.ckjava.test.properties.DbProperties;
import org.junit.runner.RunWith;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit4.AbstractJUnit4SpringContextTests;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

@RunWith(SpringJUnit4ClassRunner.class)
@TestPropertySource(value = {"classpath:application.properties"})
@EnableConfigurationProperties(value = {DbProperties.class})
@ContextConfiguration(classes = {
        DataSourceConfig.class})
public abstract class BaseTest extends AbstractJUnit4SpringContextTests {

}

import com.ckjava.test.BaseTest;
import com.ckjava.test.properties.DbProperties;
import com.ckjava.test.utils.StringUtils;
import org.junit.Assert;
import org.junit.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.ContextConfiguration;

@ContextConfiguration(classes = {
        DbProperties.class})
public class TestDbProperties extends BaseTest {

    @Autowired
    private DbProperties dbProperties;

    @Test
    public void test_read_dbProperties() {
        System.out.println(dbProperties.toString());
        Assert.assertTrue(StringUtils.isNotBlank(dbProperties.getDriverClassName()));
    }
}
```

## 2 原因

当前的测试没有将整个 SpringBoot 应用启动起来，因此无法通过 `@ConfigurationProperties` 注解来加载配置。

## 3 解决

在 BaseTest 上增加 `@EnableConfigurationProperties(value = {DbProperties.class})` 即可解决这个问题，具体参考上面的代码。

## 4 参考

- [spring boot configuration properties not working](https://stackoverflow.com/questions/44933047/spring-boot-configuration-properties-not-working)