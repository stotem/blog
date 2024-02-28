---
title: Docker与Podman日志大小设置
tags:
  - 原创
  - Docker
  - podman
keywords:
  - Podman日志过大
  - Podman日志限制
  - docker日志过大
  - docker日志限制
date: 2024-02-28 14:36:17
---


## Docker限制容器日志大小

日志存储路径：

```
vi /etc/docker/daemon.json
以限制50mb为例，配置以下内容

{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": 3
  }
}
```

`注意：`设置的日志大小，只对新建的容器有效。已存在的容器不会生效，需要重建才可以.

## Podman限制容器日志大小
### root用户下启动的容器

日志存储路径： /var/lib/containers/storage/overlay-containers/[CONTAINER_ID]/userdata/ctr.log

```
vi /etc/containers/containers.conf
以限制10mb为例，配置以下内容

[containers]
log_size_max=10485760

```

### rootless下启动的容器

日志存储路径： $HOME/.local/share/containers/storage/overlay-containers/[CONTAINER_ID]/userdata/log/ctr.log

```
$HOME/.config/containers/containers.conf
以限制10mb为例，配置以下内容

[containers]
log_size_max=10485760
```



-----

*观点仅代表自己，期待你的留言。*
