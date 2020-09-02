---
title: 详解 RandomAccessFile 的使用以及使用场景分析
title_url: Java-RandomAccessFile-understand-practice
date: 2020-09-02
tags: [Java,IO,RandomAccessFile]
categories: [Java,IO,RandomAccessFile]
description: 详解 RandomAccessFile 的使用以及使用场景分析
---

## 1 概述

- java.io.RandomAccessFile

![RandomAccessFile](data:image/png;base64,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)

- RandomAccessFile 用于在文件的任意位置读写数据，并且不会消耗太多的内存。
- RandomAccessFile 虽然属于 `java.io` 下的类，但它不是 InputStream 或者 OutputStream 的子类；它也不同于 FileInputStream 和 FileOutputStream。 FileInputStream 只能对文件进行读操作，而 FileOutputStream 只能对文件进行写操作。
- RandomAccessFile 与输入流和输出流不同之处就是 RandomAccessFile 可以访问文件的任意地方同时支持文件的读和写，并且它通过 seek 方法实现在文件的任意位置读写访问。
- RandomAccessFile 包含 InputStream 的三个 read 方法，也包含 OutputStream 的三个 write 方法。同时 RandomAccessFile 还包含一系列的 readXxx 和 writeXxx 方法完成输入输出。 

## 2 关键点

1. 通过 seek 方法设置开始随机读写文件的位置，以字节为单位。
2. 通过 length 方法返回目标文件的长度，以字节为单位。

## 3 构造函数

1. `RandomAccessFile(File file, String mode)`：创建随机访问文件流，以从 File 参数指定的文件中读取，并可选择写入文件。
2. `RandomAccessFile(String name, String mode)`: 创建随机访问文件流，以从中指定的完整文件路径和名称读取，并可选择写入文件。

其中构造函数中 mode 参数传值介绍:

1. `r` 代表以只读方式打开指定文件。
2. `rw` 以读写方式打开指定文件。
3. `rws` 读写方式打开，并对内容或元数据都同步写入底层存储设备。
4. `rwd` 读写方式打开，对文件内容的更新同步更新至底层存储设备。

## 4 具体使用

#### 4.1 每次固定从文件中读取指定数量的字节，并通过 Consumer 接口对象进行处理

- 封装功能如下

```java
/**
 * 每次固定从文件中读取指定数量的字节，并通过 Consumer 接口对象进行处理
 *
 * @param file 指定文件
 * @param bytesCount 每次读取的固定字节数，如果为 -1 表示读取全部的
 * @param consumer Consumer 接口对象
 */
public static void fixRateReadBytes(File file, int bytesCount, Consumer<byte[]> consumer) {
    try {
        RandomAccessFile randomAccessFile = new RandomAccessFile(file, "r");
        long dataSize = randomAccessFile.length();
        logger.debug(String.format("file length=%s, 求模=%s, getFilePointer=%s", dataSize, dataSize % 2, randomAccessFile.getFilePointer()));

        if (bytesCount == -1) {
            byte[] allData = new byte[(int)dataSize];
            randomAccessFile.read(allData);
            consumer.accept(allData);
        }
        AtomicInteger count = new AtomicInteger(0);
        IntStream.range(0, (int) dataSize).forEach(i -> {
            int index = count.incrementAndGet();
            if (index == bytesCount) {
                byte[] rowData = new byte[bytesCount];
                try {
                    randomAccessFile.read(rowData);
                    consumer.accept(rowData);
                } catch (Exception e) {
                    logger.error("fixRateReadBytes has error", e);
                }
                count.set(0);
            }
        });

    } catch (Exception e) {
        logger.error("fixRateReadBytes has error", e);
    }
}
```

- 测试如下

```java
@Test
public void test_fixRateReadBytes() {
    System.out.println(System.getProperty("file.encoding"));

    FileUtils.fixRateReadBytes(new File("E:\\test.txt"), 2, data -> {
        System.out.println(String.format("data:%s", new String(data)));
    });
}
```

- 执行结果如下

```java
UTF-8
data:ab
data:ee
data:zz
data:ee
```

- 其中 E:\test.txt 的文件内容如下

```
abeezzee
```

#### 4.2 跳过指定的字节数后再读取指定字节的数据

- 封装功能如下

```java
/**
 * 跳过指定的字节数后再读取指定字节的数据
 *
 * @param file 指定文件
 * @param skipBytesCount 跳过指定的字节数
 * @param readBytes 读取的字节数
 * @param consumer Consumer 接口对象
 */
public static void skipReadBytes(File file, int skipBytesCount, int readBytes, Consumer<byte[]> consumer) {
    try {
        RandomAccessFile randomAccessFile = new RandomAccessFile(file, "r");
        long dataSize = randomAccessFile.length();
        logger.debug(String.format("file length=%s, 求模=%s, getFilePointer=%s", dataSize, dataSize % 2, randomAccessFile.getFilePointer()));
        randomAccessFile.seek(skipBytesCount);

        byte[] rowData = new byte[readBytes];
        randomAccessFile.read(rowData);

        consumer.accept(rowData);
    } catch (Exception e) {
        logger.error("skipReadBytes has error", e);
    }
}
```

- 测试如下

```java
@Test
public void test_skipReadBytes() {
    System.out.println(System.getProperty("file.encoding"));

    FileUtils.skipReadBytes(new File("E:\\test.txt"), 2, 2, data -> {
        System.out.println(String.format("data:%s", new String(data)));
    });
}
```

- 执行结果如下

```java
UTF-8
data:ee
```

- 其中 E:\test.txt 的文件内容如下

```
abeezzee
```

#### 4.3 跳过指定的字节数后再 写入 指定字节的数据，最后返回被替换的字节数

- 封装功能如下

```java
/**
 *
 * 跳过指定的字节数后再 写入 指定字节的数据，最后返回被替换的字节数
 *
 * @param file 指定的文件
 * @param skipBytesCount 跳过指定的字节数
 * @param writeBytes 写入的字节
 * @return byte[] 被替换的字节
 */
public static byte[] skipWriteBytes(File file, int skipBytesCount, byte[] writeBytes) {
    try {
        RandomAccessFile randomAccessFile = new RandomAccessFile(file, "rw");
        long dataSize = randomAccessFile.length();
        logger.debug(String.format("file length=%s, 求模=%s, getFilePointer=%s", dataSize, dataSize % 2, randomAccessFile.getFilePointer()));
        // 跳过的字节数
        randomAccessFile.seek(skipBytesCount);

        byte[] replaceBytes = new byte[writeBytes.length];
        randomAccessFile.read(replaceBytes);
        // 退回到读取字节前的位置
        randomAccessFile.seek(skipBytesCount);

        // 写入新的数据
        randomAccessFile.write(writeBytes);

        return replaceBytes;
    } catch (Exception e) {
        logger.error("skipWriteBytes has error", e);
        return null;
    }
}
```

- 测试如下

```java
@Test
public void test_skipWriteBytes() {
    System.out.println(System.getProperty("file.encoding"));

    String dataString = "ee";
    byte[] dataBytes = dataString.getBytes();

    byte[] replaceBytes = FileUtils.skipWriteBytes(new File("E:\\test.txt"), 2, dataBytes);
    System.out.println(String.format("replace data=%s", new String(replaceBytes)));

    FileUtils.skipReadBytes(new File("E:\\test.txt"), 2, dataBytes.length, data -> {
        System.out.println(String.format("data:%s", new String(data)));
    });
}
```

- 执行结果如下

```java
UTF-8
replace data=eez
data:yin
```

- 其中 E:\test.txt 的文件内容前后变化如下

```
abeezzee
```

```
abyinzee
```

#### 4.4 向文件追加指定字节数据

- 封装功能如下

```java
/**
 * 向文件追加指定字节数据
 *
 * @param file 指定的文件
 * @param writeBytes 追加的字节数据
 */
public static void appendBytes(File file, byte[] writeBytes) {
    try {
        RandomAccessFile randomAccessFile = new RandomAccessFile(file, "rw");
        long dataSize = randomAccessFile.length();
        logger.debug(String.format("file length=%s, 求模=%s, getFilePointer=%s", dataSize, dataSize % 2, randomAccessFile.getFilePointer()));
        // 跳过的字节数
        randomAccessFile.seek(dataSize);
        // 写入新的数据
        randomAccessFile.write(writeBytes);
    } catch (Exception e) {
        logger.error("appendBytes has error", e);
    }
}
```

- 测试如下

```java
@Test
public void test_appendBytes_1() throws Exception {
    String dataString = "abc";
    byte[] dataBytes = dataString.getBytes();

    File file = new File("E:\\test.txt");
    // 追加数据前
    FileUtils.fixRateReadBytes(file, -1, data -> {
        System.out.println(String.format("追加数据前 data=%s", new String(data)));
    });

    // 追加数据
    FileUtils.appendBytes(file, dataBytes);

    // 追加数据前
    FileUtils.fixRateReadBytes(file, -1, data -> {
        System.out.println(String.format("追加数据后 data=%s", new String(data)));
    });
}
```

- 执行结果如下

```
追加数据前 data=abyinzeeabc
追加数据后 data=abyinzeeabcabc
```

## 5 方法

常用的方法如下：

- `void close()`: 关闭此随机访问文件流并释放与该流关联的所有系统资源。
- `FileChannel getChannel()`:  返回与此文件关联的唯一 FileChannel 对象。
- `FileDescriptor getFD()`: 返回与此流关联的不透明文件描述符对象。
- `long getFilePointer()`: 返回此文件中的当前偏移量。
- `long length()`: 返回此文件的长度。
- `int read()`: 从此文件中读取一个数据字节。
- `int read(byte[] b)`:  将最多 b.length 个数据字节从此文件读入 byte 数组。
- `int read(byte[] b, int off, int len)`: 将最多 len 个数据字节从此文件读入 byte 数组。
- `boolean readBoolean()`: 从此文件读取一个 boolean。
- `byte readByte()`: 从此文件读取一个有符号的八位值。
- `char readChar()`: 从此文件读取一个字符。
- `double readDouble()`: 从此文件读取一个 double。
- `float readFloat()`: 从此文件读取一个 float。
- `void readFully(byte[] b)`:  将 b.length 个字节从此文件读入 byte 数组，并从当前文件指针开始。
- `void readFully(byte[] b, int off, int len)`: 将正好 len 个字节从此文件读入 byte 数组，并从当前文件指针开始。
- `int readInt()`: 从此文件读取一个有符号的 32 位整数。
- `String readLine()`: 从此文件读取文本的下一行。
- `long readLong()`:  从此文件读取一个有符号的 64 位整数。
- `short readShort()`: 从此文件读取一个有符号的 16 位数。
- `int readUnsignedByte()`: 从此文件读取一个无符号的八位数。
- `int readUnsignedShort()`: 从此文件读取一个无符号的 16 位数。
- `String readUTF()`: 从此文件读取一个字符串。
- `void seek(long pos)`: 设置到此文件开头测量到的文件指针偏移量，在该位置发生下一个读取或写入操作。
- `void setLength(long newLength)`: 设置此文件的长度。
- `int skipBytes(int n)`: 尝试跳过输入的 n 个字节以丢弃跳过的字节。
- `void write(byte[] b)`:  将 b.length 个字节从指定 byte 数组写入到此文件，并从当前文件指针开始。
- `void write(byte[] b, int off, int len)`: 将 len 个字节从指定 byte 数组写入到此文件，并从偏移量 off 处开始。
- `void write(int b)`: 向此文件写入指定的字节。
- `void writeBoolean(boolean v)`: 按单字节值将 boolean 写入该文件。
- `void writeByte(int v)`: 按单字节值将 byte 写入该文件。
- `void writeBytes(String s)`:  按字节序列将该字符串写入该文件。
- `void writeChar(int v)`: 按双字节值将 char 写入该文件，先写高字节。
- `void writeChars(String s)`:  按字符序列将一个字符串写入该文件。
- `void writeDouble(double v)`: 使用 Double 类中的 doubleToLongBits 方法将双精度参数转换为一个 long，然后按八字节数量将该 long 值写入该文件，先定高字节。
- `void writeFloat(float v)`: 使用 Float 类中的 floatToIntBits 方法将浮点参数转换为一个 int，然后按四字节数量将该 int 值写入该文件，先写高字节。
- `void writeInt(int v)`: 按四个字节将 int 写入该文件，先写高字节。
- `void writeLong(long v)`: 按八个字节将 long 写入该文件，先写高字节。
- `void writeShort(int v)`: 按两个字节将 short 写入该文件，先写高字节。
- `void writeUTF(String str)`: 使用 modified UTF-8 编码以与机器无关的方式将一个字符串写入该文件。

## 6 使用场景

1. 断点续传，记录已经下载的字节数，继续下载的时候，跳过已经下载的字节，继续进行下载。
2. 向大文件（比如 100G 的文件）任意位置读取或者插入，修改指定内容。 

#### 6.1 断点续传

1. 手机端向服务器端下载文件，初始请求关键字段: `手机标识，文件名称，字节偏移（seek 方法的参数 = 0）`
2. 突然网络中断，手机端统计共下载了 25%，500 个字节，还剩下 1500 个字节
3. 手机端再次向服务器发送下载请求的时候，需要请求的关键字段：`手机标识，文件名称，字节偏移（seek 方法的参数 = 500）`

#### 6.2 大文件读写

1. 将数十亿商品详细信息存储在一个文件中，共计 10 G，然后在一个 hashMap 中存储了每个商品的 id 以及对应商品详细信息在文件中的偏移(offset)。
2. 这样根据 id 找到 偏移(offset)，就可以通过 seek(offset) 直接获取商品的详细信息。