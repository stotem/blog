---
title: 使用openssl与keytool完成https配置实例（转）
tags:
  - 原创
  - https
keywords:
  - https
  - keytool
  - openssl
date: 2018-09-13 10:37:12
---
## keytool单向认证实例
### 1) 为服务器生成证书
```bash
wujianjun@smzc ~ $ keytool -genkey -keyalg RSA -dname "cn=127.0.0.1,ou=inspur,o=none,l=shandong,st=jinan,c=cn" -alias server -keypass 111111 -keystore server.keystore -storepass 111111 -validity 3650
```
_注：cn=127.0.0.1配置的是服务器IP_
### 2) 生成csr
生成csr文件用于提交CA认证生成证书使用。
```bash
wujianjun@smzc ~ $ keytool -certReq -alias server -keystore server.keystore -file ca.csr
```
### 3) 生成cer
这个ca.cer是为了解决不信任时要导入的
```bash
wujianjun@smzc ~ $ keytool -export -alias server -keystore server.keystore -file ca.cer -storepass 111111
```
### 4) tomcat配置ssl
clientAuth="false"代表单向认证，配置如下：
```xml
<Connector SSLEnabled="true" clientAuth="false"
        maxThreads="150" port="8443"
        protocol="org.apache.coyote.http11.Http11Protocol"或者HTTP/1.1
        scheme="https" secure="true" sslProtocol="TLS"
        keystoreFile="/home/server.keystore" keystorePass="111111"/>
```
_注: Http11Protocol支持HTTP/1.1协议，是http1.1协议的ProtocolHandler实现。_

### 5) 常见问题
* __服务器的证书不受信任__
  解决方法：
  1、选择“继续前往（不安全）”，也能访问，但是此时就是以普通的HTTP方式进行信息传输了。
  2、选择生成的`ca.cer`文件，将证书存储在 __“受信任的证书颁发机构”__ ，就可以通过HTTPS正常访问了。
* __程序访问Https异常__
__sun.security.validator.ValidatorException: PKIX path building failed...__
需要将生成的证书(ca.cer ) 导入到jdk中
执行以下命令：
```bash
wujianjun@smzc ~ $ keytool -import -alias tomcatsso -file "ca.cer" -keystore "D:\java\jdk1.6.0_11\jre\lib\security\cacerts" -storepass changeit
```
_其中`changeit`是jre默认的密码。_
__No subject alternative names present__，请在生成keystore 注意CN必须要为域名（或机器名称)例如 localhost 不能为IP 。
__No name matching localhost found__，表示你生成keystore CN的名称和你访问的名称不一致。

## openssl双向认证实例
_Linux环境下，在home下建立out32dll目录，在此目录下建立ca、client、server三个文件夹。以下命令均在out32dll目录下执行。_
### 1) 模拟CA生成证书
* 创建私钥
```bash
wujianjun@smzc ~/out32dll $ openssl genrsa -out ca/ca-key.pem 1024
```
* 创建证书请求
```bash
wujianjun@smzc ~/out32dll $ openssl req -new -out ca/ca-req.csr -key ca/ca-key.pem
```
* 自签署证书
```bash
wujianjun@smzc ~/out32dll $ openssl x509 -req -in ca/ca-req.csr -out ca/ca-cert.pem -signkey ca/ca-key.pem -days 3650
```
* 将证书导出成浏览器支持的.p12格式 (供浏览器不受信任时导入)
```bash
wujianjun@smzc ~/out32dll $ openssl pkcs12 -export -clcerts -in ca/ca-cert.pem -inkey ca/ca-key.pem -out ca/ca.p12
```
_密码：111111_
### 2) 生成Server证书
* 创建私钥
```bash
wujianjun@smzc ~/out32dll $ openssl genrsa -out server/server-key.pem 1024
```
* 创建Server证书请求
```bash
wujianjun@smzc ~/out32dll $ openssl req -new -out server/server-req.csr -key server/server-key.pem
```
* 使用CA证书签署Server证书
```bash
wujianjun@smzc ~/out32dll $ openssl x509 -req -in server/server-req.csr -out server/server-cert.pem -signkey server/server-key.pem -CA ca/ca-cert.pem -CAkey ca/ca-key.pem -CAcreateserial -days 3650
```
* 将证书导出成浏览器支持的.p12格式
```bash
wujianjun@smzc ~/out32dll $ openssl pkcs12 -export -clcerts -in server/server-cert.pem -inkey server/server-key.pem -out server/server.p12
```
_密码：111111_
### 3) 生成Clinet证书
* 创建私钥
```bash
wujianjun@smzc ~/out32dll $ openssl genrsa -out client/client-key.pem 1024
```
* 创建Client证书请求
```bash
wujianjun@smzc ~/out32dll $ openssl req -new -out client/client-req.csr -key client/client-key.pem
```
* 使用CA证书签署Client证书
```bash
wujianjun@smzc ~/out32dll $ openssl x509 -req -in client/client-req.csr -out client/client-cert.pem -signkey client/client-key.pem -CA ca/ca-cert.pem -CAkey ca/ca-key.pem -CAcreateserial -days 3650  
```
* 将证书导出成浏览器支持的.p12格式
```bash
wujianjun@smzc ~/out32dll $ openssl pkcs12 -export -clcerts -in client/client-cert.pem -inkey client/client-key.pem -out client/client.p12
```
_密码：111111_
### 4) 根据CA证书生成jks文件
```bash
wujianjun@smzc ~/out32dll $ keytool -keystore truststore.jks -keypass 222222 -storepass 222222 -alias ca -import -trustcacerts -file /home/out32dll/ca/ca-cert.pem
```

### 5) 服务器配置（tomcat6示例）
修改conf/server.xml。 将keystoreFile、truststoreFile的路径填写为正确的放置路径。
```xml
<Connector port="8443" protocol="HTTP/1.1" SSLEnabled="true"
                maxThreads="150" scheme="https" secure="true"
                clientAuth="true" sslProtocol="TLS"
                keystoreFile="/home/out32dll/server/server.p12" keystorePass="111111"  keystoreType="PKCS12"
                truststoreFile="/home/out32dll/truststore.jks" truststorePass="222222" truststoreType="JKS"/>
```
### 6) 导入证书(IE示例)
将ca.p12，client.p12分别导入到IE中去（打开IE->Internet选项->内容->证书）。 ca.p12导入至 受信任的根证书颁发机构，client.p12导入至个人。
_进行浏览器访问双向Https时会弹出客户端证书供选择_

-----

*观点仅代表自己，期待你的留言。*
