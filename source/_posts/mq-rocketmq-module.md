---
title: RocketMQ各组件特性和HA集群方案
tags:
  - 转载
keywords:
  - Apache RocketMQ 组件
date: 2018-04-04 16:58:58
toc: true
list_number: false
---
## 一、简介

- RocketMQ是一款分布式、队列模型的消息中间件，具有以下特点：

- 能够保证严格的消息顺序

- 提供丰富的消息拉取模式

- 高效的订阅者水平扩展能力

- 实时的消息订阅机制

- 亿级消息堆积能力

## 二、组件特性
### 1. nameserver
相对来说，nameserver的稳定性非常高。原因有二：

+ nameserver互相独立，彼此没有通信关系，单台nameserver挂掉，不影响其他nameserver，即使全部挂掉，也不影响业务系统使用。

+ nameserver不会有频繁的读写，所以性能开销非常小，稳定性很高。

### 2. broker
__与nameserver关系__
__连接:__

单个broker和所有nameserver保持长连接

__心跳:__

心跳间隔：每隔30秒（此时间无法更改）向所有nameserver发送心跳，心跳包含了自身的topic配置信息。

心跳超时：nameserver每隔10秒钟（此时间无法更改），扫描所有还存活的broker连接，若某个连接2分钟内（当前时间与最后更新时间差值超过2分钟，此时间无法更改）没有发送心跳数据，则断开连接。

__断开:__

时机：broker挂掉；心跳超时导致nameserver主动关闭连接

动作：一旦连接断开，nameserver会立即感知，更新topc与队列的对应关系，但不会通知生产者和消费者

__负载均衡:__
1. 一个topic分布在多个broker上，一个broker可以配置多个topic，它们是多对多的关系。

2. 如果某个topic消息量很大，应该给它多配置几个队列，并且尽量多分布在不同broker上，减轻某个broker的压力。

3. topic消息量都比较均匀的情况下，如果某个broker上的队列越多，则该broker压力越大。

__可用性:__
   由于消息分布在各个broker上，一旦某个broker宕机，则该broker上的消息读写都会受到影响。所以rocketmq提供了master/slave的结构，salve定时从master同步数据，如果master宕机，则slave提供消费服务，但是不能写入消息，此过程对应用透明，由rocketmq内部解决。

这里有两个关键点：

1. 一旦某个broker master宕机，生产者和消费者多久才能发现？受限于rocketmq的网络连接机制，默认情况下，最多需要30秒，但这个时间可由应用设定参数来缩短时间。这个时间段内，发往该broker的消息都是失败的，而且该broker的消息无法消费，因为此时消费者不知道该broker已经挂掉。

2. 消费者得到master宕机通知后，转向slave消费，但是slave不能保证master的消息100%都同步过来了，因此会有少量的消息丢失。但是消息最终不会丢的，一旦master恢复，未同步过去的消息会被消费掉。

__可靠性:__
1. 所有发往broker的消息，有同步刷盘和异步刷盘机制，总的来说，可靠性非常高

2. 同步刷盘时，消息写入物理文件才会返回成功，因此非常可靠

3. 异步刷盘时，只有机器宕机，才会产生消息丢失，broker挂掉可能会发生，但是机器宕机崩溃是很少发生的，除非突然断电

__消息清理:__
+ 扫描间隔

默认10秒，由broker配置参数cleanResourceInterval决定

+ 空间阈值

物理文件不能无限制的一直存储在磁盘，当磁盘空间达到阈值时，不再接受消息，broker打印出日志，消息发送失败，阈值为固定值85%

+ 清理时机

默认每天凌晨4点，由broker配置参数deleteWhen决定；或者磁盘空间达到阈值

+ 文件保留时长

默认72小时，由broker配置参数fileReservedTime决定

__读写性能:__
1. 文件内存映射方式操作文件，避免read/write系统调用和实时文件读写，性能非常高

2. 永远一个文件在写，其他文件在读

3. 顺序写，随机读

4. 利用linux的sendfile机制，将消息内容直接输出到sokect管道，避免系统调用

__系统特性:__
1. 大内存，内存越大性能越高，否则系统swap会成为性能瓶颈

2. IO密集

3. cpu load高，使用率低，因为cpu占用后，大部分时间在IO WAIT

4. 磁盘可靠性要求高，为了兼顾安全和性能，采用RAID10阵列

5. 磁盘读取速度要求快，要求高转速大容量磁盘

### 3. 消费者
__与nameserver关系__
__连接:__

单个消费者和一台nameserver保持长连接，定时查询topic配置信息，如果该nameserver挂掉，消费者会自动连接下一个nameserver，直到有可用连接为止，并能自动重连。

__心跳:__

与nameserver没有心跳

__轮询时间:__

默认情况下，消费者每隔30秒从nameserver获取所有topic的最新队列情况，这意味着某个broker如果宕机，客户端最多要30秒才能感知。该时间由DefaultMQPushConsumer的pollNameServerInteval参数决定，可手动配置。

__与broker关系__

__连接:__

单个消费者和该消费者关联的所有broker保持长连接。

__心跳:__

默认情况下，消费者每隔30秒向所有broker发送心跳，该时间由DefaultMQPushConsumer的heartbeatBrokerInterval参数决定，可手动配置。broker每隔10秒钟（此时间无法更改），扫描所有还存活的连接，若某个连接2分钟内（当前时间与最后更新时间差值超过2分钟，此时间无法更改）没有发送心跳数据，则关闭连接，并向该消费者分组的所有消费者发出通知，分组内消费者重新分配队列继续消费

__断开:__

时机：消费者挂掉；心跳超时导致broker主动关闭连接

动作：一旦连接断开，broker会立即感知到，并向该消费者分组的所有消费者发出通知，分组内消费者重新分配队列继续消费

__负载均衡:__
集群消费模式下，一个消费者集群多台机器共同消费一个topic的多个队列，一个队列只会被一个消费者消费。如果某个消费者挂掉，分组内其它消费者会接替挂掉的消费者继续消费。

__消费机制:__

+ 本地队列
消费者不间断的从broker拉取消息，消息拉取到本地队列，然后本地消费线程消费本地消息队列，只是一个异步过程，拉取线程不会等待本地消费线程，这种模式实时性非常高。对消费者对本地队列有一个保护，因此本地消息队列不能无限大，否则可能会占用大量内存，本地队列大小由DefaultMQPushConsumer的pullThresholdForQueue属性控制，默认1000，可手动设置。

+ 轮询间隔

消息拉取线程每隔多久拉取一次？间隔时间由DefaultMQPushConsumer的pullInterval属性控制，默认为0，可手动设置。

+ 消息消费数量

监听器每次接受本地队列的消息是多少条？这个参数由DefaultMQPushConsumer的consumeMessageBatchMaxSize属性控制，默认为1，可手动设置。

__消费进度存储:__
每隔一段时间将各个队列的消费进度存储到对应的broker上，该时间由DefaultMQPushConsumer的persistConsumerOffsetInterval属性控制，默认为5秒，可手动设置。

如果一个topic在某broker上有3个队列，一个消费者消费这3个队列，那么该消费者和这个broker有几个连接？
一个连接，消费单位与队列相关，消费连接只跟broker相关，事实上，消费者将所有队列的消息拉取任务放到本地的队列，挨个拉取，拉取完毕后，又将拉取任务放到队尾，然后执行下一个拉取任务

### 4. 生产者
__与nameserver关系__
__连接:__

单个生产者者和一台nameserver保持长连接，定时查询topic配置信息，如果该nameserver挂掉，生产者会自动连接下一个nameserver，直到有可用连接为止，并能自动重连。

__轮询时间:__

默认情况下，生产者每隔30秒从nameserver获取所有topic的最新队列情况，这意味着某个broker如果宕机，生产者最多要30秒才能感知，在此期间，发往该broker的消息发送失败。该时间由DefaultMQProducer的pollNameServerInteval参数决定，可手动配置。

__心跳:__

与nameserver没有心跳

__与broker关系__
__连接:__

单个生产者和该生产者关联的所有broker保持长连接。

__心跳:__

默认情况下，生产者每隔30秒向所有broker发送心跳，该时间由DefaultMQProducer的heartbeatBrokerInterval参数决定，可手动配置。broker每隔10秒钟（此时间无法更改），扫描所有还存活的连接，若某个连接2分钟内（当前时间与最后更新时间差值超过2分钟，此时间无法更改）没有发送心跳数据，则关闭连接。

__连接断开:__

移除broker上的生产者信息

__负载均衡:__
生产者时间没有关系，每个生产者向队列轮流发送消息

## 三、集群方案
1. 单个 Master
   这种方式风险较大，一旦Broker 重启或者宕机时，会导致整个服务不可用，不建议线上环境使用。

2. 多 Master 模式
   一个集群无 Slave，全是 Master，例如 2 个 Master 或者 3 个 Master

   优点：配置简单，单个Master 宕机或重启维护对应用无影响，在磁盘配置为 RAID10 时，即使机器宕机不可恢复情况下，由与 RAID10 磁盘非常可靠，消息也不会丢（异步刷盘丢失少量消息，同步刷盘一条不丢）。性能最高。

   缺点：单台机器宕机期间，这台机器上未被消费的消息在机器恢复之前不可订阅，消息实时性会受到受到影响。

_先启动 NameServer，例如机器 IP 为：172.16.8.106:9876_

```
nohup sh mqnamesrv &
```
   _在机器 A，启动第一个 Master_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-noslave/broker-a.properties &
```
   _在机器 B，启动第二个 Master_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-noslave/broker-b.properties &
```
3. 多 Master 多 Slave 模式，异步复制
   每个 Master 配置一个 Slave，有多对Master-Slave，HA 采用异步复制方式，主备有短暂消息延迟，毫秒级。

   优点：即使磁盘损坏，消息丢失的非常少，且消息实时性不会受影响，因为 Master 宕机后，消费者仍然可以从 Slave 消费，此过程对应用透明。不需要人工干预。性能同多 Master 模式几乎一样。

   缺点：Master 宕机，磁盘损坏情况，会丢失少量消息。


_先启动 NameServer，例如机器 IP 为：172.16.8.106:9876_

```
nohup sh mqnamesrv &
```
   _在机器 A，启动第一个 Master_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-2s-async/broker-a.properties &
```
   _在机器 B，启动第二个 Master_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-2s-async/broker-b.properties &
```
   _在机器 C，启动第一个 Slave_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-2s-async/broker-a-s.properties &
```
   _在机器 D，启动第二个 Slave_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-2s-async/broker-b-s.properties &
```
4. 多 Master 多 Slave 模式，同步双写
   每个 Master 配置一个 Slave，有多对Master-Slave，HA 采用同步双写方式，主备都写成功，向应用返回成功。

   优点：数据与服务都无单点，Master宕机情况下，消息无延迟，服务可用性与数据可用性都非常高

   缺点：性能比异步复制模式略低，大约低 10%左右，发送单个消息的 RT 会略高。目前主宕机后，备机不能自动切换为主机，后续会支持自动切换功能。


_先启动 NameServer，例如机器 IP 为：172.16.8.106:9876_

```
nohup sh mqnamesrv &
```
   _在机器 A，启动第一个 Master_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-a.properties &
```
   _在机器 B，启动第二个 Master_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-b.properties &
```
   _在机器 C，启动第一个 Slave_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-a-s.properties &
```
   _在机器 D，启动第二个 Slave_

```
nohup sh mqbroker -n 172.16.8.106:9876 -c $ROCKETMQ_HOME/conf/2m-2s-sync/broker-b-s.properties &
```
   以上 Broker 与 Slave 配对是通过指定相同的brokerName 参数来配对，Master 的 BrokerId 必须是 0，Slave的BrokerId 必须是大与 0 的数。另外一个 Master 下面可以挂载多个 Slave，同一 Master 下的多个 Slave 通过指定不同的 BrokerId 来区分。

-----
_转自:https://www.cnblogs.com/xiaodf/p/5075167.html_

*观点仅代表自己，期待你的留言。*
