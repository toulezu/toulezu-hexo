---
title: Java Servlet 中两种重定向 forward 和 sendRedirect 的区分
title_url: Java-Servlet-sendRedirect-forward
date: 2019-04-25
tags: [Java,Servlet]
categories: Java
description: Java Servlet 中两种重定向 forward 和 sendRedirect 的区分
---

## 1 示例代码

```java
@RequestMapping(value = "/", method = RequestMethod.GET, produces = "text/plain;charset=UTF-8")
public void index(HttpServletRequest request, HttpServletResponse response) throws Exception {
    //request.getRequestDispatcher("/swagger-ui.html").forward(request, response);
    response.sendRedirect("/swagger-ui.html");
}
```

## 2 forward

简单来说：浏览器想请求 /a 的资源，但是服务器不告知浏览器真正的资源在 /b，直接将 /b 的内容返回给浏览器。

- 服务器将 url 的资源直接解析后返回给浏览器
- 属于服务器内部跳转，浏览器地址栏的 url 不会发生变化
- 浏览器一共进行了一次请求

## 3 sendRedirect

简单来说：浏览器想请求 /a 的资源，但是服务器告知真实的资源在 /b 那里，随后浏览器又去请求 /b 的资源。

关键点如下：

- 服务器将 url 告知浏览器，浏览器随后再次请求 url，
- 浏览器地址栏的 url 会发生变化
- 服务器响应码为 302，Response Headers 的具体内容如下

```
HTTP/1.1 302
Location: http://localhost:8011/swagger-ui.html
Content-Length: 0
Date: Sun, 16 Dec 2018 03:57:12 GMT
```

- 浏览器一共进行了两次请求