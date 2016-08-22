---
title: 工具_源代码生成器GGCode
keywords: 
  - 生成器
  - GGCode
tags:
  - 原创
date: 2016-08-22 18:15:58
---

## 简介
通过近期的努力，将编写的源代码生成器进行0.0.1版本的封版，代码生成器按数据表自动生成源代码包含简单业务的（增，删，改，查，分页等）。
部分集成的开源框架已通过配置文件进行开关配置，方便按业务进行开启和关闭。欢迎大家使用。
Github地址：https://github.com/stotem/GGCode

### 基础框架
源代码生成框架: [rapid-framework](https://code.google.com/archive/p/rapid-framework/)

UI框架: [sb-admin-2](https://startbootstrap.com/template-overviews/sb-admin-2/) 

代码框架: SpringMVC + mybatis + Velocity。

代码架构: 经典三层架构(MVC), 增加rpc模块做为调用三方api模块, 增加manager模块设置为缓存层与事务层。

主要转换规则:

1. 数据表与数据列的注释做为UI展示title。
2. 数据列的为空性、数据长度和是否可为空等属性转换为javax.validation的判断规则。
3. 数据列的数据类型转换为实体对象属性的数据类型。

### 集成功能
1. 增加shiro做为权限管理框架。
2. 为文档数据存储添加MongoDB支持。
3. 为缓存增加Redis支持, 且自动配置Spring Cache为Redis缓存。
4. 以Velocity做为页面模板语言。
5. 增加javax.validation为服务端验证框架。且Controller自动验证传入参数。
6. 采用bonecp对数据库连接池化管理。
7. spring的响应数据采用多视图配置。

### 如何使用?
在bin目录中通过配置generator.xml后直接`java -jar GGCode-0.0.1.jar`

### generator.xml配置说明
详见generator.xml注释

### 其它说明
1. controller的访问URI不带后缀.
2. 所有的页面文件后缀为view.


-----

*观点仅代表自己，期待你的留言。*