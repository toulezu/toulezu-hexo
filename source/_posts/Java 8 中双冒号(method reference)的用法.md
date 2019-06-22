---
title: Java 8 中双冒号(method reference)的用法
title_url: understand-Java-8-method-reference
date: 2019-05-14
tags: [Java,Java8]
categories: Java
description: Java 8 中双冒号(method reference)的用法
---


## 概述

- 双冒号（::）是 Java 8 引入 Lambda 表达式后的一种用法，表示方法引用（method reference），可以更加简洁的实例化接口
- 双冒号表达式返回的是一个 函数式接口对象（用 @FunctionalInterface 注解的 interface 类型）的实例，如下：
    ```java
    @Test
    public void test0() {
        List<Integer> list = Arrays.asList(1, 2, 3);

        Consumer<Integer> consumer = System.out::println;
        list.forEach(consumer);
    }
    
    // java.util.function.Consumer
    @FunctionalInterface
    public interface Consumer<T> {
        void accept(T t);
    }
    ```

## 方法引用 Method Reference 具体使用

- 双冒号（::）运算符在 Java 8 中被用作方法引用（method reference），方法引用是与 lambda 表达式相关的一个重要特性。
- 它提供了一种不执行方法的方法：双冒号的方式只是指明方法引用，具体执行还是传统的方式。
- 方法引用需要兼容 函数式接口 组成的目标类型上下文：也就是说被引用的方法的参数和 函数式接口 的参数类型必须一致。
- 具体使用方式有以下几种
    1. 静态方法引用(Reference to a static method)
        - 语法：ContainingClass::staticMethodName 
        - 例如：Person::getAge
    2. 对象的实例方法引用(Reference to an instance method of a particular object)
        - 语法：containingObject::instanceMethodName
        - 例如：System.out::println
    3. 特定类型的任意对象实例的方法(Reference to an instance method of an arbitrary object of a particular type)
        - 语法：(ContainingType::methodName)
        - 例如：String::compareToIgnoreCase
    4. 类构造器引用语法(Reference to a constructor)：
        - 语法：ClassName::new 
        - 例如：ArrayList::new

#### 1 静态方法引用(Reference to a static method)

```java
public class StringUtils {
    public static void toUpperCase(String str) {
        System.out.println(str.toUpperCase());
    }

    public static void toInt(Long data) {
        System.out.println(data.intValue());
    }
}

@Test
public void test() {
    List<String> list = Arrays.asList("aaaa", "bbbb", "cccc");
    // 参数是 String, 正确
    list.forEach(StringUtils::toUpperCase);
    // 参数是 Long, 报错
    //list.forEach(StringUtils::toInt);
}
```

#### 2 对象的实例方法引用(Reference to an instance method of a particular object)

```java
public class StringUtils {
    public void toLowerCase(String str) {
        System.out.println(str.toLowerCase());
    }
}

@Test
public void test2() {
    List<String> list = Arrays.asList("AAAA", "BBBB", "CCCC");
    // 参数是 String, 正确
    list.forEach(new StringUtils()::toLowerCase);
}
```

#### 3 特定类型的任意对象实例的方法(Reference to an instance method of an arbitrary object of a particular type)

- 先看下官方的例子

```java
@Test
public void test3() {
    String[] stringArray = { "Barbara", "James", "Mary", "John", "Patricia", "Robert", "Michael", "Linda" };
    Arrays.sort(stringArray, String::compareToIgnoreCase);
    for (int i = 0; i < stringArray.length; i++) {
        System.out.println(stringArray[i]);
    }
}
```

- `String::compareToIgnoreCase`：看起来 compareToIgnoreCase 方法应该是 String 类的 static 方法，实际上不是，这怎么理解呢？下面来一一分解：

1. 这里的 `particular type` 是指 String 类型
2. `arbitrary object` 是指 String 对象
3. `instance method` 是指 String 对象的 compareToIgnoreCase
4. `Arrays.sort(stringArray, String::compareToIgnoreCase);` 用 lambda 可以写成 `Arrays.sort(stringArray, (o1, o2) -> o1.compareToIgnoreCase(o2));`
5. 可见 `Arrays.sort(T[] a, Comparator<? super T> c)` 中的 Comparator 实例第一个参数 o1 为 String 对象本身，o2 为 compareToIgnoreCase 方法的第一个参数，如果还有 o3 那就是第二参数

- 基于上面的分析写个例子：

```java
@FunctionalInterface
public interface Append {
    String append(StringAppend a, StringAppend b, StringAppend c);
}
```

```java
public class StringAppend {

    private String data;

    public String getData() {
        return data;
    }

    public StringAppend() {
    }

    public StringAppend(String data) {
        this.data = data;
    }

    public String append(StringAppend a, StringAppend b) {
        return this.getData() + a.getData() + b.getData();
    }

    public static String doAppend(String[] arr, Append append) {
        String result = "";
        for (int i = 0; i < arr.length; i++) {
            if (i+2 <= arr.length-1) {
                result += append.append(new StringAppend(arr[i]), new StringAppend(arr[i+1]), new StringAppend(arr[i+2]));
                i += 2;
            } else {
                result += append.append(new StringAppend(arr[i]), new StringAppend(""), new StringAppend(""));
            }

        }

        return result;
    }
}
```

```java
@Test
public void test5() {
    String[] stringArray = { "Barbara", "James", "Mary", "John", "Mike" };
    String str1 = StringAppend.doAppend(stringArray, (t1,t2,t3) -> t1.getData()+t2.getData()+t3.getData());
    String str2 = StringAppend.doAppend(stringArray, StringAppend::append);
    Assert.assertTrue(str1.equals(str2));
    System.out.println(str1);
}
```

最终输出为: BarbaraJamesMaryJohnMike

#### 4 类构造函数用法(Reference to a constructor)

下面的 ITool 和 JSONTool 用于将字符串转成 JSON 字符串

- 接口定义是传入一个字符串 name, 返回一个 JSONTool 对象

```java
public interface ITool {
    JSONTool create(String name);
}
```

- JSONTool 类的构造函数：`public JSONTool(String name)`

```java
import com.alibaba.fastjson.JSONObject;

public class JSONTool {

    private String name;

    public JSONTool(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }

    private static JSONObject parseJSON(JSONTool jsonTool) {
        JSONObject jsonObject = new JSONObject();
        jsonObject.put(jsonTool.getName(), jsonTool.getName());
        return jsonObject;
    }

    public static String getJSONString(String name, ITool iTool) {
        return parseJSON(iTool.create(name)).toJSONString();
    }

}
```

- 测试如下

```java
@Test
public void test4() {
    System.out.println(JSONTool.getJSONString("a", JSONTool::new));
}
```

- 输出如下

```json
{"a":"a"}
```

上面的例子分析如下：

1. 从字面上看 JSONTool::new 返回的是 ITool 接口对象的实例
2. 因此通过在 getJSONString 方法中调用 ITool 接口对象的实例的 create 方法返回一个 JSONTool 对象
3. 通过 lambda 也可以返回一个 ITool 接口对象实例：`t -> new JSONTool(t)`，因此测试代码写成下面的方式也可以
    ```java
    @Test
    public void test4() {
        //System.out.println(JSONTool.getJSONString("a", JSONTool::new));
        System.out.println(JSONTool.getJSONString("a", t -> new JSONTool(t)));
    }
    ```
4. 通过 Java 1.8 以前的匿名类方法如下
    ```java
    @Test
    public void test4() {
        //System.out.println(JSONTool.getJSONString("a", JSONTool::new));
        //System.out.println(JSONTool.getJSONString("a", t -> new JSONTool(t)));
        System.out.println(JSONTool.getJSONString("a", new ITool() {
            @Override
            public JSONTool create(String name) {
                return new JSONTool(name);
            }
        }));
    }
    ```

## 总结

1. 双冒号相比 Lambda 表达式更加简洁
2. 将方法作为接口的实例来使用

## 参考

- [Java8中的[方法引用]“双冒号”——走进Java Lambda(四)](https://blog.csdn.net/lsmsrc/article/details/41747159)
- [Java8 method references](https://docs.oracle.com/javase/tutorial/java/javaOO/methodreferences.html)
- [How does a method “reference to an instance method of an arbitrary object of a particular type” resolve the arbitrary object? ](https://stackoverflow.com/questions/32855138/how-does-a-method-reference-to-an-instance-method-of-an-arbitrary-object-of-a-p?rq=1)