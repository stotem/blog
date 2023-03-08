---
title: MySQL备份与恢复
tags:
  - MySQL
keywords:
  - mysqldump
  - mysql备份
  - mysql恢复
date: 2023-03-01 11:42:20
---

## MySQL备份

方案一：将mysql整个数据目录备份,默认在/var/lib/mysql下，可通过my.conf指定
方案二：通过mysqldump命名备份成sql

### 通过mysqldump备份成sql

```bash
wujianjun@wujianjun-work:~$ mysqldump -uroot -p --default-character-set=utf8 --set-charset=false --hex-blob --databases db_basic db_boss --result-file=service_module_db_init.sql
```

ps: 如果需要替换则可通过sed正则替换

```bash
wujianjun@wujianjun-work:~$ sed -i "s/原内容/新内容/g" service_module_db_init.sql
wujianjun@wujianjun-work:~$ find . -type f -name "app" -exec sh {} restart \; #批量执行shell
```

### 通过mysql命令恢复备份文件
```bash
wujianjun@wujianjun-work:~$ mysql -uroot -p --default-character-set=utf8 < service_module_db_init.sql
```

## 忘记MySQL的root密码后修改密码

```
wujianjun@wujianjun-work:~$ service mysql stop
wujianjun@wujianjun-work:~$ mysqld --console --skip-grant-tables --shared-memory
wujianjun@wujianjun-work:~$ mysql -u root -p
mysql> use mysql;
mysql> ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '新密码';
mysql> flush privileges;
mysql> exit
wujianjun@wujianjun-work:~$ service mysql start
```

-----

*观点仅代表自己，期待你的留言。*
