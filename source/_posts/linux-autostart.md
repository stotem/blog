---
title: Linux开机自动启动Tomcat应用
tags:
  - 原创
date: 2016-10-09 18:43:51
---

## 前言
刚过国庆长假，工作机房断电，重回工作岗位发现N多的应用需要手动启动。感觉烦燥？
so.. 配置linux开机自启动

## 配置
在_/etc/rc.local_文件末尾增加以下内容
```
#!/bin/sh
#
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.

O_Path=`pwd`
cd /myapps/servers/apache-tomcat-6.0.43/bin/
sh startup.sh
cd $O_Path

```

__需要注意以下几点：__
* 检查startup.sh是否已授执行权限，如果没有，执行`chmod +x /myapps/servers/apache-tomcat-6.0.43/bin/startup.sh`
* 所需要执行的shell文件不能带参数。


经过以上配置则可以通过`sudo reboot`进行验证。当Linux重启成功后，可通过__/var/log/boot.log__来查看开机时的日志输出。

## 其它
`who -r` 查看开机级别

```
who --help
用法：who [选项]... [ 文件 | 参数1 参数2 ]
显示当前已登录的用户信息。

  -a, --all		等于-b -d --login -p -r -t -T -u 选项的组合
  -b, --boot		上次系统启动时间
  -d, --dead		显示已死的进程
  -H, --heading	输出头部的标题列
  -l，--login		显示系统登录进程
      --lookup		尝试通过 DNS 查验主机名
  -m			只面对和标准输入有直接交互的主机和用户
  -p, --process	显示由 init 进程衍生的活动进程
  -q, --count		列出所有已登录用户的登录名与用户数量
  -r, --runlevel	显示当前的运行级别
  -s, --short		只显示名称、线路和时间(默认)
  -T, -w, --mesg	用+，- 或 ? 标注用户消息状态
  -u, --users		列出已登录的用户
      --message	等于-T
      --writable	等于-T
      --help		显示此帮助信息并退出
      --version		显示版本信息并退出
```

-----

*观点仅代表自己，期待你的留言。*
