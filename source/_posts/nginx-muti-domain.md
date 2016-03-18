---
title: Nginx反射代理不同域名配置
tags:
  - 原创
  - Nginx
date: 2016-03-18 16:43:49
---

## 简介
由于公司内网有多台服务器的http服务要映射到公司外网静态IP，如果用路由的端口映射来做，就只能一台内网服务器的80端口映射到外网80端口，其他服务器的80端口只能映射到外网的非80端口。非80端口的映射在访问的时候要域名加上端口，比较麻烦。所以我们可以在内网搭建个nginx反向代理服务器，将nginx反向代理服务器的80映射到外网IP的80，这样指向到公司外网IP的域名的HTTP请求就会发送到nginx反向代理服务器，利用nginx反向代理将不同域名的请求转发给内网不同机器的端口，就起到了“根据域名自动转发到相应服务器的特定端口”的效果，而路由器的端口映射做到的只是“根据不同端口自动转发到相应服务器的特定端口”，真是喜大普奔啊。

## Nginx配置
vim /usr/local/nginx/conf/reverse-proxy.conf
```
server {
    listen 80;
    server_name tomcat1.vip.com;
    location /{
        proxy_redirect off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:8081;
        #proxy_pass http://tomcat;
    }
    access_log logs/tomcat1_access.log;
}

server {
    listen 80;
    server_name tomcat2.vip.com;
    location /{
        proxy_redirect off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:8082;
        #proxy_pass http://tomcat;
    }
    access_log logs/tomcat2_access.log;
}
```
在nginx.conf的http节点中include配置文件reverse-proxy.conf
```
http {
	include reverse-proxy.conf;
}
```
## 测试生效
热部署nginx配置
```
[root@localhost ~]# /usr/local/nginx/sbin/nginx -t; /usr/local/nginx/sbin/nginx -s reload;
nginx: the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /usr/local/nginx/conf/nginx.conf test is successful
```
在客户机的hosts中配置tomcat1.vip.com和tomcat2.vip.com （如果是已申请好的域名，则可跳过此步骤）
```
10.28.10.218 tomcat1.vip.com
10.28.10.218 tomcat2.vip.com
```
![](/images/QQ20160318-3.png)

从以上访问结果来看，浏览器的请求会分别引导到了tomcat1和tomcat2上。


-----

*观点仅代表自己，期待你的留言。*