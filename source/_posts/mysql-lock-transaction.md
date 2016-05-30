---
title: 关于MariaDB事务阻塞等待及锁的实验笔记
keywords:
  - 事务阻塞等待
  - MariaDB
  - InnoDB存储引擎
tags:
  - 原创
date: 2016-05-30 18:00:50
---

## 实验环境
Server Version: 10.0.24-MariaDB
SET GLOBAL tx_isolation='REPEATABLE-READ';
SET SESSION tx_isolation='REPEATABLE-READ';
SET @@autocommit=0;

SHOW VARIABLES like 'autocommit';
SELECT @@GLOBAL.tx_isolation, @@tx_isolation;

## 实验结论
### 幻读的概念是另一事务先完成的情况下判断

|事务A     											|    事务B
|------------------------------------------------------------------------------------------------------------
| start TRANSACTION;								| 
| select * from t1;(查询出2条数据)	                | 
|               									| start TRANSACTION;
|               									| insert into t1 values(null,'v222');
| select * from t1;(查询出2条数据)	                |
|               									| commit;(__这一步很关键，它标识了事务B的完成__)
| select * from t1;(查询出3条数据)	                |

`InnoDB存储引擎在REPEATABLE-READ的隔离级别下解决了幻读情况，所以会造成以上的情况。`

### 并发事务修改同一行数据时，后执行更新的事务会__阻塞等待__先执行更新事务先结束（rollback或commit）或者超时

|事务A     											|    事务B
|------------------------------------------------------------------------------------------------------------
| start TRANSACTION;								| start TRANSACTION;
| update t1 SET da='v1111' where id=1;              |
|               									| update t1 SET da='v1111' where id=1;(此时会等待事务A执行完成 OR 等待超时)

### 并发事务更新时只要被更新的数据存在交集，那么就会存在__阻塞等待__另一事务完成的现象

|事务A     											|    事务B
|------------------------------------------------------------------------------------------------------------
| start TRANSACTION;								| 
| select * from t1;(查询出2条数据)	                | 
|               									| start TRANSACTION;
|               									| insert into t1 values(null,'v222');
| update t1 set da='updated'(此时会等事务B的完成)		|
|               									| commit;


### 并发事务更新时只要存在全表扫描(不管数据存在不存在交集)，那么就会存在__阻塞等待__另一事务完成的现象

|事务A     																	|    事务B
|------------------------------------------------------------------------------------------------------------
| start TRANSACTION;														| 
| select * from t1;(查询出2条数据)	                						| 
|               															| start TRANSACTION;
|               															| update t1 SET da='v1113333331' where id=1
| update t1 set da='updated' where da like '%0000%'(此时会等事务B的完成)		|
|               															| commit;


-----

*观点仅代表自己，期待你的留言。*