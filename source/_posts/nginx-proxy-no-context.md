---
title: nginx反向代理无contextPath的应用
tags:
  - 原创
  - Nginx
date: 2024-06-21 14:01:23
---

## 简介
matabase部署之后没有contextPath，比如源访问地址为：http://10.84.102.92:3000/

## nginx代理配置增加location

```
location /metabase/ {
    proxy_pass http://10.84.102.92:3000/; # metabase
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header   X-Forwarded-Host $host;
    proxy_redirect     ~^/(.*)$ /metabase/$1;
}
```

则可通过http://a.c.com/metabase来进行访问了

-----

*观点仅代表自己，期待你的留言。*
