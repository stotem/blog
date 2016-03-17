---
title: Nginx在CentOS7上源码编译安装
tags:
  - 原创
  - Nginx
date: 2016-03-14 11:32:15
---
### 下载Nginx源码及依赖库
```
[root@localhost ~]# wget http://nginx.org/download/nginx-1.8.1.tar.gz
[root@localhost ~]# yum install -y gcc gcc-c++
[root@localhost ~]# wget http://jaist.dl.sourceforge.net/project/pcre/pcre/8.38/pcre-8.38.tar.gz
[root@localhost ~]# wget http://zlib.net/zlib-1.2.8.tar.gz
```
### 下载Nginx模块
Nginx官网所有模块列表  [http://nginx.org/en/docs/](http://nginx.org/en/docs/)
```
[root@localhost ~]# yum -y install openssl openssl-devel
[root@localhost ~]# git clone https://github.com/vozlt/nginx-module-vts.git 
[root@localhost ~]# git clone https://github.com/yaoweibin/nginx_tcp_proxy_module.git
[root@localhost ~]# git clone https://github.com/yaoweibin/nginx_upstream_check_module.git
```
### 编译安装Nginx
```
[root@localhost ~]# tar xvf nginx-1.8.1.tar.gz
[root@localhost ~]# tar xvf pcre-8.38.tar.gz
[root@localhost ~]# tar xvf zlib-1.2.8.tar.gz
[root@localhost ~]# cd nginx-1.8.1
[root@localhost nginx-1.8.1]# patch -p1 < ../nginx_tcp_proxy_module/tcp.patch
[root@localhost nginx-1.8.1]# patch -p1 < ../nginx_upstream_check_module/check_1.7.5+.patch //按nginx版本来执行不同的补丁文件
[root@localhost nginx-1.8.1]# ./configure --with-pcre=../pcre-8.38 --with-zlib=../zlib-1.2.8 --with-http_gzip_static_module --with-http_ssl_module --add-module=../nginx_tcp_proxy_module/ \--add-module=../nginx_upstream_check_module/ \--add-module=../nginx-module-vts/
[root@localhost nginx-1.8.1]# make 
[root@localhost nginx-1.8.1]# make install
[root@localhost nginx-1.8.1]# /usr/local/nginx/sbin/nginx -V 
nginx version: nginx/1.8.1
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-4) (GCC) 
built with OpenSSL 1.0.1e-fips 11 Feb 2013
TLS SNI support enabled
configure arguments: --with-pcre=../pcre-8.38 --with-zlib=../zlib-1.2.8 --with-http_gzip_static_module --with-http_ssl_module --add-module=../nginx_tcp_proxy_module/ --add-module=../nginx_upstream_check_module/ --add-module=../nginx-module-vts/
[root@localhost nginx-1.8.1]# /usr/local/nginx/sbin/nginx
[root@localhost nginx-1.8.1]# systemctl stop firewalld.service //关闭防火墙，开放访问端口80
```
![Nginx Welcome](/images/nginx.png)

nginx安装目录默认为: /usr/local/nginx, 可通过在configure时增加--prefix="path"来更改。

nginx启动时默认用户及用户组设置：
* 通过在configure时增加--user="user name"和--group="group name"来更改。
* 在nginx.conf里增加user "user name" "group name"来更改。

__注意: 在configure时如需添加多个第三方module时，从第二个--add-module开始，在之前需要加“\”__

-----
*观点仅代表自己，期待你的留言。*
