---
title: 深入理解 Java 中的 CLASSPATH 类路径概念
title_url: understand-java-classpath
date: 2019-03-02
tags: Java
categories: 技术
description: 深入理解 Java 中的 CLASSPATH 类路径概念
---

## 概述

- 在通过命令行方式执行 Java 程序的时候通过 `-classpath` 选项来指定程序依赖的类库，也可以通过 `CLASSPATH` 环境变量来指定。
- 区别是 `-classpath` 选项只针对当前程序，而 `CLASSPATH` 环境变量可以设置到操作系统的环境变量中从而可以针对所有程序。
- `-classpath` 选项使用如下
```
java -jar classpath1:classpath2...
```

- `CLASSPATH` 环境变量使用如下
```
set CLASSPATH=classpath1;classpath2...
```

- `-cp` 是 `-classpath` 的简写，使用这个参数的 Java 命令还有 jar, javac, javadoc 和 apt, 更详细的说明：[JDK Tools and Utilities](https://docs.oracle.com/javase/8/docs/technotes/tools/index.html)
- 这些 Java 命令位于 `${JAVA_HOME}\bin` 目录下，通常情况下需要将这个目录设置到操作系统的 `path` 环境变量中，这样在 cmd 或者 shell 中就可以直接使用这些命令
- `-classpath` 参数值的几种使用情况
    - 如果是含有 class 文件的 jar 或者 zip 文件，直接用这些文件名，比如：`java -cp utils.jar`
    - 如果是一个含有 class 文件的目录， 并且类中没有 package 定义，直接使用目录名，比如：`java -jar c:/utils`
    - 如果是一个含有 class 文件的目录：c:/utils，而且该目录的类使用了包名: com.ckjava.test，应该这样使用：`java -cp c:/utils com.ckjava.test.TestCP`
- windows中多个类路径需要使用 `;` 分隔，Linux 中使用 `:`
- 默认的类路径是当前目录，用 `.` 表示，可以通过 `CLASSPATH` 环境变量或者 `classpath` 参数来覆盖默认的类路径
- 如果类中有 package 定义，那么 `.` 无法表示当前类路径，必须通过 `classpath` 参数来指定

## PATH 操作系统环境变量和 CLASSPATH 环境变量

- PATH 是操作系统环境变量，CLASSPATH 是 Java 系统的环境变量，PATH 和 CLASSPATH 大小写都可以
- 下面举个综合的例子，使用了 javac 和 java 命令
    - TestCP.java, 所在目录: `F:\testjava\com\ckjava\test` , 内容如下
    ```
    package com.ckjava.test;
    
    public class TestCP {
        public static void main(String[] args) {
            TestObj testObj = new TestObj();
            testObj.test();
        }
    }
    ```
    - TestObj.java, 所在目录: `F:\testjava\com\ckjava\test` 内容如下
    ```
    package com.ckjava.test;

    public class TestObj {
        public void test() {
            System.out.println("this is TestObj");
        }
    }
    ```
    - 使用 javac 编译 TestCP.java 如下
    ```
    f:\>javac -cp F:/testjava F:/testjava/com/ckjava/test/TestCP.java
    ```
    其中 `-cp` 指定了类路径，**注意没有包含包名并且是在 f 盘根目录执行 javac 命令的**，由于 TestCP.java 依赖了 TestObj.java, 执行编译后同时生成了 TestCP.class 和 TestObj.class
    - 使用 java 执行 TestCP.class 命令如下
    ```
    f:\>java -cp F:/testjava com.ckjava.test.TestCP
    ```
    输出如下
    ```
    this is TestObj
    ```
    - 上面的 javac 和 java 命令都是配置在操作系统的 PATH 变量中的，如何使用其他版本的 javac 和 java 命令呢？下面的方法可以重置 PATH 操作系统环境变量和 CLASSPATH 环境变量，编写 `run.cmd` 脚本如下
    ```
    @echo off
    set path=D:\java\jdk1.6.0_25\bin
    set classpath=F:/testjava
    
    javac F:/testjava/com/ckjava/test/TestCP.java
    java com.ckjava.test.TestCP
    ```
    执行：`F:\>testjava\com\ckjava\test\run.cmd` 输出如下
    ```
    this is TestObj
    ```
    
## 类路径通配符

- 可以通过`*`来匹配一个目录的所有 jar 文件，比如：`/lib/*`，不能通过 `/**/*.jar` 方式，这个有点弱鸡了。
- 而且 `/lib/*` 这种方式只能匹配 lib 目录下所有 jar 文件，不能匹配 class 文件
- 下面举个综合的例子
    - TestUtils.java 内容如下
    ```
    package com.ckjava.test;
    import com.ckjava.utils.StringUtils;
    
    public class TestUtils {
        public static void main(String[] args) {
            if (StringUtils.isNotBlank(args[0])) {
                System.out.println(args[0]);
            }
        }
    }
    ```
    其中 StringUtils 是在 `F:\testjava\lib\commons-lang3-3.5.jar` 中
	
    - run-2.cmd 脚本的内容如下
    ```
    @echo off
    set path=C:\Program Files\Java\jdk1.8.0_131\bin
    set classpath=F:\testjava\lib\*;F:\testjava\
    
    javac F:/testjava/com/ckjava/test/TestUtils.java
    java com.ckjava.test.TestUtils date
    ```
    其中通过 `F:\testjava\lib\*` 指定所有依赖 jar 的位置，`F:\testjava\` 指定class 文件
    执行 `F:\>testjava\com\ckjava\test\run-2.cmd` 输出如下
    ```
    date
    ```

## 遇到的问题：找不到或无法加载主类(Error: Could not find or load main class ...")

- 错误重现： 到 `f:\testjava\com\ckjava\test` 目录，执行 `javac TestCP.java` 命令，可以正常编译 TestObj.class 和  TestCP.class， 但是执行 `java TestCP` 会出现第一个错误，具体如下
```
f:\testjava\com\ckjava\test>java TestCP
错误: 找不到或无法加载主类 TestCP
```

- 原因：javac 编译的时候在类源文件的目录下，所以无需通过 `-cp` 指定类路径，但是通过 java 运行 class 的时候，由于 class 中有包名，所以还需要指定包名才能运行，具体如下
```
f:\testjava\com\ckjava\test 的目录

2019/03/03  19:16    <DIR>          .
2019/03/03  19:16    <DIR>          ..
2019/03/03  13:58               193 run-2.cmd
2019/03/03  13:13               148 run.cmd
2019/03/03  19:16               344 TestCP.class
2019/03/03  13:29               174 TestCP.java
2019/03/03  19:16               414 TestObj.class
2019/03/03  11:23               136 TestObj.java
2019/03/03  13:42               249 TestUtils.java
               7 个文件          1,658 字节
               2 个目录 55,266,729,984 可用字节

f:\testjava\com\ckjava\test>java com.ckjava.test.TestCP
this is TestObj
```

- 如果在其他目录，那么正确的编译和执行的方式如下
```
f:\testjava\com>javac -cp f:\testjava F:/testjava/com/ckjava/test/TestCP.java

f:\testjava\com>java -cp f:\testjava com.ckjava.test.TestCP
this is TestObj
```

- 总结：
    - javac 命令编译的时候要指定类路径和完整的 Java 源文件路径
    - java 命令执行的时候指定类路径和完整的包名，如果没有包名，就无需指定了
    - 如果类文件在 jar 中呢？，具体的指定方式如下
    ```
    F:\testjava>jar -cvf testLib.jar com/ckjava/test/TestCP.class com/ckjava/test/TestObj.class
    已添加清单
    正在添加: com/ckjava/test/TestCP.class(输入 = 344) (输出 = 250)(压缩了 27%)
    正在添加: com/ckjava/test/TestObj.class(输入 = 414) (输出 = 286)(压缩了 30%)
    
    F:\testjava>java -cp F:\testjava\testLib.jar com.ckjava.test.TestCP
    this is TestObj
    ```
    - 上面的例子需要注意的地方：**当类中指定了 `package com.ckjava.test;` 那么在通过 jar 打包的时候类文件也必须带上相应的路径，而且这个路径必须是相对路径。**

## 总结

本文深入介绍了如下技术点

- JDK 命令行工具 `-classpath` 参数
- PATH 操作系统环境变量和 CLASSPATH 环境变量，以及 Java 程序执行脚本的编写
- 类路径通配符概念以及使用
- JDK 中 javac, java, jar 命令行工具的基本使用
	
## 参考

- [Setting the Class Path](https://docs.oracle.com/javase/8/docs/technotes/tools/windows/classpath.html#A1100592)
