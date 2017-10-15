---
title: Linux下通过nginx实现直播间功能的实验
tags:
  - 原创
  - nginx + obs
date: 2017-10-15 11:07:14
---

## 实验环境
 - 系统环境
```
wujianjun@wujianjun-work ~ $ uname -a
Linux wujianjun-work 4.10.0-37-generic #41~16.04.1-Ubuntu SMP Fri Oct 6 22:42:59 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux
```
 - 软件环境
 OBS(Open Broadcaster Software) v20.0.1 (Linux)

 nginx version: nginx/1.13.6
 built by gcc 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.5)
 built with OpenSSL 1.0.2g  1 Mar 2016
 TLS SNI support enabled
 configure arguments: --with-pcre=pcre-8.38 --add-module=nginx-rtmp-module-1.1.11

## Nginx+obs安装及配置
### 安装obs
```
wujianjun@wujianjun-work ~ $ sudo add-apt-repository ppa:kirillshkrogalev/ffmpeg-next
wujianjun@wujianjun-work ~ $ sudo apt-get update && sudo apt-get install ffmpeg
wujianjun@wujianjun-work ~ $ sudo apt-get install obs-studio
wujianjun@wujianjun-work ~ $ sudo add-apt-repository ppa:obsproject/obs-studio
wujianjun@wujianjun-work ~ $ sudo apt-get update && sudo apt-get install obs-studio
```
### nginx加装rtmp模块
nginx-rtmp-module (https://github.com/arut/nginx-rtmp-module)

```
wujianjun@wujianjun-work ~ $ sudo apt-get install build-essential
wujianjun@wujianjun-work ~ $ wget wget http://nginx.org/download/nginx-1.13.6.tar.gz
wujianjun@wujianjun-work ~/nginx-1.13.6 $ wget https://github.com/arut/nginx-rtmp-module/archive/v1.1.11.tar.gz
wujianjun@wujianjun-work ~/nginx-1.13.6 $ tar -xvf v1.1.11.tar.gz
wujianjun@wujianjun-work ~/nginx-1.13.6 $ wget http://jaist.dl.sourceforge.net/project/pcre/pcre/8.38/pcre-8.38.tar.gz
wujianjun@wujianjun-work ~/nginx-1.13.6 $ tar -xvf pcre-8.38.tar.gz
wujianjun@wujianjun-work ~/nginx-1.13.6 $ ls -all
总用量 748
drwxr-xr-x  9 wujianjun wujianjun   4096 10月 15 11:39 .
drwxr-xr-x 63 wujianjun wujianjun   4096 10月 15 11:33 ..
drwxr-xr-x  6 wujianjun wujianjun   4096 10月 15 11:33 auto
-rw-r--r--  1 wujianjun wujianjun 282456 10月 10 23:22 CHANGES
-rw-r--r--  1 wujianjun wujianjun 430416 10月 10 23:22 CHANGES.ru
drwxr-xr-x  2 wujianjun wujianjun   4096 10月 15 11:33 conf
-rwxr-xr-x  1 wujianjun wujianjun   2502 10月 10 23:22 configure
drwxr-xr-x  4 wujianjun wujianjun   4096 10月 15 11:33 contrib
drwxr-xr-x  2 wujianjun wujianjun   4096 10月 15 11:33 html
-rw-r--r--  1 wujianjun wujianjun   1397 10月 10 23:22 LICENSE
drwxr-xr-x  2 wujianjun wujianjun   4096 10月 15 11:33 man
drwxrwxr-x  6 wujianjun wujianjun   4096 2月  13  2017 nginx-rtmp-module-1.1.11
drwxr-xr-x  7 wujianjun wujianjun   4096 11月 23  2015 pcre-8.38
-rw-r--r--  1 wujianjun wujianjun     49 10月 10 23:22 README
drwxr-xr-x  9 wujianjun wujianjun   4096 10月 15 11:33 src
wujianjun@wujianjun-work ~/nginx-1.13.6 $ ./configure --with-pcre=pcre-8.38 --add-module=nginx-rtmp-module-1.1.11
wujianjun@wujianjun-work ~/nginx-1.13.6 $ make && sudo make install
wujianjun@wujianjun-work ~/nginx-1.13.6 $ ls -all /usr/local/nginx/
总用量 24
drwxr-xr-x  6 root root 4096 10月 15 16:11 .
drwxr-xr-x 11 root root 4096 10月 15 16:11 ..
drwxr-xr-x  2 root root 4096 10月 15 16:11 conf
drwxr-xr-x  2 root root 4096 10月 15 16:11 html
drwxr-xr-x  2 root root 4096 10月 15 16:11 logs
drwxr-xr-x  2 root root 4096 10月 15 16:11 sbin
```

### 增加rtmp协议配置
```
wujianjun@wujianjun-work ~/nginx-1.13.6 $ sudo vi /usr/local/nginx/conf/nginx.conf
```
在nginx.conf文件末尾增加以下rtmp协议的配置
```
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            record off;
        }
    }
}
```

## 启动&测试
 - 启动nginx
```
wujianjun@wujianjun-work ~/nginx-1.13.6 $ sudo /usr/local/nginx/sbin/nginx
```
 - 启动OBS
 打开刚安装的OBS软件，在来源处配置图像的推送来源（我这里选择窗口捕获），点击右下角"设置"，进行如下图配置流推送地址
 ![](/images/obs-1.png)

配置完成后，点击"开始推流"

 - 启动支持网络流播放的视频播放器(演示使用vlc播放器)
 配置网络流播放的地址，如下图：
 ![](/images/vlc-1.png)

 当点击"播放"后，稍等几秒，即可看到播放器显示了obs捕获的图像了。
 ![](/images/vlc-2.png)

由于视频流需要通过网络进行传输，所以直播图像会有几秒的延迟。

## http访问直播视频
1、更改nginx.conf中配置，增加hls配置(hls是在流媒体服务器中用来存放流媒体的文件夹),再次hls所在目录设置为http协议访问目录即可，更改后的配置如下：
```
rtmp {
    server {
        listen 1935;
        chunk_size 4096;

        application live {
            live on;
            hls on;
            hls_path /usr/share/nginx/html/hls;
            hls_fragment 5s;
        }
    }
}

http {
  server {
    listen 80;
    .....
    location / {
           #root   html;
           root /usr/share/nginx/html;
           index  index.html index.htm;
    }
    .....
  }
}
```
__注意：__ hls所在目录nginx的用户必须有写入权限。

2、obs软件配置录制流名称
 在配置obs推送流URL的下方有一个设置"流名称"的地方，这里可以随意填写一个名称（我这里示例填入"test"）

3、重启一下nginx与obs软件，我们即可在手机浏览器中输入 http://ip/hls/test.m3u8 即可通过手机播放直播视频。（直播延迟有点大，后续出文章优化）
![](/images/obs-2.png)

-----

*观点仅代表自己，期待你的留言。*
