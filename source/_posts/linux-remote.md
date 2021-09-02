---
title: 内网linux远程访问
tags:
  - 原创
keywords:
  - linux远程
  - cockpit
date: 2021-09-02 19:09:51
---

## 开通ssh远程端口
通过外网做端口映射出ssh端口(22)之后，通过外网IP进行访问

## 安装vpn
利用vpn软件远程登录进内网进行内网linux的访问

## 内网找一台电脑安装软件（如：向日葵、TeamViewer等）

## 安装cockpit
Cockpit是一个Web端的系统管理工具。Cockpit使用系统上已经存在的API。可以在Web界面管理服务、容器、存储等等，还可以配置网络、检查日志都非常方便。

由于22端口映射过于敏感，可以在内网linux上安装cockpit后，然后再做外网映射（默认9090）映射完成后，则可通过浏览器使用linux登录用户进行登录访问。

### 安装
`CentOS`：
```
wujianjun@wujianjun-work:~$ sudo yum install cockpit
```

`Ubuntu`：
```
wujianjun@wujianjun-work:~$ sudo apt install cockpit
```
### 端口更改
默认端口为9090，如果遇上端口冲突可按以下方式进行修改
```
wujianjun@wujianjun-work:~$ sudo vi /etc/systemd/system/sockets.target.wants/cockpit.socket #更改ListenStream后的端口号
wujianjun@wujianjun-work:~$ sudo systemctl restart cockpit.socket
wujianjun@wujianjun-work:~$ sudo systemctl daemon-reload
```

-----

*观点仅代表自己，期待你的留言。*
