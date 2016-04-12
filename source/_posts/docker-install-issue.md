---
title: Docker安装问题汇总
tags:
  - Docker
  - 原创
date: 2016-04-06 09:55:49
---
### 测试环境
Centos7_x86_64
```bash
[root@localhost ~]# uname -a
Linux localhost.localdomain 3.10.0-123.el7.x86_64 #1 SMP Mon Jun 30 12:09:22 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
```
### 增加yum源
```bash
[root@localhost ~]# sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
```
### 文件冲突
Transaction check error:
  file /usr/lib/systemd/system/blk-availability.service from install of device-mapper-7:1.02.107-5.el7_2.1.x86_64 conflicts with file from package lvm2-7:2.02.105-14.el7.x86_64
  file /usr/sbin/blkdeactivate from install of device-mapper-7:1.02.107-5.el7_2.1.x86_64 conflicts with file from package lvm2-7:2.02.105-14.el7.x86_64
  file /usr/share/man/man8/blkdeactivate.8.gz from install of device-mapper-7:1.02.107-5.el7_2.1.x86_64 conflicts with file from package lvm2-7:2.02.105-14.el7.x86_64

`解决方法:` 先安装lvm2
```bash
[root@localhost ~]# sudo yum install lvm2 -y
[root@localhost ~]# sudo yum install docker -y
[root@localhost ~]# docker -v
Docker version 1.10.3, build 20f81d
```
### Docker daemon未运行
[root@localhost ~]# docker pull ubuntu
Using default tag: latest
Warning: failed to get default registry endpoint from daemon (Cannot connect to the Docker daemon. Is the docker daemon running on this host?). Using system default: https://index.docker.io/v1/
Cannot connect to the Docker daemon. Is the docker daemon running on this host?
`解决方法:` 重启docker服务
```bash
[root@localhost ~]# service docker restart
Redirecting to /bin/systemctl restart  docker.service
```
### Docker被墙
[root@localhost ~]# docker pull centos
Using default tag: latest
Pulling repository docker.io/library/centos
Error while pulling image: Get https://index.docker.io/v1/repositories/library/centos/images: dial tcp: lookup index.docker.io on 10.28.10.166:53: no such host

由于docker镜像站被墙，推荐使用[灵雀云镜像](https://hub.alauda.cn/)
`解决方法:` pull的时候使用国内镜像地址
```bash
[root@localhost ~]# docker pull index.alauda.cn/tutum/centos
Using default tag: latest
latest: Pulling from tutum/centos
a3ed95caeb02: Pull complete 
196355c4b639: Pull complete 
edd0a8ebcd9d: Pull complete 
8ba44ed17115: Pull complete 
69f7e70c0063: Pull complete 
54abd94c9217: Pull complete 
Digest: sha256:11bc5863ca1643f1de49962c2741c3d1feca37ef258d5dd91baa2cca9a82b5b5
Status: Downloaded newer image for index.alauda.cn/tutum/centos:latest
[root@localhost ~]# docker images
REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
index.alauda.cn/tutum/centos   latest              e90ef4c35b09        2 weeks ago         297.3 MB
```

-----


*观点仅代表自己，期待你的留言。*
