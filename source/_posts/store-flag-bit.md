---
title: 多标识位存储优化方案
tags:
  - 原创
date: 2017-08-24 19:08:28
---

## 背景
在做程序开发的过程中常常会遇到数据的标识位（取值为"是"与"否"）需要进行存储，
如神马专车系统消息中心中的一个场景：新建一个消息需要勾选发送对象，可选的对象有：司机，下单人，乘车人。
最常见的Mysql存储方式为一个消息表中包含三个字段sendDriver,sendUser,sendPassenger
按用户新建消息所勾选的情况，依次存储到数据表中并在后续的业务中直接获取值进行对比。

## 优化方案
利用"与或非"的运算可将这多个标识符存储到一个字段中。
实例如下：
按业务这里有三个标识符需要存储，因此可以定义一个长度为3的二进行序列：000，从左至右第一位表示司机，第二位表示下单人，第三位表示乘车人。
那么，如果只需要发送给司机则可标识为100的二进行序列，如果下单人也需要通知，则可标识为110的二进行序列，依次，如果都需要通知则为111的二进制序列。
存储的值则为二进行制序列对应的十进制即可，当需要判断时，则可采用"与"运算符进行判定。

示例Java代码如下：
```java
public static final byte NOTIFY_PASSENGER = 0B001; //二进制为001
public static final byte NOTIFY_SUBSCRIBER = 0B010; //二进制为010
public static final byte NOTIFY_DRIVER = 0B100; //二进制为100

/**
 * 获取需要存储的值则为notifyFlag
 */
public byte getStoreValue() {
  byte notifyFlag = 0B000; //二进制为000
  if (request.isNotifyDriver()) {
      notifyFlag |= NOTIFY_DRIVER;
  }
  if (request.isNotifyPassenger()) {
      notifyFlag |= NOTIFY_PASSENGER;
  }
  if (request.isNotifySubscriber()) {
    notifyFlag |= NOTIFY_SUBSCRIBER;
  }
  return notifyFlag;
}

/**
 * 判断是否需要通知
 * @param notifyTarget 预计需要通知的目标
 * @return true-需要通知，false-不需要通知
 */
public boolean isNotify(byte notifyTarget) {
  byte notifyFlag = 0B111;//二进制为111 , 从数据库取出
  return notifyFlag & notifyTarget == notifyTarget;
}
```

在Java中byte的最大值为：127，二进行为0B1111111, 足够标识七个标识位!

-----

*观点仅代表自己，期待你的留言。*
