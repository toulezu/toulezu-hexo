---
title: Phabricator 的 conduit API 使用说明
title_url: Phabricator-conduit-API-Java
date: 2017-08-15
tags: Phabricator
categories: [Phabricator,PHP]
description: Phabricator 的 conduit API 使用说明
---

## 基本介绍

Phabricator 的 conduit API 地址在 `http://test.pha.com/conduit/`, 在使用 API 前需要生成一个访问用的 Token,地址在 `http://test.pha.com/settings/user/chen_k/page/apitokens/` 其中 `chen_k` 是自己的用户名.

这里举一个查询任务的API，地址在`http://test.pha.com/conduit/method/maniphest.search/`.

## 参数介绍

![pha-api-param](http://7xt8a6.com1.z0.glb.clouddn.com/pha-api-param.PNG)

- queryKey 表示 Phabricator 内置的查询对象，具体有 "assigned", "authored", "subscribed", "open", "all", 当然也可以自定义查询后在这里使用
- constraints ： 查询条件，`{"statuses": ["open"]}` 表示任务状态为 open 的
- attachments 任务对象关联其他对象查询， `{ "subscribers": true}` 表示查询任务的订阅者
- order 排序，内置的有 "priority","updated","outdated","newest","oldest","title", "priority" 表示 `order by priority, subpriority, id`
- before 表示分页中的 上一页
- after 表示分页中的 下一页
- limit 表示分页中的 每页记录数

## 使用 Java 访问 API

点击 `Call Method` 后，生成的 cURL 查询格式如下

![pha-api-param-2](http://7xt8a6.com1.z0.glb.clouddn.com/pha-api-param-2.PNG)

```
$ curl http://test.pha.com/api/maniphest.search \
    -d api.token=api-token \
    -d queryKey=all \
    -d constraints[statuses][0]=open \
    -d attachments[subscribers]=1 \
    -d order[0]=id
```

在 Java 中查询方式如下, 主要就是根据生成的 cURL 参数来构造查询

```java
public void testPhabricatorAPI() {
	try {
		Response res = Request.Post("http://test.pha.com/api/maniphest.search")
				.bodyForm(Form.form()
				.add("api.token", "api-6mlsh56cb5uexqbxgpnvah6djhmc")
				.add("queryKey", "all")
				.add("constraints[statuses][0]", "open")
				.add("attachments[subscribers]", "1")
				.add("order[0]", "id")
				.build())
				.execute();
		Content content = res.returnContent();
		System.out.println(content.toString());
	} catch (ClientProtocolException e) {
		e.printStackTrace();
	} catch (IOException e) {
		e.printStackTrace();
	}
}
```

这里使用的 Maven 依赖如下

```xml
<dependency>
	<groupId>org.apache.httpcomponents</groupId>
	<artifactId>fluent-hc</artifactId>
	<version>4.3.1</version>
</dependency>

<dependency>
	<groupId>org.apache.httpcomponents</groupId>
	<artifactId>httpclient</artifactId>
	<version>4.3.1</version>
</dependency>

<dependency>
	<groupId>org.apache.httpcomponents</groupId>
	<artifactId>httpcore</artifactId>
	<version>4.3.2</version>
</dependency> 
```

## 使用 before，after 和 limit 进行翻页查询

![pha-api-param-1](http://7xt8a6.com1.z0.glb.clouddn.com/pha-api-param-1.PNG)

这里举个例子，当 before，after 和 limit 三个参数为空的时候
返回的任务 id 分别是：28，27，26，22，21，19，17，16，14，13，12，11，10，9，7，5，1

- 当 before=21,after为空,limit=5, 返回 28，27，26，22，相当于上一页
- 当 before为空，after=22, limit=5, 返回 21, 19，17，16，14，相当于下一页
- 当 before为空，after=14, limit=5, 返回 13，12，11，10，9，相当于下一页

## 总结

本文简单介绍了 Phabricator 的 conduit API 的使用，关键点在于通过 Phabricator 生成的 cURL 参数来构造 Java 查询。
