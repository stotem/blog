---
title: ubuntu下thinkpad电池阀设置（待验证）
tags:
  - 笔记
date: 2017-10-18 16:04:47
---

## 设置电池阀
sudo add-apt-repository ppa:linrunner/tlp
sudo apt-get update

sudo apt-get install tlp tlp-rdw
sudo apt-get install tp-smapi-dkms acpi-call-tools

sudo gedit /etc/default/tlp

# Main battery (values in %)
START_CHARGE_THRESH_BAT0=10
STOP_CHARGE_THRESH_BAT0=96

之后执行

sudo tlp setcharge

重启 OK 电池阀设置完成了

## 查看电池阀设置
tone@ubuntu:~$ sudo tlp-stat --battery
--- TLP 0.4 --------------------------------------------


+++ ThinkPad Extended Battery Functions
tp-smapi = active
tpacpi-bat = active


+++ ThinkPad Battery Status (Main)
/sys/devices/platform/smapi/BAT0/manufacturer = LGC
/sys/devices/platform/smapi/BAT0/model = 42T4865
/sys/devices/platform/smapi/BAT0/manufacture_date = 2011-11-24
/sys/devices/platform/smapi/BAT0/first_use_date = 2012-04-13
/sys/devices/platform/smapi/BAT0/cycle_count = 63
/sys/devices/platform/smapi/BAT0/design_capacity = 62160 [mWh]
/sys/devices/platform/smapi/BAT0/last_full_capacity = 59470 [mWh]
/sys/devices/platform/smapi/BAT0/remaining_capacity = 42410 [mWh]
/sys/devices/platform/smapi/BAT0/remaining_percent = 71 [%]
/sys/devices/platform/smapi/BAT0/remaining_running_time_now = 189 [min]
/sys/devices/platform/smapi/BAT0/remaining_charging_time = not_charging [min]
/sys/devices/platform/smapi/BAT0/power_now = -13432 [mW]
/sys/devices/platform/smapi/BAT0/power_avg = -12742 [mW]


tpacpi-bat.BAT0.startThreshold = 10 [%]
tpacpi-bat.BAT0.stopThreshold = 96 [%]
tpacpi-bat.BAT0.forceDischarge = 0


-----

*观点仅代表自己，期待你的留言。*
