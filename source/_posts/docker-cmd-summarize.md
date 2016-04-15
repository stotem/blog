---
title: docker常用命令总结
tags:
  - Docker
  - 原创
date: 2016-04-15 10:54:54
---

### docker pull
`说明：`获取网络镜像到本地
 ```
 [root@localhost ~]# docker pull --help

Usage:	docker pull [OPTIONS] NAME[:TAG|@DIGEST]

Pull an image or a repository from a registry

  -a, --all-tags                  Download all tagged images in the repository
  --disable-content-trust=true    Skip image verification
  --help                          Print usage
 ```
当不指定TAG时，默认为：latest
示例：
```
[root@localhost ~]# sudo docker pull ubuntu:12.04
[root@localhost ~]# docker pull registry.hub.docker.com/ubuntu:12.04
```
### docker images
`说明：`显示本地已有的镜像
```
[root@localhost ~]# docker images --help

Usage:	docker images [OPTIONS] [REPOSITORY[:TAG]]

List images

  -a, --all          Show all images (default hides intermediate images)
  --digests          Show digests
  -f, --filter=[]    Filter output based on conditions provided
  --format           Pretty-print images using a Go template
  --help             Print usage
  --no-trunc         Don't truncate output
  -q, --quiet        Only show numeric IDs
```
镜像的 `ID` 唯一标识了镜像。
### docker run
`说明：`使用已下载到本地的镜像启动一个新容器
```
[root@localhost ~]# docker run --help

Usage:	docker run [OPTIONS] IMAGE [COMMAND] [ARG...]

Run a command in a new container

  -a, --attach=[]                 Attach to STDIN, STDOUT or STDERR
  --add-host=[]                   Add a custom host-to-IP mapping (host:ip)
  --blkio-weight                  Block IO (relative weight), between 10 and 1000
  --blkio-weight-device=[]        Block IO weight (relative device weight)
  --cpu-shares                    CPU shares (relative weight)
  --cap-add=[]                    Add Linux capabilities
  --cap-drop=[]                   Drop Linux capabilities
  --cgroup-parent                 Optional parent cgroup for the container
  --cidfile                       Write the container ID to the file
  --cpu-period                    Limit CPU CFS (Completely Fair Scheduler) period
  --cpu-quota                     Limit CPU CFS (Completely Fair Scheduler) quota
  --cpuset-cpus                   CPUs in which to allow execution (0-3, 0,1)
  --cpuset-mems                   MEMs in which to allow execution (0-3, 0,1)
  -d, --detach                    Run container in background and print container ID
  --detach-keys                   Override the key sequence for detaching a container
  --device=[]                     Add a host device to the container
  --device-read-bps=[]            Limit read rate (bytes per second) from a device
  --device-read-iops=[]           Limit read rate (IO per second) from a device
  --device-write-bps=[]           Limit write rate (bytes per second) to a device
  --device-write-iops=[]          Limit write rate (IO per second) to a device
  --disable-content-trust=true    Skip image verification
  --dns=[]                        Set custom DNS servers
  --dns-opt=[]                    Set DNS options
  --dns-search=[]                 Set custom DNS search domains
  -e, --env=[]                    Set environment variables
  --entrypoint                    Overwrite the default ENTRYPOINT of the image
  --env-file=[]                   Read in a file of environment variables
  --expose=[]                     Expose a port or a range of ports
  --group-add=[]                  Add additional groups to join
  -h, --hostname                  Container host name
  --help                          Print usage
  -i, --interactive               Keep STDIN open even if not attached
  --ip                            Container IPv4 address (e.g. 172.30.100.104)
  --ip6                           Container IPv6 address (e.g. 2001:db8::33)
  --ipc                           IPC namespace to use
  --isolation                     Container isolation level
  --kernel-memory                 Kernel memory limit
  -l, --label=[]                  Set meta data on a container
  --label-file=[]                 Read in a line delimited file of labels
  --link=[]                       Add link to another container
  --log-driver                    Logging driver for container
  --log-opt=[]                    Log driver options
  -m, --memory                    Memory limit
  --mac-address                   Container MAC address (e.g. 92:d0:c6:0a:29:33)
  --memory-reservation            Memory soft limit
  --memory-swap                   Swap limit equal to memory plus swap: '-1' to enable unlimited swap
  --memory-swappiness=-1          Tune container memory swappiness (0 to 100)
  --name                          Assign a name to the container
  --net=default                   Connect a container to a network
  --net-alias=[]                  Add network-scoped alias for the container
  --oom-kill-disable              Disable OOM Killer
  --oom-score-adj                 Tune host's OOM preferences (-1000 to 1000)
  -P, --publish-all               Publish all exposed ports to random ports
  -p, --publish=[]                Publish a container's port(s) to the host
  --pid                           PID namespace to use
  --privileged                    Give extended privileges to this container
  --read-only                     Mount the container's root filesystem as read only
  --restart=no                    Restart policy to apply when a container exits
  --rm                            Automatically remove the container when it exits
  --security-opt=[]               Security Options
  --shm-size                      Size of /dev/shm, default value is 64MB
  --sig-proxy=true                Proxy received signals to the process
  --stop-signal=SIGTERM           Signal to stop a container, SIGTERM by default
  -t, --tty                       Allocate a pseudo-TTY
  --tmpfs=[]                      Mount a tmpfs directory
  -u, --user                      Username or UID (format: <name|uid>[:<group|gid>])
  --ulimit=[]                     Ulimit options
  --uts                           UTS namespace to use
  -v, --volume=[]                 Bind mount a volume
  --volume-driver                 Optional volume driver for the container
  --volumes-from=[]               Mount volumes from the specified container(s)
  -w, --workdir                   Working directory inside the container
```
`IMAGE`可以为镜像名或者镜像ID。
示例： 
```
sudo docker run -t -i ouruser/sinatra:v2 /bin/bash
sudo docker run -d ubuntu:14.04 /bin/sh -c "while true; do echo hello world; sleep 1; done" #守护态运行
```
### docker logs
`说明：`获取容器输出的信息，适用于守护态运行docker容器。
```
[root@localhost ~]# docker logs --help

Usage:	docker logs [OPTIONS] CONTAINER

Fetch the logs of a container

  -f, --follow        Follow log output
  --help              Print usage
  --since             Show logs since timestamp
  -t, --timestamps    Show timestamps
  --tail=all          Number of lines to show from the end of the logs
```
### docker stop
`说明：`停止一个正在启动的容器。
```
[root@localhost ~]# docker stop --help

Usage:	docker stop [OPTIONS] CONTAINER [CONTAINER...]

Stop a running container.
Sending SIGTERM and then SIGKILL after a grace period

  --help             Print usage
  -t, --time=10      Seconds to wait for stop before killing it
```
### docker start
`说明：`启动一个已经停止的容器。
```
[root@localhost ~]# docker start --help

Usage:	docker start [OPTIONS] CONTAINER [CONTAINER...]

Start one or more stopped containers

  -a, --attach         Attach STDOUT/STDERR and forward signals
  --detach-keys        Override the key sequence for detaching a container
  --help               Print usage
  -i, --interactive    Attach container's STDIN
```
### docker restart
`说明：`将一个运行态的容器终止，然后再重新启动它。
```
[root@localhost ~]# docker restart --help

Usage:	docker restart [OPTIONS] CONTAINER [CONTAINER...]

Restart a container

  --help             Print usage
  -t, --time=10      Seconds to wait for stop before killing the container
```
### docker attach
`说明：`在使用 -d 参数时，容器启动后会进入后台。 某些时候需要进入容器进行操作就可以用它。
```
[root@localhost ~]# docker attach --help

Usage:	docker attach [OPTIONS] CONTAINER

Attach to a running container

  --detach-keys       Override the key sequence for detaching a container
  --help              Print usage
  --no-stdin          Do not attach STDIN
  --sig-proxy=true    Proxy all received signals to the process
```

### docker commit
`说明：`将修改后的容器提交保存为一个新的镜像。
```
[root@localhost ~]# docker commit --help

Usage:	docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]

Create a new image from a container's changes

  -a, --author        Author (e.g., "John Hannibal Smith <hannibal@a-team.com>")
  -c, --change=[]     Apply Dockerfile instruction to the created image
  --help              Print usage
  -m, --message       Commit message
  -p, --pause=true    Pause container during commit
```
示例：
```
$ sudo docker commit -m "Added json gem" -a "Docker Newbee" 0b2616b0e5a8 ouruser/sinatra:v2
4f177bd27a9ff0f6dc2a830403925b5360bfe0b93d476f7fc3231110e7f71b1c
```
### docker tag
`说明:`修改镜像标签
```
[root@localhost ~]# docker tag --help

Usage:	docker tag [OPTIONS] IMAGE[:TAG] [REGISTRYHOST/][USERNAME/]NAME[:TAG]

Tag an image into a repository

  --help             Print usage
```
示例：
```
docker tag 5db5f8471261 ouruser/sinatra:devel #将5db5f8471261的镜像tag更改为devel
```
### docker push
`说明:`自己创建的本地镜像上传到远程仓库中来共享。
```
[root@localhost ~]# docker push --help

Usage:	docker push [OPTIONS] NAME[:TAG]

Push an image or a repository to a registry

  --disable-content-trust=true    Skip image signing
  --help                          Print usage
```
### docker save
`说明:`将镜像导出成本地文件
```
[root@localhost ~]# docker save --help

Usage:	docker save [OPTIONS] IMAGE [IMAGE...]

Save an image(s) to a tar archive (streamed to STDOUT by default)

  --help             Print usage
  -o, --output       Write to a file, instead of STDOUT
```
示例：
```
[root@localhost ~]# docker save -o ubuntu_14.04.tar ubuntu:14.04
```
### docker load
`说明:`将镜像本地文件加载成为本地镜像
```
[root@localhost ~]# docker load --help

Usage:	docker load [OPTIONS]

Load an image from a tar archive or STDIN

  --help             Print usage
  -i, --input        Read from a tar archive file, instead of STDIN
```
示例：
```
[root@localhost ~]# docker load --input ubuntu_14.04.tar
```
### docker ps
`说明：`列出对应的容器
```
[root@localhost ~]# docker ps --help

Usage:	docker ps [OPTIONS]

List containers

  -a, --all          Show all containers (default shows just running)
  -f, --filter=[]    Filter output based on conditions provided
  --format           Pretty-print containers using a Go template
  --help             Print usage
  -l, --latest       Show the latest created container (includes all states)
  -n=-1              Show n last created containers (includes all states)
  --no-trunc         Don't truncate output
  -q, --quiet        Only display numeric IDs
  -s, --size         Display total file sizes
```
示例：
```
[root@localhost ~]# docker ps -a
```
### docker export
`说明：`导出本地某个容器为快照文件
```
[root@localhost ~]# docker export --help

Usage:	docker export [OPTIONS] CONTAINER

Export a container's filesystem as a tar archive

  --help             Print usage
  -o, --output       Write to a file, instead of STDOUT
```
### docker import
`说明：`将容器快照文件导入为本地容器或者本地镜像。与`docker load`的区别在于容器快照文件将丢弃所有的历史记录和元数据信息,而镜像存储文件将保存完整记录，体积也要大。
```
[root@localhost ~]# docker import --help

Usage:	docker import [OPTIONS] file|URL|- [REPOSITORY[:TAG]]

Import the contents from a tarball to create a filesystem image

  -c, --change=[]    Apply Dockerfile instruction to the created image
  --help             Print usage
  -m, --message      Set commit message for imported image
```
示例：
```
[root@localhost ~]# cat ubuntu.tar | sudo docker import - test/ubuntu:v1.0
```
### docker rm
`说明：`移除容器
```
[root@localhost ~]# docker rm --help

Usage:	docker rm [OPTIONS] CONTAINER [CONTAINER...]

Remove one or more containers

  -f, --force        Force the removal of a running container (uses SIGKILL)
  --help             Print usage
  -l, --link         Remove the specified link
  -v, --volumes      Remove the volumes associated with the container
```
示例：
```
[root@localhost ~]# docker rm $(docker ps -a -q) #清理所有处于终止状态的容器
```
### docker rmi
`说明:`移除本地镜像，移出前需要先移除到镜像对应的容器。
```
[root@localhost ~]# docker rmi --help

Usage:	docker rmi [OPTIONS] IMAGE [IMAGE...]

Remove one or more images

  -f, --force        Force removal of the image
  --help             Print usage
  --no-prune         Do not delete untagged parents
```

清理所有未打过标签的本地镜像：`docker rmi $(docker images -q -f "dangling=true")`

### docker inspect
`说明:`查看容器或者镜像的详情信息。
```
[root@localhost ~]# docker inspect --help

Usage:	docker inspect [OPTIONS] CONTAINER|IMAGE [CONTAINER|IMAGE...]

Return low-level information on a container or image

  -f, --format       Format the output using the given go template
  --help             Print usage
  -s, --size         Display total file sizes if the type is container
  --type             Return JSON for specified type, (e.g image or container)
```

-----


*观点仅代表自己，期待你的留言。*
