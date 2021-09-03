---
title: ubuntu下podman环境搭建
tags:
  - 原创
  - podman
keywords:
  - docker
  - podman
date: 2021-09-03 22:33:31
---

## Linux环境信息
```
wujianjun@wujianjun-work:~$ cat /etc/os-release
NAME="Ubuntu"
VERSION="20.04.3 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.3 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal
```

## 安装podman
```
wujianjun@wujianjun-work:~$ echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
wujianjun@wujianjun-work:~$ curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_20.04/Release.key" | sudo apt-key add -
wujianjun@wujianjun-work:~$ sudo apt update
wujianjun@wujianjun-work:~$ sudo apt -y upgrade
wujianjun@wujianjun-work:~$ sudo apt -y install podman
```
速度有点慢。。。

## 设置国内镜像源
```
wujianjun@wujianjun-work:~$ vi /etc/containers/registries.conf 后面增加
`
[[registry]]
prefix = "docker.io"
location = "hub-mirror.c.163.com"
`
wujianjun@wujianjun-work:~$ sudo systemctl restart podman
```

## 开机自己podman
```
wujianjun@wujianjun-work:~$ sudo systemctl start podman
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
