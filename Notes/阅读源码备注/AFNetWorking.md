## AFNetWorking 

#### AFURLSessionManager

1.AFURLSessionManager 主要做了什么？

AFURLSessionManager是AF的核心类，主要的作用就是发送请求，发送请求的主要步骤如下：
1.需要创建一个AFURLSessionManager其实传入的配置就是创建了一个session。

2.通过session 创建task。

3.通过task发送请求。

这里要注意的是AFURLSessionManager中还有一个类，那就是AFURLSessionManagerTaskDelegate，那么这个类的主要作用是：

1.存贮上传下载返回的回调。

2.实现task级别的代理回调(回调方式是直接调用方法不是真的代理)，由该类处理所有的回调。

那么如何做AFURLSessionManagerTaskDelegate与task的绑定呢？

其实很简单的想法就出来了键值对：task.taskIdentifier为键 而delegate为值就可以了。

最后AFURLSessionManager，做了很多通知等，会发现有大量的钩子，提供给用户使用。

#### AFURLRequestSerialization

这是一个请求的序列化器 一般会通过URL与parameters 生成request  当然生成request 过程中还是有很多配置的，都可以在AFURLRequestSerialization里设置，典型的有编码方式等等。

生成request之后 在通过session 生成task发送请求。

#### AFHTTPResponseSerializer

这是解析返回值的序列化器，这里AF写了一个父类AFHTTPResponseSerializer 父类主要是校验数据是否正确以及请求是否成功。这里默认写着返回码为100 或200时候请求成功。

后面定义了很多子类来解析不同的数据，其中有AFJSONResponseSerializer、AFXMLParserResponseSerializer等等。而子类的实现也简单，主要是先调用父类的方法判断请求是否成功，数据是否可以解析。然后在调用子类相应数据的解析方法。当然子类里也可以实现一些特性方法，比如AFJSONResponseSerializer里就实现了一个过滤空字段的方法。只需要你设置BOOL类型的值进行开关就可以了。

解析完数据后返回对应的数据。

#### AFNetworkReachabilityManager

这是一个网络监听的类，主要是通过SCNetworkReachabilityRef实现的。其实也没啥东西，就是SCNetworkReachabilityRef的一个检测封装，写了一套枚举，可以设置回调，可以设置一个共享的，但是回调也就一份，需要使用的地方还是自己创建可以比较好。可以监听某个地址，都可以。主要是实现是把监听任务加入的到runloop里。

这里有个坑，我以为AF实现了监听网络 网络不好直接不发请求之类的吊爆了的功能，实际上没有（估计被删了）。在AFURLSessionManager里只有一个AFNetworkReachabilityManager创建的方法 其他啥也没有，说明根本就没有用到这个网络检测类。不过用户自己使用倒是十分不错的。

#### AFSecurityPolicy

这是一个校验证书的库  所有需要校验证书的地方如果用户没有实现钩子方法都会使用AFSecurityPolicy中的校验方法。

AFSecurityPolicy 有个验证方式的枚举，可以选择默认（校验有效性）、校验自己设置的证书以及添加的公钥三总。还有是否校验Domain以及是否校验证书是否有效两个bool类型的值可供选择。

AF默认的情况是用的校验默认的 切校验有效性以及Domain。当然你如果需要修改可以在AFURLSessionManager创建后修改。

#### AFNetWorking做了什么？

1.主要为我们写一个一套通过NSURLSession生成task 以及发送请求后与回调绑定的机制。

2.为了让请求良好的发出，则需要一个转化为请求对象再让NSURLSession生成task。这时候就有了请求的序列化器。在这里我们可以配置所有我们想配置的东西，当然如果AF所提供的不满足需求还可以自己实现协议来实现它。

3.为我们请求返回的数据做了简单的处理。主要靠的是响应序列化器。为什么说简单处理呢，这里主要验证了请求范围的状态码已经把数据转化为我们约定的json或者其他数据。而进一步的数据转model 需要你自己完成。当然如果AF提供的序列化器你觉得不能满足需求也可以自己实现，只要遵守了其相应的协议就好了。

4.关于安全相关的证书校验，AF专门也拉出了一个类AFSecurityPolicy来处理。这里基本能满足你不校验，正常校验，校验自建证书等需求了。

5.最后还提供了一个网络检测类AFNetworkReachabilityManager当然在整个请求里它自己是没有使用的。如果你需要使用可以使用。

另外一块是UIKit+AFNetworking 输入插件性质的是模块，使用较少，这里就忽略了。

#### AFNetWorking如何提高性能

其实提高性能最简单的方式可能就是很多方法用C写。静态语言的编译执行速度绝对高于动态语言的。

有兴趣的可以看下代码注解或者自己看下源码。