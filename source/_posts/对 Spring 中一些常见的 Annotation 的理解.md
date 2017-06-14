---
title: 对 Spring 中一些常见的 Annotation 的理解
title_url: Spring-Annotation
date: 2017-05-23
tags: [Spring,Annotation]
categories: 技术
description: 对 Spring 中一些常见的 Annotation 的理解
---

## `@Service`

作用于类上,自动根据bean的类名实例化一个首写字母为小写的bean，如果需要自己改名字则:`@Service("你自己改的bean名")`, 默认是单例模式(singleton),用于业务层.

## `@Component`

功能和 `@Service` 类似,用于一些功能组件,或者帮助类.

## `@Repository`

功能和 `@Service` 类似,用于持久层(Dao)

## `@Controller`

功能和 `@Service` 类似,用于控制层(Controller),或者Web层

## `@Autowired` 和 `@Resource`

- 都作用于类成员变量、方法及构造函数上,用于成员变量自动注入
- 只不过 `@Resource` 默认按 byName 自动注入,而 `@Autowired` 默认安装 byType 而已.
- `@Resource` 可以带上 `@Resource(name="myCar")` 或者 `@Resource(type=Car.class)` 来区分是通过 byName 还是 byType 自动注入.

## `@Qualifier`
- 对于 `@Autowired` 如果容器中有多个类型相同而名称不同的类型需要自动注入,需要多加一个 `@Qualifier("office")` 来区分不同的类型
```
public class Boss {  

    @Autowired  
    @Qualifier("office")  
    private Office office;  
    …  
} 
```
这种情况如果都通过注解来定义Bean是不会存在的.

## `@PostConstruct` 和 `@PreDestroy`
这两个注释只能应用于方法上。标注了 `@PostConstruct` 注释的方法将在类实例化后调用，而标注了 `@PreDestroy` 的方法将在类销毁之前调用。  

## 关于 context:annotation-config

使用以上注解都必须在 Spring 的核心配置文件中加入如下配置

```xml
<?xml version="1.0" encoding="UTF-8" ?>  
<beans xmlns="http://www.springframework.org/schema/beans"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  
     xmlns:context="http://www.springframework.org/schema/context"  
     xsi:schemaLocation="http://www.springframework.org/schema/beans   
 http://www.springframework.org/schema/beans/spring-beans-2.5.xsd  
 http://www.springframework.org/schema/context   
 http://www.springframework.org/schema/context/spring-context-2.5.xsd">  
   
    <context:annotation-config/>
    
    <bean id="boss" class="com.test.Boss"/>  
    <bean id="office" class="com.test.Office">  
        <property name="officeNo" value="001"/>  
    </bean>  
    <bean id="car" class="com.test.Car" scope="singleton">  
        <property name="brand" value=" 红旗 CA72"/>  
        <property name="price" value="2000"/>
    </bean>  
</beans>  
```

`<context:annotation-config/>` 将隐式地向 Spring 容器注册 AutowiredAnnotationBeanPostProcessor、CommonAnnotationBeanPostProcessor、PersistenceAnnotationBeanPostProcessor 以及 equiredAnnotationBeanPostProcessor 这 4 个 BeanPostProcessor。  
该配置将处理容器中已有的Bean的依赖注入问题,在容器初始化的时候将容器中的实体中含有 `@Autowired` 或者 `@Resource` 的Bean自动注入相应的依赖Bean

## 关于 context:component-scan

这个配置更强大,不但启用了对类包进行扫描以实现注解驱动的**Bean定义**的功能，同时还启用了注解驱动的**依赖注入**的功能（即还隐式地在内部注册了 AutowiredAnnotationBeanPostProcessor 和 CommonAnnotationBeanPostProcessor），因此当使用 `<context:component-scan/>` 后，就可以将 `<context:annotation-config/>` 移除了。 
最终的配置可以简化成如下的样子

```xml
<?xml version="1.0" encoding="UTF-8" ?>  
<beans xmlns="http://www.springframework.org/schema/beans"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  
     xmlns:context="http://www.springframework.org/schema/context"  
     xsi:schemaLocation="http://www.springframework.org/schema/beans   
 http://www.springframework.org/schema/beans/spring-beans-2.5.xsd  
 http://www.springframework.org/schema/context   
 http://www.springframework.org/schema/context/spring-context-2.5.xsd">  
   
    <context:component-scan base-package="com.test"/>
    
</beans>
```

## 参考

- [使用Spring2.5的Autowired实现注释型的IOC](http://crabboy.iteye.com/blog/339840)
- [Spring @Qualifier 注释](http://wiki.jikexueyuan.com/project/spring/annotation-based-configuration/spring-qualifier-annotation.html)