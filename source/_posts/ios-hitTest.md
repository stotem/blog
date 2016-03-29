---
title: iOS-hitTest:withEvent与pointInside:withEvent
tags:
  - iOS
  - 转载
date: 2016-03-24 10:45:13
---

## 简介
对于触摸事件的响应，首先要找到能够响应该事件的对象，iOS是用hit-testing 来找到哪个视图被触摸了（hit-test view），也就是以keyWindow为起点，hit-test view为终点,逐级调用hitTest:withEvent。

![](/images/1452221174578074.png)

## hitTest:withEvent:方法的处理流程:

先调用pointInside:withEvent:判断触摸点是否在当前视图内
1.如果返回YES，那么该视图的所有子视图调用hitTest:withEvent,调用顺序由层级低到高（top->bottom）依次调用。

2.如果返回NO，那么hitTest:withEvent返回nil，该视图的所有子视图的分支全部被忽略

如果某视图的pointInside:withEvent:返回YES，并且他的所有子视图hitTest:withEvent:都返回nil，或者该视图没有子视图，那么该视图的hitTest:withEvent:返回自己。
如果子视图的hitTest:withEvent:返回非空对象，那么当前视图的hitTest:withEvent:也返回这个对象，也就是沿原路回推，最终将hit-test view传递给keyWindow
以下视图的hitTest:withEvent:方法会返回nil，导致自身和其所有子视图不能被hit-testing发现，无法响应触摸事件：
 1.隐藏(hidden=YES)的视图
 2.禁止用户操作(userInteractionEnabled=NO)的视图
 3.alpha<0.01的视图
 4.视图超出父视图的区域



-----

*观点仅代表自己，期待你的留言。*
