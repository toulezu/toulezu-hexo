---
title: WebJars 的介绍以及在 SpringBoot 中的使用
title_url: SpringBoot-webjars-usage
date: 2019-02-22
tags: [SpringBoot,webjars]
categories: SpringBoot
description: 本文介绍了 WebJars 的相关功能以及和 SpringBoot 集成的一个例子。
---

## 概要

简单来说，WebJars 就是将 web 依赖（js，css）放到 jar 文件中，然后通过 Maven 的形式依赖到项目中，避免手工下载这些依赖。从纯前端角度来说，依赖管理有 npm, Bower, 后端有 Maven, Gradle，WebJars 就是让 web 依赖能够运行在后端 Jvm 上的技术。

像 Bootstrap, jQuery, Angular JS, Chart.js 等都在 [webjars 官网](https://www.webjars.org/) 上可以找到。

## 为什么使用 WebJars？

显而易见，因为简单。但不仅是依赖这么简单：

- 清晰的管理 web 依赖
- 通过 Maven, Gradle 等项目管理工具就可以下载 web 依赖
- 解决 web 组件中传递依赖的问题以及版本问题
- 页面依赖的版本自动检测功能

## Maven 依赖

在 Maven 中通过下面的依赖就可以将 bootstrap 和 jquery 引入到项目中。

```
<dependency>
    <groupId>org.webjars</groupId>
    <artifactId>bootstrap</artifactId>
    <version>3.3.7-1</version>
</dependency>
<dependency>
    <groupId>org.webjars</groupId>
    <artifactId>jquery</artifactId>
    <version>3.1.1</version>
</dependency>
```

依赖导入了，这些 js 和 css 文件都在 classPath 路径下的 `META-INF/resources/webjars` 目录下。

- 在 SpringMVC 中通过实现 WebMvcConfigurer 接口来定义这些静态文件的访问入口，具体如下

```
@Configuration
public class WebConfig implements WebMvcConfigurer {
 
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry
            .addResourceHandler("/webjars/**")
            .addResourceLocations("classpath:/META-INF/resources/webjars/");
    }
}
```

- xml 方式类似的配置如下

```
<mvc:resources mapping="/webjars/**" location="classpath:/META-INF/resources/webjars/" />
```

- 如果使用 SpringBoot，上面的配置也可以忽略，系统自动将 `/META-INF/resources/webjars` 映射到 `/webjars` 请求路径上。

## 自动检测依赖的版本

如果使用 Spring 4.2 以上的版本，并且加入 webjars-locator 组件，就不需要在 html 添加依赖的时候填写版本。

```
<dependency>
    <groupId>org.webjars</groupId>
    <artifactId>webjars-locator</artifactId>
    <version>0.30</version>
</dependency>
```

之前是 

```
<script src="/webjars/bootstrap/3.3.7-1/js/bootstrap.min.js"></script>
```

引入 webjars-locator 后是

```
<script src="/webjars/bootstrap/js/bootstrap.min.js"></script>
```

**注意：只能去掉版本号**

## 前端页面使用

编写 index.html 如下，将其放到 `src\main\resources\public\index.html` 目录下，启动项目，访问 `http://localhost:8080/` 即可看到效果。

```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>webjars 测试</title>

    <!--<script src="/webjars/jquery/3.1.1/jquery.min.js"></script>
    <script src="/webjars/bootstrap/3.3.7-1/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="/webjars/bootstrap/3.3.7-1/css/bootstrap.min.css" />-->

    <script src="/webjars/jquery/jquery.min.js"></script>
    <script src="/webjars/bootstrap/js/bootstrap.min.js"></script>

    <link rel="stylesheet" href="/webjars/bootstrap/css/bootstrap.min.css" />

</head>
<body>

    <div class="container"><br/>
        <div class="alert alert-success">
            <a href="#" class="close" data-dismiss="alert" aria-label="close">×</a>
            <strong>Success!</strong> It is working as we expected.
        </div>
    </div>
</body>
</html>
```

由于 SpringBoot 自动将 classpath 下的 `/static`, `/public`, `/resources`, `/META-INF/resources` 这些目录自动映射到 `/**` 请求路径上，因此访问 `http://localhost:8080/` 就可以找到 `public\index.html`。

## 代码

- [spring-boot-webjars](https://gitee.com/toulezucom/spring-boot-learning/tree/master/spring-boot-webjars)

## 总结

本文介绍了 WebJars 的相关功能以及和 SpringBoot 集成的一个例子。

## 参考

- [Introduction to WebJars](https://www.baeldung.com/maven-webjars)
- [webjar doc](https://www.webjars.org/documentation)
