---
title: SpringBoot Jpa 单元测试实践
title_url: SpringBoot-jpa-junit-test-practice
date: 2019-05-27
tags: [SpringBoot,jpa,junit]
categories: 技术
description: 本文将介绍如何在 SpringBoot 环境中编写独立于 Spring context 的 Jpa 单元测试，比如：单个 service, 单个 controller 的单元测试。
---

## 1 概述

本文将介绍如何在 SpringBoot 环境中编写独立于 Spring context 的 Jpa 单元测试，比如：单个 service, 单个 controller 的单元测试。

## 2 依赖

依赖如下

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
    <version>1.5.13.RELEASE</version>
</dependency>
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>test</scope>
    <version>1.4.196</version>
</dependency>
```

- `spring-boot-starter-test` 是 SpringBoot 测试的主要依赖
- h2 DB 是内存型数据库，与数据有关的操作仅在测试环境中有效

## 3 父类 BaseTest 定义

BaseTest 定义了测试需要的 Bean 以及测试需要用的配置文件，具体如下

```java
import com.ckjava.test.web.TaskController;
import com.ckjava.xutils.StringUtils;
import com.zaxxer.hikari.HikariDataSource;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.jdbc.DataSourceBuilder;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.test.context.ConfigFileApplicationContextInitializer;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.core.env.Environment;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.JpaVendorAdapter;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.PlatformTransactionManager;

import javax.naming.NamingException;
import javax.persistence.EntityManagerFactory;
import javax.sql.DataSource;
import java.util.Properties;

@RunWith(SpringRunner.class)
@ContextConfiguration(initializers = ConfigFileApplicationContextInitializer.class)
public class BaseTest {

    @TestConfiguration
    @TestPropertySource(locations = "classpath:application.yml")
    @ActiveProfiles("local")
    public static class TestContextConfiguration {

        @Autowired
        private Environment environment;

        @Value("${datasource.sampleapp.maxPoolSize:10}")
        private int maxPoolSize;

        /*
         * 将 application.yml 的配置填充到 SpringBoot 中的 DataSourceProperties 对象里面
         */
        @Bean
        @Primary
        public DataSourceProperties dataSourceProperties() {
            DataSourceProperties dataSourceProperties = new DataSourceProperties();
            dataSourceProperties.setDriverClassName(environment.getRequiredProperty("datasource.sampleapp.driverClassName"));
            dataSourceProperties.setUrl(environment.getRequiredProperty("datasource.sampleapp.url"));
            dataSourceProperties.setUsername(environment.getRequiredProperty("datasource.sampleapp.username"));
            dataSourceProperties.setPassword(environment.getRequiredProperty("datasource.sampleapp.password"));
            return dataSourceProperties;
        }

        /*
         * 配置 HikariCP 连接池数据源.
         */
        @Bean
        public DataSource dataSource() {
            DataSourceProperties dataSourceProperties = dataSourceProperties();
            HikariDataSource dataSource = (HikariDataSource) DataSourceBuilder
                    .create(dataSourceProperties.getClassLoader())
                    .driverClassName(dataSourceProperties.getDriverClassName())
                    .url(dataSourceProperties.getUrl())
                    .username(dataSourceProperties.getUsername())
                    .password(dataSourceProperties.getPassword())
                    .type(HikariDataSource.class)
                    .build();
            dataSource.setMaximumPoolSize(maxPoolSize);
            return dataSource;
        }

        /*
         * Entity Manager Factory 配置.
         */
        @Bean
        public LocalContainerEntityManagerFactoryBean entityManagerFactory() throws NamingException {
            LocalContainerEntityManagerFactoryBean factoryBean = new LocalContainerEntityManagerFactoryBean();
            factoryBean.setDataSource(dataSource());
            factoryBean.setPackagesToScan(new String[]{"com.ckjava.test.domain"});
            factoryBean.setJpaVendorAdapter(jpaVendorAdapter());
            factoryBean.setJpaProperties(jpaProperties());
            return factoryBean;
        }

        /**
         * 指定 hibernate 为 jpa 的持久化框架
         * @return
         */
        @Bean
        public JpaVendorAdapter jpaVendorAdapter() {
            HibernateJpaVendorAdapter hibernateJpaVendorAdapter = new HibernateJpaVendorAdapter();
            return hibernateJpaVendorAdapter;
        }

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

        @Bean
        public PlatformTransactionManager transactionManager(EntityManagerFactory entityManagerFactory) {
            JpaTransactionManager txManager = new JpaTransactionManager();
            txManager.setEntityManagerFactory(entityManagerFactory);
            return txManager;
        }

        @Bean
        public TaskService taskService() {
            return new TaskService();
        }

        @Bean
        public TaskController taskController() {
            return new TaskController();
        }

        @Bean
        public MockMvc mockMvc() {
            Object[] contorllers = { taskController() };
            return MockMvcBuilders.standaloneSetup(contorllers).build();
        }
    }

}
```

- `@ContextConfiguration(initializers = ConfigFileApplicationContextInitializer.class)` 必须放在父类中，这个配置用于解析测试配置文件 application.yml
- `@TestConfiguration` 配置测试需要的 Bean, 包含了 jpa 数据源 DataSource Bean， entityManagerFactory Bean, transactionManager Bean 等
- `@TestPropertySource(locations = "classpath:application.yml")` 表示测试使用的配置文件
- `@ActiveProfiles("local")` 表示测试使用 application.yml 配置文件中的 local profile

## 4 Service 单元测试

- TestTaskService 直接继承 BaseTest， 通过 `@Autowired` 注入待测 TaskService Bean
- TaskService Bean 在 BaseTest 中的 TestContextConfiguration 类中定义

```java
import com.ckjava.test.domain.Task;
import org.junit.Assert;
import org.junit.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;

public class TestTaskService extends BaseTest {

    @Autowired
    private TaskService taskService;

    @Test
    @Transactional
    public void testCRUD() {
        // save
        Task task = new Task();
        task.setName("test1");
        task.setDate(new Date());
        task.setContent("test content");
        taskService.save(task);

        // findAll
        List<Task> taskList = taskService.findAll();
        Assert.assertTrue(taskList.size() == 1);

        // 删除
        task = taskList.get(0);
        taskService.delete(task);

        taskList = taskService.findAll();
        task = taskList.get(0);
        Assert.assertTrue(task.getDelFlag().equals("1"));
    }
}
```

## 5  Controller 单元测试

- TestTaskController 直接继承 BaseTest， 通过 `@Autowired` 注入待测 MockMvc Bean
- MockMvc Bean 在 BaseTest 中的 TestContextConfiguration 类中定义
- 其中 MockMvc Bean 创建过程中引入了 TaskController Bean

```java
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.ckjava.test.domain.Task;
import org.junit.Assert;
import org.junit.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public class TestTaskController extends BaseTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @Transactional
    public void testCRUD() throws Exception {
        Task task = new Task();
        task.setId(1L);
        task.setName("test");

        // post
        ResultActions postResultActions = mockMvc.perform(
                MockMvcRequestBuilders.post("/api/task")
                        .accept(MediaType.APPLICATION_JSON)
                        .content(JSONObject.toJSONString(task))
                        .contentType(MediaType.APPLICATION_JSON));
        Assert.assertTrue(postResultActions.andReturn().getResponse().getStatus() == 200);

        // get
        ResultActions resultActions = mockMvc.perform(MockMvcRequestBuilders.get("/api/task/".concat(task.getId().toString()))
                .accept(MediaType.APPLICATION_JSON));

        MvcResult mvcResult = resultActions.andReturn();
        MockHttpServletResponse resp = mvcResult.getResponse();
        Assert.assertEquals(resp.getStatus(), 200);

        JSONObject obj = JSONObject.parseObject(resp.getContentAsString());
        JSONObject dataObj = obj.getJSONObject("data");
        task = dataObj.toJavaObject(Task.class);
        Assert.assertTrue(task.getId() == 1);

        // findAll
        resultActions = mockMvc.perform(MockMvcRequestBuilders.get("/api/task/all")
                .accept(MediaType.APPLICATION_JSON));

        mvcResult = resultActions.andReturn();
        resp = mvcResult.getResponse();
        Assert.assertEquals(resp.getStatus(), 200);

        obj = JSONObject.parseObject(resp.getContentAsString());
        JSONArray dataArr = obj.getJSONArray("data");
        List<Task> dataList = dataArr.toJavaList(Task.class);
        Assert.assertTrue(dataList.size() == 1);

        task = dataList.get(0);
        Assert.assertTrue(task.getId() == 1);

        // delete
        resultActions = mockMvc.perform(MockMvcRequestBuilders.delete("/api/task/".concat(task.getId().toString()))
                .accept(MediaType.APPLICATION_JSON));

        mvcResult = resultActions.andReturn();
        resp = mvcResult.getResponse();
        Assert.assertEquals(resp.getStatus(), 200);

        obj = JSONObject.parseObject(resp.getContentAsString());
        dataObj = obj.getJSONObject("data");
        Assert.assertNull(dataObj);

    }
}
```

## 6 问题

#### 6.1 `javax.persistence.TransactionRequiredException: No EntityManager with actual transaction available for current thread - cannot reliably process 'persist' call`

- 解决方法如下

在相关的测试方法上也要加上 `@Transactional`，具体如下

```java
@Test
@Transactional
public void testCRUD() {
    // save
    Task task = new Task();
    task.setName("test1");
    task.setDate(new Date());
    task.setContent("test content");
    taskService.save(task);

    // findAll
    List<Task> taskList = taskService.findAll();
    Assert.assertTrue(taskList.size() == 1);

    // 删除
    task = taskList.get(0);
    taskService.delete(task);

    taskList = taskService.findAll();
    task = taskList.get(0);
    Assert.assertTrue(task.getDelFlag().equals("1"));
}
```

#### 6.2 `org.h2.jdbc.JdbcSQLException: Database is already closed (to disable automatic closing at VM shutdown, add ";DB_CLOSE_ON_EXIT=FALSE" to the db URL)`

- 解决方法如下

在数据库连接 url 后面追加上 `;DB_CLOSE_ON_EXIT=FALSE`, 具体如下

```yml
spring:
  profiles: local,default
datasource:
  sampleapp:
    url: jdbc:h2:~/test;DB_CLOSE_ON_EXIT=FALSE
    username: SA
    password:
    driverClassName: org.h2.Driver
    defaultSchema:
    maxPoolSize: 10
    hibernate:
      hbm2ddl.auto: create-drop
      show_sql: true
      format_sql: true
      dialect: org.hibernate.dialect.H2Dialect
```

## 7 参考

- [SpringBoot 集成 Jpa 实现单表 CRUD 功能并提供 RESTful api 服务](http://ckjava.com/2019/05/27/SpringBoot-jpa-RESTful-practice/)