---
title: 使用端口转发解决80端口使用问题
keywords:
  - "MacOS端口转发"
  - "Linux端口转发"
  - "80端口使用"
  - "java.net.BindException: Permission denied:80"
tags:
  - 原创
  - 操作系统
date: 2016-05-26 11:07:35
---

## 简介
当我用在使用linux非root用户进行应用发布时，如遇到应用程序需要占用80端口时总会由于权限不足遇到`java.net.BindException: Permission denied:80`的错误报出。
Linux为保证系统安全，限制了非root用户对1024以下的端口进行占用。
那么，本文将通过端口转发的方式解决80端口在Linux和MacOSX系统上占用的问题。

## linux非Root用户使用80端口
linux操作系统的可以通过iptables来进行端口转发，将流向80端口的数据内部转发到大于1024的端口上。那么非root用户就可以通过占用大于1024的端口进行程序应用的功能处理。
以80转发到8080端口为例：
```
[root@localhost ~]# sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8080
[root@localhost ~]# sudo iptables -t nat -A OUTPUT -d localhost -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8080
[root@localhost ~]# iptables -t filter -F
[root@localhost ~]# iptables-save
[root@localhost ~]# service iptables restart
[root@localhost ~]# chkconfig iptables on 
```
iptables -t filter -F : 为清除所有的过滤规则。
chkconfig iptables on : 设置iptables开机启动。

iptables存储文件：/etc/sysconfig/iptables

## MacOSX使用80端口
MacOS操作系统下则使用`pf`来进行端口转发。
pf启动时会自动装载/etc/pf.conf文件，因此，我们可以通过修改这个文件进行80端口数据的转发。
修改后的文件内容如下：
```
scrub-anchor "com.apple/*"
nat-anchor "com.apple/*"
rdr-anchor "com.apple/*"
rdr on lo0 inet proto tcp from any to 127.0.0.1 port 80 -> 127.0.0.1 port 8080
dummynet-anchor "com.apple/*"
anchor "com.apple/*"
load anchor "com.apple" from "/etc/pf.anchors/com.apple"
```
使用 pfctl使用重新加载pf.conf配置，并启动pf
```
Jianjun:~ Jianjun$ sudo pfctl -f /etc/pf.conf
Jianjun:~ Jianjun$ sudo pfctl -e
```
另，关闭pf的命令为：`sudo pfctl -d`


-----

*观点仅代表自己，期待你的留言。*