## 阅读笔记 — RunLoop
### 1.什么是runloop，它和线程又有什么关系？
一个线程往往执行一个任务，执行完后线程就退出了，我们需要一个机制能做到线程随时能处理事件但是不退出。这种模型通常被称作Event Loop，在OSX/iOS也就是RunLoop。
**其实runloop就是一个管理处理事件和消息的对象**，原理也很简单就是一个while循环而已。当然实现还有很多其他的考量。内部主要的循环就是 接受消息->等待->处理。
OSX/iOS 提供2个对象 NSRunLoop 和CFRunLoopRef，NSRunLoop是CFRunLoopRef的分装，提供了面向对象的API不是线程安全的。而CFRunLoopRef纯C函数的API是线程安全的。
线程与runloop是一一对应的关系，从之前的runloop中也可以解释的通，但是要注意线程创建后不会自动创建runloop只有你通过CFRunLoopGetMain()与CFRunLoopGetCurrent()函数获取。当调用该函数就会自动创建runloop，当线程销毁时runloop销毁，除主线程外，其他线程只能在其内部获取其RunLoop。
### 2.runloop实现主要有哪几个类，分别有什么用处
在CoreFoundation中主要有五个类：
CFRunLoopRef
CFRunLoopModeRef
CFRunLoopSourceRef
CFRunLoopTimerRef
CFRunLoopObserverRef
在这里可以把这五个类分为三层：CFRunLoopRef 最外层主类，CFRunLoopModeRef内层，CFRunLoopSourceRef、CFRunLoopTimerRef、CFRunLoopObserverRef 最内层。
这里有一句话可以概括他们的关系**一个RunLoop只能在一个时间跑一个model(可以有多个)，每个model下面有多个source、timer、observer任务（mode item）**
#### CFRunLoopModeRef
model种类很多，不同的model功能也不相同，很多我们平时也遇不到主要有下面几种
kCFRunLoopDefaultMode: App的默认 Mode，通常主线程是在这个 Mode 下运行的。
UITrackingRunLoopMode: 界面跟踪 Mode，用于 ScrollView 追踪触摸滑动，保证界面滑动时不受其他 Mode 影响。
kCFRunLoopCommonModes: 其实是一个占位的model，可以理解为复合model
#### CFRunLoopSourceRef

顾名思义，这是一个事件产生的地方。Source主要有2个：

1.scource0 只包含一个指针回调，所以它不能唤醒runLoop,当然你可以手动唤醒RunLoop(CFRunLoopWakeUp(runloop)方法)

2.scource1 不但包含一个指针回调，还包含一个mach_port,mach_port可以通过内核间的通讯获取消息，从而主动唤起RunLoop。

而指针回调就是处理事情的回调。

#### CFRunLoopTimerRef

这个是时间触发器，可以与NSTimer完美桥接，它主要包含一个时长与一个回调的函数指针，当加入到runloop中时，runloop会注册对应的时间，时间到了runloop会被唤醒执行那个回调。

#### CFRunLoopObserverRef

它其实就是一个事件的观察者。主要的事件有下面几种

```c
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
    kCFRunLoopEntry         = (1UL << 0), // 即将进入Loop
    kCFRunLoopBeforeTimers  = (1UL << 1), // 即将处理 Timer
    kCFRunLoopBeforeSources = (1UL << 2), // 即将处理 Source
    kCFRunLoopBeforeWaiting = (1UL << 5), // 即将进入休眠
    kCFRunLoopAfterWaiting  = (1UL << 6), // 刚从休眠中唤醒
    kCFRunLoopExit          = (1UL << 7), // 即将退出Loop
};
```

### 3.runloop内部逻辑是怎么样的

![RunLoop_1](https://raw.githubusercontent.com/YW-Keep/ReadingNotes/master/image/RunLoop/RunLoop_1.png)

这张图就能比较直观的看到runloop的整个过程。因为整个代码是C写的这里就不贴了。想看的可以在[这里下载](https://opensource.apple.com/tarballs/CF/)

### runloop内部是怎么实现的？

由上面的图可以看出，其主要的问题是在7,就是runloop是怎么休眠，又是怎么被唤醒的。其实主要是通过Mach层来实现的。Mach层是最底层的架构，是XNU内核的内环，其作为一个微内核，仅提供如处理器调度、IPC (进程间通信)等非常少量的基础服务。

“消息”是Mach中最基础的概念，消息在两个端口之间传递（之前提到过soucre1是有个mach port 的），这就是Mach 的IPC(进程间通信)的核心。

为了实现消息的发送和接收，mach_msg() 函数实际上是调用了一个 Mach 陷阱 (trap)，即函数mach_msg_trap()，陷阱这个概念在 Mach 中等同于系统调用。当你在用户态调用 mach_msg_trap() 时会触发陷阱机制，切换到内核态；内核态中内核实现的 mach_msg() 函数会完成实际的工作，如下图：