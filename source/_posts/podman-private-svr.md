---
title: podman系列之Nexus3私服搭建与使用
tags:
  - 原创
  - podman
keywords:
  - podman
  - manifest unknown
  - invalid status code from registry 403
date: 2021-09-27 11:42:20
---

## Nexus新建docker仓库
Nexus的仓库分三类
1. docker（proxy）：用于代理其它的hub，类似mirror。
2. docker（hosted）：用于上传本地镜像到仓库。
3. docker（group）：可将proxy类型和hosted类型的仓库对外统一访问入口（注意不能使用这个地址进行镜像的上传）。

以下为我的配置：

`docker（proxy）`
![proxy](/images/docker-proxy.png)

`docker（hosted）`
![hosted](/images/docker-hosted.png)

`docker（group）`
![group](/images/docker-group.png)

`配置权限`
![realms](/images/docker-realms.png)

## podman客户端配置

1. 注册私服

```bash
wujianjun@wujianjun-work:~$ vi /etc/containers/registries.conf
`
unqualified-search-registries = ["docker.io", "quay.io"]
#更改docker.io镜像加速器为私服统一访问地址
[[registry]]
prefix = "docker.io"
location = "10.84.102.90:7791"
insecure = true
#更改quay.io镜像加速器为私服统一访问地址
[[registry]]
prefix = "quay.io"
location = "10.84.102.90:7791"
insecure = true
#注册group访问地址
[[registry]]
prefix = "10.84.102.90:7791"
location = "10.84.102.90:7791"
insecure = true
#注册hosted上传地址
[[registry]]
prefix = "10.84.102.90:7792"
location = "10.84.102.90:7792"
insecure = true
`
```
注意：`insecure`设置为true，表示支持http访问

2. 重新加载

```bash
wujianjun@wujianjun-work:~$ sudo systemctl daemon-reload
wujianjun@wujianjun-work:~$ sudo systemctl restart podman
```
## 测试生效

接下来以redis镜像来演示效果
![docker-images-redis](/images/docker-images-redis.png)

1. 拉取镜像

```bash
wujianjun@wujianjun-work:~$ podman pull redis:latest
Resolved "redis" as an alias (/home/wujianjun/.cache/containers/short-name-aliases.conf)
Trying to pull docker.io/library/redis:latest...
Getting image source signatures
Copying blob a330b6cecb98 skipped: already exists  
Copying blob 4f9efe5b47a5 done  
Copying blob 6af3a5ca4596 done  
Copying blob 14bfbab96d75 done  
Copying blob 8b3e2d14a955 done  
Copying blob 5da5e1b21a2f done  
Copying config 02c7f20544 done  
Writing manifest to image destination
Storing signatures
02c7f2054405dadaf295fac7281034e998646996e9768e65a78f90af62218be3
```
此时再去私服上可以看到镜像已被镜像到私服上了

2. 推送到私服

```bash
wujianjun@wujianjun-work:~$ podman tag redis 10.84.102.90:7792/library/myredis:1.0.0
wujianjun@wujianjun-work:~$ podman push 10.84.102.90:7792/library/myredis:1.0.0
Getting image source signatures
Copying blob be5818ef2907 done  
Copying blob c54e0c16ea22 done  
Copying blob bdad86443e47 done  
Copying blob 6a7992ac4800 done  
Copying blob be43d2475cf8 done  
Copying blob d000633a5681 done  
Copying config 02c7f20544 done  
Writing manifest to image destination
Storing signatures
```
注意：这里要通过7792的docker-hosted上传地址进行自有镜像的上传。`library`是指镜像的basePath（这里与docker.io/的镜像保持统一便于直接拉于自上传的镜像）
此时再去私服上可以看到myredis镜像已经可以查看到了。

3. 从私服拉取

```bash
wujianjun@wujianjun-work:~$ podman pull myredis:1.0.0
✔ docker.io/library/myredis:1.0.0
Trying to pull docker.io/library/myredis:1.0.0...
Getting image source signatures
Copying blob dec078b46822 skipped: already exists  
Copying blob c10395c8d924 done  
Copying blob 3c4c5d2db949 done  
Copying blob 6f8bb7da49ba done  
Copying blob 64906f58d083 done  
Copying blob 991f02c53ad6 done  
Copying config 02c7f20544 done  
Writing manifest to image destination
Storing signatures
02c7f2054405dadaf295fac7281034e998646996e9768e65a78f90af62218be3
wujianjun@wujianjun-work:~$ podman images
REPOSITORY                      TAG         IMAGE ID      CREATED      SIZE
docker.io/library/myredis       1.0.0       02c7f2054405  3 weeks ago  109 MB
```

## 常见问题
1. 未登录私服
```bash
wujianjun@wujianjun-work:~$ podman pull redis:latest
Resolved "redis" as an alias (/home/wujianjun/.cache/containers/short-name-aliases.conf)
Trying to pull docker.io/library/redis:latest...
Error: initializing source docker://redis:latest: Requesting bear token: invalid status code from registry 403 (Forbidden)
wujianjun@wujianjun-work:~$ podman login 10.84.102.90:7791
Username: de^Cwujianjun@wujianjun-work:~$ podman login -u developer 10.84.102.90:7791
Password:
Login Succeeded!
wujianjun@wujianjun-work:~$ podman pull redis:latest
Resolved "redis" as an alias (/home/wujianjun/.cache/containers/short-name-aliases.conf)
Trying to pull docker.io/library/redis:latest...
Getting image source signatures
Copying blob a330b6cecb98 skipped: already exists  
Copying blob 4f9efe5b47a5 done  
Copying blob 6af3a5ca4596 done  
Copying blob 14bfbab96d75 done  
Copying blob 8b3e2d14a955 done  
Copying blob 5da5e1b21a2f done  
Copying config 02c7f20544 done  
Writing manifest to image destination
Storing signatures
02c7f2054405dadaf295fac7281034e998646996e9768e65a78f90af62218be3
wujianjun@wujianjun-work:~$
wujianjun@wujianjun-work:~$ podman images
REPOSITORY                      TAG         IMAGE ID      CREATED      SIZE
docker.io/library/redis         latest      02c7f2054405  3 weeks ago  109 MB
```
根因分析：由于未登录私服故返回403的错误，已登录的信息会保存在`/run/user/1000/containers/auth.json`文件中

2. tag没有对应
```bash
wujianjun@wujianjun-work:~$ podman pull myredis:v1.0.0
✔ docker.io/library/myredis:v1.0.0
Trying to pull docker.io/library/myredis:v1.0.0...
Error: initializing source docker://myredis:v1.0.0: reading manifest v1.0.0 in 10.84.102.90:7791/library/myredis: manifest unknown: manifest unknown
```
根因分析：由于tag为v1.0.0的myredis镜像没有找到


-----

*观点仅代表自己，期待你的留言。*
