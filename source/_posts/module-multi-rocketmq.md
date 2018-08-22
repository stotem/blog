---
title: 同一微服务连接多套RocketMQ集群
tags:
  - 原创
  - rocketmq
date: 2018-08-22 11:11:03
---

## 需要实现的通讯消息架构
![通讯消息连接架构](/images/multi-rocketmq-1.png)
## 分析
`注`:　以下分析均在rocketmq4.0.0-incubating源码上进行

org.apache.rocketmq.client.impl.producer.DefaultMQProducerImpl#start(boolean)
```java
public void start(final boolean startFactory) throws MQClientException {
    switch (this.serviceState) {
        case CREATE_JUST:
            this.serviceState = ServiceState.START_FAILED;

            this.checkConfig();

            if (!this.defaultMQProducer.getProducerGroup().equals(MixAll.CLIENT_INNER_PRODUCER_GROUP)) {
                this.defaultMQProducer.changeInstanceNameToPID();
            }

            this.mQClientFactory = MQClientManager.getInstance().getAndCreateMQClientInstance(this.defaultMQProducer, rpcHook);
            // 从上一句可以看出：MQClientManager为Producer连接管理器，用户管理连接ＭQ的TCP客户端的连接

            boolean registerOK = mQClientFactory.registerProducer(this.defaultMQProducer.getProducerGroup(), this);
            if (!registerOK) {
                this.serviceState = ServiceState.CREATE_JUST;
                throw new MQClientException("The producer group[" + this.defaultMQProducer.getProducerGroup()
                    + "] has been created before, specify another name please." + FAQUrl.suggestTodo(FAQUrl.GROUP_NAME_DUPLICATE_URL),
                    null);
            }

            this.topicPublishInfoTable.put(this.defaultMQProducer.getCreateTopicKey(), new TopicPublishInfo());

            if (startFactory) {
                mQClientFactory.start();
            }

            log.info("the producer [{}] start OK. sendMessageWithVIPChannel={}", this.defaultMQProducer.getProducerGroup(),
                this.defaultMQProducer.isSendMessageWithVIPChannel());
            this.serviceState = ServiceState.RUNNING;
            break;
        case RUNNING:
        case START_FAILED:
        case SHUTDOWN_ALREADY:
            throw new MQClientException("The producer service state not OK, maybe started once, "//
                + this.serviceState//
                + FAQUrl.suggestTodo(FAQUrl.CLIENT_SERVICE_NOT_OK),
                null);
        default:
            break;
    }

    this.mQClientFactory.sendHeartbeatToAllBrokerWithLock();
}
```

org.apache.rocketmq.client.impl.MQClientManager#getAndCreateMQClientInstance(org.apache.rocketmq.client.ClientConfig, org.apache.rocketmq.remoting.RPCHook)
```java
public MQClientInstance getAndCreateMQClientInstance(final ClientConfig clientConfig, RPCHook rpcHook) {
    String clientId = clientConfig.buildMQClientId();
    MQClientInstance instance = this.factoryTable.get(clientId);
    //　从上一句可以看出：找到对应的客户端通讯实例是通过一个clientId在factoryTable内存缓存中进行查询的

    if (null == instance) {
        instance =
            new MQClientInstance(clientConfig.cloneClientConfig(),
                this.factoryIndexGenerator.getAndIncrement(), clientId, rpcHook);
        MQClientInstance prev = this.factoryTable.putIfAbsent(clientId, instance);
        if (prev != null) {
            instance = prev;
            log.warn("Returned Previous MQClientInstance for clientId:[{}]", clientId);
        } else {
            log.info("Created new MQClientInstance for clientId:[{}]", clientId);
        }
    }

    return instance;
}
```

org.apache.rocketmq.client.ClientConfig#buildMQClientId
```java
public String buildMQClientId() {
    StringBuilder sb = new StringBuilder();
    sb.append(this.getClientIP());

    sb.append("@");
    sb.append(this.getInstanceName());
    if (!UtilAll.isBlank(this.unitName)) {
        sb.append("@");
        sb.append(this.unitName);
    }

    return sb.toString();
}
//　从以上方法可以看出：这个clientId信息中包含当前微服务的IP，当前模块实例名(默认通过changeInstanceNameToPID更改为进程ID值）和一个unitName
```

`结论`: 经以上源码可以得到一个模块需要连接多个RocketMQ集群，则需要生产多个MQClientInstance，换言之，则需要在获取MQClientInstance时传递不同的ClientID即可。
      由于__ClientID=localIP + instanceName + unitName__，所以只需要创建Producer对象时传入不同的instanceName或unitName值即可。


-----

*观点仅代表自己，期待你的留言。*
