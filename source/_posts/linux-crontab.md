---
title: Linux定时任务之crontab
tags:
  - 原创
keywords:
  - linux
  - crontab
date: 2021-07-30 12:01:55
---

## Linux定时任务

-  列出当前用户签定的任务： # crontab -l
-  删除当前用户签定的任务： # crontab -r
-  编辑用户个人的计划任务： # crontab -e
```
# m h  dom mon dow   command m:分钟，0-59，每分钟可以用 * 或 */1 表示，每5分钟用 */5 表示 h:小时，0-23 dom:日期，1-31
mon:月份，1-12 dow:星期，0-7，其中0、7都是代表星期天 command:需要执行的命令
```
示例： */30 * * * * echo ‘hello’ 每 30 分钟输出hello
30 * * * *  echo ‘hello’ 每小时的 30 分钟（间隔1小时）输出hello
30 1-3 * * *  echo ‘hello’ 每日 1:00-3:00 之间的 30 分钟（即1:30、2:30、3:30）输出hello
*/30 1-3 * * *  echo ‘hello’ 每日 1:00-3:00 之间每隔 30 分钟输出hello
30 3 * * *  echo ‘hello’ 每日 3:30 输出hello
30 3 1,5,9 * *  echo ‘hello’ 每月1、5、9日 3:30 输出hello
30 3 1,5,9 1 *  echo ‘hello’ 每年1月1、5、9日 3:30 输出hello
30 3 * * 0,6  echo ‘hello’ 每星期六、日 3:30 输出hello

- 编辑系统计划任务： # vi /etc/crontab
```
# m h dom mon dow user  command
m:分钟，0-59，每分钟可以用 * 或 */1 表示，每5分钟用 */5 表示 h:小时，0-23 dom:日期，1-31
mon:月份，1-12 dow:星期，0-7，其中0、7都是代表星期天
user: 指定用户名 command:需要执行的命令
```
示例：
*/10 * * * * root /usr/local/demo.sh
每 10 分钟以 root 身份执行 /usr/local/demo.sh 这个脚本。

- 开启运行日志：#vi /etc/rsyslog.d/50-default.conf && sudo systemctl restart rsyslog.service
```
tail -f /var/log/cron.log
```


-----

*观点仅代表自己，期待你的留言。*
