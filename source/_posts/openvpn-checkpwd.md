---
title: OpenVPN系列三之账号密码认证
tags:
  - 原创
  - OpenVPN
keywords:
  - 账号密码认证

date: 2022-08-04 14:53:36
---

## 背景
基于vpn的敏感性及人员的流动性，要进一步加强访问的安全性。OpenVPN支持配置账号密码认证。

## OpenVPN服务端配置修改
1. 增加验证配置
```
root@wujianjun-work:~# vi /etc/openvpn/server/server.conf
```
在配置文件末尾增加
```
script-security 3
auth-user-pass-verify checkpsw.sh via-env
username-as-common-name
client-cert-not-required
```

2. 增加账号验证脚本
```
root@wujianjun-work:~# vi /etc/openvpn/server/checkpsw.sh
```
内容如下：
```
#!/bin/sh
###########################################################
# checkpsw.sh (C) 2004 Mathias Sundman <mathias@open***.se>
#
# This script will authenticate Open××× users against
# a plain text file. The passfile should simply contain
# one row per user with the username first followed by
# one or more space(s) or tab(s) and then the password.

PASSFILE="/etc/openvpn/server/psw-file"
LOG_FILE="/var/log/openvpn/openvpn-password.log"
TIME_STAMP=`date "+%Y-%m-%d %T"`

###########################################################

if [ ! -r "${PASSFILE}" ]; then
  echo "${TIME_STAMP}: Could not open password file \"${PASSFILE}\" for reading." >> ${LOG_FILE}
  exit 1
fi

CORRECT_PASSWORD=`awk '!/^;/&&!/^#/&&$1=="'${username}'"{print $2;exit}' ${PASSFILE}`

if [ "${CORRECT_PASSWORD}" = "" ]; then
  echo "${TIME_STAMP}: User does not exist: username=\"${username}\", password=\"${password}\"." >> ${LOG_FILE}
  exit 1
fi

echo "${password}--${CORRECT_PASSWORD}" >> ${LOG_FILE}

if [ "${password}" = "${CORRECT_PASSWORD}" ]; then
  echo "${TIME_STAMP}: Successful authentication: username=\"${username}\"." >> ${LOG_FILE}
  exit 0
fi

echo "${TIME_STAMP}: Incorrect password: username=\"${username}\", password=\"${password}\"." >> ${LOG_FILE}
exit 1
```
3. 增加账号配置
```
root@wujianjun-work:~# vi /etc/openvpn/server/checkpsw.sh
```
内容如下：
```
#account password
test 123
```

4. 重启服务
```
root@wujianjun-work:~# sudo systemctl restart openvpn-server@server.service
```

客户机再次尝试连接vpn时则会提示输入认证账号

-----

*观点仅代表自己，期待你的留言。*
