---
title: OpenVPN系列二之外网映射
tags:
  - 原创
  - OpenVPN
keywords:
  - 外网映射
  - "write UDP: Can't assign requested address (code=49)"
  - "vpn网络互通"

date: 2022-08-04 14:11:29
---

## 背景
按![OpenVPN系列一之安装配置](/2022/08/04/openvpn-install)配置好之后，需要做以下两件事情才能让客户机正常使用
- OpenVPN服务器1194端口映射到外网，则客户机通过外网就能连接上vpn
- 内网服务器能访问到OpenVPN的子网内的客户机

以上两步需要在路由上进行设置

## 服务器环境参数

| 序号 | 设备名 | IP地址 | 说明 |
| ------ | ------ | ------ | ------ |
| 1 | 路由器 | 10.84.102.1 | H3C专线路由器  |
| 2 | Vpn服务器 | 10.84.102.131 | 搭建20.04 LTS操作系统  |
| 3 | 服务器1 | 10.84.102.90 | 内网服务器  |

所涉及到的软件为：
OpenVPN 2.4.7（服务端）
Tunnelblick 3.8.7a（客户机软件）

## OpenVPN服务器1194端口映射到外网
登录到路由器10.84.102.1进行外网映射配置
```
******************************************************************************
* Copyright (c) 2004-2015 Hangzhou H3C Tech. Co., Ltd. All rights reserved.  *
* Without the owner's prior written consent,                                 *
* no decompiling or reverse-engineering shall be allowed.                    *
******************************************************************************


Login authentication


Username:admin
Password:
<GPluslife>sys
System View: return to User View with Ctrl+Z.
# 进入外网网卡
[GPluslife]in gig0/0
[GPluslife-Ethernet0/0] nat server 15 protocol udp global current-interface 1194 inside 10.84.102.131 1194
[GPluslife-Ethernet0/0] save
[GPluslife-Ethernet0/0] quit
# 查看更改后的配置是否成功
[GPluslife]dis cur
[GPluslife]quit
```

映射完成后可找台外网服务器通过nmap扫描下1194端口是否开放

```
root@wujianjun-net-work:~# nmap -sU [路由器外网IP] -p 1194 -Pn
Starting Nmap 7.80 ( https://nmap.org ) at 2022-08-04 11:36 CST
Nmap scan report for xx.xx.xx.xx
Host is up.

PORT     STATE         SERVICE
1194/udp open|filtered openvpn
```
经过以上步骤，可通过client1.ovpn加载到Tunnelblick进行连接了。

`注意：client1.ovpn配置中的remote后的ip为路由器的外网IP`

## 内网服务器能访问到OpenVPN的子网内
登录到路由器10.84.102.1进行子网路由配置
```
******************************************************************************
* Copyright (c) 2004-2015 Hangzhou H3C Tech. Co., Ltd. All rights reserved.  *
* Without the owner's prior written consent,                                 *
* no decompiling or reverse-engineering shall be allowed.                    *
******************************************************************************


Login authentication


Username:admin
Password:
<GPluslife>sys
System View: return to User View with Ctrl+Z.
# 查看现有配置
[GPluslife]dis cur
[GPluslife] ip route-static 10.8.0.0 255.255.255.0 10.84.102.131
# 查看添加路由后的配置
[GPluslife]dis cur
[GPluslife] save
[GPluslife] quit
```
经过以上步骤，可通过内网服务器（10.84.102.90）ping客户机分配的（10.8.0.x）是否可以连通

## 客户机信息查看,以macOS为例
```
# 查看客户机的vpn所分配的内网IP地址
wujianjun@work-mbp blog % ifconfig
# 查看客户机路由表
wujianjun@work-mbp blog % netstat -nr
```

## 常见问题, 以macOS为例
1. Tunnelblick出现`write UDP: Can't assign requested address (code=49)`错误
解决方案：由于客户机路由表影响，通过在终端`sudo route flush`来解决

2. 测试期间可以尝试通过以下方法来在客户机上加路由
解决方案：
#添加基于接口的路由
sudo route add -host 1.1.1.1 -iface lo0
sudo route add -net 1.1.1.0/24 -iface lo0
#添加基于网关IP的路由
sudo route add -net 1.1.1.0/24 192.168.1.1
sudo route add -host 1.1.1.1 192.168.1.1
#删除静态路由
sudo route delete 1.1.1.0/24
sudo route delete 1.1.1.1

-----

*观点仅代表自己，期待你的留言。*
