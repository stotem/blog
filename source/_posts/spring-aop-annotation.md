---
title: Spring-AOP实现之注解
keywords: 
  - "Spring aop实现"
  - "注解aop实现"
  - "面向切面编程"
tags:
  - 原创
date: 2016-06-30 15:29:18
---

## AOP概念

AOP术语:
* 切面（Aspect）：一个关注点的模块化，这个关注点可能会横切多个对象。事务管理是J2EE应用中一个关于横切关注点的很好的例子。在Spring AOP中，切面可以使用基于模式或者基于@Aspect注解的方式来实现。
* 连接点（Joinpoint）：在程序执行过程中某个特定的点，比如某方法调用的时候或者处理异常的时候。在Spring AOP中，一个连接点总是表示一个方法的执行。
* 通知（Advice）：在切面的某个特定的连接点上执行的动作。其中包括了“around”、“before”和“after”等不同类型的通知（通知的类型将在后面部分进行讨论）。许多AOP框架（包括Spring）都是以拦截器做通知模型，并维护一个以连接点为中心的拦截器链。
* 切入点（Pointcut）：匹配连接点的断言。通知和一个切入点表达式关联，并在满足这个切入点的连接点上运行（例如，当执行某个特定名称的方法时）。切入点表达式如何和连接点匹配是AOP的核心：Spring缺省使用AspectJ切入点语法。
* 引入（Introduction）：用来给一个类型声明额外的方法或属性（也被称为连接类型声明（inter-type declaration））。Spring允许引入新的接口（以及一个对应的实现）到任何被代理的对象。例如，你可以使用引入来使一个bean实现IsModified接口，以便简化缓存机制。
* 目标对象（Target Object）： 被一个或者多个切面所通知的对象。也被称做被通知（advised）对象。 既然Spring AOP是通过运行时代理实现的，这个对象永远是一个被代理（proxied）对象。
* AOP代理（AOP Proxy）：AOP框架创建的对象，用来实现切面契约（例如通知方法执行等等）。在Spring中，AOP代理可以是JDK动态代理或者CGLIB代理。
* 织入（Weaving）：把切面连接到其它的应用程序类型或者对象上，并创建一个被通知的对象。这些可以在编译时（例如使用AspectJ编译器），类加载时和运行时完成。Spring和其他纯Java AOP框架一样，在运行时完成织入。

通知类型：
* 前置通知（Before advice）：在某连接点之前执行的通知，但这个通知不能阻止连接点之前的执行流程（除非它抛出一个异常）。
* 后置通知（After returning advice）：在某连接点正常完成后执行的通知：例如，一个方法没有抛出任何异常，正常返回。
* 异常通知（After throwing advice）：在方法抛出异常退出时执行的通知。
* 最终通知（After (finally) advice）：当某连接点退出的时候执行的通知（不论是正常返回还是异常退出）。
* 环绕通知（Around Advice）：包围一个连接点的通知，如方法调用。这是最强大的一种通知类型。环绕通知可以在方法调用前后完成自定义的行为。它也会选择是否继续执行连接点或直接返回它自己的返回值或抛出异常来结束执行。

## 配置实现
实例需求: 监控各Api接口执行时间，找出耗时的业务操作。
1、启用@AspectJ支持
_spring.xml_
```
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mvc="http://www.springframework.org/schema/mvc"
       xmlns:util="http://www.springframework.org/schema/util" xmlns:context="http://www.springframework.org/schema/context"
       xmlns:tx="http://www.springframework.org/schema/tx" xmlns:aop="http://www.springframework.org/schema/aop"
       xmlns:cache="http://www.springframework.org/schema/cache" xmlns:p="http://www.springframework.org/schema/p"
		xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
        http://www.springframework.org/schema/mvc http://www.springframework.org/schema/mvc/spring-mvc.xsd
        http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx.xsd
        http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop.xsd
        http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd
        http://www.springframework.org/schema/util http://www.springframework.org/schema/util/spring-util.xsd
        http://www.springframework.org/schema/cache http://www.springframework.org/schema/cache/spring-cache-3.2.xsd"
       default-lazy-init="true">

	<aop:aspectj-autoproxy />

</beans>
```
2、增加aspectj依赖库
_pom.xml_
```
<dependency>
    <groupId>org.aspectj</groupId>
    <artifactId>aspectjrt</artifactId>
    <version>1.7.4</version>
</dependency>
<dependency>
    <groupId>org.aspectj</groupId>
    <artifactId>aspectjweaver</artifactId>
    <version>1.7.4</version>
</dependency>
```
3、编写切面类
```
@Aspect
@Repository
public class AspectPoint {

    @Around("within(org.wujianjun.apps.service..*)")
    public Object doBasicProfiling(ProceedingJoinPoint pjp) throws Throwable {
        final long beginTime = System.currentTimeMillis();
        Object res = pjp.proceed(pjp.getArgs());
        final long endTime = System.currentTimeMillis();
        System.out.println(pjp.getTarget().getClass().getSimpleName()+"."+pjp.getSignature().getName()+"-->"+(endTime-beginTime)+"ms");
        return res;
    }
}
```

对比一下xml配置
```
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mvc="http://www.springframework.org/schema/mvc"
       xmlns:util="http://www.springframework.org/schema/util" xmlns:context="http://www.springframework.org/schema/context"
       xmlns:tx="http://www.springframework.org/schema/tx" xmlns:aop="http://www.springframework.org/schema/aop"
       xmlns:cache="http://www.springframework.org/schema/cache" xmlns:p="http://www.springframework.org/schema/p"
    xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
        http://www.springframework.org/schema/mvc http://www.springframework.org/schema/mvc/spring-mvc.xsd
        http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx.xsd
        http://www.springframework.org/schema/aop http://www.springframework.org/schema/aop/spring-aop.xsd
        http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd
        http://www.springframework.org/schema/util http://www.springframework.org/schema/util/spring-util.xsd
        http://www.springframework.org/schema/cache http://www.springframework.org/schema/cache/spring-cache-3.2.xsd"
       default-lazy-init="true">

  <bean id="aspectPoint" class="AspectPoint" />
  <aop:aspectj-autoproxy/> 
  <aop:config>
    <aop:aspect ref="aspectPoint">
      <aop:around method="doBasicProfiling" pointcut="within(org.wujianjun.apps.service..*)" />
    </aop:aspect>
  </aop:config>

</beans>
```

附上测试业务实现类
```
package org.wujianjun.apps.service.impl;

@Service
public class ExampleServiceImpl implements ExampleService {
    private final static Logger LOG = LoggerFactory
            .getLogger(ExampleServiceImpl.class);

    @Resource
    private ExampleManager exampleManager;

    @Override
    public void test() {
        System.out.println("test--");
        try {
            Thread.sleep(100);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

4、测试结果
```
六月 30, 2016 4:11:07 下午 org.apache.coyote.AbstractProtocol start
信息: Starting ProtocolHandler ["http-bio-8080"]
test--
ExampleServiceImpl.test-->103ms
test--
ExampleServiceImpl.test-->105ms
test--
ExampleServiceImpl.test-->103ms
test--
ExampleServiceImpl.test-->103ms
test--
ExampleServiceImpl.test-->100ms
test--
ExampleServiceImpl.test-->104ms
```

## 配置说明
### AspectJ切入点指示符：
* execution - 匹配方法执行的连接点，这是你将会用到的Spring的最主要的切入点指示符。
	具体格式：`execution(modifiers-pattern? ret-type-pattern declaring-type-pattern? name-pattern(param-pattern)throws-pattern?)`
	示例: execution(* com.xyz.service..*.*(..) - 在service包或其子包中定义的任意方法的执行
* within - 限定匹配特定类型的连接点(在使用Spring AOP的时候，在匹配的类型中定义的方法的执行)。
	示例: within(com.xyz.service..*) - 在service包或其子包中的任意连接点(在Spring AOP中只是方法执行)，包含类和接口
* this - 限定匹配特定的连接点(使用Spring AOP的时候方法的执行)，其中bean reference(Spring AOP 代理)是指定类型的实例。
	示例: this(com.xyz.service.AccountService) - 实现了AccountService接口的代理对象的任意连接点 (在Spring AOP中只是方法执行)
* target - 限定匹配特定的连接点(使用Spring AOP的时候方法的执行)，其中目标对象(被代理的应用对象)是指定类型的实例。
	示例: target(com.xyz.service.AccountService) - 实现AccountService接口的目标对象的任意连接点 (在Spring AOP中只是方法执行)
* args - 限定匹配特定的连接点(使用Spring AOP的时候方法的执行)，其中参数是指定类型的实例。
	示例: args(java.io.Serializable) - 任何一个只接受一个参数，并且运行时所传入的参数是Serializable 接口的连接点(在Spring AOP中只是方法执行)
* bean - 标记可以是任何Spring bean的名字支持通配符'*'。
	示例: bean(*Service) - 任何一个在名字匹配通配符表达式'*Service'的Spring bean之上的连接点 (在Spring AOP中只是方法执行)
* @target - 限定匹配特定的连接点(使用Spring AOP的时候方法的执行)，其中正执行对象的类持有指定类型的注解。
	示例: @target(org.springframework.transaction.annotation.Transactional) - 目标对象中有一个 @Transactional 注解的任意连接点 (在Spring AOP中只是方法执行)
* @args - 限定匹配特定的连接点(使用Spring AOP的时候方法的执行)，其中实际传入参数的运行时类型持有指定类型的注解。
	示例: @args(com.xyz.security.Classified) - 任何一个只接受一个参数，并且运行时所传入的参数类型具有@Classified 注解的连接点(在Spring AOP中只是方法执行)
* @within - 限定匹配特定的连接点，其中连接点所在类型已指定注解(在使用Spring AOP的时候，所执行的方法所在类型已指定注解)。
	示例: @within(org.springframework.transaction.annotation.Transactional) - 任何一个目标对象声明的类型有一个 @Transactional 注解的连接点 (在Spring AOP中只是方法执行)
* @annotation - 限定匹配特定的连接点(使用Spring AOP的时候方法的执行)，其中连接点的主题持有指定的注解。
	示例: @annotation(org.springframework.transaction.annotation.Transactional) - 任何一个执行的方法有一个 @Transactional 注解的连接点 (在Spring AOP中只是方法执行)

`注意：`__切入点表达式可以使用'&', '||' 和 '!'来组合__

### 通知类型声明注解：
* 前置通知 - 使用 @Before 注解声明
* 后置通知 - 使用 @AfterReturning 注解来声明
* 异常通知 - 使用@AfterThrowing注解
* 最终通知 - 使用@After 注解来声明
* 环绕通知 - 使用@Around注解来声明

### 共享通用切入点定义

通过@Pointcut先定义好切入点, 当通知类型可以通过被 @Pointcut 标识的方法名直接共享其切入点配置。

示例：
```
package com.xyz.someapp;

@Aspect
public class SystemArchitecture {
	@Pointcut("within(com.xyz.someapp.web..*)")
  	public void inWebLayer() {}

  	@Before("com.xyz.someapp.SystemArchitecture.inWebLayer()")
  	public void doBefore() {

  	}

  	@After("com.xyz.someapp.SystemArchitecture.inWebLayer()")
  	public void doAfter() {

  	}
}
```

### 获取切入点更多的信息
任何通知方法可以将第一个参数定义为org.aspectj.lang.JoinPoint类型 （环绕通知需要定义第一个参数为ProceedingJoinPoint类型， 它是 JoinPoint 的一个子类）。JoinPoint 接口提供了一系列有用的方法，比如 getArgs()（返回方法参数）、 getThis()（返回代理对象）、getTarget()（返回目标）、 getSignature()（返回正在被通知的方法相关信息）和 toString() （打印出正在被通知的方法的有用信息）。

-----
http://shouce.jb51.net/spring/aop.html

*观点仅代表自己，期待你的留言。*