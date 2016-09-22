---
title: 查看jvm堆内GC情况利器 - jstat
keywords: 
  - jstat
tags:
  - 原创
date: 2016-09-22 17:30:09
---

## 简介
jstat是JDK自带的一个轻量级小工具。全称“Java Virtual Machine statistics monitoring tool”，主要利用JVM内建的指令对Java应用程序的资源和性能进行实时的命令行的监控，包括了对Heap size和垃圾回收状况的监控。
以命令行方式运行对系统资源占用很小，在大压力下很少影响性能。并且运行要求低，只要通过Telnet或SSH等方式远程登录到服务器所在机器，就可以进行监控。在与jstat、jstack等工具结合使用时非常方便。
## 命令安装
1. Oracle JDK在安装完成后bin目录下就会发现有jstat命令。
2. Open JDK在安装完成后需要安装openjdk-devel开发包才能得到jstat命令。
安装方法如下（以CentOS为例）：
使用 `yum whatprovides '*/jstat'`查包含jstat命令开发包的名称。
```
[root@wujianjun-linux bin]# yum whatprovides '*/jstat'
Loaded plugins: fastestmirror, security
Loading mirror speeds from cached hostfile
base/filelists_db                                                                                  | 6.4 MB     00:00     
extras/filelists_db                                                                                |  38 kB     00:00     
updates/filelists_db                                                                               | 1.5 MB     00:00     
1:java-1.7.0-openjdk-devel-1.7.0.99-2.6.5.1.el6.x86_64 : OpenJDK Development Environment
Repo        : base
Matched from:
Filename    : /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.99.x86_64/bin/jstat
......
.....
...
```
找到与jdk版本相对应的开发包进行安装
```
[root@wujianjun-linux bin]# yum install java-1.7.0-openjdk-devel
```
安装完成后查找命令所在目录
```
[root@wujianjun-linux bin]# whereis jstat
jstat: /usr/bin/jstat /usr/share/man/man1/jstat.1.gz
```
只要能显示相应目录，则表示安装成功。
## jstat使用
```
[root@order-zhiMaoQu-com ~]# jstat --help
invalid argument count
Usage: jstat -help|-options
       jstat -<option> [-t] [-h<lines>] <vmid> [<interval> [<count>]]

Definitions:
  <option>      An option reported by the -options option
  <vmid>        Virtual Machine Identifier. A vmid takes the following form:
                     <lvmid>[@<hostname>[:<port>]]
                Where <lvmid> is the local vm identifier for the target
                Java virtual machine, typically a process id; <hostname> is
                the name of the host running the target Java virtual machine;
                and <port> is the port number for the rmiregistry on the
                target host. See the jvmstat documentation for a more complete
                description of the Virtual Machine Identifier.
  <lines>       Number of samples between header lines.
  <interval>    Sampling interval. The following forms are allowed:
                    <n>["ms"|"s"]
                Where <n> is an integer and the suffix specifies the units as 
                milliseconds("ms") or seconds("s"). The default units are "ms".
  <count>       Number of samples to take before terminating.
  -J<flag>      Pass <flag> directly to the runtime system.
```
__<option> 可选值如下：__
* -gcutil: 查看gc情况
* -class: 显示加载class的数量，及所占空间等信息
* -compiler: 显示VM实时编译的数量等信息。
* –gccapacity: 可以显示，VM内存中三代（young,old,perm）对象的使用和占用大小，
    如：PGCMN显示的是最小perm的内存使用量，PGCMX显示的是perm的内存最大使用量，PGC是当前新生成的perm内存占用量，PC是但前perm内存占用量。
    其他的可以根据这个类推，OC是old内纯的占用量。
* -gcnew: new对象的信息
* -gcnewcapacity: new对象的信息及其占用量
* -gcold: old对象的信息。
* -gcoldcapacity: old对象的信息及其占用量
* -gcpermcapacity: perm对象的信息及其占用量
* -printcompilation: 当前VM执行的信息

__附GC显示术语解释：__
* S0C - 年轻代中第一个survivor（幸存区）的容量 (字节)
* S1C - 年轻代中第二个survivor（幸存区）的容量 (字节)
* S0U - 年轻代中第一个survivor（幸存区）目前已使用空间 (字节)
* S1U - 年轻代中第二个survivor（幸存区）目前已使用空间 (字节)
* EC - 年轻代中Eden的容量 (字节)
* EU - 年轻代中Eden目前已使用空间 (字节)
* OC - Old代的容量 (字节)
* OU - Old代目前已使用空间 (字节)
* PC - Perm(持久代)的容量 (字节)
* PU - Perm(持久代)目前已使用空间 (字节)
* YGC - 从应用程序启动到采样时年轻代中gc次数
* YGCT - 从应用程序启动到采样时年轻代中gc所用时间(s)
* FGC - 从应用程序启动到采样时old代(全gc)gc次数
* FGCT - 从应用程序启动到采样时old代(全gc)gc所用时间(s)
* GCT - 从应用程序启动到采样时gc用的总时间(s)
* NGCMN - 年轻代(young)中初始化(最小)的大小 (字节)
* NGCMX - 年轻代(young)的最大容量 (字节)
* NGC - 年轻代(young)中当前的容量 (字节)
* OGCMN - old代中初始化(最小)的大小 (字节)
* OGCMX - old代的最大容量 (字节)
* OGC - old代当前新生成的容量 (字节)
* PGCMN - perm代中初始化(最小)的大小 (字节)
* PGCMX - perm代的最大容量 (字节)
* PGC - perm代当前新生成的容量 (字节)
* S0 - 年轻代中第一个survivor（幸存区）已使用的占当前容量百分比
* S1 - 年轻代中第二个survivor（幸存区）已使用的占当前容量百分比
* E - 年轻代中Eden已使用的占当前容量百分比
* O - old代已使用的占当前容量百分比
* P - perm代已使用的占当前容量百分比
* S0CMX - 年轻代中第一个survivor（幸存区）的最大容量 (字节)
* S1CMX  - 年轻代中第二个survivor（幸存区）的最大容量 (字节)
* ECMX - 年轻代中Eden的最大容量 (字节)
* DSS - 当前需要survivor（幸存区）的容量 (字节)（Eden区已满）
* TT -  持有次数限制
* MTT  -  最大持有次数限制

-----

*观点仅代表自己，期待你的留言。*