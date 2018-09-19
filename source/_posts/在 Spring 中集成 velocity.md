---
title: 在 Spring 中集成 velocity
title_url: Spring-SpringMVC-integration-velocity-practice
date: 2018-09-19
tags: [模板技术,velocity]
categories: [模板技术,velocity]
description: 在 Spring 或者 SpringMVC 中集成 velocity 的方法
---

## 在 SpringMVC 项目中集成 velocity

这种方式的话 velocity 的所有配置都在 xml 文件中。

### 1. 在 pom.xml 中引入 velocity 的 jar 包

```xml
<!-- velocity核心包 -->
<dependency>
    <groupId>org.apache.velocity</groupId>
    <artifactId>velocity-tools</artifactId>
    <version>2.0</version>
</dependency>
<!-- velocity核心包 -->
```

### 2. 视图配置

在 `springMVC-servlet.xml` 文件中配置, 这里使用 VelocityLayoutViewResolver 对象, 需要默认的布局文件.

```xml
<!-- 视图模式配置,velocity配置文件 -->
<bean id="velocityConfig" class="org.springframework.web.servlet.view.velocity.VelocityConfigurer">
    <property name="resourceLoaderPath" value="/WEB-INF/velocity/"/>
    <property name="configLocation" value="classpath:velocity.properties"/>
</bean>

<!-- 配置后缀
默认 VelocityViewResolver 就可以了,如果需要使用 layout 功能, 需要使用 VelocityLayoutViewResolver
-->
<bean id="velocityViewResolver" class="org.springframework.web.servlet.view.velocity.VelocityLayoutViewResolver">
    <property name="suffix" value=".vm" /><!-- 视图文件的后缀名 -->
    <property name="toolboxConfigLocation" value="/WEB-INF/velocity/tools.xml" /><!--toolbox配置文件路径-->
    <property name="dateToolAttribute" value="date" /><!--日期函数名称-->
    <property name="numberToolAttribute" value="number" /><!--数字函数名称-->
    <property name="contentType" value="text/html;charset=UTF-8" />
    <property name="exposeSpringMacroHelpers" value="true" /><!--是否使用spring对宏定义的支持-->
    <property name="exposeRequestAttributes" value="true" /><!--是否开放request属性-->
    <property name="requestContextAttribute" value="rc"/><!--request属性引用名称-->
    <property name="exposeSessionAttributes" value="true" />
    <property name="layoutUrl" value="layout/default.vm"/><!--指定layout文件-->
    <property name="order" value="1" />
</bean>
```

### 3. 配置 velocity.properties

`velocity.properties` 和 `springMVC-servlet.xml` 文件都在 `src/main/resources` 目录下,

velocity.properties 内容如下

```
#encoding
input.encoding=UTF-8
output.encoding=UTF-8
#autoreload when vm changed
file.resource.loader.cache=false
file.resource.loader.modificationCheckInterval=2
velocimacro.library.autoreload=false
```

### 4. 页面布局 layout 的使用 

系统默认布局文件 `default.vm` 具体如下

```
<html>
<head>
    <title>Spring MVC and Velocity</title>
    #*<link rel="stylesheet" href="" media="all" type="text/css">*#
    <script src="#springUrl('/plugins/jQuery/jquery-2.2.3.min.js')"></script>
</head>
<body>
<div align="center">
    <table class="tabellaLayout">
        <tr>
            <td>
                <div align="center">#parse("layout/header.vm")</div>
            </td>
        </tr>
        <tr>
            <td>
                <div align="center">$screen_content</div>
            </td>
        </tr>
        <tr>
            <td>
                <div align="center">#parse("layout/footer.vm")</div>
            </td>
        </tr>
    </table>
</div>
</body>
</html>
```

### 5. 配置 tools.xml 

tools.xml 是 velocity 中 VelocityToolboxView 对象的配置文件，如果没有这个文件系统也不会初始化这个对象。文件默认位于项目的 `/WEB-INF/` 目录下。

具体内容如下

```xml
<?xml version="1.0" encoding="UTF-8"?>
<toolbox>
    <tool>
        <key>mathTool</key>
        <scope>application</scope>
        <class>org.apache.velocity.tools.generic.MathTool</class>
    </tool>
    <tool>
        <key>numberTool</key>
        <scope>application</scope>
        <class>org.apache.velocity.tools.generic.NumberTool</class>
        <parameter name="format" value="#0.00"/> <!--2-->
        <parameter name="locale" value="zh_CN"/> <!--3-->
    </tool>
    <tool>
        <key>dateTool</key>
        <scope>application</scope>
        <class>org.apache.velocity.tools.generic.DateTool</class>
        <parameter name="format" value="yyyy/MM/dd HH:mm:ss"/> <!--2-->
        <parameter name="locale" value="zh_CN"/> <!--3-->
        <parameter name="timezone" value="Asia/Shanghai"/> <!--4-->
    </tool>
    <tool>
        <key>listTool</key>
        <scope>application</scope>
        <class>org.apache.velocity.tools.generic.ListTool</class>
    </tool>
    <tool>
        <key>escTool</key>
        <scope>application</scope>
        <class>org.apache.velocity.tools.generic.EscapeTool</class>
    </tool>
</toolbox>
```

在 vm 文件中的使用方法如下

```
$dateTool.format($!{now})
```

其中 dateTool 是 `tools.xml` 文件中的 key 的元素名称, format, locale, timezone 表示 DateTool 对象的三个配置参数.

### 6. 编写 Controller 和 页面

- VelocityController

```java
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import javax.servlet.http.HttpServletRequest;

@Controller
@RequestMapping("/test/velocity")
public class VelocityController {

    @RequestMapping({"/myVelocity.do"})
    public ModelAndView test(HttpServletRequest request) {
        ModelAndView mv = new ModelAndView("myVelocity");
        mv.addObject("key", "我来了，velocity！");
        mv.addObject("now", new Date());
        return mv;
    }

}
```

- myVelocity.vm

```
<!DOCTYPE html>

<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>show all users</title>
</head>
<script type="text/javascript">
    $(function () {
        alert("sss");
    });
</script>
<body>
    <table>
        $!{key}
        $dateTool.format($!{now})
    </table>
</body>
</html>
```

- 项目启动后, 访问 `http://localhost:8012/test/velocity/myVelocity.do`, 返回内容如下

```
header...
我来了，velocity！
footer...
```

## 在 Spring 中使用 velocity

也就是不通过 xml 配置的方式来使用，将 VelocityEngine 配置成一个 Spring Bean 对象，可以用于邮件模板，或者代码模板。Maven 依赖和上面的一样。

VelocityEngine 配置如下

```java
import org.apache.velocity.app.VelocityEngine;
import org.apache.velocity.runtime.RuntimeConstants;
import org.apache.velocity.runtime.resource.loader.ClasspathResourceLoader;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class VelocityConfig {

	@Bean
	public VelocityEngine velocityEngine() throws Exception {
		VelocityEngine velocityEngine = new VelocityEngine();

		velocityEngine.setProperty(RuntimeConstants.RESOURCE_LOADER, "classpath");
		velocityEngine.setProperty("classpath.resource.loader.class", ClasspathResourceLoader.class.getName());
		velocityEngine.setProperty(RuntimeConstants.INPUT_ENCODING, "UTF-8");
		velocityEngine.setProperty(RuntimeConstants.OUTPUT_ENCODING, "UTF-8");

		velocityEngine.init();
		return velocityEngine;
	}

}
```

使用如下

```java
import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.io.StringWriter;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Component
public class ProcessVelocityTemplate {

	@Autowired
	private VelocityEngine velocityEngine;

	public String getVelocityResult() {

		try {
			Template template = velocityEngine.getTemplate("vtls/hellovelocity.vm");
			VelocityContext ctx = new VelocityContext();

			ctx.put("name", "模板velocity");
			ctx.put("date", (new Date()).toString());

			List temp = new ArrayList();
			temp.add("1");
			temp.add("2");
			ctx.put("list", temp);

			StringWriter sw = new StringWriter();

			template.merge(ctx, sw);

			return sw.toString();
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}
}
```

其中需要注意的是 `hellovelocity.vm` 位于 Maven 项目中的 `src/main/resources/vtls` 目录下。