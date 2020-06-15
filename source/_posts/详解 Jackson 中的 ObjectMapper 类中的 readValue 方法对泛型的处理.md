---
title: 详解 Jackson 中的 ObjectMapper 类中的 readValue 方法对泛型的处理
title_url: Jackson-ObjectMapper-readValue-practice
date: 2020-06-15
tags: [Java,Jackson]
categories: Jackson
description: 详解 Jackson 中的 ObjectMapper 类中的 readValue 方法对泛型的处理
---

## 1 概述

本文介绍 Jackson 中的 ObjectMapper 类中的 readValue 方法将 json 字符串转成 Java 对象过程中对泛型的处理，具体内容如下

1. 通过 `new TypeReference<Json<User>>(){}` 来解决泛型问题
2. 通过 TypeFactory 类中的 constructParametricType 方法来解决泛型问题
3. TypeFactory 一些方法解析

## 2 Jackson ObjectMapper readValue 泛型问题

- 问题：通过 `readValue(String, T)` 只能默认将字符串转成 `HttpResponse<List<Map<String, Object>>` 类型
- 解决：通过 TypeReference 对象解决，具体如下

```java
HttpResult httpResult = HttpClientUtils.post(url, HeaderMap.jsonHeader, null, JsonUtils.getMapper().writeValueAsString(jsonBody));
HttpResponse<List<HeartbeatVo>> httpResponse = JsonUtils.getMapper().readValue(httpResult.getBodyString(), new TypeReference<HttpResponse<List<HeartbeatVo>>>(){});
```

或者通过 TypeFactory 类中的 constructParametricType 方法

```java
public Data<T> read(InputStream json, Class<T> contentClass) {
   JavaType type = mapper.getTypeFactory().constructParametricType(Data.class, contentClass);
   return mapper.readValue(json, type);
}
```

## 3 完整测试

#### 3.1 pojo 对象

- 忽略 get set 以及构造函数

```
public class User {
    private int age;//年龄
    private String name;//姓名
}

public class Hit<T> {
    public String id;
    public T data;
}

public class Hits<T> {
    public int found;
    public int start;
    public ArrayList<Hit<T>> hit;
}

public class Json<T> {
    public Hits<T> hits;
}
```

#### 3.2 测试代码

1. 通过 `new TypeReference<Json<User>>(){}` 来解决泛型问题
2. 通过 TypeFactory 类中的 constructParametricType 方法来解决泛型问题

```java
@Test
public void test() {
    Json<User> userJson = new Json<>();

    Hit<User> hit = new Hit<>();
    hit.setId("1");
    hit.setData(new User(20, "jack"));

    Hits<User> userHits = new Hits<>();
    userHits.setFound(1);
    userHits.setStart(2);
    ArrayList<Hit<User>> hitArrayList = new ArrayList<>();
    hitArrayList.add(hit);
    userHits.setHit(hitArrayList);

    userJson.setHits(userHits);
    try {
        String userJsonString = JsonUtils.getMapper().writerWithDefaultPrettyPrinter().writeValueAsString(userJson);
        System.out.println(String.format("hit to jsonString:\n%s", userJsonString));

        Json<User> readValue = JsonUtils.getMapper().readValue(userJsonString, new TypeReference<Json<User>>(){});
        System.out.println(readValue.getHits().getFound());

        userJsonString = JsonUtils.getMapper().writeValueAsString(readValue);
        System.out.println(String.format("hit to jsonString:\n%s", userJsonString));
    } catch (Exception e) {
        e.printStackTrace();
    }
}

@Test
public void test2() {
    String jsonString = "{\"hits\":{\"found\":1,\"start\":2,\"hit\":[{\"id\":\"1\",\"data\":{\"age\":20,\"name\":\"jack\",\"enName\":null,\"password\":null,\"gender\":\"\\u0000\",\"hasMarried\":false}}]}}";
    try {
        // 通过 new TypeReference<Json<User>>(){} 来解决泛型问题
        Json<User> readValue = JsonUtils.getMapper().readValue(jsonString, new TypeReference<Json<User>>(){});
        System.out.println(readValue.getHits().getFound());

        // 通过 TypeFactory 来解决泛型问题
        JavaType jsonType = JsonUtils.getMapper().getTypeFactory().constructParametricType(Json.class, User.class);
        readValue = JsonUtils.getMapper().readValue(jsonString, jsonType);
        System.out.println(readValue.getHits().getFound());
    } catch (Exception e) {
        e.printStackTrace();
    }

}

@Test
public void test3() {
    String jsonString = "{\"data\":{\"hits\":{\"found\":1,\"start\":2,\"hit\":[{\"id\":\"1\",\"data\":{\"age\":20,\"name\":\"jack\",\"enName\":null,\"password\":null,\"gender\":\"\\u0000\",\"hasMarried\":false}}]}},\"sign\":\"success\",\"code\":200,\"message\":null,\"dataSize\":1}";
    try {
        // 通过 new TypeReference<Json<User>>(){} 来解决泛型问题
        HttpResponse<Json<User>> httpResponse = JsonUtils.getMapper().readValue(jsonString, new TypeReference<HttpResponse<Json<User>>>(){});
        System.out.println(httpResponse.getData().getHits().getFound());

        // 通过 TypeFactory 来解决泛型问题
        JavaType jsonType = JsonUtils.getMapper().getTypeFactory().constructParametricType(Json.class, User.class);
        JavaType httpResponseJavaType = JsonUtils.getMapper().getTypeFactory().constructParametricType(HttpResponse.class, jsonType);
        HttpResponse<Json<User>> parseHttpResponse = JsonUtils.getMapper().readValue(jsonString, httpResponseJavaType);
        System.out.println(parseHttpResponse.getData().getHits().getFound());
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

## 4 TypeFactory 一些方法解析

- com.fasterxml.jackson.databind.type.TypeFactory
- com.fasterxml.jackson.databind.JavaType

1. TypeFactory 用于构造 JavaType 对象。
2. JavaType 在 Jackson 将 json 字符串反序列化为 Java 对象的时候会用到。
3. TypeFactory 内置了很多生成 JavaType 的方法，用于生成各类 JavaType 对象，包含复杂的嵌套泛型，比如下面的两个

```
JavaType stringType = mapper.constructType(String.class);
JavaType stringCollection = mapper.getTypeFactory().constructCollectionType(List.class, String.class);
```

#### 4.1 constructCollectionType 方法处理 List<T> 的 json 类型

- constructCollectionType 方法

```java
@Test
public void test_list_string() {
    try {
        String listString = "[ \"1\",\"2\",\"3\" ]";
        JavaType stringCollection = JsonUtils.getMapper().getTypeFactory().constructCollectionType(List.class, String.class);
        List<String> dataList = JsonUtils.getMapper().readValue(listString, stringCollection);

        dataList.forEach(data -> System.out.println(String.format("data:%s", data)));

    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

#### 4.2 constructMapLikeType 方法处理 Map<k, List<T>> 的 json 类型

- constructMapLikeType 方法

```java
@Test
public void test_map_list_string() {
    try {
        String jsonString = "{ \"list\" : [ \"1\",\"2\",\"3\" ] }";

        JavaType stringType = JsonUtils.getMapper().getTypeFactory().constructType(String.class);
        JavaType listType = JsonUtils.getMapper().getTypeFactory().constructCollectionType(List.class, String.class);

        JavaType mapLikeType = JsonUtils.getMapper().getTypeFactory().constructMapLikeType(Map.class, stringType, listType);
        Map<String, List<String>> dataMap = JsonUtils.getMapper().readValue(jsonString, mapLikeType);

        dataMap.forEach((key,value) -> {
            System.out.println(String.format("key:%s", key));
            System.out.println("value:");
            value.forEach(data -> System.out.print(String.format("data:%s,", data)));
        });
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

#### 4.3 constructParametricType 方法处理 HttpResponse<Json<T>> 的 json 类型

- constructParametricType 方法

```
@Test
public void test3() {
    String jsonString = "{\"data\":{\"hits\":{\"found\":1,\"start\":2,\"hit\":[{\"id\":\"1\",\"data\":{\"age\":20,\"name\":\"jack\",\"enName\":null,\"password\":null,\"gender\":\"\\u0000\",\"hasMarried\":false}}]}},\"sign\":\"success\",\"code\":200,\"message\":null,\"dataSize\":1}";
    try {
        // 通过 new TypeReference<Json<User>>(){} 来解决泛型问题
        HttpResponse<Json<User>> httpResponse = JsonUtils.getMapper().readValue(jsonString, new TypeReference<HttpResponse<Json<User>>>(){});
        System.out.println(httpResponse.getData().getHits().getFound());

        // 通过 TypeFactory 来解决泛型问题
        JavaType jsonType = JsonUtils.getMapper().getTypeFactory().constructParametricType(Json.class, User.class);
        JavaType httpResponseJavaType = JsonUtils.getMapper().getTypeFactory().constructParametricType(HttpResponse.class, jsonType);
        HttpResponse<Json<User>> parseHttpResponse = JsonUtils.getMapper().readValue(jsonString, httpResponseJavaType);
        System.out.println(parseHttpResponse.getData().getHits().getFound());
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

#### 4.4 constructParametricType 方法处理 JsonType<K,T> 的 json 类型

如果将类的泛型有多个呢？新增泛型对象如下

```java
public class JsonType<K,T> {
    private K key;
    public Hits<T> hits;
}
```

- 测试如下

```java
@Test
public void testJsonType() {
    JsonType<String, User> userJson = new JsonType<>();

    Hit<User> hit = new Hit<>();
    hit.setId("1");
    hit.setData(new User(20, "jack"));

    Hits<User> userHits = new Hits<>();
    userHits.setFound(1);
    userHits.setStart(2);
    ArrayList<Hit<User>> hitArrayList = new ArrayList<>();
    hitArrayList.add(hit);
    userHits.setHit(hitArrayList);

    userJson.setKey("chen");
    userJson.setHits(userHits);
    try {
        String userJsonString = JsonUtils.getMapper().writerWithDefaultPrettyPrinter().writeValueAsString(userJson);
        System.out.println(String.format("hit to jsonString:\n%s", userJsonString));

        // 1. new TypeReference<JsonType<String, User>>(){} 方式
        JsonType<String, User> readValue = JsonUtils.getMapper().readValue(userJsonString, new TypeReference<JsonType<String, User>>(){});
        System.out.println(readValue.getHits().getFound());

        userJsonString = JsonUtils.getMapper().writeValueAsString(readValue);
        System.out.println(String.format("hit to jsonString:\n%s", userJsonString));

        // 2. JavaType 方式
        JavaType jsonType = JsonUtils.getMapper().getTypeFactory().constructParametricType(JsonType.class, String.class, User.class);
        JsonType<String, User> JsonTypeValue = JsonUtils.getMapper().readValue(userJsonString, jsonType);
        System.out.println(JsonTypeValue.getHits().getFound());

        userJsonString = JsonUtils.getMapper().writeValueAsString(JsonTypeValue);
        System.out.println(String.format("hit to jsonString:\n%s", userJsonString));
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

## 5 参考

- [jackson-deserialize-using-generic-class](https://stackoverflow.com/questions/11664894/jackson-deserialize-using-generic-class)
- [Jackson - Deserialize Generic class variable](https://stackoverflow.com/questions/11659844/jackson-deserialize-generic-class-variable)