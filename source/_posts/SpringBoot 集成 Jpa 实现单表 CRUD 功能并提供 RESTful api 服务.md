---
title: SpringBoot 集成 Jpa 实现单表 CRUD 功能并提供 RESTful api 服务
title_url: SpringBoot-jpa-RESTful-practice
date: 2019-05-27
tags: [SpringBoot,jpa,RESTful]
categories: 技术
description: 这里介绍在 SpringBoot 集成 Jpa 并提供 RESTful api 服务，实现单表的 CRUD 功能；使用 Swagger 自动生成 RESTful api 文档；通过泛型封装 Service 和 Controller 抽象基类。
---

## 1 概述

1. 这里介绍在 SpringBoot 集成 Jpa 并提供 RESTful api 服务，实现单表的 CRUD 功能
2. 使用 Swagger 自动生成 RESTful api 文档
3. 通过泛型封装 Service 和 Controller 抽象基类

## 2 应用配置

- 通过 application-dev.yml 和 application-prd.yml 区分不同的开发环境，测试开发使用 h2 db, 生产环境使用 mysql
- 在 IDE 开发中通过在 vm 参数中增加 `-Dspring.profiles.active=dev` 来使用  application-dev.yml 文件中的配置, 在生产环境的启动脚本中通过 `java -Dspring.profiles.active=prd -jar appProject.jar` 来使用 application-prd.yml 文件中的配置

- `src\main\resources\application-dev.yml` 配置如下
    ```yaml
    debug: true
    server:
      port: 8080
      contextPath: /
    
    datasource:
      sampleapp:
        url: jdbc:h2:~/test
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
    
- `src\main\resources\application-prd.yml` 配置如下    
    ```yaml
    debug: false
    server:
      port: 8080
      contextPath: /
    
    datasource:
      sampleapp:
        url: jdbc:mysql://localhost:3306/jpaTest;DB_CLOSE_ON_EXIT=FALSE
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
    
## 3 jpa 配置

- 通过 Environment 和 @Value 两种方式来获取 application.yml 中的配置

```java
import com.ckjava.xutils.StringUtils;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.jdbc.DataSourceBuilder;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.core.env.Environment;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.JpaVendorAdapter;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.EnableTransactionManagement;

import javax.naming.NamingException;
import javax.persistence.EntityManagerFactory;
import javax.sql.DataSource;
import java.util.Properties;

@Configuration
@EnableJpaRepositories(basePackages = "com.ckjava.test",
        entityManagerFactoryRef = "entityManagerFactory",
        transactionManagerRef = "transactionManager")
@EnableTransactionManagement
public class JpaConfig {

    @Autowired
    private Environment environment;

    @Value("${datasource.sampleapp.maxPoolSize:10}")
    private int maxPoolSize;

    /*
     * 将配置填充到 SpringBoot 中的 DataSourceProperties 对象里面
     */
    @Bean
    @Primary
    @ConfigurationProperties(prefix = "datasource.sampleapp")
    public DataSourceProperties dataSourceProperties() {
        return new DataSourceProperties();
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
     * 读取 hibernate 相关配置
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
}
```

## 4 集成 Swagger

Swagger 用于将 RESTful api 提供一个可视化，可调试的页面，便于开发和测试

- maven 依赖如下

```xml
<!-- swagger2 相关 -->
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger2</artifactId>
    <version>${swagger2.version}</version>
</dependency>

<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger-ui</artifactId>
    <version>${swagger2.version}</version>
</dependency>

<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-annotations</artifactId>
</dependency>

<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
</dependency>

<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-core</artifactId>
</dependency>
<!-- swagger2 相关 -->
```

- Swagger 配置类

```java
import io.swagger.annotations.Api;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import springfox.documentation.builders.ApiInfoBuilder;
import springfox.documentation.builders.PathSelectors;
import springfox.documentation.builders.RequestHandlerSelectors;
import springfox.documentation.service.ApiInfo;
import springfox.documentation.spi.DocumentationType;
import springfox.documentation.spring.web.plugins.Docket;
import springfox.documentation.swagger2.annotations.EnableSwagger2;

@Configuration
@EnableSwagger2
public class SwaggerConfig {

	@Bean
	public Docket api() {
		return new Docket(DocumentationType.SWAGGER_2).select()
				.apis(RequestHandlerSelectors.withClassAnnotation(Api.class))
				.paths(PathSelectors.any()).build()
				.apiInfo(apiInfo());
	}

	private ApiInfo apiInfo() {
		return new ApiInfoBuilder().title("api 标题").description("api 描述").version("1.0.0")
				.termsOfServiceUrl("http://ckjava.com").license("MIT")
				.licenseUrl("http://ckjava.com").build();
	}
}
```

- WebAppConfig 用于配置 swagger-ui.html 页面的访问地址， swagger-ui.html 这页面是通过 Maven 依赖引入的，在系统中的实际路径是：`classpath:/META-INF/resources/swagger-ui.html`, 通过映射，可以通过 `http://host:ip/contextPath/swagger-ui.html` 访问到。

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;

@Configuration
public class WebAppConfig extends WebMvcConfigurerAdapter {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        /**
         * 自动将 `src\main\resources\webStatic` 目录的文件映射到 /**
         * /** 表示匹配任意层级的目录和文件
         */
        //registry.addResourceHandler(new String[]{"/**"}).addResourceLocations("classpath:/webStatic/").setCacheControl(CacheControl.noCache());

        registry.addResourceHandler("swagger-ui.html").addResourceLocations("classpath:/META-INF/resources/");
        registry.addResourceHandler("/webjars/**").addResourceLocations("classpath:/META-INF/resources/webjars/");
    }

}
```

## 5 业务开发

具体的业务开发分为业务实体定义，业务逻辑以及web 接口。

#### 5.1 业务实体定义 domain

- 定义实体基类 BaseJpaEntity，包含了基本的字段

```java
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.annotations.ApiModelProperty;
import org.springframework.format.annotation.DateTimeFormat;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Date;
import java.util.Map;

@MappedSuperclass
public abstract class BaseJpaEntity implements Serializable {

    public static final String DEL_YES = "1";
    public static final String DEL_NO = "0";

    @Id
    @GeneratedValue(strategy= GenerationType.IDENTITY)
    protected Long id;

    @Column(name="create_date")
    @ApiModelProperty("创建时间")
    @JsonFormat(timezone = "GMT+08", pattern = "yyyy-MM-dd HH:mm:ss") // 返回格式化的字符串
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") // 接收格式化的字符串，转为Date类型对象
    protected Date createDate;

    @Column(name="create_user", length = 64)
    @ApiModelProperty("创建人")
    protected String createUser;

    @Column(name="update_date")
    @ApiModelProperty("更新时间")
    @JsonFormat(timezone = "GMT+08", pattern = "yyyy-MM-dd HH:mm:ss") // 返回格式化的字符串
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") // 接收格式化的字符串，转为Date类型对象
    protected Date updateDate;

    @Column(name="update_user", length = 64)
    @ApiModelProperty("更新人")
    protected String updateUser;

    @Column(name="del_flag", length = 1)
    @ApiModelProperty("删除标识")
    protected String delFlag;

    @ApiModelProperty(hidden = true, value = "排序字段")
    protected transient String orderBy;

    @ApiModelProperty(hidden = true, value = "排序方式 ")
    protected transient Boolean desc;

    @ApiModelProperty(hidden = true, value = "起始行数")
    protected transient Integer start;

    @ApiModelProperty(hidden = true, value = "每页数据大小")
    protected transient Integer pageSize;

    @ApiModelProperty(hidden = true, value = "查询条件")
    protected transient Map<String, String> conditionMap;
    
    // 忽略 get/set 构造函数
}
```

- 定义 Task 实体类，继承 BaseJpaEntity

```java
import com.ckjava.test.domain.base.BaseJpaEntity;
import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.annotations.ApiModelProperty;
import org.hibernate.validator.constraints.NotEmpty;
import org.springframework.format.annotation.DateTimeFormat;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Date;

@Entity
@Table(name="task")
public class Task extends BaseJpaEntity implements Serializable {

    @NotEmpty
    @Column(name="name", length = 255)
    @ApiModelProperty("任务名称")
    private String name;

    @Column(name="date")
    @JsonFormat(timezone = "GMT+08", pattern = "yyyy-MM-dd HH:mm:ss") // 返回格式化的字符串
    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") // 接收格式化的字符串，转为Date类型对象
    @ApiModelProperty("所属日期")
    private Date date;

    @Column(name="content", length = 2000)
    @ApiModelProperty("具体内容")
    private String content;

    // 忽略 get/set 构造函数
}
```

- 定义分页参数对象 PageParamer, 用于处理前端传过来的 分页参数，查询条件，排序等字段

```java
import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

import java.util.Map;

/**
 * 分页参数对象
 */
@ApiModel("分页参数对象")
public class PageParamer {

    @ApiModelProperty("排序对象")
    private Sort sort;

    @ApiModelProperty("字段搜索对象")
    private Search search;

    @ApiModelProperty("分页导航条对象")
    private Pagination pagination;

    public Sort getSort() {
        return sort;
    }

    public void setSort(Sort sort) {
        this.sort = sort;
    }

    public Search getSearch() {
        return search;
    }

    public void setSearch(Search search) {
        this.search = search;
    }

    public Pagination getPagination() {
        return pagination;
    }

    public void setPagination(Pagination pagination) {
        this.pagination = pagination;
    }

    /**
     * 排序对象
     */
    @ApiModel("排序对象")
    public class Sort {
        @ApiModelProperty("排序字段")
        private String predicate;

        @ApiModelProperty("是否倒序")
        private boolean reverse;

        public String getPredicate() {
            return predicate;
        }

        public void setPredicate(String predicate) {
            this.predicate = predicate;
        }

        public boolean isReverse() {
            return reverse;
        }

        public void setReverse(boolean reverse) {
            this.reverse = reverse;
        }

        public Sort() {
        }

        public Sort(String predicate, boolean reverse) {
            this.predicate = predicate;
            this.reverse = reverse;
        }
    }

    /**
     * 字段搜索对象
     */
    @ApiModel("字段搜索对象")
    public class Search {

        @ApiModelProperty("关键字段")
        private Map<String, String> predicateObject;

        public Map<String, String> getPredicateObject() {
            return predicateObject;
        }

        public void setPredicateObject(Map<String, String> predicateObject) {
            this.predicateObject = predicateObject;
        }

        public Search() {
        }

        public Search(Map<String, String> predicateObject) {
            this.predicateObject = predicateObject;
        }
    }

    /**
     * 分页导航条对象
     */
    @ApiModel("分页导航条对象")
    public class Pagination {

        @ApiModelProperty("起始行")
        private Integer start;

        @ApiModelProperty("总记录数")
        private Integer totalItemCount;

        @ApiModelProperty("每页记录数")
        private Integer number;

        @ApiModelProperty("总页数")
        private Integer numberOfPages;

        public Integer getStart() {
            return start;
        }

        public void setStart(Integer start) {
            this.start = start;
        }

        public Integer getTotalItemCount() {
            return totalItemCount;
        }

        public void setTotalItemCount(Integer totalItemCount) {
            this.totalItemCount = totalItemCount;
        }

        public Integer getNumber() {
            return number;
        }

        public void setNumber(Integer number) {
            this.number = number;
        }

        public Integer getNumberOfPages() {
            return numberOfPages;
        }

        public void setNumberOfPages(Integer numberOfPages) {
            this.numberOfPages = numberOfPages;
        }

        public Pagination() {
        }

        public Pagination(Integer start, Integer totalItemCount, Integer number, Integer numberOfPages) {
            this.start = start;
            this.totalItemCount = totalItemCount;
            this.number = number;
            this.numberOfPages = numberOfPages;
        }
    }

    public PageParamer() {
    }

    public PageParamer(Sort sort, Search search, Pagination pagination) {
        this.sort = sort;
        this.search = search;
        this.pagination = pagination;
    }
}
```

#### 5.2 业务逻辑 service

1. BaseJpaCrudService 泛型基类
    - 通过封装 EntityManager 对象和泛型来定义 BaseJpaCrudService 对象，做到通用化
    - 增加 `@Transactional(readOnly = true)`，子类所有的方法默认没有事务，`@Transactional` 是可继承的

```java
import com.ckjava.test.domain.base.BaseJpaEntity;
import com.ckjava.xutils.Constants;
import com.ckjava.xutils.http.Page;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.TypedQuery;
import java.util.*;

@Transactional(readOnly = true)
public abstract class BaseJpaCrudService<E extends BaseJpaEntity> implements Constants {

    @PersistenceContext
    private EntityManager entityManager;

    public abstract Class<E> getClassType();

    /**
     * 根据 id 查询一个对象
     * @param id
     * @return
     */
    public E get(Long id) {
        return entityManager.find(getClassType(), id);
    }

    /**
     * 获取所有
     * @return
     */
    public List<E> findAll() {
        List<E> dataList = new ArrayList<>();
        try {
            dataList = entityManager.createQuery( "from " + getClassType().getName(), getClassType()).getResultList();
        } catch (Exception e) {
            e.printStackTrace();
        }

        return dataList;
    }

    /**
     * 分页获取数据
     * @param e
     * @return
     */
    public Page<E> getPage(E e) {
        StringBuilder qlString = new StringBuilder();
        qlString.append("from " + getClassType().getName());
        qlString.append(" where 1=1 ");

        Map<String, String> conditionMap = e.getConditionMap();
        for (Iterator<Map.Entry<String, String>> it = conditionMap.entrySet().iterator(); it.hasNext();) {
            Map.Entry<String, String> entry = it.next();
            // key name, value like,张三
            // key age, value =,10

            String key = entry.getKey();
            String value = entry.getValue();
            String op = value.split(SPLITER.COMMA)[0];
            qlString.append(" and " + key + " " + op + " :" + key); // name LIKE :name 或者 age = :age
        }

        qlString.append(" order by :desc ");

        TypedQuery<E> typedQuery = entityManager.createQuery(qlString.toString(), getClassType())
                .setParameter("desc", e.getDesc())
                .setFirstResult(e.getStart())
                .setMaxResults(e.getPageSize());

        for (Iterator<Map.Entry<String, String>> it = conditionMap.entrySet().iterator(); it.hasNext();) {
            Map.Entry<String, String> entry = it.next();
            String key = entry.getKey();
            String value = entry.getValue();
            String valued = value.split(SPLITER.COMMA)[1];
            typedQuery.setParameter(key, valued);
        }

        return new Page<>(e.getStart(), e.getPageSize(), typedQuery.getMaxResults(), typedQuery.getResultList());
    }

    @Transactional
    public void saveOrUpdate(E e) {
        if (e.getId() == null) {
            save(e);
        } else {
            update(e);
        }
    }

    @Transactional
    public void save(E e) {
        e.setDelFlag(E.DEL_NO);
        e.setCreateDate(new Date());
        entityManager.persist(e);
    }

    @Transactional
    public E update(E e) {
        e.setUpdateDate(new Date());
        return entityManager.merge(e);
    }

    @Transactional
    public void delete(E e) {
        e.setDelFlag(E.DEL_YES);
        update(e);
    }

    @Transactional
    public void delete(Long id) {
        E e = get(id);
        delete(e);
    }

}
```

2. TaskService 实现如下

```java
import com.ckjava.test.domain.Task;
import com.ckjava.test.service.base.BaseJpaCrudService;
import org.springframework.stereotype.Service;

import javax.transaction.Transactional;

@Service
@Transactional
public class TaskService extends BaseJpaCrudService<Task> {

    @Override
    public Class<Task> getClassType() {
        return Task.class;
    }
}
```

#### 5.3 web 接口 RESTful api

1. CorsController 抽象类: 通过 `@CrossOrigin` 注解使 RESTful api 可以跨域访问

```java
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RequestMethod;

@CrossOrigin(
        origins = "*",
        allowedHeaders = "*",
        allowCredentials = "true",
        methods = {RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, RequestMethod.DELETE, RequestMethod.OPTIONS, RequestMethod.HEAD}
)
public abstract class CorsController {
}
```

2. BaseJpaCrudController 泛型抽象基类，继承 CorsController，并通过泛型做到通用化

```java
import com.ckjava.test.domain.base.BaseJpaEntity;
import com.ckjava.test.service.base.BaseJpaCrudService;
import com.ckjava.xutils.Constants;
import com.ckjava.xutils.http.HttpResponse;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Api
public abstract class BaseJpaCrudController<S extends BaseJpaCrudService, E extends BaseJpaEntity> extends CorsController implements Constants {

    @Autowired
    public S service;

    @ApiOperation("根据 id 获取一个对象")
    @GetMapping("/{id}")
    public HttpResponse<Object> get(
            @PathVariable Long id) {
        return HttpResponse.getReturn(service.get(id), HttpResponse.SUCCESS, null);
    }

    @ApiOperation("获取所有的对象")
    @GetMapping(value = "/all")
    public HttpResponse<List<E>> findAll() {
        return HttpResponse.getReturn(service.findAll(), HttpResponse.SUCCESS, null);
    }

    @ApiOperation("保存或者修改一个对象")
    @PostMapping
    public HttpResponse<String> saveOrUpdate(
            @RequestBody E e) {
        service.saveOrUpdate(e);
        return HttpResponse.getReturn(HttpResponse.SUCCESS, HttpResponse.SUCCESS, null);
    }

    @ApiOperation("根据 id 删除一个对象")
    @DeleteMapping("/{id}")
    public HttpResponse delete(
            @PathVariable Long id) {
        service.delete(id);
        return HttpResponse.getReturn(null, HttpResponse.SUCCESS, null);
    }
}
```

3. TaskController 实现类，这里只提供分页方法，其他 CRUD 接口自动继承

```java
import com.alibaba.fastjson.JSONObject;
import com.ckjava.test.domain.PageParamer;
import com.ckjava.test.domain.Task;
import com.ckjava.test.service.TaskService;
import com.ckjava.test.web.base.BaseJpaCrudController;
import com.ckjava.xutils.http.HttpResponse;
import com.ckjava.xutils.http.Page;
import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import io.swagger.annotations.ApiParam;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Api
@RestController
@RequestMapping(value = "/api/task", produces = "application/json;charset=utf-8")
public class TaskController extends BaseJpaCrudController<TaskService, Task> {

    @ApiOperation("分页获取数据")
    @GetMapping(value = "page")
    public HttpResponse<Page<Task>> page(
            @ApiParam("{\n" +
                    "    \"sort\": {\n" +
                    "        \"predicate\": \"id\",\n" +
                    "        \"reverse\": true\n" +
                    "    },\n" +
                    "    \"search\": {\n" +
                    "        \"predicateObject\": {\n" +
                    "            \"name\": \"like,test\"\n" +
                    "        }\n" +
                    "    },\n" +
                    "    \"pagination\": {\n" +
                    "        \"start\": 1,\n" +
                    "        \"totalItemCount\": 0,\n" +
                    "        \"number\": 10,\n" +
                    "        \"numberOfPages\": 2\n" +
                    "    }" +
                    " }\n" +
                    "对于 predicateObject 中的参数，如果 activity=false, 传参为： \"activity\": \"=,false\"，" +
                    "如果 activity like '%false%', 传参为 \"activity\": \"like,false\"" +
                    "}")
            @RequestParam String params) {
        try {

            PageParamer pageParamer = JSONObject.parseObject(params, PageParamer.class);

            Task task = new Task();

            // 排序
            task.setOrderBy(pageParamer.getSort().getPredicate());
            task.setDesc(pageParamer.getSort().isReverse());

            // 查询字段
            task.setConditionMap(pageParamer.getSearch().getPredicateObject());

            // 分页导航
            task.setStart(pageParamer.getPagination().getStart());
            task.setPageSize(pageParamer.getPagination().getNumber());

            return HttpResponse.getReturn(service.getPage(task), HttpResponse.SUCCESS, null);
        } catch (Exception e) {
            e.printStackTrace();
            return HttpResponse.getReturn(null, HttpResponse.EXCEPTION, null);
        }

    }
}
```

## 6 完整的 pom

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.ckjava</groupId>
    <artifactId>spring-boot-jpa-test</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>spring-boot-jpa-test</name>
    <url>http://ckjava.com</url>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
        <java.version>1.8</java.version>
        <swagger2.version>2.5.0</swagger2.version>
    </properties>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.5.15.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>

    <dependencies>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- Test -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

        <!-- swagger2 相关 -->
        <dependency>
            <groupId>io.springfox</groupId>
            <artifactId>springfox-swagger2</artifactId>
            <version>${swagger2.version}</version>
        </dependency>

        <dependency>
            <groupId>io.springfox</groupId>
            <artifactId>springfox-swagger-ui</artifactId>
            <version>${swagger2.version}</version>
        </dependency>

        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-annotations</artifactId>
        </dependency>

        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-databind</artifactId>
        </dependency>

        <dependency>
            <groupId>com.fasterxml.jackson.core</groupId>
            <artifactId>jackson-core</artifactId>
        </dependency>
        <!-- swagger2 相关 -->

        <!-- jpa -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        <!-- jpa -->

        <!-- Add Hikari Connection Pooling support -->
        <dependency>
            <groupId>com.zaxxer</groupId>
            <artifactId>HikariCP</artifactId>
        </dependency>
        <!-- Add Hikari Connection Pooling support -->

        <!-- freemarker -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-freemarker</artifactId>
        </dependency>
        <!-- freemarker -->

        <!-- mysql -->
        <dependency>
            <groupId>mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
        </dependency>
        <!-- mysql -->

        <!-- h2 -->
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <version>1.4.199</version>
        </dependency>
        <!-- h2 -->

        <dependency>
            <groupId>com.ckjava</groupId>
            <artifactId>xutils</artifactId>
            <version>1.0.3</version>
        </dependency>

    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```