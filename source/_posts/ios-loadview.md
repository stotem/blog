---
title: iOS中UIViewController初始化过程及LoadView默认实现
tags:
  - iOS
  - 原创
date: 2016-03-29 15:41:52
---


## Xib或者Storyboard方式初始化UIViewController
1、系统会通过 (instancetype)initWithCoder:(NSCoder *)aDecoder创建Controller对象实例。
2、当需要将UIController的View添加到父级View时则会通过loadViewIfRequired方法来先判断self.view对象是否为nil
	如果为nil则会调用 (void)loadView进行view的初始化。然后会调用viewDidLoad方法

![](/images/xib_init.png)

## 编码的方式初始化UIViewController
[[UIViewController alloc] init]，系统会调用[[UIViewController alloc] initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil]创建实例对象
![](/images/code_init.png)


## 系统默认loadView实现
通过initWithNibName保存的nibName来加载对应的nib资源并赋值于self.view, 如果nibName为空，则创建一个空的UIView实例赋值。

![](/images/def_loadview.png)

__注意：__在loadView方法自定义实现中由于view未进行初始化，如果使用self.view获取值，由会再次触发调用loadView方法造成loadView的递归调用。在ios9.3环境下通过self.view进行赋值则不存在此情况。


附一张UIViewController生命周期图：
![](/images/uiviewcontroller-lifecycle.jpg)

-----

*观点仅代表自己，期待你的留言。*
