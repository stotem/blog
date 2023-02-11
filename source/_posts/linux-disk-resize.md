---
title: Linux下硬盘的一些操作
tags:
  - 原创
keywords:
  - Linux硬盘扩容
  - Linux删除分区
date: 2023-02-09 22:33:31
---

## Linux环境信息
```
wujianjun@wujianjun-work:~$ cat /etc/os-release
PRETTY_NAME="Ubuntu 22.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="22.04"
VERSION="22.04.1 LTS (Jammy Jellyfish)"
VERSION_CODENAME=jammy
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=jammy
```

## 同一硬盘逻辑分区扩容
```
wujianjun@wujianjun-work:~$ fdisk -l #查看系统硬盘信息
wujianjun@wujianjun-work:~$ lsblk #查看硬盘分区及容量情况
wujianjun@wujianjun-work:~$ df -hT #查看挂载情况
wujianjun@wujianjun-work:~$ lvdisplay #查看逻辑分区情况
wujianjun@wujianjun-work:~$ lvextend -L +1643.2G /dev/ubuntu-vg/ubuntu-lv #/dev/ubuntu-vg/ubuntu-lv为lvdisplay中展示的LV Path
wujianjun@wujianjun-work:~$ resize2fs /dev/ubuntu-vg/ubuntu-lv #重新加载逻辑卷
```

## 删除硬盘分区
```
wujianjun@wujianjun-work:~$ lsblk #查看硬盘分区及容量情况
root@gigatech-linux:~# fdisk /dev/sdb #/dev/sdb为fdisk -l中的硬盘名
Welcome to fdisk (util-linux 2.37.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Command (m for help): d
Selected partition 1
Partition 1 has been deleted.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

## 增加硬盘分区
```
wujianjun@wujianjun-work:~$ lsblk #查看硬盘分区及容量情况
wujianjun@wujianjun-work:~$ fdisk /dev/sdb
Welcome to fdisk (util-linux 2.37.2).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): e
Partition number (1-4, default 1):
First sector (2048-3907029167, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-3907029167, default 3907029167):

Created a new partition 1 of type 'Extended' and of size 1.8 TiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
wujianjun@wujianjun-work:~$ mkfs -t ext4 /dev/sdb1 #对新区进行格式化
```

## 根分区扩容加装硬盘（当根分区为lvm时可行）
```
wujianjun@wujianjun-work:~$ vgdisplay -v #查看卷分组
wujianjun@wujianjun-work:~$ pvcreate /dev/sdb1 #创建物理卷，pvdisplay查看创建结果
wujianjun@wujianjun-work:~$ vgextend ubuntu-vg /dev/sdb1 #将物理卷添加到根分区所属卷分组，券分组为vgdisplay的VG Name
wujianjun@wujianjun-work:~$ lvextend -L +256G /dev/ubuntu-vg/ubuntu-lv #扩展lvm容量
wujianjun@wujianjun-work:~$ resize2fs /dev/ubuntu-vg/ubuntu-lv #重新加载逻辑卷
```

-----

*观点仅代表自己，期待你的留言。*
