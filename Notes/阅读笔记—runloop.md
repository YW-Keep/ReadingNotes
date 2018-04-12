##阅读笔记 — RunLoop
###1.什么是runloop，它和线程又有什么关系？
一个线程往往执行一个任务，执行完后线程就退出了，我们需要一个机制能做到线程随时能处理事件但是不退出。这种模型通常被称作Event Loop，在OSX/iOS也就是RunLoop。
**其实runloop就是一个管理处理事件和消息的对象**，原理也很简单就是一个while循环而已。当然实现还有很多其他的考量。内部主要的循环就是 接受消息->等待->处理。
OSX/iOS 提供2个对象 NSRunLoop 和CFRunLoopRef，NSRunLoop是CFRunLoopRef的分装，提供了面向对象的API不是线程安全的。而CFRunLoopRef纯C函数的API是线程安全的。
线程与runloop是一一对应的关系，从之前的runloop中也可以解释的通，但是要注意线程创建后不会自动创建runloop只有你通过CFRunLoopGetMain()与CFRunLoopGetCurrent()函数获取。当调用该函数就会自动创建runloop，当线程销毁时runloop销毁，除主线程外，其他线程只能在其内部获取其RunLoop。
###2.runloop实现主要有哪几个类，分别有什么用处
在CoreFoundation中主要有五个类：
CFRunLoopRef
CFRunLoopModeRef
CFRunLoopSourceRef
CFRunLoopTimerRef
CFRunLoopObserverRef
在这里可以把这五个类分为三层：CFRunLoopRef 最外层主类，CFRunLoopModeRef内层，CFRunLoopSourceRef、CFRunLoopTimerRef、CFRunLoopObserverRef 最内层。
这里有一句话可以概括他们的关系**一个RunLoop只能在一个时间跑一个model(可以有多个)，每个model下面有多个source、timer、observer任务（mode item）**
####CFRunLoopModeRef
model种类很多，不同的model功能也不相同，很多我们平时也遇不到主要有下面几种
kCFRunLoopDefaultMode: App的默认 Mode，通常主线程是在这个 Mode 下运行的。
UITrackingRunLoopMode: 界面跟踪 Mode，用于 ScrollView 追踪触摸滑动，保证界面滑动时不受其他 Mode 影响。
kCFRunLoopCommonModes: 其实是一个占位的model，可以理解为复合model
####CFRunLoopSourceRef
