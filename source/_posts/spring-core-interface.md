---
title: Spring ApplicationContext与常用接口笔记
keywords:
  - spring applicationContext
  - spring InitializingBean
  - spring FactoryBean
  - spring ApplicationListener
  - spring DisposableBean
tags:
  - 原创
toc: true
list_number: false
date: 2016-08-29 11:17:18
---

## 一、在Web项目中的ApplicationContext
在web 项目中（spring mvc），系统会存在两个容器，一个是ApplicationContext,另一个就是我们自己的WebApplicationContext（作为ApplicationContext的子容器）。

* ApplicationContext: 默认配置文件名applicationContext.xml，通过org.springframework.web.context.ContextLoaderListener进行加载并初始化。
* WebApplicationContext: 默认配置文件名xxx-servlet.xml，xxx为DispatcherServlet配置的servlet-name, 通过org.springframework.web.servlet.DispatcherServlet进行加载并初始化。

WebApplicationContext通过getParent()获取到ApplicationContext，而ApplicationContext的getParent()将获取到null（ApplicationContext没有父容器）。

## 二、Spring常用接口
### org.springframework.beans.factory.InitializingBean
InitializingBean表示为spring管理的初始类，当Bean初始时进行属性注入完成后调用afterPropertiesSet进行初始处理。( [趟坑笔记 add by 2017-07-18](/2017/07/18/spring-initializingbean/))

### org.springframework.beans.factory.FactoryBean<T>
FactoryBean 是创建 复杂的bean，一般的bean 直接用xml配置即可，如果一个bean的创建过程中涉及到很多其他的bean 和复杂的逻辑，用xml配置比较困难，这时可以考虑用FactoryBean。

spring配置时会自动调用getObject来获取注入对象。

@see org.springframework.web.accept.ContentNegotiationManagerFactoryBean

### org.springframework.context.ApplicationListener<E extends ApplicationEvent>
ApplicationListener用于监听应用程序的事件。
所包含的事件详见ApplicationEvent子类。
当Application事件发生时会自动调用监听器的onApplicationEvent方法。

### org.springframework.context.ApplicationContextAware

ApplicationContextAware用于用户保存ApplicationContext的引用，供客户端程序获取ApplicationContext时使用。

### org.springframework.beans.factory.DisposableBean
DisposableBean用于标识可销毁的类，当类进行回收时调用destroy()


-----

*观点仅代表自己，期待你的留言。*
