---
title: 详解 Jackson 中的 JsonNode 类中的 at 方法
title_url: Jackson-JsonNode-at-practice
date: 2020-06-15
tags: [Java,Jackson]
categories: Jackson
description: 详解 Jackson 中的 JsonNode 类中的 at 方法
---

## 1 概述

本文详细介绍 Jackson 中的 JsonNode 类中的 at 方法的使用， 具体如下

1. 从 json 字符串中快速读取指定的字段值
2. 从 json 字符串中快速读取指定的 json 对象
3. 实例中分别以 json 对象字符串 和 json 数组字符串为例进行试验

## 2 实例

#### 2.1 从 json 对象字符串中读取

1. 读取 json 字符串为 JsonNode 对象
2. 读取单个字段
3. 读取数组中的某项的某个字段
4. 读取数组为 JsonNode 对象
5. 将数组中某个对象转成 pojo

```json
{
  "library": "My Personal Library",
  "total": 2,
  "books": [
    { "title":"Title 1", "author":"Jane Doe" },
    { "title":"Title 2", "author":"John Doe" }
  ]
}
```

```java
private static class Book {
    private String title;
    private String author;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAuthor() {
        return author;
    }

    public void setAuthor(String author) {
        this.author = author;
    }

    public Book() {
    }

    @Override
    public String toString() {
        final StringBuilder sb = new StringBuilder("Book{");
        sb.append("title='").append(title).append('\'');
        sb.append(", author='").append(author).append('\'');
        sb.append('}');
        return sb.toString();
    }
}
    
protected void readTestFile(String filePath, Consumer<String> consumer) {
    try {
        InputStream inputStream = TestCdWebHookCom.class.getResourceAsStream(filePath);
        BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(inputStream));
        String temp;
        StringBuilder data = new StringBuilder();
        while ((temp = bufferedReader.readLine()) != null) {
            data.append(temp);
        }
        consumer.accept(data.toString());
    } catch (Exception e) {
        e.printStackTrace();
    }
}
    
private ObjectMapper mapper = new ObjectMapper();

@Test
public void testObjAt() {
    readTestFile("/testPointObj.json", dataString -> {

        try {
            // 读取 json 字符串为 JsonNode 对象
            JsonNode data = mapper.readTree(dataString);

            // 读取单个字段
            int total = data.at("/total").asInt();
            // 读取数组中的某项的某个字段
            String title = data.at("/books/0/title").asText();
            System.out.println(String.format("total:%s, 0 title:%s", total, title));
            // 读取数组为 JsonNode 对象
            JsonNode nodeArr = data.at("/books");
            nodeArr.forEach(jsonNode -> {
                // 将数组中某个对象转成 pojo
                try {
                    Book book1 = mapper.readValue(jsonNode.toString(), Book.class);
                    System.out.println(book1.toString());
                } catch (Exception e) {
                    e.printStackTrace();
                }

            });

        } catch (Exception e) {
            e.printStackTrace();
        }

    });
}
```

- 输出如下

```
total:2, 0 title:Title 1
Book{title='Title 1', author='Jane Doe'}
Book{title='Title 2', author='John Doe'}
```

#### 2.2 从 json 数组字符串中读取

1. 读取数组中某项某个对象的某个字段

```
[
  {
    "library": "My Personal Library",
    "total": 2,
    "books": [
      {
        "title": "Title 1",
        "author": "Jane Doe"
      },
      {
        "title": "Title 2",
        "author": "John Doe"
      }
    ]
  },
  {
    "library": "public Library",
    "total": 4,
    "books": [
      {
        "title": "Title 1",
        "author": "Jane Doe"
      },
      {
        "title": "Title 2",
        "author": "John Doe"
      },
      {
        "title": "Title 3",
        "author": "John e"
      }
    ]
  }
]
```

```
@Test
public void testArrAt() {
    readTestFile("/testPointArr.json", dataString -> {

        try {
            JsonNode data = mapper.readTree(dataString);

            // 读取数组中某项某个对象的某个字段
            String title = data.at("/1/books/0/title").asText();
            System.out.println(String.format("title:%s", title));
        } catch (Exception e) {
            e.printStackTrace();
        }

    });
}
```

- 输出如下

```
title:Title 1
```