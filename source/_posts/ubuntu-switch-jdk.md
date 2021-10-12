---
title: Ubuntu下切换jdk版本
tags:
  - 原创
keywords:
  - update-alternatives

date: 2021-10-12 18:57:13
---

## 安装新版本jdk和切换

```bash
wujianjun@wujianjun-work:~$ update-alternatives --install /usr/bin/java java /opt/jdk1.8.0_111/bin/java 300
wujianjun@wujianjun-work:~$ update-alternatives --config java
```

## 在profile上修改JAVA_HOME的指向目录

profile文件在两处, `/etc/profile`和`~/.profile`

```
export JAVA_HOME=/opt/jdk1.8.0_111
export PATH=$JAVA_HOME/bin:$PATH
```

-----

*观点仅代表自己，期待你的留言。*
