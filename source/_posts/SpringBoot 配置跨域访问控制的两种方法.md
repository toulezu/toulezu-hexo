---
title: SpringBoot 配置跨域访问控制的两种方法
title_url: SpringBoot-CORS-practice
date: 2019-03-05
tags: SpringBoot
categories: 技术
description: SpringBoot 配置跨域访问控制的两种方法
---

## 跨域访问概念

CORS（Cross Origin Resource Sharing）跨域资源共享：表示 JavaScript 代码所在的机器和后端 api 所在的机器不是同一台的情况下实现资源访问。

在前后端分离的项目中，前端一般是 SPA （Single Page Application）类型的应用，所有的 JavaScript 代码都会“下载”到用户机器的浏览器中，后端 api 在服务器端以单个机器或者集群的形式存在。

## 同源策略

>同源策略限制了从同一个源加载的文档或脚本如何与来自另一个源的资源进行交互。这是一个用于隔离潜在恶意文件的重要安全机制。

由于浏览器的同源策略限制，在前后端分离的项目中必须要考虑这个问题，否则会出现以下错误：

```
Access to XMLHttpRequest at 'http://localhost:8081/api' from origin 'http://localhost:3000' has been blocked by CORS policy: Response to preflight request doesn't pass access control check: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## HTTP OPTIONS 请求

跨域请求时候首先通过 `OPTIONS` 方法和请求头中的 `Access-Control-Request-Method` 属性向服务器端查看是否有请求权限，如果有权限才能继续请求到数据，否则出现上面的错误。有权限时服务器 `OPTIONS` 请求的响应头基本内容如下

```
Access-Control-Allow-Credentials: *
Access-Control-Allow-Headers: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, HEAD
Access-Control-Allow-Origin: *
```

## 在 SpringBoot 中实现跨域访问的方法

#### 方法1：通过 Filter 设置通用的响应头

- 新建 Filter

```java
import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletResponse;

public class CorsFilter implements Filter {
	@Override
	public void init(FilterConfig filterConfig) throws ServletException {

	}

	@Override
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
			throws IOException, ServletException {
		
		HttpServletResponse httpServletResponse = (HttpServletResponse) response;
		httpServletResponse.setHeader("Access-Control-Allow-Origin", "*");
		httpServletResponse.setHeader("Access-Control-Allow-Headers","User-Agent,Origin,Cache-Control,Content-type,Date,Server,withCredentials,AccessToken,username,offlineticket,Authorization");
		httpServletResponse.setHeader("Access-Control-Allow-Credentials", "true");
		httpServletResponse.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, HEAD");
		
		chain.doFilter(request, response);
	}

	@Override
	public void destroy() {
	}

}
```

- 配置 Filter

```java
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;

import com.ctrip.payment.filter.CorsFilter;

@Configuration
public class WebAppConfig extends WebMvcConfigurerAdapter {

	@Override
	public void addResourceHandlers(ResourceHandlerRegistry registry) {
		registry.addResourceHandler("swagger-ui.html").addResourceLocations("classpath:/META-INF/resources/");
		registry.addResourceHandler("/webjars/**").addResourceLocations("classpath:/META-INF/resources/webjars/");
	}
	
	/**
	 * 注册 cors filter
	 * @return
	 */
	@Bean
	public FilterRegistrationBean someFilterRegistration() {
	    FilterRegistrationBean registration = new FilterRegistrationBean();
	    registration.setFilter(new CorsFilter());
	    registration.addUrlPatterns("/api/*");
	    registration.setName("corsFilter");
	    registration.setOrder(1);
	    return registration;
	}

}
```

#### 方法2：通过 `@CrossOrigin` 注解

在 Controller 类上使用如下

```
@Api
@RestController
@RequestMapping(value = "/api")
@CrossOrigin(
        origins = "*",
        allowedHeaders = "*",
        allowCredentials = "true",
        methods = {RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, RequestMethod.DELETE, RequestMethod.OPTIONS, RequestMethod.HEAD}
)
public class UserController {
}
```

- spring 4.2 以上的版本才有
- 不仅作用于类上，也可以用在方法上，支持让类中的某个方法可以跨域请求，**并且方法的配置会重置类上的配置**
- 参数说明
    - maxAge: 配置响应头的 `Access-Control-Max-Age`
    - origins： 配置响应头的 `Access-Control-Allow-Origin`，`*` 表示允许所有的请求源
    - allowedHeaders： 配置响应头的 `Access-Control-Allow-Headers`, `*` 表示允许所有的请求头
    - exposedHeaders: 配置响应头的 `Access-Control-Expose-Headers`，表示允许对应的 user-agent 设置
    - methods：表示支持的请求方法，配置：`{RequestMethod.GET, RequestMethod.POST}`
    - allowCredentials: 配置响应头的 `Access-Control-Allow-Credentials`， 表示浏览器请求的时候是否需要带上相关的 cookie
        - 如果设置为 "", 表示 undefined，需要包含相关的 cookie
        - 如果设置为 false, 表示不需要包含相关的 cookie
        - 如果设置为 true, 表示需要包含相关的 cookie

#### CorsFilter 和 `@CrossOrigin` 对比

- `@CrossOrigin` 注解在 spring 4.2 以上的版本才有
- 如果有多个 Controller 类，可以新建一个类，加上 `@CrossOrigin` 注解，其他 Controller 继承该类即可，具体如下

```
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.RequestMethod;

@CrossOrigin(
        origins = "*",
        allowedHeaders = "*",
        allowCredentials = "true",
        methods = {RequestMethod.GET, RequestMethod.POST, RequestMethod.PUT, RequestMethod.DELETE, RequestMethod.OPTIONS, RequestMethod.HEAD}
)
public class CorsBase {
}
```

然后 UserController 继承 CorsBase

```
@Api
@RestController
@RequestMapping(value = "/api")
public class UserController extends CorsBase {
}
```

## 总结

本文核心的内容如下

- 跨域访问基本概念
- 浏览器同源策略以及 HTTP OPTIONS 请求
- 在 SpringBoot 中实现跨域访问的方法：Filter 和 `@CrossOrigin` 注解
- 在 SpringBoot 中如何配置 Filter
- `@CrossOrigin` 注解的使用