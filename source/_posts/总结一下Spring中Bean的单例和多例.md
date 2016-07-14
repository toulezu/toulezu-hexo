---
title: 总结一下关于Spring中bean的scope属性
title_url: Spring-bean-scope-usage
date: 2016-07-13
tags: Spring
categories: 技术
description: 总结一下关于Spring中bean的scope属性，主要是Controller的singleton和prototype的区别，并举例说明
---

## 关于Spring bean的scope属性

- Spring的bean默认是singleton-单例模式的，即Spring容器只存在一个共享的bean实例

- 对于singleton-单例模式，如果有共享变量会导致线程不安全

- 如果为prototype-原型模式，那么每次对bean的请求都会创建一个新的bean实例

- prototype-原型模式是线程安全的，Spring中的Controller默认是singleton

- 可以在类上面通过`@Scope("prototype")`设置为多例，或者在xml中设置`scope="prototype"`

- singleton-单例模式相对prototype-原型模式性能更高，因为不会每次对bean的请求都会创建一个新的bean实例

- 二者选择的原则：有状态的bean都使用prototype，而对无状态的bean则应该使用singleton

- 有无状态是指bean中有无成员变量

- Struts2的Action默认是多例的，原因在于Struts2将表单数据作为Action的成员变量

- scope还可以设置成request、session和global session

## 举例说明Controller的singleton和prototype的区别

- TestController如下
```java
@Controller
@RequestMapping("/test")
@Api(basePath = "/test", value = "test", description = "测试相关接口", position = 8)
public class TestController {
	
	private Map<String, String> cacheData = Collections.synchronizedMap(new HashMap<String, String>());

	@ResponseBody
	@RequestMapping(value = "/test_cache", method = RequestMethod.GET, produces = "application/json; charset=utf-8")
	@ApiOperation(value = "测试scope", notes = "测试scope", response = KVBean.class, responseContainer = "List")
	public List<KVBean> getTestCache(@RequestParam String key, @RequestParam String value) throws Exception {
		
		System.out.println(Thread.currentThread().getName());
		cacheData.put(key, value);
		
		List<KVBean> data = new ArrayList<KVBean>();
		for (Entry<String, String> it : cacheData.entrySet()) {
			data.add(new KVBean(it.getKey(), it.getValue()));
		}
		
		return data;
	}
	
}
```

- 第一次在浏览器中输入
`http://localhost:8080/plainWebApi/test/test_cache?key=1&value=1`
返回
`[{"key":"1","value":"1","next":null}]`
第二次在浏览器中输入
`http://localhost:8080/plainWebApi/test/test_cache?key=2&value=2`
返回
`[{"key":"1","value":"1","next":null},{"key":"2","value":"2","next":null}]`
可见对于两次请求cacheData都是同一个对象，TestController当然也没有被new。

- 增加`@Scope(value = "prototype")`的TestController如下
```java
@Controller
@RequestMapping("/test")
@Api(basePath = "/test", value = "test", description = "测试相关接口", position = 8)
@Scope(value = "prototype")
public class TestController {
	
	private Map<String, String> cacheData = Collections.synchronizedMap(new HashMap<String, String>());

	@ResponseBody
	@RequestMapping(value = "/test_cache", method = RequestMethod.GET, produces = "application/json; charset=utf-8")
	@ApiOperation(value = "测试scope", notes = "测试scope", response = KVBean.class, responseContainer = "List")
	public List<KVBean> getTestCache(@RequestParam String key, @RequestParam String value) throws Exception {
		
		System.out.println(Thread.currentThread().getName());
		cacheData.put(key, value);
		
		List<KVBean> data = new ArrayList<KVBean>();
		for (Entry<String, String> it : cacheData.entrySet()) {
			data.add(new KVBean(it.getKey(), it.getValue()));
		}
		
		return data;
	}
	
}
```

- 同样第一次在浏览器中输入
`http://localhost:8080/plainWebApi/test/test_cache?key=1&value=1`
返回
`[{"key":"1","value":"1","next":null}]`
第二次在浏览器中输入
`http://localhost:8080/plainWebApi/test/test_cache?key=2&value=2`
返回
`[{"key":"2","value":"2","next":null}]`
可见对于两次请求cacheData都是不是一个对象，TestController当然也不是同一个。

参考：
[Struts action的单例与多例](http://my.oschina.net/davidzhang/blog/67429)
[在spring来管理实例对象prototype和singleton的选择.针对action如何使用](http://www.cnblogs.com/shipengzhi/articles/2099694.html)
[Spring MVC Controller单例陷阱](http://lavasoft.blog.51cto.com/62575/1394669)
[struts+spring action应配置为scope="prototype"](http://www.cnblogs.com/JemBai/archive/2010/11/10/1873954.html)
[struts2 Action获取表单数据](http://blog.csdn.net/lsh6688/article/details/7863322)
