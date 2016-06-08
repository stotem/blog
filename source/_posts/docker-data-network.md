---
title: docker数据卷与网络配置
tags:
  - Docker
  - 原创
date: 2016-04-18 11:33:08
---

# 数据卷
Docker 挂载数据卷的默认权限是读写，用户也可以通过 :ro 指定为只读。
示例：
```
$ sudo docker run -d -P --name web -v /src/webapp:/opt/webapp:ro training/webapp python app.py
```
## 创建数据卷
在用 `docker run` 命令的时候，使用 `-v` 标记来创建一个数据卷并挂载到容器里。在一次 run 中多次使用可以挂载多个数据卷。
示例： 
```
$ sudo docker run -d -P --name web -v /webapp training/webapp python app.py
```
## 挂载一个主机目录作为数据卷
加载主机的 /src/webapp 目录到容器的 /opt/webapp 目录.
示例：
```
$ sudo docker run -d -P --name web -v /src/webapp:/opt/webapp training/webapp python app.py
```
`注意：`本地目录的路径必须是绝对路径，如果目录不存在 Docker 会自动为你创建它。
## 挂载一个本地主机文件作为数据卷
-v 标记也可以从主机挂载单个文件到容器中
示例：
```
$ sudo docker run --rm -it -v ~/.bash_history:/.bash_history ubuntu /bin/bash
```
## 删除数据卷
数据卷是被设计用来持久化数据的，它的生命周期独立于容器，Docker不会在容器被删除后自动删除数据卷，并且也不存在垃圾回收这样的机制来处理没有任何容器引用的数据卷。如果需要在删除容器的同时移除数据卷。可以在删除容器的时候使用 `docker rm -v`这个命令。无主的数据卷可能会占据很多空间，要清理会很麻烦。
## 数据卷容器
如果你有一些持续更新的数据需要在容器之间共享，最好创建数据卷容器。
数据卷容器，其实就是一个正常的容器，专门用来提供数据卷供其它容器挂载的。
首先，创建一个名为 dbdata 的数据卷容器：
```
$ sudo docker run -d -v /dbdatas --name dbdata training/postgres echo Data-only container for postgres
```
然后，在其他容器中使用 `--volumes-from` 来挂载 dbdata 容器中的数据卷。
```
$ sudo docker run -d --volumes-from dbdata --name db1 training/postgres
$ sudo docker run -d --volumes-from dbdata --name db2 training/postgres
```
可以使用超过一个的 --volumes-from 参数来指定从多个容器挂载不同的数据卷。 也可以从其他已经挂载了数据卷的容器来级联挂载数据卷。
```
$ sudo docker run -d --name db3 --volumes-from db1 training/postgres
```
*注意：使用 `--volumes-from` 参数所挂载数据卷的容器自己并不需要保持在运行状态。
如果删除了挂载的容器（包括 dbdata、db1 和 db2），数据卷并不会被自动删除。如果要删除一个数据卷，必须在删除最后一个还挂载着它的容器时使用 `docker rm -v` 命令来指定同时删除关联的容器。
## 利用数据卷容器来备份、恢复、迁移数据卷
### 备份
首先使用 --volumes-from 标记来创建一个加载 dbdata 容器卷的容器，并从主机挂载当前目录到容器的 /backup 目录。
命令如下：
```
$ sudo docker run --volumes-from dbdata -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /dbdata
```
容器启动后，使用了 tar 命令来将 dbdata 卷备份为容器中 /backup/backup.tar 文件，也就是主机当前目录下的名为 backup.tar 的文件。
### 恢复
如果要恢复数据到一个容器，首先创建一个带有空数据卷的容器 dbdata2。
```
$ sudo docker run -v /dbdata --name dbdata2 ubuntu /bin/bash
```
然后创建另一个容器，挂载 dbdata2 容器卷中的数据卷，并使用 untar 解压备份文件到挂载的容器卷中。
```
$ sudo docker run --volumes-from dbdata2 -v $(pwd):/backup busybox tar xvf /backup/backup.tar
```
为了查看/验证恢复的数据，可以再启动一个容器挂载同样的容器卷来查看
```
$ sudo docker run --volumes-from dbdata2 busybox /bin/ls /dbdata
```
# 网络配置
## 外部访问容器
docker容器一般使用5000做为服务端口（类似于80端口的概念）。
 - docker支持在`docker run`时增加`-P`来将主机随机端口(49000~49900)映射到容器内的5000。可通过`docker ps`查看到对应的占用端口。
 - docker支持在`docker run`时增加`-p`来将指定的主机端口映射到容器内的指定端口。
 	支持以下格式：
 	* `ip:hostPort:containerPort`： 将主机指定IP下的指定端口绑定到容器内的指定端口。
 	* `ip::containerPort`：绑定主机指定IP下的任意端口到容器的指定端口，本地主机会自动分配一个端口。还可以使用 udp 标记来指定 udp 端口。如`$ sudo docker run -d -p 127.0.0.1:5000:5000/udp training/webapp python app.py`
 	* `hostPort:containerPort`：指定主机所有IP下的指定端口到容器内的指定端口。

使用 `docker port` 来查看当前映射的端口配置，
__注意：__
 - 容器有自己的内部网络和 ip 地址（使用 docker inspect 可以获取所有的变量，Docker 还可以有一个可变的网络配置。）
 - -p 参数可以多次使用。如：`$ sudo docker run -d -p 5000:5000  -p 3000:80 training/webapp python app.py`
## 容器互联
连接系统依据容器的名称来执行。因此，首先需要通过`--name`自定义一个好记的容器命名。使用 `docker ps` 来验证设定的命名。

使用 `--link` 参数可以让容器之间安全的进行交互。参数的格式为 `--link name:alias`，其中 name 是要链接的容器的名称，alias 是这个连接的别名。
将web容器与db容器连接，且连接被命名为db, 启动命令如下：
```
$ sudo docker run -d -P --name web --link db:db training/webapp python app.py
```

__实现原理：__
Docker 通过 2 种方式为容器公开连接信息：
 - 环境变量。 通过linux命令`env`可以看到，环境变量通过增加alias做为前缀标识来区别容器的环境变量与连接。
 - 更新 /etc/hosts 文件。在hosts文件中增加alias条目的映射ip。


-----


*观点仅代表自己，期待你的留言。*
