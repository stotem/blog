---
title: Let's Encrypt 免费SSL
tags:
  - 原创
  - Let's Encrypt
date: 2025-04-25 11:45:07
---

## 安装与申请

```
安装命令客户端
root@instance:~# apt install certbot
申请域名证书（使用dns验证域名拥有者），证书文件保存在/etc/letsencrypt/live目录下
root@instance:~# certbot certonly -d *.mydomain.com -d mydomain.com --manual --preferred-challenges dns
查看已申请的证书信息
root@instance:~# certbot certificates
```

## 续期

```
手动续期
root@instance:~# certbot certonly -d *.mydomain.com -d mydomain.com --manual --preferred-challenges dns
自动续期（dns验证域名拥有者需要使用hook脚本调用域名服务商api更新dns值）
root@instance:~# certbot renew
```

-----

*观点仅代表自己，期待你的留言。*
