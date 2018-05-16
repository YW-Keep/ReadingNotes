## runtime

Runtime 又叫运行时，是一套底层的 C 语言 API，是 iOS 系统的核心之一。开发者在编码过程中，可以给任意一个对象发送消息，在编译阶段只是确定了要向接收者发送这条消息，而接受者将要如何响应和处理这条消息，那就要看运行时来决定了。

C语言中，在编译期，函数的调用就会决定调用哪个函数。
 而OC的函数，属于动态调用过程，在编译期并不能决定真正调用哪个函数，只有在真正运行时才会根据函数的名称找到对应的函数来调用。

Objective-C 是一个动态语言，这意味着它不仅需要一个编译器，也需要一个运行时系统来动态得创建类和对象、进行消息传递和转发。

 Objc 在三种层面上与 Runtime 系统进行交互：

1.通过 Objective-C 源代码

2.通过 Foundation 框架的 NSObject 类定义的方法

在NSObject协议中，有以下5个方法，是可以从Runtime中获取信息，让对象进行自我检查。

```swift
- (Class)class OBJC_SWIFT_UNAVAILABLE("use 'anObject.dynamicType' instead");
- (BOOL)isKindOfClass:(Class)aClass;
- (BOOL)isMemberOfClass:(Class)aClass;
- (BOOL)conformsToProtocol:(Protocol *)aProtocol;
- (BOOL)respondsToSelector:(SEL)aSelector;
```

3.通过对 Runtime 库函数的直接

####  NSObject

首先Objective-C是个面向对象编程（OOP）的语言 。其实它的组成就是**C + Objc编译器 + runtime** C就是C语言，编译器也没什么好说的，还有就是runtime,就是因为runtime，Objective-C才成为一门动态语言。那么什么是runtimene ? 其实核心就是动态消息派发机制。 那这里就要主要讨论下下面2个话题

1.runtime是如何建立起**支持Objc语言的数据结构**

2.runtime如何建立起**消息机制**

对象(内存)和消息（函数）在协议下工作。

isa指针是OOP下runtime消息机制的协议，只要首地址是isa指针，就能给你发消息。 (对象发送一个消息，需要找到这个消息，去哪里找?用isa指针指向的地方去找)

对象的实例方法调用时，通过对象的 isa 在类中获取方法的实现。

类对象的类方法调用时，通过类的 isa 在元类中获取方法的实现。

NSObject 是如何创建的：

![](https://raw.githubusercontent.com/YW-Keep/ReadingNotes/master/image/runtime/171526366340_.pic.jpg)

这就是创建的精简版本，其中instanceSize编译时就决定了。（其实从这里我们也大概能看出为什么分类不能加属性了，这里大小都定了）

那么接下来会有个问题，那就是为什么变量不需要手动设置0/nil，其实在calloc()方法为我们连续分配足够的空间，以计数对象大小字节的内存，并返回分配内存的指针。 非配的空间默认设置了0。

好了 那么我们画图了解下其内存存放的样子。

![](https://raw.githubusercontent.com/YW-Keep/ReadingNotes/master/image/runtime/181526372024_.pic.jpg)

所以类方法与对象方法是统一的，一个类(Class)当然发消息的时候（调用类方法的时候）就是一个实例变量，而当它未发送消息的时候是一个type。

这里就有人要问了，那类的实现到底是怎么样的：



那么问题来了，消息怎么发的呢（方法调用） 其实[obj foo] 会被编译成objc_msgSend(obj,"foo")。

这里可以额外提一句其实self 是一个隐藏参数，指向当前的对象或者类，而super并不是，它只是一个编译器指示符，也就是说super 与self的消息接受者其实是同一个。