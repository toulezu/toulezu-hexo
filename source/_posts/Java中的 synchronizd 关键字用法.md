---
title: Java 中的 synchronizd 关键字在同步中的使用
title_url: Java-synchronizd-usage
date: 2016-06-07
tags: Java
categories: [Java,并发]
description: Java 中的 synchronizd 关键字在同步中的使用
---

### 为什么要线程同步

- 同步的目的是避免在同一个时间点操作同一个数据
- 这里操作是指`update`，`delete`，数据是指任意对象
- 每一个对象都有一把锁，`synchronized` 就是为此对象上锁，等到 `synchronized` 方法或`synchronized` 代码块执行完就会自动解锁，所有多线程执行相同带`synchronized`的代码时会检查所操作对象是否上锁，如果已经被锁住，就阻塞等待，直到锁此代码段的线程执行完此代码块。

### synchronized 5种用法

-	用在普通方法上
```java
public synchronized void test() {
 // 业务代码
}
```
-	用在静态方法上
```java
public static synchronized void test3() {
 // 业务代码
}
```
-	用在代码块，括号里面是this
```java
public void test1() {
    synchronized(this) {
      // 业务代码
	  }
}
```
-	用在代码块，括号里面是类的一个实例，和this类似
```java
public void test11() {
  Sync sync = this;
  synchronized(sync) {
    // 业务代码
  }
}
```
-	用在代码块，括号里面是类
```java
public void test2() {
  synchronized (Sync.class) {
      // 业务代码
  }
}
```

synchronized 锁住的是括号里的对象，而不是代码。对于非静态的 synchronized 方法，锁的就是对象本身也就是this。

当 synchronized 锁住一个对象后，别的线程如果也想拿到这个对象的锁，就必须等待这个线程执行完成释放锁，才能再次给对象加锁，这样才达到线程同步的目的。

```java
public class SynchronizedTest {
	
	Person p = new Person("lin", 15);
	
	public synchronized void say() {//相当于锁住this，效果和say3()一样，只要多个线程同时访问同一个SynchronizedTest实例（相当于this），就会发生不能同时访问此方法
		System.out.println(p.getName());
	}
	
	public void say2() {
		synchronized(p) {//相当于锁住p，只要多个线程同时访问此代码块且是同一个p，那么在同一时间，只有一个线程能对P进行操作。
			System.out.println(p.getName());
		}
	}
	
	public void say3() {
		synchronized(this) {//锁住this，效果和say()一样，只要多个线程同时访问同一个SynchronizedTest实例（this），就会发生不能同时访问此代码块
			System.out.println(p.getName());
		}
	}
}

```
上面的三种用法都是为了避免在多个线程操作同一个对象的时候同时访问一个代码块或者某个方法。

### 误用 synchronized 的情况
下面的代码想要防止多个线程同时对某个代码块的访问，但是最后没有做到。
```java
class Sync {  
  
    public synchronized void test() {  
        System.out.println("test开始..");  
        try {  
            Thread.sleep(1000);  
        } catch (InterruptedException e) {  
            e.printStackTrace();  
        }  
        System.out.println("test结束..");  
    }  
}  
  
class MyThread extends Thread {  
  
    public void run() {  
        Sync sync = new Sync();  
        sync.test();  
    }  
}  
  
public class Main {  
  
    public static void main(String[] args) {  
        for (int i = 0; i < 3; i++) {  
            Thread thread = new MyThread();  
            thread.start();  
        }  
    }  
}  
```
```
运行结果：
test开始..
test开始..
test开始..
test结束..
test结束..
test结束..
```
可以看出来，上面的程序起了三个线程，同时运行test方法，虽然test方法加上了synchronized，但是还是同时运行起来，貌似synchronized没起作用。

将test方法改成如下：
```java
public void test() {  
    synchronized(this){  
        System.out.println("test开始..");  
        try {  
            Thread.sleep(1000);  
        } catch (InterruptedException e) {  
            e.printStackTrace();  
        }  
        System.out.println("test结束..");  
    }  
}  
```
```
运行结果：
test开始..
test开始..
test开始..
test结束..
test结束..
test结束..
```
一切还是这么平静，没有看到synchronized 达到想要的结果。为什么？刚才讲到上面的两种方法是为了避免在多个线程操作**同一个对象**的时候同时访问一个代码块或者某个方法，但是在
```java
class MyThread extends Thread {  
  
    public void run() {  
        Sync sync = new Sync();  
        sync.test();  
    }  
}  
```
中，每个线程都单独操作一个 Sync 对象，这样线程之间根本不会发生同步。怎么做呢？
```java
class MyThread2 extends Thread {
	
	private Sync sync;
	
	public MyThread2(Sync sync) {
		this.sync = sync;
	}
	  
    public void run() {
        sync.test();  
    }  
}
```
```java
Sync sync = new Sync();
for (int i = 0; i < 3; i++) {  
    Thread thread = new MyThread2(sync);
    thread.start();  
}
```
输出结果如下：
```
test开始..
test结束..
test开始..
test结束..
test开始..
test结束..
```
这样就达到预期了，多个线程在操作同一个对象的时候只有一个线程能够访问 test 方法。

但是还有其他方法吗？也就是如何避免多个线程执行多个对象的同一个代码块呢。看看下面的代码：
```java
public class Sync {
	public void test2() {
		synchronized (Sync.class) { // 作用于 Sync 类的所有实例
			System.out.println("test2开始..");
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			System.out.println("test2结束..");
		}
	}
}
```
```java
class MyThread3 extends Thread {  
	  
    public void run() {  
        Sync sync = new Sync();  
        sync.test2();  
    }  
}
```
```java
for (int i = 0; i < 3; i++) {  
    Thread thread = new MyThread3();
    thread.start();  
}
```
输出结果如下：
```
test2开始..
test2结束..
test2开始..
test2结束..
test2开始..
test2结束..
```
这样就满足期望了，关键是
```java
synchronized (Sync.class) { // 作用于 Sync 类的所有实例
//...
}
```

如果synchronized作用于某个静态方法上会有什么效果呢？
```java
public static synchronized void test3() {
	System.out.println("test3开始..");
	try {
		Thread.sleep(1000);
	} catch (InterruptedException e) {
		e.printStackTrace();
	}
	System.out.println("test3结束..");
}
```
```java
class MyThread4 extends Thread {  
	  
    public void run() {  
        Sync.test3();  
    }  
}
```
```java
for (int i = 0; i < 3; i++) {  
    Thread thread = new MyThread4();
    thread.start();  
}
```
输出结果如下：
```
test3开始..
test3结束..
test3开始..
test3结束..
test3开始..
test3结束..
```
这同样能够满足期望，从上面的这些例子也很好说明了5种的synchronized区别和相同点。


### 对 synchronized 的总结

- 方法同步，锁当前对象（this）
- 静态同步方法，锁当前类的Class对象
- 对于同步代码块，锁住的是synchronized括号中的对象，任意对象，当前类对象或者是其他对象。

参考如下：
[Java:使用synchronized和Lock对象获取对象锁](http://zhangjunhd.blog.51cto.com/113473/70300)
[线程同步总结--synchronized方法和synchronized代码块](http://991690137.iteye.com/blog/1948882)