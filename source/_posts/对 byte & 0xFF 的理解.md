---
title: 对 byte & 0xFF 的理解
title_url: java-byte-0XFF
date: 2018-05-03
tags: Java
categories: [Java]
description: 这篇博客涉及到对 Java 基本类型的转换, 对原码, 反码, 补码的理解, 对 移位运算, 位运算 的应用.
---

这篇博客涉及到对 Java 基本类型的转换, 对原码, 反码, 补码的理解, 对 移位运算, 位运算 的应用.

## 由一段代码引入的思考

先看看下面一段代码

```
/** 字节数组转成16进制字符串 **/
public static String byte2hex(byte[] b) { // 一个字节的数，
    StringBuffer sb = new StringBuffer(b.length * 2);
    String tmp = "";
    for (int n = 0; n < b.length; n++) {
        // 整数转成十六进制表示
        tmp = Integer.toHexString(b[n] & 0XFF);
        if (tmp.length() == 1) {
            sb.append("0");
        }
        sb.append(tmp);
    }
    return sb.toString().toUpperCase(); // 转成大写
}
```

其中关键是 `b[n] & 0XFF`, 为什么要一个 byte 要和`0XFF`进行与(&)运算后再传给 `toHexString` 方法?

目前知道的一点是 `0XFF` 也就是 int 类型的 255, 在 Java 中可以使用八进制、十六进制的数据直接给long, int, short, byte类型的数据赋值.

## 关于原码, 反码, 补码

计算机要使用一定的编码方式进行存储. 原码, 反码, 补码是机器存储一个具体数字的编码方式.

#### 1. 原码

原码就是符号位加上真值的绝对值, 即用第一位表示符号, 其余位表示值. 比如如果是8位二进制:

`[+1]原 = 0000 0001`

`[-1]原 = 1000 0001`

第一位是符号位. 因为第一位是符号位, 所以8位二进制数的取值范围就是:

`[1111 1111 , 0111 1111]`

即

`[-127 , 127]`

#### 2. 反码

反码的表示方法是:

正数的反码是其本身

负数的反码是在其原码的基础上, 符号位不变，其余各个位取反.

`[+1] = [00000001]原 = [00000001]反`

`[-1] = [10000001]原 = [11111110]反`

可见如果一个反码表示的是负数, 人脑无法直观的看出来它的数值. 通常要将其转换成原码再计算.

#### 3. 补码

补码的表示方法是:

正数的补码就是其本身

负数的补码是在其原码的基础上, 符号位不变, 其余各位取反, 最后+1. (即在反码的基础上+1)

`[+1] = [00000001]原 = [00000001]反 = [00000001]补`

`[-1] = [10000001]原 = [11111110]反 = [11111111]补`

对于负数, 补码表示方式也是人脑无法直观看出其数值的. 通常也需要转换成原码在计算其数值.

从上面可以看到, 对于正数: 原码, 反码, 补码都是一样的, 对于负数:原码, 反码, 补码都不一样.

## 关于`&`与运算

`&`运算是二进制数据的计算方式, 两个操作位都为1，结果才为1，否则结果为0. 在上面的 `b[n] & 0XFF` 计算过程中, byte 有 8bit, `OXFF` 是16进制的255, 表示的是 int 类型, int 有 32bit.

如果b[n]为 `-118`, 那么其原码表示为

> 00000000 00000000 00000000 10001010

反码为

> 11111111 11111111 11111111 11110101 

补码为

> 11111111 11111111 11111111 11110110


`0XFF` 表示16进制的数据255, 原码, 反码, 补码都是一样的, 其二进制数据为

> 00000000 00000000 00000000 11111111

`0XFF` 和 `-118` 进行`&`运算后结果为

> 00000000 00000000 00000000 11110110

还原为原码后为

> 00000000 00000000 00000000 10001010

其表示的 int 值为 138, 可见将 byte 类型的 -118 与 `0XFF` 进行与运算后值由 -118 变成了 int 类型的 138, 其中低8位和byte的-118完全一致.

如果b[n]为0或者正数, 其原码, 反码, 补码都是一样的, 和 `0XFF` 进行与运算后的结果不变.

byte 的取值范围为 [-128, 127], 根据上面的转换过程我们可以发现, 只有当 byte 的值为负数的时候才有必要和`0XFF` 进行与运算, 为0或者为正数的时候byte的值和对应int的值完全一致.

## 关于无符号`>>>`右移运算

通过上面的对 原码, 反码, 补码 和 `&`与运算的理解已经可以解答:**为什么一个字节要和`0XFF`进行与(&)运算后再传给 `toHexString` 方法?**这个问题. 这里再深入了解一下 int 和 byte 互转的问题.

#### int 转 byte数组

int 有 32bit, byte 有 8bit, 那么一个 int 转成 byte 后有 4 个byte. 过程如下

```java
public static byte[] intToBytes(int a) {
	byte[] intbyte = new byte[4];
	
	byte b = (byte) (a >>> 24);
	byte c = (byte) (a >>> 16);
	byte d = (byte) (a >>> 8);
	byte e = (byte) (a);
	
	intbyte[0] = b;
	intbyte[1] = c;
	intbyte[2] = d;
	intbyte[3] = e;
	
	return intbyte;
}
```

其中用到了无符号`>>>`右移运算, 为什么不用有符号`>>`右移运算呢? 两者的区别在于前者向右移动后无论当前数据是正数还是负数都用 `0` 来填充.

这里拿值为 -10 的 byte 举个例子.

```
int a = -120;
System.out.println("toBinaryString(a)="+Integer.toBinaryString(a));

int b = a >>> 2;
int c = a >> 2;
System.out.println("int b="+b);
System.out.println("toBinaryString(b)="+Integer.toBinaryString(b));
System.out.println("int c="+c);
System.out.println("toBinaryString(c)="+Integer.toBinaryString(c));
```

输出如下

```
toBinaryString(a)=11111111111111111111111110001000
b=1073741794
toBinaryString(b)=111111111111111111111111100010
c=-30
toBinaryString(c)=11111111111111111111111111100010
```

可见对b进行无符号`>>>`右移运算2位后, 高2位变成了`00`. 

还有一点需要注意的是:无符号右移运算符 `>>>` 只对32位和64位的值有意义.

回到上面 int 转 byte 的例子. 如果传入的 int 值为 55588, 其二进制表示为


> 00000000 00000000 11011001 00100100


- `>>> 24` 无符号向右移动 24 位后为(把`00000000 11011001 00100100`挤掉了,高位用`0`填充)


> 00000000 00000000 00000000 **00000000**


转成 byte 后为 `00000000` (其实就是低8位), intbyte数组下标0的值为 `00000000`

- `>>> 16` 无符号向右移动 16 位后为(把`11011001 00100100`挤掉了,高位用`0`填充)


> 00000000 00000000 **00000000 00000000**


转成 byte 后为 `00000000`, intbyte数组下标1的值为 `00000000`

- `>>> 8` 无符号向右移动 8 位后为(把`00100100`挤掉了,高位用`0`填充)

> 00000000 00000000 00000000 **11011001**

转成 byte 后为 `11011001`, intbyte数组下标2的值为 `11011001`

- 最后intbyte数组下标3的值为 `00100100`.

经过上面的计算, 就将一个 int 转成了长度为4的 byte 数组.

#### byte数组 转 int

对于上面的 byte 数组如何转回 int 呢? 方法如下

```java
int a = (intbyte[0] & 0xFF) << 24;
int b = (intbyte[1] & 0xFF) << 16; 
int c = (intbyte[2] & 0xFF) << 8; 
int d = (intbyte[3] & 0xFF);
System.out.println("a|b|c|d = " + (a|b|c|d));
```

其中想当然会用到`<<`左移动, 因为前面用到了右移嘛.

第一个 byte 先跟 `0XFF` 进行与运算转成 int, 然后向左移动 24 位变成 a

> **00000000** 00000000 00000000 00000000

第二个 byte 先跟 `0XFF` 进行与运算转成 int, 然后向左移动 16 位变成 b

> 00000000 **00000000** 00000000 00000000

第三个 byte 先跟 `0XFF` 进行与运算转成 int, 然后向左移动 8 位变成 c

> 00000000 00000000 **11011001** 00000000

第四个 byte 跟 `0XFF` 进行与运算转成 int d

> 00000000 00000000 00000000 **00100100**

最后还要用到`|`或运算, 或运算规律：两个位只要有一个为1，那么结果就是1，否则就为0. 

a 和 b 的或运算结果为

> **00000000** **00000000** 00000000 00000000

上面的结果再和 c 的或运算结果为

> **00000000** **00000000** **11011001** 00000000

上面的结果再和 d 的或运算结果为

> **00000000** **00000000** **11011001** **00100100**

最终将 byte 数组又转成了 int.

#### 单个 byte 转成 int

根据上面的分析, 单个 byte 转成 int 其实就是将 byte 和 int 类型的 255 进行(&)与运算即可. 

```
byte b = 25;
int a = b & 0XFF; // 或者 b & 255;
```

现在已经知道了在 Java 中通过补码来表示负数, 对于0和正数来说:原码,反码,补码都是一样的. 那么可以得出的结论是:**对于 byte[-128,127], 其[0,127]范围的数据和 int 中的 [0,127] 完全一致,不需要 `& 0XFF`, 只有对于 [-128,-1] 的 byte 数据才需要 `& 0XFF`**.

```java
System.out.println(Integer.toHexString((byte)138 & 0XFF).toUpperCase());
System.out.println(Integer.toHexString(138).toUpperCase());

System.out.println(Integer.toHexString((byte)-138 & 0XFF).toUpperCase());
int a = (byte)-138 & 0XFF;
System.out.println("a="+a);
System.out.println(Integer.toHexString(a).toUpperCase());
```

运行结果如下

```
8A
8A
76
a=118
76
```

## 最后一个问题

`Integer.toHexString(b[n] & 0XFF);` 返回16进制的字符串，最长2个字符，最少1个字符，为什么？这个就相对简单了，无需研究 `toHexString` 方法的具体实现，实验的方法如下

```java
byte a = -128;
byte c = 0;
byte b = 127;
System.out.println(Integer.toHexString(a & 0XFF));
System.out.println(Integer.toHexString(c & 0XFF));
System.out.println(Integer.toHexString(b & 0XFF));
```

返回的结果如下

```
80
0
7f
```

对于 byte[-128,127] 转成16进制后都小于 `OXFF`（255）, 因此是不会超过3个字符串的。

## 参考

- [0xFF 是什么?](http://zim.logdown.com/posts/397666-0xff-is)
- [原码, 反码, 补码 详解](https://www.cnblogs.com/zhangziqiu/archive/2011/03/30/ComputerCode.htm)
- [浅谈 &0xFF操作](https://blog.csdn.net/LVGAOYANH/article/details/53486933)
- [Java 位运算(移位、位与、或、异或、非）](https://blog.csdn.net/xiaochunyong/article/details/7748713)