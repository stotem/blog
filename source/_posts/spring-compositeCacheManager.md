---
title: 妙用Spring中的CompositeCacheManager
keywords:
  - Spring
  - CompositeCacheManager
tags:
  - 原创
date: 2016-07-19 16:47:23
---

## 简介
Spring提供了@Cacheable，@CacheEvict,@CachePut等注解很方便有实现数据的缓存，而CompositeCacheManager主要用于集合多个CacheManager实例，在使用多种缓存容器时特别有用。

## fallbackToNoOpCache属性的真实意义
经过查看Spring 4.1.9.RELEASE的源码,当CompositeCacheManager的fallbackToNoOpCache属性设置为true时，CompositeCacheManager会在已配置的cacheManagers末尾添加一个NoOpCacheManager。
当通过代码中指定的缓存容器（@Cacheable等注解设置的value）没有在cacheManagers中都找到时，则会进入到NoOpCacheManager中，此时就相当于禁用掉了缓存，而不抛出相应的异常。

网络上有朋友在说，当设置fallbackToNoOpCache属性设置为true时，则可以解决缓存容器没有准备好时自动禁用缓存的效果，经过查看Spring源码，并未实现。
不过，经测试以下方法可以实现通过配置禁用缓存。

## 通过配置禁用缓存

利用CompositeCacheManager + NoOpCacheManager还能解决当缓存容器没有准备好（缓存容器崩溃，网络不可用等）或者需要暂时去掉缓存的需求。

只需要将cacheManagers的list值的第一个元素设置为NoOpCacheManager就OK了。

__spring.xml__
```
<bean id="cacheManager" class="org.springframework.cache.support.CompositeCacheManager">
    <property name="cacheManagers">
        <list>
        	<bean class="org.springframework.cache.support.NoOpCacheManager" />
            <ref bean="simpleCacheManager" />
        </list>
    </property>
    <property name="fallbackToNoOpCache" value="true" />
</bean>
```

-----

*观点仅代表自己，期待你的留言。*