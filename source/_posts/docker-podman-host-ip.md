---
title: Docker与Podman在容器内获取宿主机网络IP
tags:
  - 原创
  - Docker
  - podman
keywords:
  - Docker宿主机IP
  - podman宿主机IP
date: 2024-02-28 14:38:13
---

## Docker使用host-getway
docker需要在创建容器时加入桥接地址为外部host，容器内则可通过桥接地址来访问宿主机的网络。
- docker创建时增加 `--add-host <hostname>:<ip>`，如：`--add-host host.docker.internal:host-gateway`
- docker-compose.yml中增加
  ```
  extra_hosts:
    - "host.docker.internal:host-gateway"
  ```

## Podman容器
podman在创建容器时会在容器中/etc/hosts文件内加入一个宿主机的host，使用`host.containers.internal`由可以访问到宿主机的网络

-----

*观点仅代表自己，期待你的留言。*
