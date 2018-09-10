---
title: Linux常用命令备注（nslookup,find,grep,sed,awk）
tags:
  - 原创
keywords:
  - nslookup
  - find
  - grep
  - sed
  - awk

date: 2018-09-10 15:09:20
---

## nslookup 指定DNS服务器解析
```
wujianjun@smzc ~ $ nslookup m.vvip-u.com 10.28.17.101
Server:		10.28.17.101
Address:	10.28.17.101#53

Name:	m.vvip-u.com
Address: 10.28.17.80

wujianjun@smzc ~ $ nslookup m.vvip-u.com
Server:		127.0.1.1
Address:	127.0.1.1#53

Non-authoritative answer:
Name:	m.vvip-u.com
Address: 120.77.124.39
```
## BIND 局域网DNS程序

https://www.isc.org/downloads/bind/

## find包含某关键字的文件内容
```
wujianjun@smzc ~ $ find /smapp/logs -name “*” | xargs grep “keywords”
```

```
wujianjun@smzc ~ $ grep -nR "keywords" /smapp/logs
```

grep + RegExp (提取行首不是abc的行)
```
wujianjun@smzc ~ $ grep “^[^abc]” /smapp/logs
```

## 文本替换
```
wujianjun@smzc ~ $ sed -n ‘s/oldk/newk/g’ file
```

先删除1到3行，然后用bb替换aa；
```
wujianjun@smzc ~ $ sed -e ’1,3d’ -e ‘s/aa/bb/g’ file
```

## 文本处理
打印所有内容行(相当于cat)
```
wujianjun@smzc ~ $ awk '{print $0}' result.txt
18100000011 - "status":"SUCCESS"
18100000012 - "status":"SUCCESS"
18100000013 - "status":"SUCCESS"
18100000014 - "status":"SUCCESS"
```

按`空格`分隔逐行内容并打印第一个内容
```
wujianjun@smzc ~ $ awk '{print $1}' result.txt
18100000011
18100000012
18100000013
18100000014
```

-----

*观点仅代表自己，期待你的留言。*
