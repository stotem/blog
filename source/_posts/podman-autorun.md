---
title: Podman容器开机自启动
tags:
  - 原创
  - podman
keywords:
  - Podman
  - 容器开机启动
date: 2024-02-28 14:39:15
---

## ROOT用户启动容器
1. 启动一个容器
```
# podman run -d --name web httpd
```
2. 查看该容器
```
# podman ps
```
3. 每次都启动新容器方式创建servcie //--new参数，每次启动都删除旧容器，启动一个新容器
```
# podman generate systemd -n --new -f web
```
4. 将service文件保存在/etc/systemd/system/
```
# mv container-web.service /etc/systemd/system/
```
5. 刷新配置文件，让其生效
```
# systemctl daemon-reload
```
6. 修改selinux
```
# cat config |grep SELINUX=disabled
```
7. 设置容器开机自启，并且现在启动
```
# systemctl enable --now /etc/systemd/system/container-web.service
```
8. 测试，重启虚拟机
```
# reboot
```
9. 查看容器是否在运行，并查看container-web.service是否开机自启和运行
```
# systemctl status container-web.service
# podman ps
```


## rootless模式启动容器
1. 创建~/.config/systemd/user/目录来存储unit文件
```
# mkdir -p ~/.config/systemd/user/
```
2. 查看该容器
```
# podman ps
```
3. 每次都启动新容器方式创建servcie //--new参数，每次启动都删除旧容器，启动一个新容器
```
# podman generate systemd -n --new -f web
```
4.将service文件保存在~/.config/systemd/user/
```
# mv container-web.service ~/.config/systemd/user/
```
5.刷新配置文件，让其生效
```
# systemctl --user daemon-reload
```
6.修改selinux
```
# cat config |grep SELINUX=disabled
```
8.设置容器开机自启，并且现在启动
```
# systemctl --user enable --now ~/.config/systemd/user/container-web.service
```
9.测试启动容器
```
# systemctl --user restart container-web.service
```
10.查看容器是否在运行，并查看container-web.service是否开机自启和运行
```
# systemctl --user status container-web.service
# podman ps
```

`注意：` systemd使用systemctl命令管理这些服务当用户服务类型为非根用户时，通过文本或图形控制台或使用SSH打开第一个会话时， 该服务将自动启动。当关闭最后一次会话时，服务将停止。
这种行为与系统服务不同，系统服务在系统启动时启动，在系统关闭时停止。但也可以更改此默认行为，通过运行loginctl enable-linger命令强制service在服务器启动时启动并在关闭时停止。
逆向操作,请使用loginctl disable-linger命令。查看当前状态，使用loginctl show-user username命令。



-----

*观点仅代表自己，期待你的留言。*
