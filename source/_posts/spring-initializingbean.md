---
title: Spring InitializingBean趟坑笔记
tags:
  - 原创
date: 2017-07-18 17:59:12
list_number: false
---

## 问题现象
在Spring完成上下文初始化完成后, InitializingBean的实现类中重写的`afterPropertiesSet`方法并未执行.
## 一、类对象延迟初始
``` java
public interface InitializingBean {
    /**
      * Invoked by a BeanFactory after it has set all bean properties supplied
      * (and satisfied BeanFactoryAware and ApplicationContextAware).
      * <p>This method allows the bean instance to perform initialization only
      * possible when all bean properties have been set and to throw an
      * exception in the event of misconfiguration.
      * @throws Exception in the event of misconfiguration (such
      * as failure to set an essential property) or if initialization fails.
      */
     void afterPropertiesSet() throws Exception;
 }
```
由于此接口的方法afterPropertiesSet是在对象的所有属性被初始化后才会调用。当Spring的配置文件中设置类初始默认为"延迟初始"（`default-lazy-init="true"`，此值默认为false）时，
类对象如果不被使用，则不会实例化该类对象。所以 InitializingBean子类不能用于在容器启动时进行初始化的工作，则应使用Spring提供的`ApplicationListener`接口来进行程序的初始化工作。

另外，如果需要InitializingBean子类对象在Spring容器启动时就初始化并则容器调用afterPropertiesSet方法则需要在类上增加`org.springframework.context.annotation.Lazy`注解并设置为false即可（也可通过spring配置bean时添加`lazy-init="false"`)。

-----

*观点仅代表自己，期待你的留言。*
