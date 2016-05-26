---
title: Maven应用发布之不同环境不同配置的实现
keywords:
  - "Maven管理依赖"
  - "Maven多套环境打包"
  - "Maven Profile"
tags:
  - 原创
  - Maven
date: 2016-05-26 16:15:01
---

## 简介
一个应用程序从研发到发布一般需要经过三套环境（研发环境、测试环境、生产环境）甚至更多。针对这同的运行环境应用程序也需要一些不同的参数配置值（如果日志输出级别、数据库连接池配置等）。
Maven的Profile配置很好的解决这一问题。在pom.xml中配置多套参数值，在程序打包__编译时期__通过部署环境对配置参数进行替换来完成。
__注意:__当配置项找不到对应的配置值时会保持原样。
## pom.xml多套参数配置
以不同部署环境配置日志输出级别为例。
```
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <properties>
    	<catalina.base>/app/servers/logs</catalina.base>
    </properties>
    <profiles>
    	<profile>
            <id>dev</id>
            <activation>
                <activeByDefault>true</activeByDefault>
            </activation>
            <properties>
                <catalina.log.priority>debug</catalina.log.priority>
            </properties>
        </profile>
        <profile>
            <id>test</id>
            <properties>
                <catalina.log.priority>warn</catalina.log.priority>
            </properties>
        </profile>
    	<profile>
            <id>pro</id>
            <properties>
                <catalina.log.priority>error</catalina.log.priority>
            </properties>
        </profile>
    </profiles>
    <build>
    	<resources>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>true</filtering>
            </resource>
        </resources>
    </build>
</project>
```
__说明：__
以上配置表示在编译时期对`src/main/resources`目录下配置文件中的`${catalina.log.priority}`和`${catalina.base}`进行替换。而catalina.base参数值不区分部署环境。
编译开发环境的部署程序包命令如下：
```
Jianjun:~ Jianjun$ mvn package –P dev
```
编译测试环境的部署程序包命令如下：
```
Jianjun:~ Jianjun$ mvn package –P test
```
编译生产环境的部署程序包命令如下：
```
Jianjun:~ Jianjun$ mvn package –P pro
```
如果不指-P参数，默认会使用dev的配置，由于dev节点配置了__activeByDefault__

## 参数配置项太多
当配置项太多之后我们可以通过外置properties文件来进行配置，而properties文件需要与pom.xml在同一路径下。
properties配置如下：
_product-deploy-config-dev.properties_
```
catalina.log.priority=debug
```
_product-deploy-config-test.properties_
```
catalina.log.priority=warn
```
_product-deploy-config-pro.properties_
```
catalina.log.priority=error
```
pom.xml配置如下：
```
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <properties>
    	<catalina.base>/app/servers/logs</catalina.base>
    </properties>
    <profiles>
    	<profile>
            <id>dev</id>
            <activation>
                <activeByDefault>true</activeByDefault>
            </activation>
            <build>
            	<filters>
            		<filter>product-deploy-config-dev.properties</filter>
				</filters>
            </build>
        </profile>
        <profile>
            <id>test</id>
            <build>
            	<filters>
					<filter>product-deploy-config-test.properties</filter>
				</filters>
            </build>
        </profile>
    	<profile>
            <id>pro</id>
            <build>
            	<filters>
					<filter>product-deploy-config-pro.properties</filter>
				</filters>
            </build>
        </profile>
    </profiles>
    <build>
    	<resources>
            <resource>
                <directory>src/main/resources</directory>
                <filtering>true</filtering>
            </resource>
        </resources>
    </build>
</project>
```

-----

*观点仅代表自己，期待你的留言。*