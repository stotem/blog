---
title: OpenVPN系列一之安装配置
tags:
  - 原创
  - OpenVPN
keywords:
  - "macOS Monterey 连接 L2TP vpn后无法联网"
  - "OpenVPN"
  - "vpn_gateway"
  - "net_gateway"
date: 2022-08-04 11:54:10
---

## 背景
最近成都疫情严重，为了研发工作顺序不中断推进，方便研发人员在家也能debug程序，需要外网到内网访问通道。

最初在H3C路由器上搭建L2TP VPN通道，经测试发现macOS11能正常联通和使用，在macOS12下则能ping通但不能访问内网服务器的任何其它端口，在网络上遇到这个问题的人还不少，都没有提出有效的解决方法。

经过不断的尝试最终决定在内网服务器上通过vpn软件来构建vpn访问通道。

## 服务器环境参数

| 序号 | 设备名 | IP地址 | 说明 |
| ------ | ------ | ------ | ------ |
| 1 | 路由器 | 10.84.102.1 | H3C专线路由器  |
| 2 | Vpn服务器 | 10.84.102.131 | 搭建20.04 LTS操作系统  |
| 3 | 服务器1 | 10.84.102.90 | 内网服务器  |

所涉及到的软件为：
OpenVPN 2.4.7（服务端）
Tunnelblick 3.8.7a（客户机软件）

## 搭建VpnServer

以下操作均在10.84.102.131上进行

### 安装软件
```
root@wujianjun-work:~# sudo apt update
root@wujianjun-work:~# sudo apt install openvpn easy-rsa
root@wujianjun-work:~# openvpn --version
OpenVPN 2.4.7 x86_64-pc-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on Mar 22 2022
library versions: OpenSSL 1.1.1f  31 Mar 2020, LZO 2.10
Originally developed by James Yonan
Copyright (C) 2002-2018 OpenVPN Inc <sales@openvpn.net>
```
### 配置并启动VpnServer
1. OpenVPN使用TLS/SSL协议保证传输安全，它使用证书对服务器与客户端之间的传输进行加密，所以这里需要我们自己创建一个简单的CA证书，easy-rsa可以帮助我们做到这一点。
```
root@wujianjun-work:~# mkdir ~/ca
root@wujianjun-work:~# ln -s /usr/share/easy-rsa/* ~/ca/
root@wujianjun-work:~# cd ~/ca
root@wujianjun-work:~# sudo vi var

打开var文件后，在其中添加以下两行，保存关闭：
set_var EASYRSA_ALGO "ec"
set_var EASYRSA_DIGEST "sha512"

root@wujianjun-work:~# ./easyrsa init-pki
root@wujianjun-work:~# ./easyrsa build-ca
root@wujianjun-work:~# ./easyrsa gen-req server nopass
root@wujianjun-work:~# sudo cp ~/ca/pki/private/server.key /etc/openvpn/server/
root@wujianjun-work:~# ./easyrsa sign-req server server
root@wujianjun-work:~# sudo cp ~/ca/pki/ca.crt /etc/openvpn/server/
root@wujianjun-work:~# sudo cp ~/ca/pki/issued/server.crt /etc/openvpn/server/
# 为了应对端口扫描等恶意举动，这里需要添加额外的安全措施
root@wujianjun-work:~# openvpn --genkey --secret ta.key
root@wujianjun-work:~# sudo cp ta.key /etc/openvpn/server/
```
2. 配置服务端的文件
```
root@wujianjun-work:~# sudo vi /etc/openvpn/server/server.conf
```
把以下内容拷贝进去
```file
#################################################
# Sample OpenVPN 2.0 config file for            #
# multi-client server.                          #
#                                               #
# This file is for the server side              #
# of a many-clients <-> one-server              #
# OpenVPN configuration.                        #
#                                               #
# OpenVPN also supports                         #
# single-machine <-> single-machine             #
# configurations (See the Examples page         #
# on the web site for more info).               #
#                                               #
# This config should work on Windows            #
# or Linux/BSD systems.  Remember on            #
# Windows to quote pathnames and use            #
# double backslashes, e.g.:                     #
# "C:\\Program Files\\OpenVPN\\config\\foo.key" #
#                                               #
# Comments are preceded with '#' or ';'         #
#################################################

# Which local IP address should OpenVPN
# listen on? (optional)
# 如果存在多网卡，由需要绑定具体ip地址
;local a.b.c.d

# Which TCP/UDP port should OpenVPN listen on?
# If you want to run multiple OpenVPN instances
# on the same machine, use a different port
# number for each one.  You will need to
# open up this port on your firewall.
# vpn服务的监听端口
port 1194
;port 1701

# TCP or UDP server?
;proto tcp
proto udp

# "dev tun" will create a routed IP tunnel,
# "dev tap" will create an ethernet tunnel.
# Use "dev tap0" if you are ethernet bridging
# and have precreated a tap0 virtual interface
# and bridged it with your ethernet interface.
# If you want to control access policies
# over the VPN, you must create firewall
# rules for the the TUN/TAP interface.
# On non-Windows systems, you can give
# an explicit unit number, such as tun0.
# On Windows, use "dev-node" for this.
# On most systems, the VPN will not function
# unless you partially or fully disable
# the firewall for the TUN/TAP interface.
;dev tap
dev tun

# Windows needs the TAP-Win32 adapter name
# from the Network Connections panel if you
# have more than one.  On XP SP2 or higher,
# you may need to selectively disable the
# Windows firewall for the TAP adapter.
# Non-Windows systems usually don't need this.
;dev-node MyTap

# SSL/TLS root certificate (ca), certificate
# (cert), and private key (key).  Each client
# and the server must have their own cert and
# key file.  The server and all clients will
# use the same ca file.
#
# See the "easy-rsa" directory for a series
# of scripts for generating RSA certificates
# and private keys.  Remember to use
# a unique Common Name for the server
# and each of the client certificates.
#
# Any X509 key management system can be used.
# OpenVPN can also use a PKCS #12 formatted key file
# (see "pkcs12" directive in man page).
ca ca.crt
cert server.crt
key server.key  # This file should be kept secret

# Diffie hellman parameters.
# Generate your own with:
#   openssl dhparam -out dh2048.pem 2048
;dh dh2048.pem
dh none

# Network topology
# Should be subnet (addressing via IP)
# unless Windows clients v2.0.9 and lower have to
# be supported (then net30, i.e. a /30 per client)
# Defaults to net30 (not recommended)
;topology subnet

# Configure server mode and supply a VPN subnet
# for OpenVPN to draw client addresses from.
# The server will take 10.8.0.1 for itself,
# the rest will be made available to clients.
# Each client will be able to reach the server
# on 10.8.0.1. Comment this line out if you are
# ethernet bridging. See the man page for more info.
# 给客户端分配的ip段，当前配置为10.8.0.X
server 10.8.0.0 255.255.255.0

# Maintain a record of client <-> virtual IP address
# associations in this file.  If OpenVPN goes down or
# is restarted, reconnecting clients can be assigned
# the same virtual IP address from the pool that was
# previously assigned.
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# Configure server mode for ethernet bridging.
# You must first use your OS's bridging capability
# to bridge the TAP interface with the ethernet
# NIC interface.  Then you must manually set the
# IP/netmask on the bridge interface, here we
# assume 10.8.0.4/255.255.255.0.  Finally we
# must set aside an IP range in this subnet
# (start=10.8.0.50 end=10.8.0.100) to allocate
# to connecting clients.  Leave this line commented
# out unless you are ethernet bridging.
;server-bridge 10.8.0.4 255.255.255.0 10.8.0.50 10.8.0.100

# Configure server mode for ethernet bridging
# using a DHCP-proxy, where clients talk
# to the OpenVPN server-side DHCP server
# to receive their IP address allocation
# and DNS server addresses.  You must first use
# your OS's bridging capability to bridge the TAP
# interface with the ethernet NIC interface.
# Note: this mode only works on clients (such as
# Windows), where the client-side TAP adapter is
# bound to a DHCP client.
;server-bridge

# Push routes to the client to allow it
# to reach other private subnets behind
# the server.  Remember that these
# private subnets will also need
# to know to route the OpenVPN client
# address pool (10.8.0.0/255.255.255.0)
# back to the OpenVPN server.
# 设置客户端连接上vpn后，访问不同网断所走网络。客户端软件连接上后会自动在客户机上创建网络路由
;push "route-gateway 10.8.0.1"
push "route-nopull"
# 以上配置表示客户端连接上后不额外加入任何路由
push "route 10.84.102.0 255.255.255.0 vpn_gateway"
# 以上配置表示客户端连接上后，访问10.84.102.X的服务器走vpn网关，下条同含义
# vpn_gateway：表示vpn网关；net_gateway：表示走本机网络网关
push "route 10.8.0.0 255.255.255.0 vpn_gateway"


# To assign specific IP addresses to specific
# clients or if a connecting client has a private
# subnet behind it that should also have VPN access,
# use the subdirectory "ccd" for client-specific
# configuration files (see man page for more info).

# EXAMPLE: Suppose the client
# having the certificate common name "Thelonious"
# also has a small subnet behind his connecting
# machine, such as 192.168.40.128/255.255.255.248.
# First, uncomment out these lines:
;client-config-dir ccd
;route 10.84.0.0 255.255.255.0
# Then create a file ccd/Thelonious with this line:
#   iroute 192.168.40.128 255.255.255.248
# This will allow Thelonious' private subnet to
# access the VPN.  This example will only work
# if you are routing, not bridging, i.e. you are
# using "dev tun" and "server" directives.

# EXAMPLE: Suppose you want to give
# Thelonious a fixed VPN IP address of 10.9.0.1.
# First uncomment out these lines:
;client-config-dir ccd
;route 10.9.0.0 255.255.255.252
# Then add this line to ccd/Thelonious:
#   ifconfig-push 10.9.0.1 10.9.0.2

# Suppose that you want to enable different
# firewall access policies for different groups
# of clients.  There are two methods:
# (1) Run multiple OpenVPN daemons, one for each
#     group, and firewall the TUN/TAP interface
#     for each group/daemon appropriately.
# (2) (Advanced) Create a script to dynamically
#     modify the firewall in response to access
#     from different clients.  See man
#     page for more info on learn-address script.
;learn-address ./script

# If enabled, this directive will configure
# all clients to redirect their default
# network gateway through the VPN, causing
# all IP traffic such as web browsing and
# and DNS lookups to go through the VPN
# (The OpenVPN server machine may need to NAT
# or bridge the TUN/TAP interface to the internet
# in order for this to work properly).
# 打开下行注释（去掉；号）表示强制代理所有流量
;push "redirect-gateway def1 bypass-dhcp"

# Certain Windows-specific network settings
# can be pushed to clients, such as DNS
# or WINS server addresses.  CAVEAT:
# http://openvpn.net/faq.html#dhcpcaveats
# The addresses below refer to the public
# DNS servers provided by opendns.com.
# 设置客户端连接上之后push DNS地址到客户端
push "dhcp-option DNS 61.139.2.69"
push "dhcp-option DNS 208.67.220.220"

# Uncomment this directive to allow different
# clients to be able to "see" each other.
# By default, clients will only see the server.
# To force clients to only see the server, you
# will also need to appropriately firewall the
# server's TUN/TAP interface.
# 多台客户机连接上同一个vpn后是否网络互通，如果不互通则注释掉以下配置。
client-to-client

# Uncomment this directive if multiple clients
# might connect with the same certificate/key
# files or common names.  This is recommended
# only for testing purposes.  For production use,
# each client should have its own certificate/key
# pair.
#
# IF YOU HAVE NOT GENERATED INDIVIDUAL
# CERTIFICATE/KEY PAIRS FOR EACH CLIENT,
# EACH HAVING ITS OWN UNIQUE "COMMON NAME",
# UNCOMMENT THIS LINE OUT.
;duplicate-cn

# The keepalive directive causes ping-like
# messages to be sent back and forth over
# the link so that each side knows when
# the other side has gone down.
# Ping every 10 seconds, assume that remote
# peer is down if no ping received during
# a 120 second time period.
keepalive 10 120

# For extra security beyond that provided
# by SSL/TLS, create an "HMAC firewall"
# to help block DoS attacks and UDP port flooding.
#
# Generate with:
#   openvpn --genkey --secret ta.key
#
# The server and each client must have
# a copy of this key.
# The second parameter should be '0'
# on the server and '1' on the clients.
;tls-auth ta.key 0 # This file is secret
tls-crypt ta.key

# Select a cryptographic cipher.
# This config item must be copied to
# the client config file as well.
# Note that v2.4 client/server will automatically
# negotiate AES-256-GCM in TLS mode.
# See also the ncp-cipher option in the manpage
;cipher AES-256-CBC
cipher AES-256-GCM
auth SHA256

# Enable compression on the VPN link and push the
# option to the client (v2.4+ only, for earlier
# versions see below)
;compress lz4-v2
;push "compress lz4-v2"

# For compression compatible with older clients use comp-lzo
# If you enable it here, you must also
# enable it in the client config file.
;comp-lzo

# The maximum number of concurrently connected
# clients we want to allow.
;max-clients 100

# It's a good idea to reduce the OpenVPN
# daemon's privileges after initialization.
#
# You can uncomment this out on
# non-Windows systems.
user nobody
group nogroup

# The persist options will try to avoid
# accessing certain resources on restart
# that may no longer be accessible because
# of the privilege downgrade.
persist-key
persist-tun

# Output a short status file showing
# current connections, truncated
# and rewritten every minute.
status /var/log/openvpn/openvpn-status.log

# By default, log messages will go to the syslog (or
# on Windows, if running as a service, they will go to
# the "\Program Files\OpenVPN\log" directory).
# Use log or log-append to override this default.
# "log" will truncate the log file on OpenVPN startup,
# while "log-append" will append to it.  Use one
# or the other (but not both).
;log         /var/log/openvpn/openvpn.log
;log-append  /var/log/openvpn/openvpn.log

# Set the appropriate level of log
# file verbosity.
#
# 0 is silent, except for fatal errors
# 4 is reasonable for general usage
# 5 and 6 can help to debug connection problems
# 9 is extremely verbose
verb 3

# Silence repeating messages.  At most 20
# sequential messages of the same message
# category will be output to the log.
;mute 20

# Notify the client that when the server restarts so it
# can automatically reconnect.
explicit-exit-notify 1
```
3. 开启ipv4转发
```
root@wujianjun-work:~# echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
root@wujianjun-work:~# sudo sysctl -p
```

4. 启动服务器OpenVPN服务
```
root@wujianjun-work:~# sudo systemctl -f enable openvpn-server@server.service
root@wujianjun-work:~# sudo systemctl start openvpn-server@server.service
# 检查udp监听是否正常
root@wujianjun-work:~# netstat -antup|grep 1194
udp        0      0 0.0.0.0:1194            0.0.0.0:*  
```

### 生成客户端ovpn配置文件
1. 生成客户端的密钥文件
```
root@wujianjun-work:~# mkdir -p ~/client_conf/keys/
root@wujianjun-work:~# chmod -R 700 ~/client_conf/
root@wujianjun-work:~# cd ~/ca
root@wujianjun-work:~# ./easyrsa gen-req client1 nopass
root@wujianjun-work:~# cp ~/ca/pki/private/client1.key ~/client_conf/keys/
root@wujianjun-work:~# ./easyrsa sign-req client client1
root@wujianjun-work:~# cp client1.crt ~/client_conf/keys/
root@wujianjun-work:~# cp ~/ca/ta.key ~/client_conf/keys/
root@wujianjun-work:~# sudo cp /etc/openvpn/server/ca.crt ~/client_conf/keys/
```
2. 配置并生成客户端的认证文件
```
root@wujianjun-work:~# mkdir -p ~/client_conf/files/
root@wujianjun-work:~# vi ~/client_conf/base.conf
```
把以下内容拷贝进去
```file
##############################################
# Sample client-side OpenVPN 2.0 config file #
# for connecting to multi-client server.     #
#                                            #
# This configuration can be used by multiple #
# clients, however each client should have   #
# its own cert and key files.                #
#                                            #
# On Windows, you might want to rename this  #
# file so it has a .ovpn extension           #
##############################################

# Specify that we are a client and that we
# will be pulling certain config file directives
# from the server.
client

# Use the same setting as you are using on
# the server.
# On most systems, the VPN will not function
# unless you partially or fully disable
# the firewall for the TUN/TAP interface.
dev tap
;dev tun

# Windows needs the TAP-Win32 adapter name
# from the Network Connections panel
# if you have more than one.  On XP SP2,
# you may need to disable the firewall
# for the TAP adapter.
;dev-node MyTap

# Are we connecting to a TCP or
# UDP server?  Use the same setting as
# on the server.
;proto tcp
proto udp

# The hostname/IP and port of the server.
# You can have multiple remote entries
# to load balance between the servers.
# remote server-ip 1194
remote [Vpn服务器外网IP] 1194
;remote my-server-2 1194

# Choose a random host from the remote
# list for load-balancing.  Otherwise
# try hosts in the order specified.
;remote-random

# Keep trying indefinitely to resolve the
# host name of the OpenVPN server.  Very useful
# on machines which are not permanently connected
# to the internet such as laptops.
resolv-retry infinite

# Most clients don't need to bind to
# a specific local port number.
nobind

# Downgrade privileges after initialization (non-Windows only)
user nobody
group nogroup

# Try to preserve some state across restarts.
persist-key
persist-tun

# If you are connecting through an
# HTTP proxy to reach the actual OpenVPN
# server, put the proxy server/IP and
# port number here.  See the man page
# if your proxy server requires
# authentication.
;http-proxy-retry # retry on connection failures
;http-proxy [proxy server] [proxy port #]

# Wireless networks often produce a lot
# of duplicate packets.  Set this flag
# to silence duplicate packet warnings.
;mute-replay-warnings

# SSL/TLS parms.
# See the server config file for more
# description.  It's best to use
# a separate .crt/.key file pair
# for each client.  A single ca
# file can be used for all clients.
;ca ca.crt
;cert client.crt
;key client.key

# Verify server certificate by checking that the
# certicate has the correct key usage set.
# This is an important precaution to protect against
# a potential attack discussed here:
#  http://openvpn.net/howto.html#mitm
#
# To use this feature, you will need to generate
# your server certificates with the keyUsage set to
#   digitalSignature, keyEncipherment
# and the extendedKeyUsage to
#   serverAuth
# EasyRSA can do this for you.
remote-cert-tls server

# If a tls-auth key is used on the server
# then every client must also have the key.
;tls-auth ta.key 1

# Select a cryptographic cipher.
# If the cipher option is used on the server
# then you must also specify it here.
# Note that v2.4 client/server will automatically
# negotiate AES-256-GCM in TLS mode.
# See also the ncp-cipher option in the manpage
;cipher AES-256-CBC
cipher AES-256-GCM
auth SHA256

# Enable compression on the VPN link.
# Don't enable this unless it is also
# enabled in the server config file.
#comp-lzo

# Set log file verbosity.
verb 3

# Silence repeating messages
;mute 20
key-direction 1
```

4. 创建一个脚本文件用来生成客户端配置文件并对其提权
```
root@wujianjun-work:~# vi ~/client_conf/make_config.sh
```
把以下内容拷贝进去
```file
#!/bin/bash

# First argument: Client identifier

KEY_DIR=~/client_conf/keys
OUTPUT_DIR=~/client_conf/files
BASE_CONFIG=~/client_conf/base.conf

cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-crypt>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-crypt>') \
    > ${OUTPUT_DIR}/${1}.ovpn
```
```
root@wujianjun-work:~# chmod 700 ~/client_conf/make_config.sh
root@wujianjun-work:~# cd ~/client_conf
root@wujianjun-work:~# ./make_config.sh client1
root@wujianjun-work:~# ls -l ~/client_conf/files
-rw-r--r-- 1 root root 11859 Aug  3 19:29 client1.ovpn
```


至此，我们获得了客户端的配置文件client1.ovpn

-----

*观点仅代表自己，期待你的留言。*
