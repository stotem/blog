---
title: 问题分析 之 Transaction marked as rollbackOnly
keywords:
  - 数据库事务
  - Transaction marked as rollbackOnly
tags:
  - 原创
  - Transaction
  - spring
date: 2017-07-21 17:01:27
---

## 问题现象
```java
org.springframework.transaction.TransactionSystemException: Could not commit JPA transaction; nested exception is javax.persistence.RollbackException: Transaction marked as rollbackOnly
        at org.springframework.orm.jpa.JpaTransactionManager.doCommit(JpaTransactionManager.java:526)
        at org.springframework.transaction.support.AbstractPlatformTransactionManager.processCommit(AbstractPlatformTransactionManager.java:757)
        at org.springframework.transaction.support.AbstractPlatformTransactionManager.commit(AbstractPlatformTransactionManager.java:726)
        at org.springframework.transaction.interceptor.TransactionAspectSupport.commitTransactionAfterReturning(TransactionAspectSupport.java:521)
        at org.springframework.transaction.interceptor.TransactionAspectSupport.invokeWithinTransaction(TransactionAspectSupport.java:291)
        at org.springframework.transaction.interceptor.TransactionInterceptor.invoke(TransactionInterceptor.java:96)
        at org.springframework.aop.framework.ReflectiveMethodInvocation.proceed(ReflectiveMethodInvocation.java:179)
        at org.springframework.aop.framework.JdkDynamicAopProxy.invoke(JdkDynamicAopProxy.java:207)
        at com.sun.proxy.$Proxy49.lazyAssignOrder(Unknown Source)
        at com.smzc.provider.order.facade.OrderFacade.lazyAssignOrder(OrderFacade.java:1015)
        at com.smzc.provider.order.schedule.LazyAssignOrderTask$2.run(LazyAssignOrderTask.java:51)
        at java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1145)
        at java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:615)
        at java.lang.Thread.run(Thread.java:745)
Caused by: javax.persistence.RollbackException: Transaction marked as rollbackOnly
        at org.hibernate.jpa.internal.TransactionImpl.commit(TransactionImpl.java:74)
        at org.springframework.orm.jpa.JpaTransactionManager.doCommit(JpaTransactionManager.java:517)
        ... 13 more

```
## 代码示例-事务嵌套
```java
@Transaction
public void doA() {
  // do something
  try {
    doB();
  } catch(Exception e) {
    doC();
  }
  // do something
}

@Transaction
public void doA2() {
  // do something
  try {
    doB();
  } catch(Exception e) {

  }
  // do save or update
}

@Transaction
public void doB() {
  // do save or update
  if(true) {
    throw new Exception("模拟异常");
  }
}

@Transaction
public void doC() {
  // do save or update
}
```
__问题分析：__
如上代码段，由于事务的传播性，doA,doB,doC方法其实共用的是由doA开启的同一个事务对象。
当doB方法抛出异常后事务被标记为回滚状态，再尝试执行doC方法或者执行任何的更改方法，在进行数据更新后进行事务commit时，此时则为抛出以上的异常。

__解决方法：__
```java
public class ClassA {
  private ClassB classB;
  //@Transaction
  public void doA() {
    try {
      classB.doB();
    } catch(Exception e) {
      classB.doC();
    }
  }
}

public class ClassB {
  @Transaction
  public void doB() {
    if(1==1) {
      throw new Exception("模拟异常");
    }
  }

  @Transaction
  public void doC() {
    //有数据更改动作
  }
}
```
以上的解决方法去掉了doA的事务，交由doB与doC分别开启两个事务解决，当doB失败时只标记doB的事务回滚，doC的事务依然能进行提交。


-----

*观点仅代表自己，期待你的留言。*
