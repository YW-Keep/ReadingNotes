## 关于内存管理 Block 多线程（iOS与OS X多线程和内存管理）

### 内存管理

#### 引用计数式内存管理的思考方式：

1.自己生成的对象，自己持有。

2.非自己生成的对象，自己也能持有。

3.不在需要自己持有对象时释放。

4.非自己持有的对象无法释放。

5.没有人持有时，对象废弃。

生成并持有对象 -> alloc/new/copy/mutableCopy等方法。

持有-> retain方法

释放-> release方法

废弃-> delloc方法

引用计数表（散列表也就是哈希表）各记录中存有内存块地址，可从各个记录追溯到各对象的内存块。

#### autorelease的具体使用方法：

1.生成并持有NSAutoreleasePool对象。

2.调用已分配对象的autorelease。

3.废弃NSAutoreleasePool。

PS:ARC（NSAutoreleasePool已经不可用可以使用@autoreleasepool）

#### 所有权修饰符

ARC有效时，id类型和对象类型必须附加所有权修饰符**：

__strong修饰符（默认 所以可以忽略不写）

__weak修饰符 

__unsafe_unretained 修饰符

__autoreleasing

其中除了__unsafe_unretained修饰符其他修饰符变量会自动初始化为nil。（声明后）

__strong修饰符会持有对象，而\_\_weak修饰符则不会持有对象。（\_\_weak主要用于防止循环引用，当然还有个优点是在对象被释放时会自动设置为nil）

__unsafe_unretained 不会自动设置成nil其他与\_\_weak相同。

__autoreleasing基本上隐式使用，例如

对象作为函数的返回值，编译器会自动将其注册到autoreleasepool。

id的指针或者对象的指针在没用显式的指定时会被附加上__autoreleasing修饰符。例如**error。

#### ARC有效的情况下，应遵循如下规则（下面很多编译器帮你校验了）:

1.不能使用retain/release/retainCount/autorlease

2.不能使用NSAllocateObject/NSDeallocateObject

3.须遵守内存管理的方法命名规则

4.不要显式调用dealloc

5.使用@autoreleasepool块代替NSAutoreleasePool

6.不能使用区域（NSZone）

7.对象型变量不能作为你C语言结构体（struct/union）的成员

8.显示的转换"id"和"void*"

**属性赋值给指定的属性中就相当于赋值给附加各属性对应的所有权修饰符的变量中。**

assign -> __unsafe_unretained

copy -> __strong

retain -> __strong

strong -> __strong

unsafe_unretained -> __unsafe_unretained

weak -> __weak

**ARC的实现不单单只有编译器进行内存管理，还需要运行时的协助。**

#### __weak的实现

__weak 能自动设置为nil的实现是因为用其修饰的对象，会以对象地址作为建，变量地址作为值存入weak表中。（哈希表，即散列表）而对象被废弃时最后会调用objc_clear_deallocating函数它会：

1.从weak表中获取废弃对象的地址为键值的记录。

2.讲将包含在记录中附有__weak修饰符变量的地址赋值为nil。

3.从weak表中删除该记录。

4.从引用计数表（也是散列表）中删除废弃对象的地址为键值的记录。

**所以，如果大量使用附有__weak修饰符的变量，则会消耗相应的CPU资源，良策是只在需要避免循环引用时使用\_\_weak修饰符。**

### Blcoks

带有自动变量（局部变量）的匿名函数。

Blocks中将匿名函数部分称为"Block literal",简称"Block"。

#### Block

Block 语法为： ^返回值类型 参数表 表达式

```objective-c
^int (int count){return count + 1;}
```

其中返回值类型与参数表可以省略。

block类型变量的声明则为： 返回值类型  ^类型名 参数表 

```objective-c
int (^myBlock)(int) = ^int (int count){return count + 1;};
```

由于这么写十分繁琐 一般用typedef 来简写

```objective-c
typedef int (^MyBlock)(int)
MyBlock block = ^int (int count){return count + 1;};
```

使用附有__block说明符的自动变量可在Block中赋值，该变量称为\_\_block变量。

**Block即为Objective-C对象。** 
**所谓"截获自动变量值"意味着在执行Block语法时，Block语法表达式所使用的自动变量值被保存到Block的结构体实例（即Block自身）中。**

**__block之所以修饰之后block中可以修改是因为该修饰的变量被转化为了一个结构体类型的自动变量，结构体中有forwarding指针指向自己**

block超出变量作用域可以存在的原因是：

**Blocks提供了将Block和__block变量从栈上复制到堆上的方法**

内存一般分配：栈上运行，堆放对象。

一般情况下Blocks会在需要时把Block从栈上复制到堆上，但是有时候不会，不会时需要手动调用copy。

什么时候栈上的Blocks会复制到堆：

1.调用Block的copy实例方法

2.Block作为函数返回值返回时

3.将Block赋值给附有__strong修饰符id类型的类或Block类型成员变量时。

4.在方法名中含有usingBlock的Cocoa框架方法或Grand Central Dspatch的API中传递Block时。

**如果在Block中使用附有__strong修饰符的对象类型自动变量，那么当Block从栈复制到堆时，该对象为Block所持有，这样容易引起循环引用。**

解除block循环引用有两种方法：

1.把自动变量设置为__weak(相对比较好用的比较多的方式)

2.用__block修饰自动变量，在block结束后设置为nil（这种方式有个缺点就是block不执行还是存在内存泄露）

### GCD(Grand Central Dispatch)

官方说明：**开发者要做的只是定义想执行的任务并追加到适当的Dispatch Queue中。**

GCD用我们难以置信的非常简洁的记述方法，实现了极为复杂繁琐的多线程编程。

尽管使用多线程编程容易导致数据竞争、死锁、太多线程导致消耗大量内存，但是我们还是会使用多线程编程，因为使用多线程编程可以保证应用程序的响应性能。

串行队列使用一个线程，而并行队列使用多个线程。

创建：

```objective-c
dispatch_queue_t serialDiapatchQueue = dispatch_queue_create("com.test.queue", DISPATCH_QUEUE_SERIAL); 
// 第一个参数是队列名 第二个参数是队列类型，如果是并行则用DISPATCH_QUEUE_CONCURRENT,另外NULL 也是串行队列的意思
// 另外需要自己用release释放：
 dispatch_release(serialDiapatchQueue);
// 当然也可以猜到有
dispatch_retain(serialDiapatchQueue);

```

系统为我们其实已经生成了两个队列，一个是主线程的队列，会在runloop里执行。一个是全区并发队列，即Global Dispatch Queue。这个线程还提供了四种优先级：

```objective-c
#define DISPATCH_QUEUE_PRIORITY_HIGH 2
#define DISPATCH_QUEUE_PRIORITY_DEFAULT 0
#define DISPATCH_QUEUE_PRIORITY_LOW (-2)
#define DISPATCH_QUEUE_PRIORITY_BACKGROUND INT16_MIN
// 获取主线程
dispatch_queue_t mian = dispatch_get_main_queue();
// 获取系统提供的并行线程
dispatch_queue_t high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
// 另外这两个队列使用dispatch_release与dispatch_retain不会有任何变化与问题所以使用这两个队列。
```

#### dispatch_set_target_queue

该方法可以改变自己创建的队列的优先级

```objective-c
dispatch_queue_t serialDiapatchQueue=dispatch_queue_create("com.test.queue", NULL);
dispatch_queue_t dispatchgetglobalqueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
dispatch_set_target_queue(serialDiapatchQueue, dispatchgetglobalqueue);
// 可以理解为把自己的队列塞到了有优先级的 global队列中，从而有了优先级。
// 其实也可以猜到我们自己创建的线程其实就是在globlal线程中执行的。所以默认优先级与globlal默认值相同。
```

#### dispatch_after

该方法表示延迟调用，要注意延迟的是加入任务的时间，而不是任务多久后执行。比如加入到主线程中因为runloop是每隔1/60秒执行一次就有可能是加入后的1/60秒后才执行。

```objective-c

double delayInSeconds = 2.0;
dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
dispatch_after(time , dispatch_get_main_queue(), ^(void){
    NSLog(@"延迟调用");
});

```

#### dispatch_group

这个就是执行组，组执行完了在进行一个回调设置，也可以进行等待都成功了再继续：

```objective-c
dispatch_queue_t queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_group_t group=dispatch_group_create();
dispatch_group_async(group, queue, ^{NSLog(@"0");});
dispatch_group_async(group, queue, ^{NSLog(@"1");});
dispatch_group_async(group, queue, ^{NSLog(@"2");});
// 这是回调设置方式
dispatch_group_notify(group, dispatch_get_main_queue(), ^{NSLog(@"dowFOREVER
// 这是等待处理结果方式 其中第一个是组，第二个是等待时间 
// 这里用DISPATCH_TIME_FOREVER表示永远等待
// relsut 表示执行结果，0表示执行完成，如果时间是DISPATCH_TIME_FOREVER一定会回调0而不为0表示在规定时间执行未完成 
long reslut = dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
dispatch_release(group)
```

一般情况下是使用回调的方式来做处理的。

#### dispatch_barrier_async

在访问数据时，写入确实不能同时写入避免数据竞争但是读取却是可以并行的。

而dispatch_barrier_async可以轻易做到这一点，dispatch_barrier_async的效果是先等前面的任务执行完再执行该任务，是用在并行队列中的。

```objective-c
dispatch_queue_t concurrentDiapatchQueue=dispatch_queue_create("com.test.queue", DISPATCH_QUEUE_CONCURRENT);
dispatch_async(concurrentDiapatchQueue, ^{NSLog(@"0");});
dispatch_async(concurrentDiapatchQueue, ^{NSLog(@"1");});
dispatch_async(concurrentDiapatchQueue, ^{NSLog(@"2");});
dispatch_async(concurrentDiapatchQueue, ^{NSLog(@"3");});
dispatch_barrier_async(concurrentDiapatchQueue, ^{NSLog(@"4");});
dispatch_async(concurrentDiapatchQueue, ^{NSLog(@"5");});
dispatch_async(concurrentDiapatchQueue, ^{NSLog(@"6");});
dispatch_async(concurrentDiapatchQueue, ^{NSLog(@"7");});
dispatch_async(concurrentDiapatchQueue, ^{NSLog(@"8");});

```

这里0123并发执行，然后执行4 执行完后在并发执行5678

#### dispatch_sync

同步追加任务。就是停止当前线程，直到任务处理结束继续。这个很简单不追加例子了。

但是要特变注意，**在串行队列中往当前队列同步追加任务会引起线程锁死。**

#### dispatch_apply

循环往队列中添加任务，它会等待全部处理执行结束。

```objective-c
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
dispatch_apply(10, queue, ^(size_t index) {
    NSLog(@"%@",index);
});
NSLog(@"阻塞");
```

这里会并发调用打印0-9 然后会打印阻塞。

**dispatch_apply经常用在无序查找中，比如无序查找数组等并发提高效率**

#### dispatch_suspend & dispatch_resume

挂起和恢复某个队列

````objective-c
dispatch_suspend(queue)
dispatch_resume(queue)
````

一般在不同的线程挂起和恢复某个队列，用于管理队列吧。

#### Dispatch Semaphore

信号量，主要来解决数据并发更新时冲突问题，颗粒度更加细。

比如说数组并发写入。

```objective-c
dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
//这里是创建信号量，因为这里是数组，写入我希望一次写入一个所以设置为1
NSMutableArray *array = [[NSMutableArray alloc] init];
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
for (int i = 0; i <100; i++)
{
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    // 它会一直等待信号量直到信号量大于0，大于0了 就减1
    dispatch_async(queue, ^{
        [array addObject:@1];
        dispatch_semaphore_signal(semaphore);
        //因为这里任务执行完了，所以再加1表示任务已完成
    });
}
```

#### dispatch_once

主要是为了保证执行一次的代码，dispatch_once能保证在多线程的环境下执行也是安全的，一般会用在单利的创建。

```objective-c
static Objc * instance;
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    instance = [[Objc alloc] init];
});
return instance;
```

最后有一个Dispatch I/O 可以提高文件的读取速度，并不常用。

#### GCD的实现

GCD是XNU内核级别实现的线程管理方法。所以性能是最强的。 

其实还有个Dispatch Source 不常用,她是kqueue的包装。

kqueue可以说是应用程序梳理XNU内核中发生的各种事件的方法中最优秀的一种。