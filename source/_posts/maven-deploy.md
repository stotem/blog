---
title: Maven应用远程部署
keywords:
  - "Maven应用发布"
  - "Maven deploy"
  - "远程发布"
  - "远程部署"
tags:
  - 原创
  - Maven
date: 2016-05-26 16:51:51
---

## 简介
在程序开发的过程中对研发环境服务器应用部署将会非常的频繁，而通过tomcat-maven-plugin的deploy很容易实现web应用的远程发布。
而针对jar的发布一般会搭建maven私服，同样在研发阶段也会发布的非常频繁通过maven的deploy也非常容易实现maven私服的jar提交。

## 远程发布Web应用
以tomcat-maven-plugin为例，具体配置如下：
_pom.xml_
```
<?xml version='1.0' encoding='utf-8'?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <build>	
    	<plugins>	
    		<plugin>
                <groupId>org.apache.tomcat.maven</groupId>
                <artifactId>tomcat7-maven-plugin</artifactId>
                <version>2.2</version>
                <configuration>
                    <path>/</path>
                    <port>8080</port>
                    <uriEncoding>UTF-8</uriEncoding>
                    <server>DevServer</server>
                    <url>http://deploy.dev.com/manager</url>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```
__说明:__
server: 为settings.xml中配置的server节点ID，用于上传鉴权。
url：发布到的服务器的tomcat/manager工程访问地址。

_settings.xml_
```
<?xml version='1.0' encoding='utf-8'?>
<settings xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd" xmlns="http://maven.apache.org/SETTINGS/1.1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <servers>
	    <server>
	    	<id>DevServer</id>
	      	<username>abc</username>
	        <password>xxx</password>
	    </server>
    </servers>
</settings>
```
_tomcat-users.xml_
```
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
<role rolename="manager-gui" />
<role rolename="manager-script" />
<user username="abc" password="xxx" roles="manager-gui,manager-script"/>
</tomcat-users>
```

--[更新] 发现更简便配置,详细如下：---
将maven的pom.xml中将server节点直接替换成username与password节点，这样就不需要在setting.xml中进行配置了。
_pom.xml_
```
<?xml version='1.0' encoding='utf-8'?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <build> 
      <plugins> 
        <plugin>
                <groupId>org.apache.tomcat.maven</groupId>
                <artifactId>tomcat7-maven-plugin</artifactId>
                <version>2.2</version>
                <configuration>
                    <path>/</path>
                    <port>8080</port>
                    <uriEncoding>UTF-8</uriEncoding>
                    <username>abc</username>
                    <password>xxx</password>
                    <url>http://deploy.dev.com/manager</url>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

## 远程发布依赖库jar
_pom.xml_
```
<?xml version='1.0' encoding='utf-8'?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <distributionManagement>
        <snapshotRepository>
            <id>snapshots</id>
            <name>libs-snapshot</name>
            <url>http://mvn.code.com/artifactory/libs-snapshot-local</url>
        </snapshotRepository>
    </distributionManagement>
</project>
```
__说明:__
id: 表示配置的用户名和密码，这个ID在settings.xml里配置
url: 为私服上传地址。

_settings.xml_
```
<?xml version='1.0' encoding='utf-8'?>
<settings xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd" xmlns="http://maven.apache.org/SETTINGS/1.1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <servers>
	    <server>
	    	<id>snapshots</id>
	      	<username>abc</username>
	        <password>xxx</password>
	    </server>
    </servers>
</settings>
```

配置完成之后执行`maven deploy`就OK啦。

-----

*观点仅代表自己，期待你的留言。*