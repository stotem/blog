---
title: Effective Objective-C 理解消息传递机制
tags:
  - iOS
  - 转载
date: 2016-03-30 16:44:25
---

## 最简单的动态
Objective-C 是一门极其动态的语言，许多东西都可以推迟到运行时决定、修改。那么到底何为动态、何为静态？我们通过一个简单的例子对比下
```
/***********  例1 静态绑定   ***********/
#import <stdio.h>
void printHello() {
    printf("Hello, world!\n");
}
void printGoodbye() {
    printf("Goodbye, world!\n");
}
void saySomething(int type) 
{
    if (type == 0) {
        printHello();
    } else {
        printGoodbye();
    }
    return 0;
}
```
```
/***********  例2 动态绑定   ***********/
#import <stdio.h>
void printHello() {
    printf("Hello, world!\n");
}
void printGoodbye() {
    printf("Goodbye, world!\n");
}
void saySomething(int type) 
{
    void (*func)();
    if (type == 0) {
        func = printHello;
    } else {
        func = printGoodbye;
    }
    func();
    return 0;
}
```
例1的代码在编译期，编译器就已经知道了有 void printHello()、void printGoodbye() 俩函数，并且在 saySomething() 函数中，调用的函数明确，可以直接将函数名硬编码成地址，生成调用指令，这就是 __静态绑定__（static binding）。那么例2呢？例2的调用的是 func() 函数，而这函数实际调用的地址只能到程序运行时才能确定，这就是所谓的 __动态绑定__（dynamic binding）。动态绑定将函数调用从编译期推迟到了运行时。

在 Objective-C 中，向对象传递消息，就会使用这种动态绑定机制来决定需要调用的方法，这种动态特性使得 Objective-C 成为一门真正动态的语言。

## objec_msgSend 函数
Objective-C 的方法调用通常都是下面这种形式
```
id returnValue = [someObject messageName:parameter];
```
这种方法调用其实就是消息传递，编译器看到这条消息会转换成一条标准的 C 语言函数调用
```
id returnValue = objc_msgSend(someObject,
                              @selector(messageName:),
                              parameter);
```
用消息传递的话来解释就是：向 someObject 对象发送了一个名叫 messageName 的消息，这个消息携带了一个叫 parameter 的参数。这里用到了一个 objc_msgSend 函数，其函数原型如下
```
void objc_msgSend(id self, SEL cmd, ...);
```
这是一个可变参数的函数，第一个参数代表消息接收者，第二个代表 SEL 类型，后面的参数就是消息传递中使用的参数。

那么什么是 SEL 呢？SEL 就是代码在编译时，编译器根据方法签名来生成的一个唯一 ID。此 ID 可以用以区分不同的方法，只要 ID 一致，即看成同一个方法，ID 不同，即为不同的方法。

当进行消息传递，对象在响应消息时，是通过 SEL 在 methodlist 中查找函数指针 IMP，找到后直接通过指针调用函数，这其实就是前文介绍的 __动态绑定__。若是找到对应函数就跳转到实现代码，若找不到，就沿着继承链往上查找，直到找到相应的实现代码为止。若最终还是没找到实现代码，说明当前对象无法响应此消息，接下来就会执行 __消息转发__ 操作，以试图找到一个能响应此消息的对象。
```
// 获取 SEL 
SEL sel = @selector(methodName);
// 获取 IMP
IMP imp = methodForSelector(sel);
```
## 消息转发
消息转发并不神奇，我们其实早已接触过，只是不知道而已
```
-[__NSCFNumber lowercaseString]:unrecognized selector sent to instance 0x87
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason:'-[NSCFNumber lowercaseString]:unrecognized selector sent to instance 0x87'
```
这段异常代码就是由 NSObject 的 doesNotRecognizeSelector: 方法所抛出的，异常表明：消息的接收者类型为 __NSCFNumber，无法响应 lowercaseString 消息，从而转发给 NSObject 处理。

消息转发分为三大阶段

* 第一阶段先征询消息接收者所属的类，看其是否能动态添加方法，以处理当前这个无法响应的 selector，这叫做 动态方法解析（dynamic method resolution）。如果运行期系统（runtime system） 第一阶段执行结束，接收者就无法再以动态新增方法的手段来响应消息，进入第二阶段。
* 第二阶段看看有没有其他对象（备援接收者，replacement receiver）能处理此消息。如果有，运行期系统会把消息转发给那个对象，转发过程结束；如果没有，则启动完整的消息转发机制。
* 第三阶段 完整的消息转发机制。运行期系统会把与消息有关的全部细节都封装到 NSInvocation 对象中，再给接收者最后一次机会，令其设法解决当前还未处理的消息。

### 动态方法解析
对象在收到无法响应的消息后，会调用其所属类的下列方法
```
/**
 *  如果尚未实现的方法是实例方法，则调用此函数
 *
 *  @param selector 未处理的方法
 *
 *  @return 返回布尔值，表示是否能新增实例方法用以处理selector
 */
+ (BOOL)resolveInstanceMethod:(SEL)selector;
/**
 *  如果尚未实现的方法是类方法，则调用此函数
 *
 *  @param selector 未处理的方法
 *
 *  @return 返回布尔值，表示是否能新增类方法用以处理selector
 */
+ (BOOL)resolveClassMethod:(SEL)selector;
```
方法返回布尔类型，表示是否能新增一个方法来处理 selector，此方案通常用来实现 @dynamic 属性。
```
/************** 使用 resolveInstanceMethod 实现 @dynamic 属性 **************/
id autoDictionaryGetter(id self, SEL _cmd);
void autoDictionarySetter(id self, SEL _cmd, id value);
+ (BOOL)resolveInstanceMethod:(SEL)selector
{
    NSString *selectorString = NSStringFromSelector(selector);
    if (/* selector is from a @dynamic property */)
    {
        if ([selectorString hasPrefix:@"set"])
        {
            // 添加 setter 方法
            class_addMethod(self, selector, (IMP)autoDictionarySetter, "v@:@");
        }
        else
        {
            // 添加 getter 方法
            class_addMethod(self, selector, (IMP)autoDictionaryGetter, "@@:");
        }
        return YES;
    }
    return [super resolveInstanceMethod:selector];
}
```
### 备援接收者
如果无法 __动态解析方法__，运行期系统就会询问是否能将消息转给其他接收者来处理，对应的方法为
```
/**
 *  此方法询问是否能将消息转给其他接收者来处理
 *
 *  @param aSelector 未处理的方法
 *
 *  @return 如果当前接收者能找到备援对象，就将其返回；否则返回nil；
 */
- (id)forwardingTargetForSelector:(SEL)aSelector;
```
在对象内部，可能还有其他对象，该对象可通过此方法将能够处理 selector 的相关内部对象返回，在外界看来，就好像是该对象自己处理的似得。
### 完整的消息转发机制
如果前面两步都无法处理消息，就会启动完整的消息转发机制。首先创建 NSInvocation 对象，把尚未处理的那条消息有关的全部细节装在里面，在触发 NSInvocation 对象时，消息派发系统（message-dispatch system）将会把消息指派给目标对象。对应的方法为
```
/**
 *  消息派发系统通过此方法，将消息派发给目标对象
 *
 *  @param anInvocation 之前创建的NSInvocation实例对象，用于装载有关消息的所有内容
 */
- (void)forwardInvocation:(NSInvocation *)anInvocation;
```
这个方法可以实现的很简单，通过改变调用的目标对象，使得消息在新目标对象上得以调用即可。然而这样实现的效果与 __备援接收者__ 差不多，所以很少人会这么做。更加有用的实现方式为：在触发消息前，先以某种方式改变消息内容，比如追加另一个参数、修改 selector 等等。

## 总结
![](/images/image_note64270_1.png)


-----

*观点仅代表自己，期待你的留言。*
https://www.zybuluo.com/MicroCai/note/64270

