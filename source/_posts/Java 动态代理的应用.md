---
title: Java 动态代理的应用
title_url: java-dynamic-apply
date: 2018-01-15
tags: Java
categories: [Java]
description: 这里基于 Java 动态代理来完成 AOP 编程,责任链设计模式的实现以及注解的实现
---

这里基于 Java 动态代理来完成 AOP 编程,责任链设计模式的实现以及注解的实现. 基本步骤如下

- 根据提供的接口数组创建代理类 proxyClass
- 获取代理类 proxyClass 的构造器 proxyClassConstructor, 参数必须实现 InvocationHandler 相关接口
- 根据构造器 proxyClassConstructor 创建接口实例, 该实例由jvm创建, 
- AOP 拦截器实现了对代理对象方法在执行过程中的拦截, 从而实现在待拦截方法执行的前后,抛出异常等情况下埋入相关逻辑.
- 拦截器形成责任链, 每个拦截器完成不同的拦截任务, 最后一个拦截器必须实现对待拦截对象的调用, 也就是说最后一个拦截器中必须有代理对象的一个实例, 其他前面的拦截器就负责执行前的拦截处理.

相关代码如下

```java
public static void main(String[] args) {

	// 拦截 open 方法
	AInterceptor ainc = new AInterceptor();
	// 拦截 close 方法
	BInterceptor binc = new BInterceptor();
	ainc.setNext(binc);
	// 注解拦截
	AnnotationInterceptor annc = new AnnotationInterceptor();
	binc.setNext(annc);
	// 拦截其他方法
	AopInterceptor defc = new AopInterceptor(new MyConnectionImpl());
	annc.setNext(defc);
	
	// AInterceptor (next)-> BInterceptor
	try {
		/*Class<?> proxyClass = Proxy.getProxyClass(AppMain.class.getClassLoader(), new Class[] { IConnection.class });
		Constructor<?> proxyClassConstructor = proxyClass.getConstructor(new Class[] { InvocationHandler.class });
		IConnection conn = (IConnection) proxyClassConstructor.newInstance(ainc); // 这里必须是 AInterceptor 的实例, 由 AInterceptor 一级级向下寻找
		*/
		
		IConnection conn = (IConnection) Proxy.newProxyInstance(AppMain.class.getClassLoader(), new Class[] { IConnection.class }, ainc);
		
		conn.open();
		
		conn.create();
		
		conn.get("a");
		
		conn.get("", "");
		
		conn.close();
		
	} catch (Exception e) {
		e.printStackTrace();
	}
}
```

## 责任链设计模式的实现

>责任链模式是一种对象的行为模式。在责任链模式里，很多对象由每一个对象对其下家的引用而连接起来形成一条链。请求在这个链上传递，直到链上的某一个对象决定处理此请求。发出这个请求的客户端并不知道链上的哪一个对象最终处理这个请求，这使得系统可以在不影响客户端的情况下动态地重新组织和分配责任。

本文的这个例子中 `AInterceptor`, `BInterceptor`, `AnnotationInterceptor`, `AopInterceptor` 组合成一个 责任链, 在他们的共同父类 `AbstractInterceptorHandler` 中有一个 

```java
public void setNext(AbstractInterceptorHandler next) {
	this.next = next;
}
```

方法, 用于保存对下家的引用. 当在调用 IConnection 中每一个方法的时候责任链都会进行拦截, 从上到下的调用关系如下

```
AInterceptor
    next->
        BInterceptor
            next->
                AnnotationInterceptor
                        next->
                            AopInterceptor
```

其中 `AInterceptor` 和 `BInterceptor` 根据方法名来拦截具体的方法, 不仅可以获取方法的参数, 甚至可以替换原有方法的执行逻辑.

比如 `AInterceptor` 的 invoke 方法如下

```java
@Override
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
	System.out.println("AInterceptor ...");
	if (method.getName().equals("open")) {
		System.out.println("AInterceptor intercept open method");
		return super.invoke(proxy, method, args); // a.调用默认的 open 方法
		//return "替换 open 方法的执行结果"; // b.替换 open 方法的具体实现
	} else {
		return super.invoke(proxy, method, args);	
	}
	
}
```

当使用其中 a 中的逻辑, 输出结果如下

```
AInterceptor ...
AInterceptor intercept open method
BInterceptor ...
AnnotationInterceptor ...
AopInterceptor ...
AopInterceptor 目标方法执行前, before execute
MyConnectionImpl do open
AopInterceptor 目标方法执行后, after execute
AopInterceptor 目标方法在返回前, before returning
AInterceptor ...
BInterceptor ...
AnnotationInterceptor ...
AopInterceptor ...
AopInterceptor 目标方法执行前, before execute
MyConnectionImpl do create
AopInterceptor 目标方法执行后, after execute
AopInterceptor 目标方法在返回前, before returning
```

当使用其中 b 中的逻辑, 输出结果如下

```
AInterceptor ...
AInterceptor intercept open method
AInterceptor ...
BInterceptor ...
AnnotationInterceptor ...
AopInterceptor ...
AopInterceptor 目标方法执行前, before execute
MyConnectionImpl do create
AopInterceptor 目标方法执行后, after execute
AopInterceptor 目标方法在返回前, before returning
```

## AOP 编程

在上面的责任链中 AopInterceptor 负责对 IConnection 中的所有方法进行拦截, 也是责任链中最底层的一层. 当然了, 如果其他拦截对象对目标方法进行了替换处理, 这里就无法拦截了.

其中关键就在目标方法执行的前后,遇到异常以及返回前加入一些 AOP 逻辑, 比如日志, 根据方法的参数来判断方法的执行权限, 事务等重复性的代码.

关于 AnnotationInterceptor 的 invoke 方法实现的说明如下

```java
/**
 * proxy 由 jvm 创建的类实例, 没有数据状态, 但是可以获取到类的相关信息,比如方法, 注解等信息
 * method 代理对象的方法
 * args 代理对象的方法的参数
 * 
 * method.invoke(conn, args) 中的 conn 表示在执行过程中具体执行哪个接口实现类, 也可以根据传入方法参数的不同来动态选择实现类, 这里是根据构造函数传入的实现类
 */
@Override
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
	System.out.println("AopInterceptor ...");
	
	try {
		System.out.println("AopInterceptor 目标方法执行前, before execute");
		Object obj = method.invoke(conn, args);
		System.out.println("AopInterceptor 目标方法执行后, after execute");
		return obj;
	} catch (Exception e) {
		e.printStackTrace();
		System.out.println("AopInterceptor 目标方法执行中遇到异常, exception");
		return null;
	} finally {
		System.out.println("AopInterceptor 目标方法在返回前, before returning");
	}
	
}
```

## 注解的实现

定义注解如下

```java
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface NotNull {
	
}
```

```java
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface NotEmpty {
	
}
```

上面的注解作用于方法的参数上面, 注解的保留策略在方法执行过程中实现. 将定义的注解作用于 IConnection 接口中的方法如下

```java
public interface IConnection {
	
	public void open();
	
	public void close();
	
	public void get(@NotNull @NotEmpty String key);
	
	public void get(@NotNull String key, @NotNull String value);
	
	public void create();
	
}
```

如果将 `@NotNull` 注解作用于方法的参数上面, 并且传入的参数为 null, 将会抛出 RuntimeException 异常; 如果同时将 `@NotNull` 和 `@NotEmpty`注解作用于方法的参数上面, 并且传入的参数为 null 或者为空字符串 "", 也将会抛出 RuntimeException 异常

将 AnnotationInterceptor 加入责任链后, 即可拦截在应用执行过程中遇到的参数为 null 或者为 "" 的问题. 

AnnotationInterceptor 中的 invoke 方法的实现如下

```java
@Override
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
	System.out.println("AnnotationInterceptor ...");
	
	// 下面是针对接口中的方法如果带有参数并且加上了 @NotNull 注解的处理
	// 如果参数为 null 就会抛出 RuntimeException 异常
	// method.getParameterAnnotations(); 返回 Annotation 的二维数组, 第一纬表示参数索引, 第二维表示参数对应的注解列表
	Annotation[][] parameterAnnotations = method.getParameterAnnotations();
	for (int i = 0; i < parameterAnnotations.length; i++) {
		Annotation[] annotations = parameterAnnotations[i];
		for (Annotation annotation : annotations) {
			if (annotation instanceof NotNull && args[i] == null) {
				throw new RuntimeException("AnnotationInterceptor[the parameter has NotNull Annotation, so must be not null, method = "+method.getName()+", arg = "+args[i]+"]");
			}
			if (annotation instanceof NotEmpty && String.valueOf(args[i]).equals("")) {
				throw new RuntimeException("AnnotationInterceptor[the parameter has NotEmpty Annotation, so must be not empty, method = "+method.getName()+", arg = "+args[i]+"]");
			}
		}
	}
	return super.invoke(proxy, method, args);
}
```

根据目标方法参数带上的注解来自定义相应的逻辑, 这个例子演示了注解的定义以及实现.

## 代码地址

本文中的代码在: [代码地址](https://github.com/toulezu/play/tree/master/test-proxy-class)

## 参考

- [Java Constructor.newInstance() 的例子](http://www.javainterviewpoint.com/java-constructor-newinstance-method-example/)
- [Java的动态代理(dynamic proxy)](http://www.cnblogs.com/techyc/p/3455950.html)
- [责任链设计模式【过滤器、拦截器】](http://www.cnblogs.com/lyajs/articles/5712316.html)