---
title: Redis数据类型特点
tags:
  - 原创
date: 2018-12-25 22:49:58
---

## Redis数据类型特点
1. string：可独立设置expire time。
2. list：特有的LPUSH、RPUSH、LPOP、RPOP、LPOPRPUSH等函数可以无缝的支持生产者、消费者架构模式。
3. hash：基于Hash算法的，对于项的查找时间复杂度是O(1)。
4. set：最大的特点就是集合的计算能力，inter交集、union并集、diff差集，这些特点可以用来做高性能的交叉计算或者剔除数据。SINTERSTORE命令将交集计算后的结果存储在一个目标集合中。
5. zset：在set的基础上提供了排序的功能，可用于多维度算法计算得分后找最佳结果的场景。

由于Redis是Signle-Thread单线程模型，基于这个特性我们就可以使用Redis提供的pipeline管道来提交一连串带有逻辑的命令集合，这些命令在处理期间不会被其他客户端的命令干扰。

-----

*观点仅代表自己，期待你的留言。*
