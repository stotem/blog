---
title: podman系列之ubuntu下podman环境搭建
tags:
  - 原创
  - podman
keywords:
  - docker
  - podman 安装
date: 2021-09-03 22:33:31
---

## Linux环境信息
```
wujianjun@wujianjun-work:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 22.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.1 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy
```

## 安装podman
```
wujianjun@wujianjun-work:~$ sudo mkdir -p /etc/apt/keyrings
wujianjun@wujianjun-work:~$ curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_$(lsb_release -rs)/Release.key \
  | gpg --dearmor \
  | sudo tee /etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg > /dev/null
wujianjun@wujianjun-work:~$ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg] \
    https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_$(lsb_release -rs)/ /" \
  | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list > /dev/null
wujianjun@wujianjun-work:~$ sudo apt update && sudo apt -y upgrade
wujianjun@wujianjun-work:~$ sudo apt -y install podman
```
速度有点慢。。。

## 设置国内镜像源
由于访问速度慢，可为默认的docker.io添加加速镜像（如果后续自己搭建私服，可将镜像地址设置为私服，则每次pull时会将镜像在私服上保存一份）。
详细配置如下：
```
wujianjun@wujianjun-work:~$ vi /etc/containers/registries.conf 后面增加
`
[[registry]]
prefix = "docker.io" #需要加速的镜像地址
location = "hub-mirror.c.163.com" #加速器地址，可以为私服地址
insecure = true #支持加速器地址使用http进行访问
`
wujianjun@wujianjun-work:~$ sudo systemctl restart podman
```

## 开机自己podman
```
wujianjun@wujianjun-work:~$ sudo systemctl enable podman
```

## 验证安装版本
```
wujianjun@wujianjun-work:~$ podman version
Version:      3.2.3
API Version:  3.2.3
Go Version:   go1.15.2
Built:        Thu Jan  1 00:00:00 1970
OS/Arch:      linux/amd64

```

-----

*观点仅代表自己，期待你的留言。*
