---
title: Redis实现分布式锁和分布式队列
keywords:
  - Redis
  - 分布式锁
  - 分布式队列
tags:
  - 原创
  - Redis
date: 2016-05-31 11:56:20
---

## 分布式锁
通过Redis做分布式系统的共享内存实现方案中，可以实现分布式锁的功能。实现方法就是用 SET NX 命令设置一个设定了存活周期 TTL 的 Key 来获取锁，通过删除 Key 来释放锁，通过存活周期来保证避免死锁。
如：`SET resource_name my_random_value NX PX 30000`

 _注：_

--------------
`SET key value [EX seconds] [PX milliseconds] [NX|XX]`
从2.6.12版本开始，redis为SET命令增加了一系列选项:
* EX seconds – Set the specified expire time, in seconds.
* PX milliseconds – Set the specified expire time, in milliseconds.
* NX – Only set the key if it does not already exist.
* XX – Only set the key if it already exist.
* EX seconds – 设置键key的过期时间，单位时秒
* PX milliseconds – 设置键key的过期时间，单位时毫秒
* NX – 只有键key不存在的时候才会设置key的值
* XX – 只有键key存在的时候才会设置key的值


但，以上简单方案存在一个单点故障的风险。在master/slave环境下，当：
1. 客户端A获取到锁.
2. master节点在将 key 复制到 slave 节点之前崩溃了
3. 此时，slave节点被提升为master节点.
4. 客户端 B 从新的 master 节点获得了锁(而这个锁实际上已经由客户端 A 所持有)，导致了系统中有两个客户端在同一时间段内持有同一个互斥锁，破坏了互斥锁的安全性。

__解决方法：__需要解决以上问题，需要在进行锁设值时将惟一标识系统的ID做为value一同存储到Redis中，在完成所有的操作后，进行解锁时取出Redis内存储的value进行比对，
如果锁key对应的value还是当前系统的ID,那么表示当前锁目前只被当前系统所持有，反之，则表示锁被其它的系统抢占，那么需要回滚所有的操作。

如：

|客户端A（ID为SYSA）								|Redis 																		| 客户端B（ID为SYSB）
|--------------------------------------------------------------------------------------------------------------------------------------------------------
| 获取到锁（SET dist_lock SYSA NX PX 30000)		| 																			|
| 进行其它的业务操作。。。							| master发生故障，slave被提升为NewMaster(未将master中dist_lock复制到NewMaster) 	|
| 												| 																			| 获取到锁（SET dist_lock SYSB NX PX 30000）
| 解锁 (get dist_lock，对value进行判定，为SYSA则执行解锁，否则回滚业务)|															|
| 												|																			| 解锁 (get dist_lock，对value进行判定，为SYSB则执行解锁，否则回滚业务)


## 分布式队列
Redis实现分布式队列主要实现是通过`有序集合`实现，通过ZADD向集合内添加元素，同时添加多个元素时为事务处理（不存在部分成功部分失败的情况）

 _注：_

------
`ZADD key [NX|XX] [CH] [INCR] score member [score member ...]`
从3.0.2版本开始，增加以下选项：
* XX: Only update elements that already exist. Never add elements.
* NX: Don’t update already existing elements. Always add new elements.
* CH: Modify the return value from the number of new elements added, to the total number of elements changed (CH is an abbreviation of changed). Changed elements are new elements added and elements already existing for which the score was updated. So elements specified in the command line having the same score as they had in the past are not counted. Note: normally the return value of ZADD only counts the number of new elements added.
* INCR: When this option is specified ZADD acts like ZINCRBY. Only one score-element pair can be specified in this mode.


## 另外的选择
_Java库：_其实也在使用[redisson](https://github.com/mrniko/redisson)来实现分布式锁。它封装了针对Redis各种操作的分布式实现。

其它语言可参照官网文章: http://redis.io/topics/distlock?cm_mc_uid=77610277652214581184982&cm_mc_sid_50200000=1464593765 

-----

*观点仅代表自己，期待你的留言。*