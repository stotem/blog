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
    image: elasticsearch:latest
    container_name: elasticsearch
    env_file:
      - ./environment/elasticsearch.env
    networks:
      - component
    ports:
      - 9200:9200
      - 9300:9300
    volumes:
      - ./elasticsearch/data:/usr/share/elasticsearch/data
      - ./elasticsearch/plugins:/usr/share/elasticsearch/plugins
  kibana:
    image: kibana:latest
    container_name: kibana
    env_file:
      - ./environment/kibana.env
    networks:
      - component
    extra_hosts:
      - "elasticsearch:10.84.102.92"
    ports:
      - 5601:5601
  logstash:
    image: logstash:latest
    container_name: logstash
    env_file:
      - ./environment/logstash.env
    networks:
      - component
    ports:
      - 5000:5000
      - 5001:5001
      - 5002:5002
      - 9600:9600
    volumes:
      - ./logstash/config/logstash.yml:/etc/logstash/logstash.yml
      - ./logstash/pipeline/:/usr/share/logstash/pipeline/
```

## 三大组件环境变量设置

./environment/elasticsearch.env
```
TZ=Asia/Shanghai
discovery.type=single-node
ES_JAVA_OPTS=-Xms512m -Xmx512m
```
./environment/kibana.env
```
ELASTICSEARCH_HOSTS='["http://host.containers.internal:9200"]'
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

-----

*观点仅代表自己，期待你的留言。*
