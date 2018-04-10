---
title: redis进阶
keywords:
  - redis
  - 集群
tags:
  - 原创
date: 2018-04-10 16:30:13
---
## redis主从（读写分离）
__问题：__
 - redis为单进程程序，只能占用单核，无法充分使用多核的系统资源。
 - 单节点redis在出现故障时则无法继续提供数据存储服务，无法达到高可用要求。
__解决方法：__
 - 增加redis slave节点通过replicas进行master-slave的数据复制，故障时手动恢复。
 - 通过增加sentinel(哨兵)监控redis master-slave节点的存活状态，当master出现故障时自动将slave升级为master继续提供服务。

## data sharding
__问题：__
  单台redis节点的内存总量有限，达到上限后想要扩容除了增加内存别无它法
__解决方法：__
 - redis client (部署多个独立的redis节点，通过在客户端代码中针对key进行hash，然后将数据按hash映射存储到不同的redis中)
 - Twemproxy (部署多个独立的redis节点，通过引入twitter开源中间件封装key的hash操作，最终将数据存储到不同的redis中)

## redis cluster
__问题：__
  单台redis节点的内存容量有限，达到上限后想要扩容除了增加内存别无它法
__解决方法：__
 - 将所有的redis节点的内存总容量划分为n个哈希槽(hash slot)(默认为16384个)，每一个redis节点负责一段solt，存取数据时通过CRC16算法对key进行取余来决定应该从哪一个redis节点进行存取操作。
   redis节点两两连接共同形成一个集群，客户端代码连接集群中任意节点进行存取服务，集群中的节点会通过CRC16算法来将存取请求转发到目标redis节点完成数据的存取。
