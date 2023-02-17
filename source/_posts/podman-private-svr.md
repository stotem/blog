---
title: Podman系列之Nexus3私服搭建与使用
tags:
  - 原创
  - Podman
keywords:
  - Podman
  - manifest unknown
  - invalid status code from registry 403
  - server gave HTTP response to HTTPS client
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

`国内镜像站`
 - https://hub-mirror.c.163.com
 - https://registry-1.docker.io

 
## Nginx反向代理docker仓库
```
upstream nexus_docker_group {
    server 10.84.102.90:7793;
}
upstream nexus_docker_hosted {
    server 10.84.102.90:7792;
}
server {
    listen 80;
    server_name mirror.docker.com;

    access_log logs/docker_mirror.log;

    client_max_body_size 0;
    # required to avoid HTTP 411: see Issue #1486 (https://github.com/docker/docker/issues/1486)
    chunked_transfer_encoding on;
    # 设置默认使用推送代理
    set $upstream "nexus_docker_hosted";
    # 当请求是GET，也就是拉取镜像的时候，这里改为拉取代理，如此便解决了拉取和推送的端口统一
    if ( $request_method ~* 'GET') {
        set $upstream "nexus_docker_group";
    }
    # 只有本地仓库才支持搜索，所以将搜索请求转发到本地仓库，否则出现500报错
    if ($request_uri ~ '/search') {
        set $upstream "nexus_docker_group";
    }
    location / {
        proxy_pass http://$upstream;
        proxy_set_header Host $http_host;
        proxy_connect_timeout 3600;
        proxy_send_timeout 3600;
        proxy_read_timeout 3600;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
    }
}
```

## podman客户端配置

1. 注册私服

```bash
wujianjun@wujianjun-work:~$ vi /etc/containers/registries.conf
`
unqualified-search-registries = ["mirror.docker.com"]
[[registry]]
location = "mirror.docker.com"
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
Trying to pull mirror.docker.com/library/redis:latest...
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
wujianjun@wujianjun-work:~$ podman tag redis mirror.docker.com/library/myredis:1.0.0
wujianjun@wujianjun-work:~$ podman push mirror.docker.com/library/myredis:1.0.0
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

3. 从私服拉取

```bash
wujianjun@wujianjun-work:~$ podman pull myredis:1.0.0
✔ mirror.docker.com/library/myredis:1.0.0
Trying to pull mirror.docker.com/library/myredis:1.0.0...
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
mirror.docker.com/library/myredis       1.0.0       02c7f2054405  3 weeks ago  109 MB
```

## 常见问题
1. 未登录私服
```bash
wujianjun@wujianjun-work:~$ podman pull redis:latest
Resolved "redis" as an alias (/home/wujianjun/.cache/containers/short-name-aliases.conf)
Trying to pull mirror.docker.com/library/redis:latest...
Error: initializing source docker://redis:latest: Requesting bear token: invalid status code from registry 403 (Forbidden)
wujianjun@wujianjun-work:~$ podman login -u developer mirror.docker.com
Password:
Login Succeeded!
wujianjun@wujianjun-work:~$ podman pull redis:latest
Resolved "redis" as an alias (/home/wujianjun/.cache/containers/short-name-aliases.conf)
Trying to pull mirror.docker.com/library/redis:latest...
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
mirror.docker.com/library/redis         latest      02c7f2054405  3 weeks ago  109 MB
```
根因分析：由于未登录私服故返回403的错误，已登录的信息会保存在`/run/user/1000/containers/auth.json`文件中

2. tag没有对应
```bash
wujianjun@wujianjun-work:~$ podman pull myredis:v1.0.0
✔ mirror.docker.com/library/myredis:v1.0.0
Trying to pull mirror.docker.com/library/myredis:v1.0.0...
Error: initializing source docker://myredis:v1.0.0: reading manifest v1.0.0 in mirror.docker.com/library/myredis: manifest unknown: manifest unknown
```
根因分析：由于tag为v1.0.0的myredis镜像没有找到

3. 未开启http访问
```bash
wujianjun@wujianjun-work:~$ podman pull myredis:1.0.0
✔ mirror.docker.com/library/myredis:v1.0.0
Trying to pull mirror.docker.com/library/myredis:1.0.0...
  Get https://mirror.docker.com/v2/: http: server gave HTTP response to HTTPS client
Error: error pulling image "mirror.docker.com/library/myredis": unable to pull mirror.docker.com/library/myredis: unable to pull image: Error initializing source docker://mirror.docker.com/library/myredis:1.0.0: error pinging docker registry mirror.docker.com: Get https://mirror.docker.com/v2/: http: server gave HTTP response to HTTPS client
```
根因分析：由于在注册私服地址时没有开启`insecure = true`

-----

*观点仅代表自己，期待你的留言。*
