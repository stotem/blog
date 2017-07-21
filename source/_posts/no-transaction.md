---
title: 问题分析 之 no transaction is in progress
tags:
  - 原创
  - spring
  - transaction
date: 2017-07-21 17:55:05
---

## 问题现象
```java
javax.persistence.TransactionRequiredException: no transaction is in progress
	at org.hibernate.ejb.AbstractEntityManagerImpl.flush(AbstractEntityManagerImpl.java:301)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:39)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:25)
	at java.lang.reflect.Method.invoke(Method.java:597)
	at org.springframework.orm.jpa.ExtendedEntityManagerCreator$ExtendedEntityManagerInvocationHandler.invoke(ExtendedEntityManagerCreator.java:365)
	at $Proxy34.flush(Unknown Source)
	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:39)
	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:25)
	at java.lang.reflect.Method.invoke(Method.java:597)
	at org.springframework.orm.jpa.SharedEntityManagerCreator$SharedEntityManagerInvocationHandler.invoke(SharedEntityManagerCreator.java:240)
	at $Proxy34.flush(Unknown Source)
  ... 53 more
```
## 示例代码 - Proxy
```java
public class classA {

  public void doA {
    this.doB();
  }

  @Transaction
  public void doB{
    // do save or update
  }
}
```
__问题分析：__
如上代码段，由于doB为对象内方法，而Spring事务的开启依赖到AOP（Proxy），在doA方法调用doB方法时，
由于是对象内的方法调用，造成doB方法的@Transaction不会被Proxy对象代理，进而造成Transaction失效。

__解决方法：__
```java
public class ClassA {
  private ClassB classB;

  public void doA() {
    classB.doB();
  }
}

public class ClassB {

  @Transaction
  public void doB() {
    // do save or update
  }

}
```
将需要事务的方法doB通过Proxy进行代理，doA在使用时则是通过Spring开启事务的代理进行的调用。

-----

*观点仅代表自己，期待你的留言。*
