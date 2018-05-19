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

前面简短的提到过转发这里细致的看下：

```	C
objc_msgSend(id _Nullable self, SEL _Nonnull op, ...)

/// An opaque type that represents a method selector.
typedef struct objc_selector *SEL;

/// A pointer to the function of a method implementation. 
#if !OBJC_OLD_DISPATCH_PROTOTYPES
typedef void (*IMP)(void /* id, SEL, ... */ ); 
#else
typedef id _Nullable (*IMP)(id _Nonnull, SEL _Nonnull, ...); 
#endif

struct method_t {
    SEL name;
    const char *types;
    IMP imp;

    struct SortBySELAddress :
        public std::binary_function<const method_t&,
                                    const method_t&, bool>
    {
        bool operator() (const method_t& lhs,
                         const method_t& rhs)
        { return lhs.name < rhs.name; }
    };
};
```

从源码中我们可以看到发送消息的方法，这是一个可变参数函数（原因很简单，入参可能是多个。）

第一个参数是receiver,也就是接受对象。

第二个参数类型是SEL。SEL在OC中是selector方法选择器。objc_selector是一个映射到方法的C字符串。需要注意的是@selector()选择子**只与函数名有关**。

最后的可变参数就是可变的入参了。

在receiver拿到对应的selector之后，如果自己无法执行这个方法，那么该条消息要被转发。或者临时动态的添加方法实现。如果转发到最后依旧没法处理，程序就会崩溃。

**所以编译期仅仅是确定了要发送消息，而消息如何处理是要运行期需要解决的事情。**

那么问题来了objc_msgSend到底干了什么呢？[「objc_msgSend() Tour」](http://www.friday.com/bbum/2009/12/18/objc_msgsend-part-1-the-road-map/)这篇文章里有一个比较详细的结论：

1.检查这个selector是不是要忽略。

2.检查nil（如果配置了nil的处理程序就跳转到处理程序，没有就返回）

3.搜索方法（先在缓存中找，如果找到了就跳转，如果没找到则到类的方法中，顺序查找，如果找到则加入到缓存并跳转，如果没找到则启动转发机制。） 到这里objc_msgSend就完成了。

细看下源代码：

```SAS
/********************************************************************
 *
 * id objc_msgSend(id self, SEL	_cmd,...);
 * IMP objc_msgLookup(id self, SEL _cmd, ...);
 *
 * objc_msgLookup ABI:
 * IMP returned in r11
 * Forwarding returned in Z flag
 * r10 reserved for our use but not used
 *
 ********************************************************************/
	
	.data
	.align 3
	.globl _objc_debug_taggedpointer_classes
_objc_debug_taggedpointer_classes:
	.fill 16, 8, 0
	.globl _objc_debug_taggedpointer_ext_classes
_objc_debug_taggedpointer_ext_classes:
	.fill 256, 8, 0

	ENTRY _objc_msgSend
	UNWIND _objc_msgSend, NoFrame
	MESSENGER_START

	NilTest	NORMAL   // nil 校验

	GetIsaFast NORMAL		// r10 = self->isa
	CacheLookup NORMAL, CALL	// calls IMP on success  // 查缓存

	NilTestReturnZero NORMAL

	GetIsaSupport NORMAL

// cache miss: go search the method lists
LCacheMiss:
	// isa still in r10
	MESSENGER_END_SLOW
	jmp	__objc_msgSend_uncached   // 跳这里了。

	END_ENTRY _objc_msgSend

	
	ENTRY _objc_msgLookup 

	NilTest	NORMAL

	GetIsaFast NORMAL		// r10 = self->isa
	CacheLookup NORMAL, LOOKUP	// returns IMP on success

	NilTestReturnIMP NORMAL

	GetIsaSupport NORMAL

// cache miss: go search the method lists
LCacheMiss:
	// isa still in r10
	jmp	__objc_msgLookup_uncached

	END_ENTRY _objc_msgLookup

	
	ENTRY _objc_msgSend_fixup
	int3
	END_ENTRY _objc_msgSend_fixup

	
	STATIC_ENTRY _objc_msgSend_fixedup
	// Load _cmd from the message_ref
	movq	8(%a2), %a2
	jmp	_objc_msgSend
	END_ENTRY _objc_msgSend_fixedup

```

```SAS
/********************************************************************
 *
 * _objc_msgSend_uncached
 * _objc_msgSend_stret_uncached
 * _objc_msgLookup_uncached
 * _objc_msgLookup_stret_uncached
 *
 * The uncached method lookup.
 *
 ********************************************************************/

	STATIC_ENTRY __objc_msgSend_uncached
	UNWIND __objc_msgSend_uncached, FrameWithNoSaves
	
	// THIS IS NOT A CALLABLE C FUNCTION
	// Out-of-band r10 is the searched class

	// r10 is already the class to search
	MethodTableLookup NORMAL	// r11 = IMP  // 这个方法去搜索了
	jmp	*%r11			// goto *imp

	END_ENTRY __objc_msgSend_uncached

	
	STATIC_ENTRY __objc_msgSend_stret_uncached
	UNWIND __objc_msgSend_stret_uncached, FrameWithNoSaves
	
	// THIS IS NOT A CALLABLE C FUNCTION
	// Out-of-band r10 is the searched class

	// r10 is already the class to search
	MethodTableLookup STRET		// r11 = IMP
	jmp	*%r11			// goto *imp

	END_ENTRY __objc_msgSend_stret_uncached

	
	STATIC_ENTRY __objc_msgLookup_uncached
	UNWIND __objc_msgLookup_uncached, FrameWithNoSaves
	
	// THIS IS NOT A CALLABLE C FUNCTION
	// Out-of-band r10 is the searched class

	// r10 is already the class to search
	MethodTableLookup NORMAL	// r11 = IMP
	ret

	END_ENTRY __objc_msgLookup_uncached

	
	STATIC_ENTRY __objc_msgLookup_stret_uncached
	UNWIND __objc_msgLookup_stret_uncached, FrameWithNoSaves
	
	// THIS IS NOT A CALLABLE C FUNCTION
	// Out-of-band r10 is the searched class

	// r10 is already the class to search
	MethodTableLookup STRET		// r11 = IMP
	ret

	END_ENTRY __objc_msgLookup_stret_uncached

```

```SAS
/////////////////////////////////////////////////////////////////////
//
// MethodTableLookup NORMAL|STRET
//
// Takes:	a1 or a2 (STRET) = receiver
//		a2 or a3 (STRET) = selector to search for
// 		r10 = class to search
//
// On exit: imp in %r11, eq/ne set for forwarding
//
/////////////////////////////////////////////////////////////////////

.macro MethodTableLookup

	push	%rbp
	mov	%rsp, %rbp
	
	sub	$$0x80+8, %rsp		// +8 for alignment

	movdqa	%xmm0, -0x80(%rbp)
	push	%rax			// might be xmm parameter count
	movdqa	%xmm1, -0x70(%rbp)
	push	%a1
	movdqa	%xmm2, -0x60(%rbp)
	push	%a2
	movdqa	%xmm3, -0x50(%rbp)
	push	%a3
	movdqa	%xmm4, -0x40(%rbp)
	push	%a4
	movdqa	%xmm5, -0x30(%rbp)
	push	%a5
	movdqa	%xmm6, -0x20(%rbp)
	push	%a6
	movdqa	%xmm7, -0x10(%rbp)

	// _class_lookupMethodAndLoadCache3(receiver, selector, class)

.if $0 == NORMAL
	// receiver already in a1
	// selector already in a2
.else
	movq	%a2, %a1
	movq	%a3, %a2
.endif
	movq	%r10, %a3
	call	__class_lookupMethodAndLoadCache3

	// IMP is now in %rax
	movq	%rax, %r11

	movdqa	-0x80(%rbp), %xmm0
	pop	%a6
	movdqa	-0x70(%rbp), %xmm1
	pop	%a5
	movdqa	-0x60(%rbp), %xmm2
	pop	%a4
	movdqa	-0x50(%rbp), %xmm3
	pop	%a3
	movdqa	-0x40(%rbp), %xmm4
	pop	%a2
	movdqa	-0x30(%rbp), %xmm5
	pop	%a1
	movdqa	-0x20(%rbp), %xmm6
	pop	%rax
	movdqa	-0x10(%rbp), %xmm7

.if $0 == NORMAL
	cmp	%r11, %r11		// set eq for nonstret forwarding
.else
	test	%r11, %r11		// set ne for stret forwarding
.endif
	
	leave

.endmacro

```

```C
// 核心查找方法
IMP _class_lookupMethodAndLoadCache3(id obj, SEL sel, Class cls)
{
    return lookUpImpOrForward(cls, sel, obj, 
                              YES/*initialize*/, NO/*cache*/, YES/*resolver*/);
}

```

```C
IMP lookUpImpOrForward(Class cls, SEL sel, id inst, 
                       bool initialize, bool cache, bool resolver)
{
    IMP imp = nil;
    bool triedResolver = NO;

    runtimeLock.assertUnlocked();

    // Optimistic cache lookup  先在缓存查找了
    if (cache) {
        imp = cache_getImp(cls, sel);
        if (imp) return imp;
    }

    // runtimeLock is held during isRealized and isInitialized checking
    // to prevent races against concurrent realization.

    // runtimeLock is held during method search to make
    // method-lookup + cache-fill atomic with respect to method addition.
    // Otherwise, a category could be added but ignored indefinitely because
    // the cache was re-filled with the old value after the cache flush on
    // behalf of the category.

    runtimeLock.read();

    if (!cls->isRealized()) {
        // Drop the read-lock and acquire the write-lock.
        // realizeClass() checks isRealized() again to prevent
        // a race while the lock is down.
        runtimeLock.unlockRead();
        runtimeLock.write();

        realizeClass(cls);

        runtimeLock.unlockWrite();
        runtimeLock.read();
    }

    if (initialize  &&  !cls->isInitialized()) {
        runtimeLock.unlockRead();
        _class_initialize (_class_getNonMetaClass(cls, inst));
        runtimeLock.read();
        // If sel == initialize, _class_initialize will send +initialize and 
        // then the messenger will send +initialize again after this 
        // procedure finishes. Of course, if this is not being called 
        // from the messenger then it won't happen. 2778172
    }

    
 retry:    
    runtimeLock.assertReading();

    // Try this class's cache.  在类的缓存中找
    
    imp = cache_getImp(cls, sel);
    if (imp) goto done;

    // Try this class's method lists. 在本类的方法中找
    {
        Method meth = getMethodNoSuper_nolock(cls, sel);
        if (meth) {
            log_and_fill_cache(cls, meth->imp, sel, inst, cls);
            imp = meth->imp;
            goto done;
        }
    }

    // Try superclass caches and method lists.  // 父类的方法列表中找
    {
        unsigned attempts = unreasonableClassCount();
        for (Class curClass = cls->superclass;
             curClass != nil;
             curClass = curClass->superclass)
        {
            // Halt if there is a cycle in the superclass chain.
            if (--attempts == 0) {
                _objc_fatal("Memory corruption in class list.");
            }
            
            // Superclass cache. 超类缓存
            imp = cache_getImp(curClass, sel);
            if (imp) {
                if (imp != (IMP)_objc_msgForward_impcache) {
                    // Found the method in a superclass. Cache it in this class.
                    log_and_fill_cache(cls, imp, sel, inst, curClass);
                    goto done;
                }
                else {
                    // Found a forward:: entry in a superclass.
                    // Stop searching, but don't cache yet; call method 
                    // resolver for this class first.
                    break;
                }
            }
            
            // Superclass method list.超类方法列表
            Method meth = getMethodNoSuper_nolock(curClass, sel);
            if (meth) {
                log_and_fill_cache(cls, meth->imp, sel, inst, curClass);
                imp = meth->imp;
                goto done;
            }
        }
    }

    // No implementation found. Try method resolver once.  //都找不到 尝试_class_resolveMethod方法。注意，这些需要打开读锁，因为开发者可能会在这里动态增加方法实现，所以不需要缓存结果。然后因为增加了方法 所以需要重新搜索

    if (resolver  &&  !triedResolver) {
        runtimeLock.unlockRead();
        _class_resolveMethod(cls, sel, inst);
        runtimeLock.read();
        // Don't cache the result; we don't hold the lock so it may have 
        // changed already. Re-do the search from scratch instead.
        triedResolver = YES;
        goto retry;
    }

    // No implementation found, and method resolver didn't help. 
    // Use forwarding. 没实现，只能转发了。

    imp = (IMP)_objc_msgForward_impcache;
    cache_fill(cls, sel, imp, inst);

 done:
    runtimeLock.unlockRead();

    return imp;
}
```

详细内容见[Objective-C 消息发送与转发机制原理](https://link.jianshu.com/?t=http://yulingtianxia.com/blog/2016/06/15/Objective-C-Message-Sending-and-Forwarding/) （里面最下面一张图很厉害，可以看下。）

这里主要（笼统的）总结一下整个消息的发送与转发流程：

1.在缓存内查找。

2.在该类方法中查找。

3.在超类中查找。

4.有没有进行动态解析方法（有 解析玩 从头开始再来一次）

```objective-c
+ (BOOL)resolveInstanceMethod:(SEL)selector  //如果是类方法则调用resolveClassMethod
```

5.有没有备用接受者（有 重新像备用接受者发送消息 快速转发）：

```objective-c
- (id)forwardingTargetForSelector:(SEL)selector
```

6.完整的转发

```objective-c
-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector
-(void)forwardInvocation:(NSInvocation *)anInvocation
```

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

##### 54.isa

下面代码的值是多少：

```objective-c
    BOOL res1 = [[NSObject class] isMemberOfClass:[NSObject class]];
    BOOL res2 = [[NSObject class] isKindOfClass:[NSObject class]];
    BOOL res3 = [[Person class] isMemberOfClass:[Person class]];
    BOOL res4 = [[Person class] isKindOfClass:[Person class]];
```

应该是NO,YES,NO,NO

看上面那张的isa 与superclass图就能得到答案。

##### 5.地址

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

##### 6.重载

下面代码可以编译通过吗？

```objective-c
// 第一种情况
- (void)tellName;
- (void)tellName:(NSString *)name;
// 第二种情况
- (void)tellName:(NSString *)name;
- (void)tellName:(NSArray *)name;
```

OC是不支持重载的，原因请看上面的SEL的本质。不同类中相同名字的方法所对应的方法选择器是相同的，即使方法名字相同而变量类型不同也会导致它们具有相同的方法选择器。

##### 7.为什么给nil发送消息不会崩溃

因为在在发送消息的过程中先做了判断 如果nil 清空 直接返回了。

##### 8.NSObject

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

#####  5.runtime 如何实现 weak 变量的自动置nil？

##### @property 的本质是什么？

