---
title: SpringBoot（一）
tags:
  - 原创
keywords:
  - springboot
date: 2019-01-07 16:44:15
---

## 配置演进
1. spring1.x时代xml配置，优点：取代new实例、ioc、实例对象池化管理
2. spring2.x时代注解配置，优点：减少配置量
3. spring3.x时代Java配置，优点：类型安全，可重构

## POM简化
增加parent module依赖，自动引入默认的jar配置
```xml
<parent>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-starter-parent</artifactId>
<version>1.4.4.RELEASE</version>
</parent>
```

## 知识点
一. WEB应用添加spring-boot-starter-web启动器
```xml
<dependency>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-starter-web</artifactId>
</dependency>
```
二. 更改jdk依赖版本，在properties下增加`java.version`配置jdk版本，如：
```xml
<properties>
  <java.version>1.7</java.version>
</properties>
```
三. spring-boot-devtools实现热部署调试
```xml
<dependency>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-devtools</artifactId>
</dependency>
```
四. spring-boot-test实现单元测试
```xml
<dependency>
<groupId>org.springframework.boot</groupId>
<artifactId>spring-boot-test</artifactId>
<scope>test</scope>
</dependency>
```
```java
@RunWith(SpringJUnit4ClassRunner.class)
@SpringBootTest(classes = Application.class)
public class TestCls {
  @Test
  public void hello() {
    //....
  }
}
```
五. 程序读取配置文件
src/main/resources/application.properties
```properties
cfg.name=abc
```
1) 环境对象实例中获取
```java
public class A {
  @Resource
  private org.springframework.core.env.Environment env;

  public void hello() {
    System.out.println(env.getProperty("cfg.name"));// 输出abc
  }
}
```
2) Value获取
```java
public class A {
  @Value("${cfg.name}")
  private String cfgName;

  public void hello() {
    System.out.println(cfgName);// 输出abc
  }
}
```
3) ConfigurationProperties获取
```java
@Component
@ConfigurationProperties("cfg")
@Setter
public class A {
  private String name;
}
```
六. spring-boot-starter-actuator实现应用运行状态监控
* 设置`management.endpoint.<id>.enabled=true/false`(id是endpoint的id)来完成一个endpoint的开启和关闭
* 自定义检测指标：实现HealthIndicator接口或继承AbstractHealthIndicator类
* 可通过Spring Security或Shiro来保障Actuator Endpoints的安全
* 设置`management.endpoint.health.show-details=always`则可查看详细的应用健康信息

七、框架接口
* CommandLineRunner、ApplicationRunner接口在容器启动成功后的Spring框架加载前回调（类似开机自启动），适合初始读取资源或加载通讯证书等

## 打包
一. 编译生成jar包程序（默认包类型）
```xml
<packaging>jar</packaging>
<build>
  <plugins>
    <plugin>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-maven-plugin</artifactId>
    </plugin>
  </plugins>
</build>
```
`输出:` 生成带tomcat-plugin的package.jar，通过java -jar package.jar运行。

二. 编译生成war包程序
```xml
<!--1. 更改package类型-->
<packaging>war</packaging>
<!--2. 修改tomcat的依赖为provided-->
<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-tomcat</artifactId>
    <scope>provided</scope>
  </dependency>
</dependencies>
<build>
  <!--3. 设置输出package的名称-->
  <finalName>package</finalName>
</build>
```
调整启动类:
```java
@SpringBootApplication
public class ClientApplication extends SpringBootServletInitializer  {
	public static void main(String[] args) {
		SpringApplication.run(ClientApplication.class, args);
	}
	@Override
	protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
		return builder.sources(getClass());
	}
}
```
`输出:` 生成package.war，将war放入到tomcat或其它的支持java运行的服务器中运行。

三. appassembler-maven-plugin生成跨平台启动脚本
```xml
<plugin>
	<groupId>org.codehaus.mojo</groupId>
	<artifactId>appassembler-maven-plugin</artifactId>
</plugin>
```
执行 `mvn package appassembler:assemble`完成脚本的生成
优点:
* jar包分散容易管理
* 编译发布代码速度快
* 可配置jvm相关启动参数
* 日志管理
* shell启动，停止、重启方便

四、docker-maven-plugin生成docker使用包
__优点:__
* 减少Dockerfile编写
* 增强代码一致性
* 编译部署方便
* 快速运维。
__缺点：__
* 编译后包比较大
* 无法替换局部jar文件

-----

*观点仅代表自己，期待你的留言。*
