---
title: jvm查内存泄漏利器 - jmap
keywords:
  - jmap
  - 内存泄漏
  - 对象实例数
  - 对象所占字节数
tags:
  - 原创
date: 2016-09-21 14:21:51
---
## 简介
Oracle将jmap描述为一种“输出进程、核心文件、远程调试服务器的共享对象内存映射和堆内存细节”的程序。
通过它可以查看内存中对象实例，从而解决程序出现不正常的高内存负载、频繁无响应或内存溢出等问题。
## 命令安装
1. Oracle JDK在安装完成后bin目录下就会发现有jmap命令。
2. Open JDK在安装完成后需要安装openjdk-devel开发包才能得到jmap命令。
安装方法如下（以CentOS为例）：
使用 `yum whatprovides '*/jmap'`查包含jmap命令开发包的名称。
```
[root@wujianjun-linux bin]# yum whatprovides '*/jmap'
Loaded plugins: fastestmirror, security
Loading mirror speeds from cached hostfile
base/filelists_db                                                                                  | 6.4 MB     00:00     
extras/filelists_db                                                                                |  38 kB     00:00     
updates/filelists_db                                                                               | 1.5 MB     00:00     
1:java-1.7.0-openjdk-devel-1.7.0.99-2.6.5.1.el6.x86_64 : OpenJDK Development Environment
Repo        : base
Matched from:
Filename    : /usr/lib/jvm/java-1.7.0-openjdk-1.7.0.99.x86_64/bin/jmap
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
[root@wujianjun-linux bin]# whereis jmap
jmap: /usr/bin/jmap /usr/share/man/man1/jmap.1.gz
```
只要能显示相应目录，则表示安装成功。
## jmap使用
```
root@wujianjun-linux ~]# jmap --help
Usage:
    jmap [option] <pid>
        (to connect to running process)
    jmap [option] <executable <core>
        (to connect to a core file)
    jmap [option] [server_id@]<remote server IP or hostname>
        (to connect to remote debug server)

where <option> is one of:
    <none>               to print same info as Solaris pmap
    -heap                to print java heap summary
    -histo[:live]        to print histogram of java object heap; if the "live"
                         suboption is specified, only count live objects
    -permstat            to print permanent generation statistics
    -finalizerinfo       to print information on objects awaiting finalization
    -dump:<dump-options> to dump java heap in hprof binary format
                         dump-options:
                           live         dump only live objects; if not specified,
                                        all objects in the heap are dumped.
                           format=b     binary format
                           file=<file>  dump heap to <file>
                         Example: jmap -dump:live,format=b,file=heap.bin <pid>
    -F                   force. Use with -dump:<dump-options> <pid> or -histo
                         to force a heap dump or histogram when <pid> does not
                         respond. The "live" suboption is not supported
                         in this mode.
    -h | -help           to print this help message
    -J<flag>             to pass <flag> directly to the runtime system
```
* jmap pid #打印内存使用的摘要信息
* jmap –heap pid #java heap信息
* jmap -histo:live pid #统计对象count ，live表示在使用
* jmap -histo pid >mem.txt #打印比较简单的各个有多少个对象占了多少内存的信息，一般重定向的文件
* jmap -dump:format=b,file=mem.dat pid #将内存使用的详细情况输出到mem.dat 文件
  通过`jhat -port 7000 mem.dat`可以将mem.dat的内容以web的方式暴露到网络，访问`http://ip-server:7000`查看。
  
针对内存泄漏这一问题，可以通过查看堆内存中存活对象实例及所占内存数查到对象是否一直被占用导致不能被GC回收。
如：
```
[root@wujianjun-linux ~]# jps |grep -v Jps
9495 Bootstrap

[root@wujianjun-linux ~]# jmap -histo:live 9495
 num     #instances         #bytes  class name
----------------------------------------------
   1:        294149       29662584  [C
   2:        187061       27752880  <constMethodKlass>
   3:        187061       23955120  <methodKlass>
   4:         15897       19221104  <constantPoolKlass>
   5:         61107       13783928  [B
   6:         15897       11445056  <instanceKlassKlass>
   7:         13934       11267712  <constantPoolCacheKlass>
   8:        280651        6735624  java.lang.String
   9:        102892        5761952  org.springframework.asm.Item
  10:        234489        5627736  org.springframework.asm.Edge
  11:         84750        5424000  org.springframework.asm.Label
  12:         66211        5296880  java.lang.reflect.Method
  13:         63388        4503312  [I
  14:         75275        4215400  org.springframework.asm.Item
  15:         62580        4005120  org.springframework.asm.Label
  16:        132458        3178992  org.springframework.asm.Edge

[root@wujianjun-linux ~]# jmap -histo:live 9495|grep com.yqyw
 num     #instances         #bytes  class name
----------------------------------------------
2788:             1             48  com.yqyw.user.rpc.client.UserClient
3570:             1             32  com.yqyw.pnr.sdk.client.ShopClient
3731:             1             32  com.yqyw.pnr.sdk.client.ShopClient
3842:             1             24  com.yqyw.user.rpc.client.impl.FavoriteServiceImpl
```
从以上输出可以看出目前堆内存中自己程序中的对象实例以及占用bytes，从而确定程序中哪些位置对这些对象进行创建使用且未被释放（典型的情况是将对象存入List等集合类而未被remove）。
也通过多次执行`jmap -histo:live pid >mem.txt`将每次结果定向到不同的txt中，然后对象对比。发现对象实例的增长与占用字节的变化。


__附 - jmap输出中class name非自定义类的说明：__

|BaseType Character     |Type           |Interpretation 
|---------------------------------------------------------
|B 						|byte 			|signed byte
|C 						|char        	|Unicode character
|D 						|double			|double-precision floating-point value
|F 						|float 			|single-precision floating-point value
|I 						|int 			|integer
|J 						|long 			|long integer
|L; 					|reference 		|an instance of class
|S 						|short			|signed short
|Z						|boolean 		|true or false
|[ 						|reference 		|one array dimension

-----

*观点仅代表自己，期待你的留言。*