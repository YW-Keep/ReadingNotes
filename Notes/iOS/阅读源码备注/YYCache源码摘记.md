### YYCache源码摘记

YYCache这个库主要是做缓存处理，其实代码量很少。主要有一下几个文件:

#### YYCache

其实YYCahe没有做什么特别的事情。主要是统一了两个缓存，内存缓存与硬盘缓存。

总的来说。就是一句话，先从缓存读，缓存没有从硬盘读，然后存入缓存。删除2个都删除。

#### 内存缓存相关

内存缓存用了一个文件来实现，那就是**YYMemoryCache**其中还包含两个类，是自用类，那就是节点类**_YYLinkedMapNode**以及保存节点的map类**_YYLinkedMap**。

那就有人可能会有疑问为什么会用这两个类其实需求有关：

1.我们需要一种快速的方式去存取我们的类，很显然map是一个很好的方式。

2.我们如果需要做一个缓存的维度维护（比如到一定数量清理缓存，等等）那么我们需要维护一个表，来排列缓存的删除先后顺序，当然这里用了淘汰算法(也就是最近使用的缓存放在前面)因为表的插入删除相对比较频繁。所以用了双向链表（因为要从尾部删除，头部加入）。

YYMemoryCache这个文件中主要就是做了对表的增删改查操作。但是要注意，因为没有做单利所以缓存对象如果释放，那么这个内存缓存理论上也是直接释放的。使用的时候也要注意。

#### 磁盘缓存相关

磁盘相关的有2个文件第一个是YYDiskCache，YYDiskCache其实就另外一个文件YYKVStorage的封装，封装这一层主要处理业务相关的逻辑，比如线程安全，定期清理等等。其实跟上面的缓存有点像YYKVStorage有点想上面的_YYLinkedMap，存储删除的核心方法都在其中。

那么我们仔细的可以看下YYKVStorage，YYKVStorage其实实现了2套磁盘缓存一套是sqlite 一套是file文件管理。

从写入看可以看到他是根据文件名判断是否写入文件的，而文件名默认是key值的md5这样避免了文件名冲突。其实不管写入文件整个磁盘缓存都是存到了数据库中，存文件与不为文件的区别是，存文件中的数据库中文件栏有值而data没值，而不存文件正好想法。

下面就是sq中存的格式

```objective-c
create table if not exists manifest (
    key                 text,  // key值
    filename            text,  //  文件名
    size                integer, // 文件大小
    inline_data         blob,    //  数据 (有文件名表示文件存储，数据没有值，)
    modification_time   integer, // 修改时间
    last_access_time    integer, // 访问时间
    extended_data       blob,    // 额外的数据
    primary key(key)
 ); 
```

整个YYKVStorage文件其实主要在做sql的操作，以及取出数据库之后转化为oc的对象的过程。

#### 另外：

延迟app关闭

```objective-c
    // 这个_YYSharedApplication() 拿到的是[UIApplication sharedApplication]
    //而beginBackgroundTaskWithExpirationHandler 方法是延迟app的关闭 可以把处理放在{}这里没有。
    UIBackgroundTaskIdentifier taskID = [_YYSharedApplication() beginBackgroundTaskWithExpirationHandler:^{}];
    // 关闭数据库
    [self _dbClose];
    // 关闭后 可以让App关闭了
    if (taskID != UIBackgroundTaskInvalid) {
        [_YYSharedApplication() endBackgroundTask:taskID];
    }
```



其实整个YYCache中有很多点值得学习，比如方法禁用，队列线程处理，锁的处理（内存缓存操作的互斥锁，磁盘缓存使用信号量来代替锁），数据库的操作，监听内存警告与进入后台，头文件的导入判断等等。

具体代码注释在源文件可以查看。

