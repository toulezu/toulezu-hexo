---
title: 在 freemarker 中使用自定义的函数的两种方法介绍
title_url: freemarker-self-define-function-usage
date: 2019-12-01
tags: [freemarker]
categories: [freemarker]
description: 本文介绍内容如下：1. 在 freemarker 模板中使用自定义的函数功能；2. freemarker 使用字符串类型的模板以及文件模板
---

## 1 概述

本文介绍内容如下

1. 在 freemarker 模板中使用自定义的函数功能
2. freemarker 使用字符串类型的模板以及文件模板

## 2 freemarker 的相关依赖

- 在 Spring 中

```xml
<!-- freemarker engine 相关 -->
<dependency>
	<groupId>org.freemarker</groupId>
	<artifactId>freemarker</artifactId>
	<version>2.3.26-incubating</version>
</dependency>

<dependency>
	<groupId>org.springframework</groupId>
	<artifactId>spring-context-support</artifactId>
	<version>4.3.6.RELEASE</version>
</dependency>

<dependency>
	<groupId>org.springframework</groupId>
	<artifactId>spring-webmvc</artifactId>
	<version>4.3.6.RELEASE</version>
</dependency>
<!-- freemarker engine 相关 -->
```

- 在 SpringBoot 中

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-freemarker</artifactId>
	<version>2.2.1.RELEASE</version>
</dependency>
```

## 3 具体使用

#### 3.1 freemarker 的配置

配置 freemarker 使用的模板文件路径, 具体如下

- FreeMarkerConfig.java 配置类

```java
package com.ckjava.test.config;

import java.util.Properties;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.view.freemarker.FreeMarkerConfigurer;

@Configuration
public class FreeMarkerConfig {

	@Bean
	public FreeMarkerConfigurer freeMarkerConfigurer() {
		FreeMarkerConfigurer freeMarkerConfigurer = new FreeMarkerConfigurer();
		freeMarkerConfigurer.setTemplateLoaderPath("classpath:/ftls");
		
		Properties pro = new Properties();
		pro.setProperty("template_update_delay", "1800");
		pro.setProperty("default_encoding", "UTF-8");
		pro.setProperty("locale", "zh_CN");
		freeMarkerConfigurer.setFreemarkerSettings(pro);
		
		return freeMarkerConfigurer;
	}

}

```

- 封装 TemplateCom.java, 用于处理字符串模板和文件模板

```java

import freemarker.cache.StringTemplateLoader;
import freemarker.template.Configuration;
import freemarker.template.Template;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.ui.freemarker.FreeMarkerTemplateUtils;
import org.springframework.web.servlet.view.freemarker.FreeMarkerConfigurer;

import java.io.StringWriter;
import java.util.Map;

@Component
public class TemplateCom {


    private static Logger logger = LoggerFactory.getLogger(TemplateCom.class);

    @Autowired
    private FreeMarkerConfigurer freeMarkerConfigurer;

    /**
     * 处理模板文件
     *
     * @param template 模板文件名称
     * @param dataMap 模板数据
     * @return 解析后的内容
     */
    public String renderTemplate(String template, Map<String, Object> dataMap) {
        try {
            Template tpl = freeMarkerConfigurer.getConfiguration().getTemplate(template);
            return FreeMarkerTemplateUtils.processTemplateIntoString(tpl, dataMap);
        } catch (Exception e) {
            logger.error(this.getClass().getName().concat(".renderTemplate has error"), e);
            return null;
        }

    }

    /**
     * 处理模板字符串
     *
     * @param string 模板字符串
     * @param dataMap 模板数据
     * @return 解析后的内容
     */
    public synchronized String renderString(String string, Map<String, Object> dataMap) {
        try {
            if (string.contains("${") && string.contains("}")) {
                // 1. 获取已经存在的配置
                Configuration configuration = freeMarkerConfigurer.getConfiguration();

                // 2. 自定义一个字符串模板
                StringTemplateLoader stringLoader = new StringTemplateLoader();
                stringLoader.putTemplate("myTemplate", string);

                // 3. 加载已经存在的模板
                configuration.setTemplateLoader(stringLoader);

                // 4. 处理模板数据
                StringWriter writer = new StringWriter();
                configuration.getTemplate("myTemplate").process(dataMap, writer);
                return writer.toString();
            }
            return string;
        } catch (Exception e) {
            logger.error(this.getClass().getName().concat(".renderString has error"), e);
            return null;
        }

    }

}
```

#### 3.2 方法1: 不实现 `TemplateMethodModelEx` 接口

模板内容如下

```
${cus.add(5, 8)}
```

其中 `cus` 是自定义对象, `add` 是其中的方法, 

具体如下

```java
package com.ckjava.test.freemarker;

public class Custom {

	public int add(int a, int b) {
		return a+b;
	}
	
}
```

使用如下

```java
package com.ckjava.test.freemarker;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.ui.freemarker.FreeMarkerTemplateUtils;
import org.springframework.web.servlet.view.freemarker.FreeMarkerConfigurer;

import freemarker.template.Template;

@Component
public class ProcessTemplate {

	@Autowired
	private FreeMarkerConfigurer freeMarkerConfigurer;
	
	public String getResult(int a, int b) {
		
		try {
			Map<String, Object> resultData = new HashMap<String, Object>();
			resultData.put("cus", new Custom());
			
			Template tpl = freeMarkerConfigurer.getConfiguration().getTemplate("test.ftl");
			String result = FreeMarkerTemplateUtils.processTemplateIntoString(tpl, resultData);	
			return result;
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
		
	}
}
```

执行 getResult 方法如下

```java
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

import com.ckjava.test.component.NewCardQuery;
import com.ckjava.test.freemarker.ProcessTemplate;

public class Run {
	private static ApplicationContext appc;

	public static void main(String[] args) {
		
		appc = new AnnotationConfigApplicationContext("com.ckjava.test");
		
		ProcessTemplate pt = appc.getBean(ProcessTemplate.class);
		System.out.println("result = " + pt.getResult());
	}
}

```

结果如下

```
result = 13
```

#### 3.3 方法2: 实现`TemplateMethodModelEx`接口

具体实现如下

```java
package com.ckjava.test.freemarker;

import java.util.List;

import freemarker.template.TemplateMethodModelEx;
import freemarker.template.TemplateModelException;

public class Subtract implements TemplateMethodModelEx {

	@SuppressWarnings("rawtypes")
	public Object exec(List arguments) throws TemplateModelException {
		return Integer.parseInt(arguments.get(0).toString()) - Integer.parseInt(arguments.get(1).toString());
	}

}

```

引入自定义函数的方式如下

```java
resultData.put("sub", new Subtract());
```

模板中的使用如下

```
${sub(9, 8)}
```

区别在于实现了 `TemplateMethodModelEx` 接口的函数不需要在使用的时候带上函数名. 从上面对比可以看出方法1在操作上更加灵活而且更容易理解.