---
title: nginx日志打印详解
tags:
  - 原创
date: 2020-05-04 10:18:42
---

## 文章内容
```
log_format  access  '$remote_addr - $remote_user [$time_local] [$msec] [$request_time] [$http_host] "$request" '
                          '$status $body_bytes_sent "$request_body" "$http_referer" '
                          '"$http_user_agent" $http_x_forwarded_for';
```

- $remote_addr  客户端IP地址
- $remote_user   客户端用户
- $time_local   访问时间与时区
- $msec   访问时间与时区字符串形式
- $request_time  请求开始到返回时间
- $http_host   请求域名
- $request   请求的url与http协议
- $status    请求状态,如成功200
- $body_bytes_sent    记录发送给客户端文件主体内容大小
- $request_body   访问url时参数
- $http_referer     记录从那个页面链接访问过来的
- $http_user_agent    记录客户浏览器的相关信息
- $http_x_forwarded_for  请求转发过来的地址
- $upstream_response_time  从 Nginx 建立连接 到 接收完数据并关闭连接

-----

*观点仅代表自己，期待你的留言。*
