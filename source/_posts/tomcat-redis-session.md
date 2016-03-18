---
title: Nginx+tomcat+redis集群之session共享
tags:
  - 原创
  - Nginx
  - tomcat
  - redis
date: 2016-03-17 11:32:15
---
## 实验环境
CentOS7, Tomcat7(tomcat-1, tomcat-2), Nginx1.8.1, redis3.0.7
## 安装redis与tomcat
```
[root@localhost ~]# wget http://download.redis.io/releases/redis-3.0.7.tar.gz
[root@localhost ~]# wget http://mirror.nus.edu.sg/apache/tomcat/tomcat-7/v7.0.68/bin/apache-tomcat-7.0.68.tar.gz
[root@localhost ~]# tar -xvf redis-3.0.7.tar.gz; cd redis-3.0.7
[root@localhost redis-3.0.7]# make && make install
[root@localhost redis-3.0.7]# redis-server & //运行redis服务
[root@localhost ~]# tar -xvf apache-tomcat-7.0.68.tar.gz
[root@localhost ~]# mv apache-tomcat-7.0.68 tomcat-1; cp -r tomcat-1 tomcat-2
```
在tomcat-1和tomcat-2的webapps/ROOT目录下新增一个名叫session.jsp的文件，内容如下：
```
<%@ page  %>
Tomcat1（tomcat-2中为Tomcat2） SessionId = <%=session.getId() %>
```
### 修改tomcat与nginx配置
架设场景如下图：

![架设场景](/images/nginx-tomcat-redis.png)

* 修改tomcat端口(conf/server.xml) 

tomcat1：Server port="8105"，Connector port="8081"，ajp Connector port="8109"

tomcat2：Server port="8205"，Connector port="8082"，ajp Connector port="8209"
* 修改nginx配置，以随机访问的方式将请求引入后端的tomcat集群中
```
http {
    upstream tomcat {
       server 127.0.0.1:8081;
       server 127.0.0.1:8082;
    }
    server {
        listen       80;
        server_name  localhost;
        #charset koi8-r;
        #access_log  logs/host.access.log  main;
        location ~ .*\.(do|jsp|action)?$ {
            proxy_redirect          off;
            proxy_set_header        Host            $host;
            proxy_set_header        X-Real-IP       $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            root   html;
            index  index.html index.htm;
            proxy_pass http://tomcat;
        }
        #配置Nginx动静分离，定义的静态页面直接从Nginx发布目录读取。
        location ~ .*\.(html|htm|gif|jpg|jpeg|bmp|png|ico|txt|js|css)$ {
            root /data/;
            gzip_static on; #开启压缩静态资源
        }
        
        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
```
然后访问http://10.28.10.218/session.jsp   可以看到服务器随机返回给我们两个tomcat的session页面。同时我们也可以看到SessionId在不停的变化。

![Tomcat1的session.jsp](/images/QQ20160316-1.png)

![Tomcat2的session.jsp](/images/QQ20160316-0.png)

通过Nginx的监控页也可以看出请求被随机的转发到了tomcat中

![Nginx的监控页](/images/QQ20160316-2.png)
## 将tomcat的session都存储到redis中

Tomcat存储到Redis库项目地址：https://github.com/jcoleman/tomcat-redis-session-manager  
从gradle配置上看，此项目还有三个依赖库。通过gradle进行编译，最终会自动从网络下载commons-pool,commons-pool2,jedis库并编译生成tomcat-redis-session-manager。
```
dependencies {
  compile group: 'org.apache.tomcat', name: 'tomcat-catalina', version: '7.0.27'
  compile group: 'redis.clients', name: 'jedis', version: '2.5.2'
  compile group: 'org.apache.commons', name: 'commons-pool2', version: '2.2'
  //compile group: 'commons-codec', name: 'commons-codec', version: '1.9'

  testCompile group: 'junit', name: 'junit', version: '4.+'
  testCompile 'org.hamcrest:hamcrest-core:1.3'
  testCompile 'org.hamcrest:hamcrest-library:1.3'
  testCompile 'org.mockito:mockito-all:1.9.5'
  testCompile group: 'org.apache.tomcat', name: 'tomcat-coyote', version: '7.0.27'
}
```
觉得麻烦的同学可以直接下载以下库，放入到tomcat/lib下：
[commons-pool-1.5.5.jar](/libs/commons-pool-1.5.5.jar)
[commons-pool2-2.2.jar](/libs/commons-pool2-2.2.jar)
[jedis-2.0.0.jar](/libs/jedis-2.0.0.jar)
[tomcat-redis-session-manager-1.2-tomcat-7-1.2.jar](/libs/tomcat-redis-session-manager-1.2-tomcat-7-1.2.jar)

按tomcat-redis-session-manager在github上地址里的说明修改两个tomcat的context.xml（tomcat/conf/context.xml）增加存储配置
```
<Valve className="com.radiadesign.catalina.session.RedisSessionHandlerValve" />
<Manager className="com.radiadesign.catalina.session.RedisSessionManager"
         host="localhost" <!-- optional: defaults to "localhost" -->
         port="6379" <!-- optional: defaults to "6379" -->
         database="0" <!-- optional: defaults to "0" -->
         maxInactiveInterval="60" <!-- optional: defaults to "60" (in seconds) -->
         sessionPersistPolicies="PERSIST_POLICY_1,PERSIST_POLICY_2,.." <!-- optional -->
         sentinelMaster="SentinelMasterName" <!-- optional -->
         sentinels="sentinel-host-1:port,sentinel-host-2:port,.." />
```
修改好配置后，启动tomcat-1和tomcat-2。再访问session.jsp时你会发现无论是从哪一个tomcat返回的页面同一个客户端的sessionID都是相同的，这就达到了session在集群tomcat下共享的目的。

![](/images/QQ20160317-0.png)![](/images/QQ20160317-1.png)

通过redis-cli命令连接到redis服务器，可以看到对应sessionID的数据已存储到了redis中。

![](/images/QQ20160317-2.png)

__提醒：session的超时时间由context.xml中的maxInactiveInterval配置，默认60秒__

-----
*观点仅代表自己，期待你的留言。*
