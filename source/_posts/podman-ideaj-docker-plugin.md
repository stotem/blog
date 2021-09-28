---
title: Podman系列之通过docker插件完成研发机镜像创建和运行
tags:
  - 原创
  - Podman
keywords:
  - Podman
  - Docker plug-in
  - Can't retrieve image ID from build stream
date: 2021-09-27 13:51:42
---

## MacOS连接Linux的Podman REST API service
由于Podman与Docker一样，不支持在windows和macos上运行。故可以通过在linux系统下的podman开启REST API service。由windows与macos进行远程连接。

1. Linux下开启Podman REST API service
```bash
gigatech-linux@gigatech-linux:~$ podman system service -t 0 tcp:0.0.0.0:2375 &
gigatech-linux@gigatech-linux:~$ podman --remote info
host:
  arch: amd64
  buildahVersion: 1.22.3
  cgroupControllers: []
  cgroupManager: cgroupfs
  cgroupVersion: v1
gigatech-linux@gigatech-linux:~$ podman system connection list #查看当前机器远程连接的列表
```
接下来MacOS或Windows就可以通过tcp://host:2375进行连接了

2. 通过Ideaj下Docker Plug-in完成远程连接

![Docker插件远程连接](/images/docker-plugin-remote-connect.png)

## 程序打包

1. 在需要打包的模块pom.xml的同级目录创建 __Dockerfile__ 文件，内容如下：
```
FROM adoptopenjdk/openjdk8:x86_64-ubuntu-jre8u292-b10
ARG MODULE_FILE_NAME
ADD target/${MODULE_FILE_NAME}.tar.gz /opt/
ENV TZ=Asia/Shanghai MODULE_FILE_NAME=${MODULE_FILE_NAME}
CMD cd /opt/${MODULE_FILE_NAME} && ./bin/app restart && tail -f ./logs/console.log
```

2. 在上一步的Docker远程连接下配置打包镜像

![Docker远程连接](/images/docker-plugin-image-configuration.png)

`注意`：如果Dockerfile里出现错误（如Add的文件不存在时）会抛出`Dockerfile: service-gateway-biz/Dockerfile': Can't retrieve image ID from build stream`的错误。

![Docker插件使用](/images/docker-plugin-notice.png)

![Podman远程仓库镜像](/images/podman-images.png)

通过登录进Podman仓库来看，两边的镜像与运行容器实例是一致的。

-----

*观点仅代表自己，期待你的留言。*
