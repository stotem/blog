---
title: Nginx+php-fpm替代apache服务器
tags:
  - 转载
  - php-fpm
  - Nginx
date: 2016-03-21 15:01:31
---

## 简介
nginx本身不能处理PHP，它只是个web服务器，当接收到请求后，如果是php请求，则发给php解释器处理，并把结果返回给客户端。

nginx一般是把请求发fastcgi管理进程处理，fascgi管理进程选择cgi子进程处理结果并返回被nginx

本文以php-fpm为例介绍如何使nginx支持PHP
一、编译安装php-fpm

什么是PHP-FPM

PHP-FPM是一个PHP FastCGI管理器，是只用于PHP的,可以在 http://php-fpm.org/download 下载得到.

PHP-FPM其实是PHP源代码的一个补丁，旨在将FastCGI进程管理整合进PHP包中。必须将它patch到你的PHP源代码中，在编译安装PHP后才可以使用。

新版PHP已经集成php-fpm了，不再是第三方的包了，推荐使用。PHP-FPM提供了更好的PHP进程管理方式，可以有效控制内存和进程、可以平滑重载PHP配置，比spawn-fcgi具有更多有点，所以被PHP官方收录了。在./configure的时候带 –enable-fpm参数即可开启PHP-FPM。

新版php-fpm安装(推荐安装方式)
```
wget http://cn2.php.net/distributions/php-5.4.7.tar.gz
tar zvxf php-5.4.7.tar.gz
cd php-5.4.7
./configure --prefix=/usr/local/php --enable-fastcgi --enable-fpm --with-mcrypt --with-zlib --enable-mbstring --disable-pdo --with-curl --disable-debug --enable-pic --disable-rpath --enable-inline-optimization --with-bz2 --with-xml --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --with-mhash --enable-xslt --enable-memcache --enable-zip --with-pcre-regex --with-mysql
make all install
```
旧版手动打补丁php-fpm安装
```
wget http://cn2.php.net/get/php-5.2.17.tar.gz
wget http://php-fpm.org/downloads/php-5.2.17-fpm-0.5.14.diff.gz

tar zvxf php-5.2.17.tar.gz
gzip -cd php-5.2.17-fpm-0.5.14.diff.gz | patch -d php-5.2.17 -p1
cd php-5.2.17
./configure --prefix=/usr/local/php  --enable-fpm --with-mcrypt --enable-mbstring --disable-pdo --with-curl --disable-debug  --disable-rpath --enable-inline-optimization --with-bz2  --with-zlib --enable-sockets --enable-sysvsem --enable-sysvshm --enable-pcntl --enable-mbregex --with-mhash --enable-zip --with-pcre-regex --with-mysql --with-mysqli --with-gd --with-jpeg-dir
make all install
cd /usr/local/php
cp etc/php-fpm.conf.default etc/php-fpm.conf
/usr/local/php/sbin/php-fpm
```
以上两种方式都可以安装php-fpm，安装后内容放在/usr/local/php目录下

二、修改nginx配置文件以支持php-fpm
nginx安装完成后，修改nginx配置文件为,nginx.conf

其中server段增加如下配置，注意标红内容配置，否则会出现No input file specified.错误

#pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
```
location ~ \.php$ {
root html;
fastcgi_pass 127.0.0.1:9000;
fastcgi_index index.php;
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
include fastcgi_params;
}
```


转自：http://www.cnblogs.com/hujiong/archive/2013/02/20/2918509.html 

-----

