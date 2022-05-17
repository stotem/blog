---
title: Ubuntu Server安装后续配置
tags:
  - 原创
keyworks:
  - 开启远程root
  - 固定IP配置
  - 免重装增加swap空间
  - 调整swap启用时间
  - swappiness
date: 2022-05-17 16:04:41
---
## 一、开启远程root
### 说明
ubuntu server默认不会开启root账号
## 配置
```
wujianjun@wujianjun-work:~$ sudo passwd root
wujianjun@wujianjun-work:~$ su - root
wujianjun@wujianjun-work:~# vi /etc/ssh/sshd_config
在文件中添加配置：PermitRootLogin yes
wujianjun@wujianjun-work:~# /etc/init.d/ssh restart
```

## 二、固定IP配置
### 说明

Ubuntu 从 17.01 开始之后的版本，都已放弃在/etc/network/interfaces 里固定IP的配置，而是改成 netplan 方式，配置文件在：`/etc/netplan/`目录下

### 配置

1. 切换到root账号，先通过ifconfig查看到网卡名

```
wujianjun@wujianjun-work:~# ifconfig
enp2s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.84.102.130  netmask 255.255.255.0  broadcast 10.84.102.255
        inet6 fe80::fe34:97ff:fe67:1359  prefixlen 64  scopeid 0x20<link>
        ether fc:34:97:67:13:59  txqueuelen 1000  (Ethernet)
        RX packets 18835846  bytes 14116403620 (14.1 GB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 19693736  bytes 9492990687 (9.4 GB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 130834632  bytes 43706613473 (43.7 GB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 130834632  bytes 43706613473 (43.7 GB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

2. 配置网卡enp2s0网卡固定IP

```
wujianjun@wujianjun-work:~# vi /etc/netplan/00-installer-config.yaml
network:
  ethernets:
    enp2s0:
      dhcp4: no
      addresses: [10.84.102.130/24]
      gateway4: 10.84.102.1
      nameservers:
        addresses: [10.84.102.1, 61.139.2.69]
  version: 2
```

3. 配置生效

```
wujianjun@wujianjun-work:~# sudo netplan apply
```

## 三、免重装增加swap空间
### 说明
有时由于硬件自身内存不足，我们可能会使用到linux的swap来顶，swap大小按经验一般需要设置成硬件内存的2倍。

### 配置
1. 切换到root

2. 创建swap文件

```
wujianjun@wujianjun-work:~# mkdir /swap
wujianjun@wujianjun-work:~# cd /swap
wujianjun@wujianjun-work:~# sudo dd if=/dev/zero of=swapfile bs=32M count=1k
建立swapfile，大小为bs*count = 32M * 1k = 32G
wujianjun@wujianjun-work:~# sudo mkswap -f swapfile
将生成的文件转换为Swap文件
```

3. 立即激活swap文件

```
wujianjun@wujianjun-work:~# sudo swapon swapfile
wujianjun@wujianjun-work:~# free -m
total        used        free      shared  buff/cache   available
Mem:          15842       12194         208         149        3439        3158
Swap:         34815        2889       31926
```

如果需要禁用swap文件则使用`sudo swapoff swapfile`

4. 永久激活swap文件

```
wujianjun@wujianjun-work:~# sudo vi /etc/fstab
增加配置
/swap/swapfile /swap swap defaults 0 0
```

## 四、调整swap启用时间
### 说明
ubuntu 和 centos 一般默认都是 60 ，就是当内存使用=(100%-60%)*内存总量时则会使用swap缓存，如需调整尽量使用物理内存，由需要调整swappiness参数值
### 配置
```
wujianjun@wujianjun-work:~# cat /proc/sys/vm/swappiness
默认值 60
wujianjun@wujianjun-work:~# sysctl vm.swappiness=10 # 临时调整
wujianjun@wujianjun-work:~# echo "vm.swappiness=10" >> /etc/sysctl.conf #永久调整
wujianjun@wujianjun-work:~# sysctl -p
vm.swappiness = 10
```

-----

*观点仅代表自己，期待你的留言。*
