---
title: iOS开发MVVM理解与总结
tags:
  - iOS
  - 原创
date: 2016-04-07 18:14:40
---

## MVC存在的问题
![](/images/ios-mvc.png)
### iOS概念对应
`M（model）:` 普通Class，用于对基础数据类型的对象封装，不包含界面逻辑、业务逻辑与数据转换等功能。
`V（view）:`  xib或storyboard，用于显示给用户的界面。
`C（controller）:` ViewController，用户下行数据输入与上线数据显示，view跳转，数据校验等功能。
### 问题
1. 所有的逻辑代码，数据校验，UI控制，对象转换，数据缓存等服务都存在到Controller中，造成代码过于臃肿，可读性低。
2. Controller中处理所有的任务，基本上很难多人协作完成，分工性差。
3. Controller依赖到UIKit库，让单元测试无法覆盖，功能可靠性不可预测。
4. 试想，iphone程序更换成macosx程序哪些能重用？功能的重用性低。

分析MVC的问题，主要还是由于Controller完成的任务过多造成，为了解决以上问题，必须让Controller进行减肥。

## MVVM
![](/images/ios-mvvm.png)
### iOS概念对应
`M（model）:` 与MVC中概念一致之外，将View分为数据model与界面model。
`V（view）:`  与MVC中概念一致之外，另外将与view连接紧密的viewcontroller划分到一起。viewcontroller只负责界面跳转、用户下行数据获取、用户上行数据绑定以及vm层的调用。
`VM（view-model）:` 用于连接view与model层，完成界面逻辑，业务逻辑，接口调用，数据model与界面model数据转换，数据校验上行数据处理与下行数据转换，数据缓存等功能。

## 另外的建议
使用[CocoaPods]将各层分开成不同的project，由workspace融合，最终通过静态库的形式进行相互的引用。
这样做的好处有以下几点：
1. 代码清晰，分工明确。
2. 对于代码修改后的编译为分段进行，提高了编译速度。
3. 对各层的代码都可以进行版本化管理，调用者的各层代码固化调用版本，对于重构代码等过程有很大的好处。
4. 由于静态库可由其它程序平台重用（iOS与MacOSX），一次编译，多次使用。

[CocoaPods]: https://cocoapods.org/

-----

*观点仅代表自己，期待你的留言。*
