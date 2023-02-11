---
title: Podman系列之通过Maven插件dockerfile-maven-plugin完成镜像打包
tags:
  - 原创
  - podman
keywords:
  - Podman
  - dockerfile-maven-plugin
  - "unix://localhost:80: No such file or directory"
date: 2021-09-28 18:35:30
---

## pom中添加插件
```
<plugin>
    <groupId>com.spotify</groupId>
    <artifactId>dockerfile-maven-plugin</artifactId>
    <version>1.4.13</version>
    <executions>
        <execution>
            <id>default</id>
            <goals>
                <goal>build</goal>
                <goal>push</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
        <repository>myrepo.gpluslife.com/${project.artifactId}</repository>
        <tag>${project.version}</tag>
        <useMavenSettingsForAuth>true</useMavenSettingsForAuth>
        <buildArgs>
            <MODULE_FILE_NAME>${project.build.finalName}</MODULE_FILE_NAME>
        </buildArgs>
    </configuration>
</plugin>
```
## 打包镜像

```bash
wujianjun@wujianjun-work:~$ clean package -U  -Dmaven.test.skip=true
```
通过在Dockerfile文件所在目录执行以上命令成功后，则会自动在远程podman服务端创建镜像
```bash
wujianjun@wujianjun-work:~$ podman images
REPOSITORY                                     TAG                         IMAGE ID      CREATED         SIZE
myrepo.gpluslife.com/service-gateway-biz       1.0.0-SNAPSHOT              aa26ce31b312  20 seconds ago  294 MB
docker.io/library/nginx                        1.20.1                      3456bc6a1c48  3 weeks ago     137 MB
docker.io/adoptopenjdk/openjdk8                x86_64-ubuntu-jre8u292-b10  48b3b187af57  5 weeks ago     229 MB
```

## 常见问题

1. mvn package时抛错

```
[INFO] I/O exception (java.io.IOException) caught when processing request to {}->unix://localhost:80: No such file or directory
[INFO] Retrying request to {}->unix://localhost:80
[INFO] I/O exception (java.io.IOException) caught when processing request to {}->unix://localhost:80: No such file or directory
[INFO] Retrying request to {}->unix://localhost:80
[INFO] I/O exception (java.io.IOException) caught when processing request to {}->unix://localhost:80: No such file or directory
[INFO] Retrying request to {}->unix://localhost:80
```

根因分析：由于未正确配置DOCKER_HOST环境变量导致走了本机默认的连接地址
解决方案：在环境变量上配置以下地址

```
DOCKER_HOST="tcp://host:2375"
```
`注意：`macOS添加环境变量时不同于其他unix或类unix系统（默认使用bash，因此在.bash_profile中设置环境变量）；macOS的terminal默认使用的是zsh，在.zshrc中进行配置。

附插件官网地址： https://github.com/spotify/dockerfile-maven

-----

*观点仅代表自己，期待你的留言。*
