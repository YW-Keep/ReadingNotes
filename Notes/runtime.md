## runtime

首先Objective-C是个面向对象编程（OOP）的语言 。其实它的组成就是**C + Objc编译器 + runtime** C就是C语言，编译器也没什么好说的，还有就是runtime,就是因为runtime，Objective-C才成为一门动态语言。那么什么是runtime呢 ? Runtime 又叫运行时，是一套底层的 C 语言 API，是 iOS 系统的核心之一。开发者在编码过程中，可以给任意一个对象发送消息，在编译阶段只是确定了要向接收者发送这条消息，而接受者将要如何响应和处理这条消息，那就要看运行时来决定了。其实核心就是动态消息派发机制。

C语言中，在编译期，函数的调用就会决定调用哪个函数。

而OC的函数，属于动态调用过程，在编译期并不能决定真正调用哪个函数，只有在真正运行时才会根据函数的名称找到对应的函数来调用。

Objective-C 是一个动态语言，这意味着它不仅需要一个编译器，也需要一个运行时系统来动态得创建类和对象、进行消息传递和转发。

 那这里就要主要讨论下下面2个话题

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
    const char *types; //存储方法的参数类型和返回值类型
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
-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector // 对方法进行签名
-(void)forwardInvocation:(NSInvocation *)anInvocation  // 转发
```

下面有个例子，简单的写了下这些方法的实现,其中关于方法签名的可以看这里 [Type Encodings](https://link.jianshu.com/?t=https%3A%2F%2Fdeveloper.apple.com%2Flibrary%2Fcontent%2Fdocumentation%2FCocoa%2FConceptual%2FObjCRuntimeGuide%2FArticles%2FocrtTypeEncodings.html%23%2F%2Fapple_ref%2Fdoc%2Fuid%2FTP40008048-CH100-SW1)  。

```objective-c
// 1.动态添加方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    
    //动态解析，指定新的IMP
    class_addMethod([self class], sel, (IMP)doSome, "v@:");
    NSLog(@"奔溃啦，没找到方法-%@",NSStringFromSelector(sel));
    return YES;
}

void doSome() {
    NSLog(@"奔溃啦");
}

// 2.快速转发  可以转发到你想要的对象中 但是该对象必须实现该方法。
- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == @selector(doSomeThings)) {
        return [Man new];
    }

    return [super forwardingTargetForSelector:aSelector];
}


// 3.完整的转发需要你签名了  这里就很吊了 你想怎么改就怎么改了  想往哪里发就往哪里发了
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if ([NSStringFromSelector(aSelector) isEqualToString:@"doSomeThings"]) {
        // v 返回值 @调用对象 id类型 :表示一个方法选择器：
        return [NSMethodSignature signatureWithObjCTypes:"v@:"];
    }
    
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL sel = anInvocation.selector;
    anInvocation.selector = @selector(singSong);
    Man *p = [Man new];
    if([p respondsToSelector:sel]) {
        [anInvocation invokeWithTarget:p];
    }
    else {
        // 主动抛出不能识别方法异常
        [self doesNotRecognizeSelector:sel];
    }
}
```

### 常用方法

```objective-c
//获取cls类对象所有成员ivar结构体
Ivar *class_copyIvarList(Class cls, unsigned int *outCount)
//获取cls类对象name对应的实例方法结构体
Method class_getInstanceMethod(Class cls, SEL name)
//获取cls类对象name对应类方法结构体
Method class_getClassMethod(Class cls, SEL name)
//获取cls类对象name对应方法imp实现
IMP class_getMethodImplementation(Class cls, SEL name)
//测试cls对应的实例是否响应sel对应的方法
BOOL class_respondsToSelector(Class cls, SEL sel)
//获取cls对应方法列表
Method *class_copyMethodList(Class cls, unsigned int *outCount)
//测试cls是否遵守protocol协议
BOOL class_conformsToProtocol(Class cls, Protocol *protocol)
//为cls类对象添加新方法
BOOL class_addMethod(Class cls, SEL name, IMP imp, const char *types)
//替换cls类对象中name对应方法的实现
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types)
//为cls添加新成员
BOOL class_addIvar(Class cls, const char *name, size_t size, uint8_t alignment, const char *types)
//为cls添加新属性
BOOL class_addProperty(Class cls, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount)
//获取m对应的选择器
SEL method_getName(Method m)
//获取m对应的方法实现的imp指针
IMP method_getImplementation(Method m)
//获取m方法的对应编码
const char *method_getTypeEncoding(Method m)
//获取m方法参数的个数
unsigned int method_getNumberOfArguments(Method m)
//copy方法返回值类型
char *method_copyReturnType(Method m)
//获取m方法index索引参数的类型
char *method_copyArgumentType(Method m, unsigned int index)
//获取m方法返回值类型
void method_getReturnType(Method m, char *dst, size_t dst_len)
//获取方法的参数类型
void method_getArgumentType(Method m, unsigned int index, char *dst, size_t dst_len)
//设置m方法的具体实现指针
IMP method_setImplementation(Method m, IMP imp)
//交换m1，m2方法对应具体实现的函数指针
void method_exchangeImplementations(Method m1, Method m2)
//获取v的名称
const char *ivar_getName(Ivar v)
//获取v的类型编码
const char *ivar_getTypeEncoding(Ivar v)
//设置object对象关联的对象
void objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy)
//获取object关联的对象
id objc_getAssociatedObject(id object, const void *key)
//移除object关联的对象
void objc_removeAssociatedObjects(id object)

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

##### 4.isa

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

##### 9.OC有多继承吗？那如果要实现一个多继承，该怎么办？

从NSObject 结构上我们可以看出OC肯定没有多继承，那么如果我们要实现多继承怎么办呢？forwardingTargetForSelector 通过消息的快速转发是可以实现假多继承的。为什么叫假多继承呢，因为这种方式和真的是有区别的，比如respondsToSelector：与isKindOfClass：是不能通过的除非你自己去改写。

##### 10.为什么runtime可以实现方法替换？方法替换常用在什么地方？ 使用过程中需要注意什么？

Method Swizzling（方法替换）是iOS中AOP(面相切面编程)的一种实现方式。其实看上面的method_t就可以很明显的看出来，其实本质就是对IMP和SEL进行交换。一般会用在1.所有情况都需要：例如统计，改变字体大小。2.对SDK系统等看不见的方法进行替换（看需求比较危险。）3.异常保护（比如替换objectAtIndex 用try去取 奔溃了直接返回nil.）

一般我们使用都是新建一个分类，在分类中进行Method Swizzling方法的交换。交换的代码模板如下：

```objective-c
#import <objc/runtime.h>
@implementation UIViewController (Swizzling)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(xxx_viewWillAppear:);
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        BOOL didAddMethod = class_addMethod(class,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}
#pragma mark - Method Swizzling
- (void)xxx_viewWillAppear:(BOOL)animated {
    [self xxx_viewWillAppear:animated];
    NSLog(@"viewWillAppear: %@", self);
}
//在进行Swizzling的时候，我们需要用class_addMethod先进行判断一下原有类中是否有要替换的方法的实现。
//如果class_addMethod返回NO，说明当前类中有要替换方法的实现，所以可以直接进行替换，调用method_exchangeImplementations即可实现Swizzling。
//如果class_addMethod返回YES，说明当前类中没有要替换方法的实现，我们需要在父类中去寻找。这个时候就需要用到method_getImplementation去获取class_getInstanceMethod里面的方法实现。然后再进行class_replaceMethod来实现Swizzling。

@end
```

使用时候的注意点：

1.Swizzling应该总在+load中执行

Objective-C在运行时会自动调用类的两个方法+load和+initialize。+load会在类初始加载时调用， +initialize方法是以懒加载的方式被调用的，如果程序一直没有给某个类或它的子类发送消息，那么这个类的 +initialize方法是永远不会被调用的。所以Swizzling要是写在+initialize方法中，是有可能永远都不被执行。

2.Swizzling应该总是在dispatch_once中执行

Swizzling会改变全局状态，所以在运行时采取一些预防措施，使用dispatch_once就能够确保代码不管有多少线程都只被执行一次。这将成为Method Swizzling的最佳实践。

3.Swizzling在+load中执行时，不要调用[super load]

原因同注意点二，如果是多次继承，并且对同一个方法都进行了Swizzling，那么调用[super load]以后，父类的Swizzling就失效了。

##### 11.KVO是怎么实现的？ KVC与KVO之间有啥关系？

KVO的本质就是监听对象有没有调用被监听属性对应的setter方法。具体实现应该是重写其setter方法即可。

````objective-c
   Person *my = [Person new];
//    [my performSelector:@selector(doSomeThings) withObject:nil];
    Man *man = [[Man alloc] init];
    NSLog(@"self->isa:%@",object_getClass(man));
    NSLog(@"self class:%@",[man class]);
    NSLog(@"ClassMethodNames = %@",ClassMethodNames(object_getClass(man)));
    [man addObserver:self forKeyPath:@"some" options:NSKeyValueObservingOptionNew context:nil];
    
    NSLog(@"self->isa:%@",object_getClass(man));
    NSLog(@"self class:%@",[man class]);
    NSLog(@"ClassMethodNames = %@",ClassMethodNames(object_getClass(man)));
    
    
    static NSArray * ClassMethodNames(Class c)
{
    NSMutableArray * array = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method * methodList = class_copyMethodList(c, &methodCount);
    unsigned int i;
    for(i = 0; i < methodCount; i++) {
        [array addObject: NSStringFromSelector(method_getName(methodList[i]))];
    }
    
    free(methodList);
    return array;
}

// 下面是打印结果
2018-05-22 14:16:02.651617+0800 runtime[539:7410616] self->isa:Man
2018-05-22 14:16:02.651762+0800 runtime[539:7410616] self class:Man
2018-05-22 14:16:02.652059+0800 runtime[539:7410616] ClassMethodNames = (
    doSomeThings,
    singSong,
    some,
    "setSome:",
    ".cxx_destruct",
    init
)
2018-05-22 14:16:02.652702+0800 runtime[539:7410616] self->isa:NSKVONotifying_Man
2018-05-22 14:16:02.652842+0800 runtime[539:7410616] self class:Man
2018-05-22 14:16:02.652979+0800 runtime[539:7410616] ClassMethodNames = (
    "setSome:",
    class,
    dealloc,
    "_isKVOA"
)

````

KVO在调用addObserver方法之后，苹果的做法是在执行完addObserver: forKeyPath: options: context: 方法之后，把isa指向到另外一个类去。

在这个新类里面重写被观察的对象四个方法。class，setter，dealloc，_isKVOA。 

1.重写class方法是为了我们调用它的时候返回跟重写继承类之前同样的内容。

```objective-c
// class 和 object_getClass 的区别
- (Class)class {
    return object_getClass(self);
}

Class object_getClass(id obj)  
{
    if (obj) return obj->getIsa();
    else return Nil;
}
```

这样看理论上是一样的，但其实不一样，如果你重写一下类方法，第二次其实调到类方法里面了，说明第二次NSKVONotifying_Man的class方法要么被重写要么被替换到了Man的类的class方法中了。

2.重写set方法就很好理解了是为了增加下面两个方法

```objective-c
// 其实也就是设置前设置后调用下而已
- (void)willChangeValueForKey:(NSString *)key
- (void)didChangeValueForKey:(NSString *)key
```

在didChangeValueForKey:方法再调用

```objective-c
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
```

3.重写dealloc为了销毁新生成的NSKVONotifying_类。

4._isKVOA这个私有方法估计可能是用来标示该类是一个 KVO 机制声称的类。

从上面的例子中我们可以看出：**永远不要用用isa来判断一个类的继承关系，而是应该用class方法来判断类的实例。**

最后说说 KVC

如果有访问器方法，则运行时会在setter方法中调用will/didChangeValueForKey:方法；

如果没用访问器方法，运行时会在setValue:forKey方法中调用will/didChangeValueForKey:方法。

所以这种情况下，KVO是奏效的。

##### 12.关联对象怎么写的，有啥用？

```objective-c
// NSObject+AssociatedObject.h
@interface NSObject (AssociatedObject)
@property (nonatomic, strong) id associatedObject;
@end

// NSObject+AssociatedObject.m
@implementation NSObject (AssociatedObject)
@dynamic associatedObject;

- (void)setAssociatedObject:(id)object {
    objc_setAssociatedObject(self, @selector(associatedObject), object, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)associatedObject {
    return objc_getAssociatedObject(self, @selector(associatedObject));
}

```

一般写法是上面这样的，用到的方法是：

```objective-c
OBJC_EXPORT void objc_setAssociatedObject(id object, const void *key, id value, objc_AssociationPolicy policy)
    __OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_3_1);

OBJC_EXPORT id objc_getAssociatedObject(id object, const void *key)
    __OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_3_1);

OBJC_EXPORT void objc_removeAssociatedObjects(id object)
    __OSX_AVAILABLE_STARTING(__MAC_10_6, __IPHONE_3_1);
//  id object 实例对象， 
// const void *key 关联对象的key 一般三种写法 1.static char AssociatedObjectKey = "AssociatedKey"; 2.static const void *AssociatedKey = "AssociatedKey"; 3.@selector(associatedKey)  第三种简单点而已

```

一般的使用场景是:1.为现有的类添加私有变量 2.为现有的类添加公有属性 3.为KVO创建一个关联的观察者。

##### 13.一般字典转模型，模型转字典是怎么实现的？

字典转模型

1.调用 class_getProperty 方法获取当前 Model 的所有属性。
 2.调用 property_copyAttributeList 获取属性列表。
 3.根据属性名称生成 setter 方法。
 4.使用 objc_msgSend 调用 setter 方法为 Model 的属性赋值（或者 KVC）

```objective-c
+(id)objectWithKeyValues:(NSDictionary *)aDictionary{
    id objc = [[self alloc] init];
    for (NSString *key in aDictionary.allKeys) {
        id value = aDictionary[key];
        
        /*判断当前属性是不是Model*/
        objc_property_t property = class_getProperty(self, key.UTF8String);
        unsigned int outCount = 0;
        objc_property_attribute_t *attributeList = property_copyAttributeList(property, &outCount);
        objc_property_attribute_t attribute = attributeList[0];
        NSString *typeString = [NSString stringWithUTF8String:attribute.value];

        if ([typeString isEqualToString:@"@\"Student\""]) {
            value = [self objectWithKeyValues:value];
        }
        
        //生成setter方法，并用objc_msgSend调用
        NSString *methodName = [NSString stringWithFormat:@"set%@%@:",[key substringToIndex:1].uppercaseString,[key substringFromIndex:1]];
        SEL setter = sel_registerName(methodName.UTF8String);
        if ([objc respondsToSelector:setter]) {
            ((void (*) (id,SEL,id)) objc_msgSend) (objc,setter,value);
        }
        free(attributeList);
    }
    return objc;
}

```



模型转字典

1.调用 class_copyPropertyList 方法获取当前 Model 的所有属性。
 2.调用 property_getName 获取属性名称。
 3.根据属性名称生成 getter 方法。
 4.使用 objc_msgSend 调用 getter 方法获取属性值（或者 KVC）

```objective-c
//模型转字典
-(NSDictionary *)keyValuesWithObject{
    unsigned int outCount = 0;
    objc_property_t *propertyList = class_copyPropertyList([self class], &outCount);
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (int i = 0; i < outCount; i ++) {
        objc_property_t property = propertyList[i];
        
        //生成getter方法，并用objc_msgSend调用
        const char *propertyName = property_getName(property);
        SEL getter = sel_registerName(propertyName);
        if ([self respondsToSelector:getter]) {
            id value = ((id (*) (id,SEL)) objc_msgSend) (self,getter);
            
            /*判断当前属性是不是Model*/
            if ([value isKindOfClass:[self class]] && value) {
                value = [value keyValuesWithObject];
            }

            if (value) {
                NSString *key = [NSString stringWithUTF8String:propertyName];
                [dict setObject:value forKey:key];
            }
        }
        
    }
    free(propertyList);
    return dict;
}

```

### 参考

1.[神经病院Objective-C Runtime](https://www.jianshu.com/p/9d649ce6d0b8)

2.[精神病讲runtime sunnyxx](http://www.docin.com/p-1600092713.html)

3.[objc-runtime](https://github.com/RetVal/objc-runtime)  ps：这是一个很好的看runtime库里的方法的地方