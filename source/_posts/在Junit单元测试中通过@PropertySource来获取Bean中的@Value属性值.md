---
title: 在Junit单元测试中通过@PropertySource来获取Bean中的@Value属性值
title_url: Spring-Junit-PropertySource-Value
date: 2016-09-30
tags: [Spring,Junit]
categories: Spring
description: 在Junit单元测试中通过@PropertySource来获取Bean中的@Value属性值
---

## 使用场景说明

- 在平时开发的时候，为了测试Spring中的一个Bean，通常要通过`@ContextConfiguration`注解来加载一些XML配置，问题是XML配置越来越多，现在要减少甚至去除XML配置，从而简化开发

- 古老的项目由于历史问题没有使用Junit来测试Bean导致现在切换过来复杂

- 有时候只想在Junit中测试几个Bean

- 避免加载XML配置，直接从properties文件中获取@Value属性值

## 使用说明

- 使用`@Configuration`注解将XML配置转换成在Bean中完成，`@PropertySource`注解用于指定properties文件
```Java
/**
 * 通过该类可以代替在xml中如下的配置
 * 
 * 
 *	
  	  <bean class="org.springframework.context.support.PropertySourcesPlaceholderConfigurer">
        <property name="ignoreUnresolvablePlaceholders" value="true"/>
        <property name="locations">
          <list>
            <value>classpath:jdbc.properties</value>
          </list>
        </property>
      </bean>
 * @author chen_k
 *
 */
@Configuration
@PropertySource(value = { "classpath:jdbc.properties" })
public class SpringPropertiesConfigure {

	@Bean
    public static PropertySourcesPlaceholderConfigurer propertySourcesPlaceholderConfigurer() {
        return new PropertySourcesPlaceholderConfigurer();
    }
}
```

- 使用`@ContextConfiguration`的`classes`属性来加载相关的几个Bean。DBService类中几个字段通过`@Value`从properties文件获取值
```Java
@ContextConfiguration(classes = {DBService.class, SpringPropertiesConfigure.class})
public class TestDBService extends BaseTest {

	@Autowired
	private DBService dBService;
	
	@Test
	public void testGetDBInfo() {
		String dbInfo = dBService.toString();
		Assert.assertNotNull(dbInfo);
		System.out.println(dbInfo);
	}
}
```

## 完整的代码

- 点击*[这里](https://github.com/toulezu/play/tree/master/SpringBoot/testSpringBoot)*

## 参考

- [Populating Spring @Value during Unit Test](http://stackoverflow.com/questions/17353327/populating-spring-value-during-unit-test?noredirect=1&lq=1)
- [Spring @PropertySource & @Value annotations example](http://websystique.com/spring/spring-propertysource-value-annotations-example/)
- [使用RunWith注解改变JUnit的默认执行类，并实现自已的Listener](http://blog.csdn.net/fenglibing/article/details/8584602)

