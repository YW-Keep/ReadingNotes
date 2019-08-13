#CocoaLumberjack 源码解析
CocoaLumberjack是一个非常强大好用的第三方日志框架，最近在写最近的日志框架所以阅读了下参考下他做的优秀的地方。
##CocoaLumberjack基本架构是怎么样的？
![](https://raw.githubusercontent.com/CocoaLumberjack/CocoaLumberjack/master/Documentation/CocoaLumberjackClassDiagram.png)
这是官方的架构图，第一眼看到的时候会一脸懵逼，没关系我们可以慢慢分析上下印证一些东西。
接下来下载了源码，粗看下它的源码主要有下面这些类。
1.主文件说明等。 
2.简单好用的一堆宏以及swift的桥接。 
3.一个捕获ASL（苹果系统日志，Apple System Logs）的类（DDASLLogCapture）。 
4.一个主类（DDLog）。
5.一个数据库日志记录器的抽象实现（DDAbstractDatabaseLogger）。 
6.一个为苹果系统日志工具提供日志记录器的类（DDASLLogger）。 
7.一个日志记录器类（DDLogFileManager）。 
8.一个位os_log提供的日志记录器类（DDOSLogger）。 
9.一个输出终端或者输出Xcode控制台提供的类（DDTTYLogger）。 
10.一个连接颜色的类（CLIColor）。 
11.一个Extensions里面放着各种格式化的类。
然后分析下上面那张架构图:
1.DDLog，全局单例类，所有调用DDLog的都会到这个类进行一次转发，这个类可以理解为通过等级判断进行转发的转发器，转发到响应的操作中去。可以添加删除自定义日志记录器。
2.DDLogger，它其实是一个协议，记录了日志记录器的基本协议。其中有一个方法就是logMessage。就是各个日志器记录日志的方法。DDLogMessage就是日志相关信息的model。
3.DDAbstractLogger日志记录器的抽象基类，作用是为了简化线程安全。其中上面的很多类比如DDTTYLogger、DDASLLogger、DDLogFileManager、DDAbstractDatabaseLogger都是继承该基类的。
4.DDLogFlag与DDLogLevel 其实就是筛选日志用的，来区分日志等级等。其中DDLogFlag是一个位枚举，而DDLogLevel就是DDLogFlag的组合。
5.DDLogFormatter又是一个协议，其实可以理解为他是一个格式器的协议。例如日志文件的日志消息可能与控制台的日志消息格式不同,就需要不一样的格式器。而那些DDContextWhitelistFilterLogFormatter、DDMultiFormatter等就是放在Extensions里的各种格式器。
到这里图上的整个架构就基本分析完了。我们可以简单的整理下流程，当我们使用DDLog时，首先会根据我们的输入和配置生成一个DDLogMessage，通过DDLog这个主类分配给需要的DDAbstractLogger即日志记录器，而日志记录器会会通过日志格式器格式化日志，生成所需要记录的string，最后日志记录器用自己的记录方式记录该string。
##如何完成日志分级
使用过CocoaLumberjack的应该知道，首先需要定义一个全局常量，ddLogLevel 这个常量就是等级。一般我们会写的方式是
```
#ifdef DEBUG
static const int ddLogLevel = DDLogLevelVerbose;
#else
static const int ddLogLevel = DDLogLevelError;
#endif
```
那么这个到底是干嘛用的呢，其实很简单想想也知道我们点进DDLog方法中去
```
这是我们在使用的宏
#define DDLogError(frmt, ...)   LOG_MAYBE(NO,                LOG_LEVEL_DEF, DDLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogWarn(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogInfo(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogDebug(frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogVerbose(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
这是宏点进去的方法的
#define LOG_MAYBE(async, lvl, flg, ctx, tag, fnct, frmt, ...) \
        do { if(lvl & flg) LOG_MACRO(async, lvl, flg, ctx, tag, fnct, frmt, ##__VA_ARGS__); } while(0)
```
PS:这里插入一个小诀窍 最后一行代码有一个 do{}while(0),可能刚看到会很奇怪为什么这么写，仔细一想就可以想明白，他是为了保证里面的代码一定正确执行不影响使用的地方的逻辑。如果不加 可能会出现插入后根据前后代码逻辑混乱。
从上面的代码里可以看出通过位运算来判断是否执行。其实很简单前面我们说了DDLogFlag是位枚举，而DDLogLevel是DDLogFlag组合，举个例子。DDLogLevelInfo即为 0....00111 而DDLogFlagInfo 为0.00100 DDLogFlagVerbose为 0...10000  当 DDLogLevelInfo & DDLogFlagInfo  有位数有1 所以肯定是过的及执行写入日志，而当DDLogLevelInfo & DDLogFlagVerbose 时 明显都为0 所以不会执行写入日志操作。
还有就是刚刚说的日志记录器在加入过程中也可以增加级别，在加入时可以传入级别（用不传入的方式加入即为全部记录）。 比如说我记录日志值要warn和 Error就可以而打印XCode控制板要全部打印出来就可以通过这种方式实现。
到这里，我们可以简单的整理下CocoaLumberjack的日志分级，所谓的分级记录其实就是他先暂定了几个级别，你需要定义一个你需要打印日志的参数。（当然他也定义了一些你可以直接使用）。通过位运算来决定是否写入日志。
##如何进行多日志器写入
首先需要加入日志记录器。这里需要强调一点它有个专门的线程处理所有的日志相关操作，很多日志相关方法都有线程断言如果不在该线程就报错。
我们看下添加日志器方法
```
- (void)addLogger:(id <DDLogger>)logger withLevel:(DDLogLevel)level {
    if (!logger) {
        return;
    }
    
    dispatch_async(_loggingQueue, ^{ @autoreleasepool {
        [self lt_addLogger:logger level:level];
    } });
}
```
这里可以看出都是在_loggingQueue 线程中操作的，这里还加了自动释放池，我们看看下面一个方法做了什么
```
- (void)lt_addLogger:(id <DDLogger>)logger level:(DDLogLevel)level {
    // Add to loggers array.
    // Need to create loggerQueue if loggerNode doesn't provide one.

    for (DDLoggerNode* node in self._loggers) {
        if (node->_logger == logger
            && node->_level == level) {
            // Exactly same logger already added, exit
            return;
        }
    }

    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    dispatch_queue_t loggerQueue = NULL;

    if ([logger respondsToSelector:@selector(loggerQueue)]) {
        // Logger may be providing its own queue

        loggerQueue = [logger loggerQueue];
    }

    if (loggerQueue == nil) {
        // Automatically create queue for the logger.
        // Use the logger name as the queue name if possible.

        const char *loggerQueueName = NULL;

        if ([logger respondsToSelector:@selector(loggerName)]) {
            loggerQueueName = [[logger loggerName] UTF8String];
        }

        loggerQueue = dispatch_queue_create(loggerQueueName, NULL);
    }

    DDLoggerNode *loggerNode = [DDLoggerNode nodeWithLogger:logger loggerQueue:loggerQueue level:level];
    [self._loggers addObject:loggerNode];

    if ([logger respondsToSelector:@selector(didAddLoggerInQueue:)]) {
        dispatch_async(loggerNode->_loggerQueue, ^{ @autoreleasepool {
            [logger didAddLoggerInQueue:loggerNode->_loggerQueue];
        } });
    } else if ([logger respondsToSelector:@selector(didAddLogger)]) {
        dispatch_async(loggerNode->_loggerQueue, ^{ @autoreleasepool {
            [logger didAddLogger];
        } });
    }
}
```
PS这里又有个小点了，就是如何判断是不是在该线程，dispatch_queue_set_specificg方法可以为线程增加标志符号在该线程中通过dispatch_get_specific获取如果获取不到则不在该线程获得到了就是在该线程。
从源码中也可以看到断言里就是这么获取的。
这里第一步判别了是否存在相同的，如果存在则不添加。然后他创造了DDLoggerNode类，把类加到了DDLog的数组中去。这个类也很简单由3个东西组成：一个logger，一个level，一个loggerQueue组成。最后把DDLoggerNode加入到DDLog数组中。其实这里就可以看出就是每一个日志记录器都有自己的线程，可以日志记录器自己创建。
PS:有时候我们看代码 会遇到#if !OS_OBJECT_USE_OBJC ... #endif 这是因为GCD在iOS6之前需要手动管理内存。
到这里日志记录器就添加完了，最后我们要看看在DDLog如何分发Message。看源码可以发现，它会先通过传入的数据装配成一个DDLogMessage 装配完成后会查看GCD的一个等待信号如果没有拥堵就可以加入队列了，主要是为了防止队列无限加长。其实分发主要调用了一个核心的方法就是lt_log ，我们来看看这个方法做了啥
```
DDLogMessage 创建完成后的方法
- (void)queueLogMessage:(DDLogMessage *)logMessage asynchronously:(BOOL)asyncFlag {
    // We have a tricky situation here...
    //
    // In the common case, when the queueSize is below the maximumQueueSize,
    // we want to simply enqueue the logMessage. And we want to do this as fast as possible,
    // which means we don't want to block and we don't want to use any locks.
    //
    // However, if the queueSize gets too big, we want to block.
    // But we have very strict requirements as to when we block, and how long we block.
    //
    // The following example should help illustrate our requirements:
    //
    // Imagine that the maximum queue size is configured to be 5,
    // and that there are already 5 log messages queued.
    // Let us call these 5 queued log messages A, B, C, D, and E. (A is next to be executed)
    //
    // Now if our thread issues a log statement (let us call the log message F),
    // it should block before the message is added to the queue.
    // Furthermore, it should be unblocked immediately after A has been unqueued.
    //
    // The requirements are strict in this manner so that we block only as long as necessary,
    // and so that blocked threads are unblocked in the order in which they were blocked.
    //
    // Returning to our previous example, let us assume that log messages A through E are still queued.
    // Our aforementioned thread is blocked attempting to queue log message F.
    // Now assume we have another separate thread that attempts to issue log message G.
    // It should block until log messages A and B have been unqueued.


    // We are using a counting semaphore provided by GCD.
    // The semaphore is initialized with our DDLOG_MAX_QUEUE_SIZE value.
    // Everytime we want to queue a log message we decrement this value.
    // If the resulting value is less than zero,
    // the semaphore function waits in FIFO order for a signal to occur before returning.
    //
    // A dispatch semaphore is an efficient implementation of a traditional counting semaphore.
    // Dispatch semaphores call down to the kernel only when the calling thread needs to be blocked.
    // If the calling semaphore does not need to block, no kernel call is made.

    dispatch_semaphore_wait(_queueSemaphore, DISPATCH_TIME_FOREVER);

    // We've now sure we won't overflow the queue.
    // It is time to queue our log message.

    dispatch_block_t logBlock = ^{
        @autoreleasepool {
            [self lt_log:logMessage];
        }
    };

    if (asyncFlag) {
        dispatch_async(_loggingQueue, logBlock);
    } else {
        dispatch_sync(_loggingQueue, logBlock);
    }
}
接下来分发的方法。
- (void)lt_log:(DDLogMessage *)logMessage {
    // Execute the given log message on each of our loggers.

    NSAssert(dispatch_get_specific(GlobalLoggingQueueIdentityKey),
             @"This method should only be run on the logging thread/queue");

    if (_numProcessors > 1) {
        // Execute each logger concurrently, each within its own queue.
        // All blocks are added to same group.
        // After each block has been queued, wait on group.
        //
        // The waiting ensures that a slow logger doesn't end up with a large queue of pending log messages.
        // This would defeat the purpose of the efforts we made earlier to restrict the max queue size.

        for (DDLoggerNode *loggerNode in self._loggers) {
            // skip the loggers that shouldn't write this message based on the log level

            if (!(logMessage->_flag & loggerNode->_level)) {
                continue;
            }
            
            dispatch_group_async(_loggingGroup, loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger logMessage:logMessage];
            } });
        }
        
        dispatch_group_wait(_loggingGroup, DISPATCH_TIME_FOREVER);
    } else {
        // Execute each logger serialy, each within its own queue.
        
        for (DDLoggerNode *loggerNode in self._loggers) {
            // skip the loggers that shouldn't write this message based on the log level

            if (!(logMessage->_flag & loggerNode->_level)) {
                continue;
            }
            
            dispatch_sync(loggerNode->_loggerQueue, ^{ @autoreleasepool {
                [loggerNode->_logger logMessage:logMessage];
            } });
        }
    }

    // If our queue got too big, there may be blocked threads waiting to add log messages to the queue.
    // Since we've now dequeued an item from the log, we may need to unblock the next thread.

    // We are using a counting semaphore provided by GCD.
    // The semaphore is initialized with our DDLOG_MAX_QUEUE_SIZE value.
    // When a log message is queued this value is decremented.
    // When a log message is dequeued this value is incremented.
    // If the value ever drops below zero,
    // the queueing thread blocks and waits in FIFO order for us to signal it.
    //
    // A dispatch semaphore is an efficient implementation of a traditional counting semaphore.
    // Dispatch semaphores call down to the kernel only when the calling thread needs to be blocked.
    // If the calling semaphore does not need to block, no kernel call is made.

    dispatch_semaphore_signal(_queueSemaphore);
}
```
首先这里有个GCD信号量的概念，为了防止过多的日志写入导致堵塞。在log方法里我们可以看到还有个计算处理的值_numProcessors，这里会判断处理器，如果多的话可以用线程组并发完成，如果就一个则直接异步加载。每一个日志记录器也在自己的线程执行相关的记录任务。到这里我们可以看到基本上已经发给日志记录器，接下来不同的日志记录器去完成不同的任务。
##NSLog到底做了什么，DDLog为什么能代替。
系统的NSLog函数，其实就是输出到两个地方，一个为苹果的系统日志ASL，另一个则为StdErr(如果StdErr是TTY则打印到了XCode控制台中)。NSLog也可以用过freopen重定向来完成一些我们需要的日志打印（比如打印到某个view上等等）详细可以看[这里](http://www.cocoachina.com/ios/20160616/16719.html)
那么其实知道NSLog是有什么组成了就很好搞定了。首先，我们之前说了DDLog有个类就是写入SAL的，我们看下其内部的实现，之前说了Log事件已分发到每一个日志记录器里了，那么我们直接看logMessage方法。
```
这是DDASLLogger里的logMessage方法
- (void)logMessage:(DDLogMessage *)logMessage {
    // Skip captured log messages
    if ([logMessage->_fileName isEqualToString:@"DDASLLogCapture"]) {
        return;
    }

    NSString * message = _logFormatter ? [_logFormatter formatLogMessage:logMessage] : logMessage->_message;

    if (message) {
        const char *msg = [message UTF8String];

        size_t aslLogLevel;
        switch (logMessage->_flag) {
            // Note: By default ASL will filter anything above level 5 (Notice).
            // So our mappings shouldn't go above that level.
            case DDLogFlagError     : aslLogLevel = ASL_LEVEL_CRIT;     break;
            case DDLogFlagWarning   : aslLogLevel = ASL_LEVEL_ERR;      break;
            case DDLogFlagInfo      : aslLogLevel = ASL_LEVEL_WARNING;  break; // Regular NSLog's level
            case DDLogFlagDebug     :
            case DDLogFlagVerbose   :
            default                 : aslLogLevel = ASL_LEVEL_NOTICE;   break;
        }

        static char const *const level_strings[] = { "0", "1", "2", "3", "4", "5", "6", "7" };

        // NSLog uses the current euid to set the ASL_KEY_READ_UID.
        uid_t const readUID = geteuid();

        char readUIDString[16];
#ifndef NS_BLOCK_ASSERTIONS
        size_t l = snprintf(readUIDString, sizeof(readUIDString), "%d", readUID);
#else
        snprintf(readUIDString, sizeof(readUIDString), "%d", readUID);
#endif

        NSAssert(l < sizeof(readUIDString),
                 @"Formatted euid is too long.");
        NSAssert(aslLogLevel < (sizeof(level_strings) / sizeof(level_strings[0])),
                 @"Unhandled ASL log level.");

        aslmsg m = asl_new(ASL_TYPE_MSG);
        if (m != NULL) {
            if (asl_set(m, ASL_KEY_LEVEL, level_strings[aslLogLevel]) == 0 &&
                asl_set(m, ASL_KEY_MSG, msg) == 0 &&
                asl_set(m, ASL_KEY_READ_UID, readUIDString) == 0 &&
                asl_set(m, kDDASLKeyDDLog, kDDASLDDLogValue) == 0) {
                asl_send(_client, m);
            }
            asl_free(m);
        }
        //TODO handle asl_* failures non-silently?
    }
}
```
方法中我们就能看到所做的事。先排查了是不是截取系统的NSLog，如果是截取系统的那就不需要再次写入了，然后做了数据的转化，获取了要写入的string。然后开始进行级别映射等把数据转化成写入ASL所需要的数据样式，最后写入ASL。因为很多用了底层的C方法就不细说了。还有写入控制台的方法，也基本调用了底层C方法主要使用writev方法。
这样只要把DDLog打印的分发到该2个日志记录器就等于实现了NSLog方法了。
##DDFileLogger的工作原理
##参考文章
http://www.jianshu.com/p/d8bad0e2683c




