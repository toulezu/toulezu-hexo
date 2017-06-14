---
title: Swagger2 在 SpringMVC 项目中的应用
title_url: Swagger2-SpringMVC
date: 2017-06-14
tags: [Swagger2,SpringMVC]
categories: 技术
description: Swagger2 在 SpringMVC 项目中的应用
---

## 添加 Maven 依赖

```xml
<dependency>
	<groupId>io.springfox</groupId>
	<artifactId>springfox-swagger2</artifactId>
	<version>2.5.0</version>
</dependency> 
<dependency>
	<groupId>io.springfox</groupId>
	<artifactId>springfox-swagger-ui</artifactId>
	<version>2.5.0</version>
</dependency>
```

springfox 的相关仓库地址如下

- Release

```xml
<repositories>
    <repository>
      <id>jcenter-Release</id>
      <name>jcenter</name>
      <url>https://jcenter.bintray.com/</url>
    </repository>
</repositories>
```

- Snapshots

```xml
<repositories>
    <repository>
      <id>jcenter-snapshots</id>
      <name>jcenter</name>
      <url>http://oss.jfrog.org/artifactory/oss-snapshot-local/</url>
    </repository>
</repositories>
```

## 添加 SwaggerConfig 配置类

```java
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import com.ckjava.test.web.ApiController;

import io.swagger.annotations.Api;
import springfox.documentation.builders.ApiInfoBuilder;
import springfox.documentation.builders.PathSelectors;
import springfox.documentation.builders.RequestHandlerSelectors;
import springfox.documentation.service.ApiInfo;
import springfox.documentation.spi.DocumentationType;
import springfox.documentation.spring.web.plugins.Docket;
import springfox.documentation.swagger2.annotations.EnableSwagger2;

@Configuration
@EnableWebMvc
@EnableSwagger2
/* @ComponentScan(basePackageClasses = { ApiController.class }) */
@ComponentScan(basePackages = "com.ckjava.test.web")
public class SwaggerConfig {

    @Bean
    public Docket api(){
        return new Docket(DocumentationType.SWAGGER_2)
            .select()
            .apis(RequestHandlerSelectors.withClassAnnotation(Api.class))
            .paths(PathSelectors.any())
            .build()
            .apiInfo(apiInfo());
    }

    private ApiInfo apiInfo() {
        return new ApiInfoBuilder()
            .title("TITLE")
            .description("DESCRIPTION")
            .version("VERSION")
            .termsOfServiceUrl("http://terms-of-services.url")
            .license("LICENSE")
            .licenseUrl("http://url-to-license.com")
            .build();
    }

}
```

- 其中 `@ComponentScan(basePackages = "com.ckjava.test.web")` 指出 `@Controller` 类所在的包名.
- 也可以通过 `@ComponentScan(basePackageClasses = { ApiController.class })` 指出具体的 `@Controller` 类
- 其中 `RequestHandlerSelectors.withClassAnnotation(Api.class)` 指出只扫描带有 `io.swagger.annotations.Api` 注解的类

- WebAppConfig 配置类用于配置展示 Swagger 的 UI, 具体如下

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;

@Configuration
@EnableWebMvc
public class WebAppConfig extends WebMvcConfigurerAdapter {

    @Override 
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("swagger-ui.html").addResourceLocations("classpath:/META-INF/resources/");
        registry.addResourceHandler("/webjars/**").addResourceLocations("classpath:/META-INF/resources/webjars/");
    }

}
```

- 等项目启动后可以通过 `http://myapp/swagger-ui.html` 访问到开放的API

## 可能遇到的问题

- 项目启动中遇到 `java.lang.NoClassDefFoundError: com/fasterxml/classmate/members/ResolvedParameterizedMember` 异常

原因如下:
由于在 springfox-swagger2 中依赖了 classmate-1.3.1.jar 而项目中使用了 hibernate-validator 其中又依赖了 classmate-1.0.0.jar,需要在 hibernate-validator 排除 classmate 依赖

解决如下:
```xml
<dependency>
	<groupId>org.hibernate</groupId>
	<artifactId>hibernate-validator</artifactId>
	<version>${validator.version}</version>
	<exclusions>
		<exclusion>
			<groupId>com.fasterxml</groupId>
			<artifactId>classmate</artifactId>
		</exclusion>
	</exclusions>
</dependency>
```

## 参考

- [A 'simple' way to implement Swagger in a Spring MVC application](https://stackoverflow.com/questions/26720090/a-simple-way-to-implement-swagger-in-a-spring-mvc-application)
- [springfox docs](http://springfox.github.io/springfox/docs/current/)
