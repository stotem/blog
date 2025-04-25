---
title: podman-compose系列之ELK搭建
tags:
  - 原创
  - podman
keywords:
  - docker
  - elk搭建
date: 2024-04-11 11:18:48
---

## ELK介绍
E: 指elasticsearch用于数据落盘存储。
L: 指logstash用于聚合接收日志并将数据存入elasticsearch。
K: 指kibana，用于界面展示和查询。

## docker-compose增加elasticsearch、logstash和kibana三大组件
```docker-compose.yml
version: '3.9'
networks:
  component: {}
services:
  elasticsearch:
    image: bitnami/elasticsearch:latest
    container_name: elasticsearch
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
    env_file:
      - ./environment/elasticsearch.env
    networks:
      - component
    ports:
      - 9200:9200
      - 9300:9300
    volumes:
      - ./elasticsearch/data:/bitnami/elasticsearch/data
      - ./elasticsearch/plugins:/bitnami/elasticsearch/plugins
  kibana:
    image: bitnami/kibana:latest
    container_name: kibana
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
    env_file:
      - ./environment/kibana.env
    networks:
      - component
    extra_hosts:
      - "elasticsearch:192.168.1.1"
    ports:
      - 5601:5601
  logstash:
    image: bitnami/logstash:latest
    container_name: logstash
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
    env_file:
      - ./environment/logstash.env
    networks:
      - component
    ports:
      - 10000:10000
      - 10001:10001
      - 10002:10002
      - 9600:9600
    volumes:
      - ./logstash/pipeline/:/opt/bitnami/logstash/pipeline/
      - ./logstash/data/:/opt/bitnami/logstash/data/
```

`注意：`将elasticsearch、environment、logstash三个目录设置为1001。(chown -R 1001:1001 elasticsearch environment logstash)

## 三大组件环境变量设置

./environment/elasticsearch.env
```
TZ=Asia/Shanghai
discovery.type=single-node
ELASTICSEARCH_ENABLE_REST_TLS=false
ES_JAVA_OPTS=-Xms512m -Xmx512m
```
./environment/kibana.env
```

```
./environment/logstash.env
```
TZ=Asia/Shanghai
```

## logstash采集配置

./logstash/config/logstash.yml指定pipeline配置文件目录
```
path.config: /usr/share/logstash/pipeline
```

./logstash/pipeline/logstash.conf 配置采集规则
```
input {
  tcp {
    mode => "server"
    host => "0.0.0.0"
    port => 1000
    tags => ["prod"]
    codec => json_lines
  }
  tcp {
    mode => "server"
    host => "0.0.0.0"
    port => 1001
    tags => ["dev"]
    codec => json_lines
  }
  tcp {
    mode => "server"
    host => "0.0.0.0"
    port => 1002
    tags => ["test"]
    codec => json_lines
  }
}

output {
  if "prod" in [tags] {
    elasticsearch {
        hosts  => ["http://host.containers.internal:9200"]
        index  => "logstash-prod"
        codec  => "json"
    }
  } else if "dev" in [tags] {
    elasticsearch {
        hosts  => ["http://host.containers.internal:9200"]
        index  => "logstash-dev"
        codec  => "json"
    }
  } else if "test" in [tags] {
    elasticsearch {
        hosts  => ["http://host.containers.internal:9200"]
        index  => "logstash-test"
        codec  => "json"
    }
  }

  stdout {
    codec => rubydebug
  }
}
```

## 访问地址

kibana ==> http://localhost:5601

elasticsearch ==> http://localhost:9200

## SpringBoot通过logstash-logback-encoder发送日志数据到logstash
pom.xml增加logstash-logback-encoder依赖
```
<dependency>
    <groupId>net.logstash.logback</groupId>
    <artifactId>logstash-logback-encoder</artifactId>
    <version>7.2</version>
</dependency>
```

logback-spring.xml增加appender和logger (以控制台输出info及以上级别日志，logstash收集error级别日志为例)
```
<appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
    <!--logstash的服务地址和端口，可以实际情况设置-->
    <destination>host-logstash.com:1000</destination>
    <!-- 日志级别过滤 -->
    <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
        <level>ERROR</level>
    </filter>
    <!-- 日志输出编码 -->
    <encoder charset="UTF-8" class="net.logstash.logback.encoder.LogstashEncoder">
        <includeMdc>false</includeMdc>
        <includeContext>false</includeContext>
        <provider class="net.logstash.logback.composite.loggingevent.LoggingEventPatternJsonProvider">
            <pattern>
                {"app":"${APP_NAME}","level":"%level","traceId":"%X{X-Request-Id}","position":"%logger:%L","message":"%msg"}
            </pattern>
        </provider>
    </encoder>
</appender>

<appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
    <filter class="ch.qos.logback.classic.filter.ThresholdFilter">
        <level>INFO</level>
    </filter>
    <encoder>
        <pattern>[%d{yyyy-MM-dd HH:mm:ss:SSS}][%thread][%logger:%L][%level][%X{X-Request-Id}] - %msg%n</pattern>
        <charset class="java.nio.charset.Charset">UTF-8</charset>
    </encoder>
</appender>

<root level="DEBUG">
    <appender-ref ref="STDOUT" />
    <appender-ref ref="LOGSTASH" />
</root>
```

-----

*观点仅代表自己，期待你的留言。*
