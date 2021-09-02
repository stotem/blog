---
title: FindbugsMaven插件集成生成html报告
tags:
  - 原创
keywords:
  - maven
  - findbugs
date: 2021-09-02 15:09:40
---

## maven配置
在pom.xml中加入
```pom.xml
<reporting>
  <plugins>
    <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>findbugs-maven-plugin</artifactId>
        <version>3.0.5</version>
        <configuration>
            <effort>Max</effort>
            <threshold>High</threshold>
            <xmlOutput>false</xmlOutput>
        </configuration>
    </plugin>
  </plugins>
</reporting>
<build>
  <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-site-plugin</artifactId>
      <version>3.9.1</version>
      <dependencies>
          <dependency>
              <groupId>org.apache.maven.doxia</groupId>
              <artifactId>doxia-site-renderer</artifactId>
              <version>1.10</version>
          </dependency>
      </dependencies>
  </plugin>
</build>
```
## 运行
在pom.xml所在目录执行`mvn compile site`生成报告
在target/site目录中则能查看到扫描报告



-----

*观点仅代表自己，期待你的留言。*
