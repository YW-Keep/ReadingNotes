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



首先Objective-C是个面向对象编程（OOP）的语言 。其实它的组成就是**C + Objc编译器 + runtime** C就是C语言，编译器也没什么好说的，还有就是runtime,就是因为runtime，Objective-C才成为一门动态语言。那么什么是runtimene ? 其实核心就是动态消息派发机制。 那这里就要主要讨论下下面2个话题

1.runtime是如何建立起**支持Objc语言的数据结构**

2.runtime如何建立起**消息机制**

### NSObject

首先我们想一想类与消息是怎么工作的，想了想 是不是一脸懵逼，没关系我们先看看源码中的类是什么样子的：

![](https://raw.githubusercontent.com/YW-Keep/ReadingNotes/master/image/runtime/%E7%B1%BB%E7%9A%84%E7%BB%A7%E6%89%BF%E5%85%B3%E7%B3%BB.jpg)

![](https://raw.githubusercontent.com/YW-Keep/ReadingNotes/master/image/runtime/%E7%B1%BB%E7%9A%84%E5%86%85%E9%83%A8%E7%BB%86%E8%8A%82.jpg)



看完是不是一脸懵逼，就对了，不过我们可以看到一个很明显的是我们有一个isa指针，他最后需要指向一个class的。

到这里，我们在思考一个问题：你觉得你调用的方法存在哪里？比如你创建一个对象，你需要调用的方法需要全部拷贝一份存起来么？

如果真的是这样，那我们创建N个对象，是不是要复制N份所有的方法存起来？但是这方法都是一样的呀，显然有极大的浪费。那最好的方式是什么？当然是有个地方，存了所有的方法，大家都指向它就好咯。

其实上面的isa 就是这么一个指针，可以指向一块区域，而这块区域就是存放所有的方法。

从上面的结构图中可以看出来方法只有一个属性，那么你就会问那怎么区分类方法与对象方法呢。

其实从isa指针上你就可以看出来其实，**类就是一个对象**，而类中的isa呢指向一个元类（可以理解为类的类= =比较拗口，其实它也是个对象。）那么一切就能解释的通了。

**对象的实例方法调用时，通过对象的 isa 在类中获取方法的实现。**

**类对象的类方法调用时，通过类的 isa 在元类中获取方法的实现。**

类方法与对象方法是统一的，一个类(Class)当发消息的时候（调用类方法的时候）就是一个实例变量，而当它未发送消息的时候是一个type。

对象(内存)和消息（函数）在协议下工作。

isa指针是OOP下runtime消息机制的协议，只要首地址是isa指针，就能给你发消息。 (对象发送一个消息，需要找到这个消息，去哪里找?用isa指针指向的地方去找)

这里有一张非常火的superclass 与isa 指向的图：

![](https://raw.githubusercontent.com/YW-Keep/ReadingNotes/master/image/runtime/superclass%E4%B8%8Eisa.png)

那么继续探究下一个问题NSObject 是如何创建的：

![](https://raw.githubusercontent.com/YW-Keep/ReadingNotes/master/image/runtime/%E5%88%9B%E5%BB%BA%E6%96%B9%E6%B3%95%E5%86%85%E9%83%A8.jpg)

这就是创建的精简版本，其中instanceSize编译时就决定了。（其实从这里我们也大概能看出为什么分类不能加属性了，这里大小都定了）

那么接下来会有个问题，那就是为什么变量不需要手动设置0/nil，其实在calloc()方法为我们连续分配足够的空间，以计数对象大小字节的内存，并返回分配内存的指针。 非配的空间默认设置了0。

好了总上所属，我们画图了解下其内存存放的样子。

![](https://raw.githubusercontent.com/YW-Keep/ReadingNotes/master/image/runtime/%E5%86%85%E5%AD%98%E5%AD%98%E6%94%BE%E5%85%B3%E7%B3%BB.jpg)

图中有2个对象person1与person2,他们内存中的大概是 对象内存里描绘的样子的。这里可能有人会问为什么下面是一个个个ivar。

首先第一个问题  对象内存里有方法吗？显然看是没有的，那有什么？实例变量。那肯定只能这么放了呀。

那么对象到底是什么？

```objective-c
//Objc的对象是一个指向ClassObject地址的变量
id obj = &ClassObject
// 而对象的实例变量 对象的地址加偏移量而已
void *ivar = &obj +offset(N)
```



那么问题来了，消息怎么发的呢（方法调用） 其实[obj foo] 会被编译成objc_msgSend(obj,"foo")。

这里可以额外提一句其实self 是一个隐藏参数，指向当前的对象或者类，而super并不是，它只是一个编译器指示符，也就是说super 与self的消息接受者其实是同一个。

### 消息的发送与转发



### 问题集

##### 1.分类为什么可以加方法不能加属性？

从上面的类的结构体中可以看到方法列表是在wr上，也就是可以读写，而属性列表在ro中就是只读的。所以分类是不可以加属性的。（其实从class中ro中的instanceSize就可以知道了，instanceSize在编译器确定，实例变量存储肯定需要要内存的。所以不可增加）

##### 2.为什么分类加方法会覆盖之前的方法？

其实方法是链表的方式存储的，从头加入从头开始遍历，所以后加入的会被覆盖。

##### 3.super和self

下面代码输出什么：

```objective-c
@interface Man : Person

@end

@implementation Man

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSLog(@"1.%@",[self class]);
        NSLog(@"2.%@",[super class]);
    }
    return self;
}

@end
//1.Man
//2.Man
```

其实super只是一个编译器指令，让我们看看看self 调用与super调用有啥区别：

```C++
// 这个是self 调用转化的
objc_msgSend(id _Nullable self, SEL _Nonnull op, ...)
    OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0, 2.0);
// 这个是super调用转化的
objc_msgSendSuper(struct objc_super * _Nonnull super, SEL _Nonnull op, ...)
    OBJC_AVAILABLE(10.0, 2.0, 9.0, 1.0, 2.0);

struct objc_super {
    id receiver;
    Class current_class;
};
```

其实从上面可以看出，当你用super调用时候其实编译器帮你打包一个self 加一个classe而已，在找的时候会先在superclass中找方法然后用，self去调用罢了。

##### 4.NSObject

下面代码会发什么？

```objective-c
@interface NSObject (DoSomething)

+ (void) doThings1;
- (void) doThings2;

@end

@implementation NSObject (DoSomething)

- (void) doThings1 {
    NSLog(@"1");
}
+ (void) doThings2 {
    NSLog(@"2");
}

@end

[NSObject doThings1];
[[NSObject new] doThings2];
```

答案是输出1 ，然后崩溃。

首先从上面的isa 与superclass图中我们可以看到NSObject类元的super 其实是他的类对象。所以第一个可以执行成功。

但是第二个，找不到实现方法，所以崩溃了。

这里可以再深入的讲下如果你用NSObject 调用copy 是可以调用的，返回的是本身，而valueForKey:也是可以调用的，但是会崩溃。

其实他很多NSObject的类方法，同样的方法名实现了对象方法（一般处理为奔溃），防止你绕过去。为什么这么设计？猜测是它有些方法可能要类和对象都能用吧，不太清楚。

##### 5.isa

下面代码的值是多少：

```objective-c
    BOOL res1 = [[NSObject class] isMemberOfClass:[NSObject class]];
    BOOL res2 = [[NSObject class] isKindOfClass:[NSObject class]];
    BOOL res3 = [[Person class] isMemberOfClass:[Person class]];
    BOOL res4 = [[Person class] isKindOfClass:[Person class]];
```

应该是NO,YES,NO,NO

看上面那张的isa 与superclass图就能得到答案。

##### 6.地址

下面代码输出什么：

```objective-c
@interface Person : NSObject

@property (nonatomic, strong) NSString *name;

- (void)tellName;

@end

@implementation Person

- (void)tellName {
    NSLog(@"my name is %@",self.name);
}

@end

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *hello = @"hello";
    Class cls  = [Person class];
    void *obj = &cls;
    [(__bridge id)obj tellName];

}
```

答案是 输出 my name is hello，如果删除NSString *hello = @"hello"; 输出 my name is <ViewController: 0x7f9317f0d660>。

原因：看上面的对象本质。ps:内存是堆存放的。

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];
    // super 会生成结构体 第一个是self  第二个是self.class 所以返回控制器了 super内容见上面
    Class cls  = [Person class];
    void *obj = &cls;
    [(__bridge id)obj tellName];

}
```

#####  5.runtime 如何实现 weak 变量的自动置nil？

##### @property 的本质是什么？

