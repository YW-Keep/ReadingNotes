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

### 4.runloop内部是怎么实现的？

由上面的图可以看出，其主要的问题是在7,就是runloop是怎么休眠，又是怎么被唤醒的。其实主要是通过Mach层来实现的。Mach层是最底层的架构，是XNU内核的内环，其作为一个微内核，仅提供如处理器调度、IPC (进程间通信)等非常少量的基础服务。

“消息”是Mach中最基础的概念，消息在两个端口之间传递（之前提到过soucre1是有个mach port 的），这就是Mach 的IPC(进程间通信)的核心。

为了实现消息的发送和接收，mach_msg() 函数实际上是调用了一个 Mach 陷阱 (trap)，即函数mach_msg_trap()，陷阱这个概念在 Mach 中等同于系统调用。当你在用户态调用 mach_msg_trap() 时会触发陷阱机制，切换到内核态；内核态中内核实现的 mach_msg() 函数会完成实际的工作，如下图：![RunLoop_2](https://raw.githubusercontent.com/YW-Keep/ReadingNotes/master/image/RunLoop/RunLoop_2.png)

至于睡眠，其实也类似，发送一个消息（其实就是 调用mach_msg()函数去等待接收消息），让内核切换线程处理。如果没有别人发送 port 消息过来，内核会将线程置于等待状态。例如你在模拟器里跑起一个 iOS 的 App，然后在 App 静止时点击暂停，你会看到主线程调用栈是停留在 mach_msg_trap() 这个地方。

### 5.runloop与autoreleasePool有啥关系？

在APP启动后，苹果就在主线程RunLoop里注册了2个observe，回调都是_wrapRunLoopWithAutoreleasePoolHandler，其中一个是监听Entry（即将进入Loop）,其回调会创建自动释放池，其 order 是-2147483647，优先级最高，保证创建释放池发生在其他所有回调之前，第二个 Observer 监视了两个事件： BeforeWaiting(准备进入休眠) 时调用_objc_autoreleasePoolPop() 和 _objc_autoreleasePoolPush() 释放旧的池并创建新池；Exit(即将退出Loop) 时调用 _objc_autoreleasePoolPop() 来释放自动释放池。这个 Observer 的 order 是 2147483647，优先级最低，保证其释放池子发生在其他所有回调之后。

所以在主线程执行的代码，都会被RunLoop 创建好的 AutoreleasePool 环绕着，所以不会出现内存泄漏，开发者也不必显示创建 Pool 了。(看代码你会发现，新版本确实有AutoreleasePool这个东西，但是为了兼容其他系统已经不是这么实现了。)

### 6.RunLoop与事件响应有什么关系？

苹果注册了一个 Source1 (基于 mach port 的) 用来接收系统事件，其回调函数为 __IOHIDEventSystemClientQueueCallback()。

首先由 IOKit.framework 生成一个 IOHIDEvent 事件并由 SpringBoard 接收,随后用 mach port 转发给需要的App进程。随后苹果注册的那个 Source1 就会触发回调，并调用 _UIApplicationHandleEventQueue() 进行应用内部的分发。

_UIApplicationHandleEventQueue() 会把 IOHIDEvent 处理并包装成 UIEvent 进行处理或分发。

这里就回唤醒响应的RunLoop 进行处理了，最经典的按钮点击。

### 7.RunLoop与手势识别有什么关系？

当上面的 _UIApplicationHandleEventQueue() 识别了一个手势时，其首先会调用 Cancel 将当前的 touchesBegin/Move/End 系列回调打断。随后系统将对应的 UIGestureRecognizer 标记为待处理。

**苹果注册了一个 Observer 监测 BeforeWaiting (Loop即将进入休眠) 事件**，这个Observer的回调函数是 _UIGestureRecognizerUpdateObserver()，其内部会获取所有刚被标记为待处理的 GestureRecognizer，并执行GestureRecognizer的回调。

当有 UIGestureRecognizer 的变化(创建/销毁/状态改变)时，这个回调都会进行相应处理。

### 8.RunLoop与界面更新有啥关系？

当在操作 UI 时，比如改变了 Frame、更新了 UIView/CALayer 的层次时，或者手动调用了 UIView/CALayer 的 setNeedsLayout/setNeedsDisplay方法后，这个 UIView/CALayer 就被标记为待处理，并被提交到一个全局的容器去。

**苹果注册了一个 Observer 监听 BeforeWaiting(即将进入休眠) 和 Exit (即将退出Loop) 事件**，回调去执行一个很长的函数：
_ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv()。这个函数里会遍历所有待处理的 UIView/CAlayer 以执行实际的绘制和调整，并更新 UI 界面。

### 9.RunLoop与NSTimer、PerformSelector有啥关系？

NSTimer 其实就是 CFRunLoopTimerRef，他们之间是 toll-free bridged 的。一个 NSTimer 注册到 RunLoop 后，RunLoop 会为其重复的时间点注册好事件。

CADisplayLink 是一个和屏幕刷新率一致的定时器（但实际实现原理更复杂，和 NSTimer 并不一样，其内部实际是操作了一个 Source）

当调用 NSObject 的 performSelecter:afterDelay: 后，实际上其内部会创建一个 Timer 并添加到当前线程的 RunLoop 中。所以如果当前线程没有 RunLoop，则这个方法会失效。

### 10.RunLoop与GCD有啥关系

协作关系吧，  GCD 提供的某些接口也用到了 RunLoop， 例如 dispatch_async()。

当调用 dispatch_async(dispatch_get_main_queue(), block) 时，libDispatch 会向主线程的 RunLoop 发送消息，RunLoop会被唤醒，并从消息中取得这个 block，并在回调 __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__() 里执行这个 block。但这个逻辑仅限于 dispatch 到主线程，dispatch 到其他线程仍然是由 libDispatch 处理的。

### 11.RunLoop与NSURLConnection有啥关系

通常使用 NSURLConnection 时，你会传入一个 Delegate，当调用了 [connection start] 后，这个 Delegate 就会不停收到事件回调。实际上，start 这个函数的内部会会获取 CurrentRunLoop，然后在其中的 DefaultMode 添加了4个 Source0 (即需要手动触发的Source)。CFMultiplexerSource 是负责各种 Delegate 回调的，CFHTTPCookieStorage 是处理各种 Cookie 的。

当开始网络传输时，我们可以看到 NSURLConnection 创建了两个新线程：com.apple.NSURLConnectionLoader 和 com.apple.CFSocket.private。其中 CFSocket 线程是处理底层 socket 连接的。NSURLConnectionLoader 这个线程内部会使用 RunLoop 来接收底层 socket 的事件，并通过之前添加的 Source0 通知到上层的 Delegate。

NSURLConnectionLoader 中的 RunLoop 通过一些基于 mach port 的 Source 接收来自底层 CFSocket 的通知。当收到通知后，其会在合适的时机向 CFMultiplexerSource 等 Source0 发送通知，同时唤醒 Delegate 线程的 RunLoop 来让其处理这些通知。CFMultiplexerSource 会在 Delegate 线程的 RunLoop 对 Delegate 执行实际的回调。

![RunLoop_network](/Users/tang/Desktop/ReadingNotes/image/RunLoop/RunLoop_network.png)

 ### 12.RunLoop平时有哪些应用

1.滑动时候修改model类型，从来可以在滑动时计时器也正常。

2.AFNetWorking,新启了一个线程，然后加入一个NSMachPort（通常情况下，调用者需要持有这个 NSMachPort (mach_port) 并在外部线程通过这个 port 发送消息到 loop 内），防止其退出。之后需要这个线程时，只需要通过调用 [NSObject performSelector:onThread:..] 将这个任务扔到了后台线程的 RunLoop 中。

Tips: Mach 已经是基本最底层的框架了，本身提供的API也十分有限，而且苹果也不鼓励。在 Mach 中，所有的东西都是通过自己的对象实现的，进程、线程和虚拟内存都被称为”对象”。和其他架构不同， Mach 的对象间不能直接调用，只能通过消息传递的方式实现对象间的通信。”消息”是 Mach 中最基础的概念，消息在两个端口 (port) 之间传递，这就是 Mach 的 IPC (进程间通信) 的核心。可以扩展