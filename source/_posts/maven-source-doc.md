---
title: Maven打包source与javadoc
keywords: 
  - Maven打包源码
  - Maven生成JavaDoc
tags:
  - 原创
date: 2016-06-12 18:30:13
---

_pom.xml_
```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	<build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-source-plugin</artifactId>
                <version>2.2.1</version>
                <executions>
                    <execution>
                        <id>create-source</id><!--指定一个名字-->
                        <phase>compile</phase><!--在编译阶段生成source包-->
                        <goals>
                            <goal>jar</goal><!--指定生成的文件为jar包-->
                        </goals>
                    </execution>
                </executions>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-javadoc-plugin</artifactId>
                <version>2.9.1</version>
                <executions>
                    <execution>
                        <id>create-doc</id><!--指定一个名字-->
                        <phase>compile</phase><!--在编译阶段生成javadoc包-->
                        <goals>
                            <goal>jar</goal><!--指定生成的文件为jar包-->
                        </goals>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

`结论：`由于指定插件在phase=compile时期生成源码与Javadoc，当执行完成编译后，会在target目录下生成三个文件,xxx.jar,xxx-javadoc.jar,xxx-sources.jar


-----

*观点仅代表自己，期待你的留言。*