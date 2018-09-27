## AFNetWorking 

### 1.做了什么

### 2.怎么做的

### 3.核心架构是什么

#### 4.AF中的线程相关



 

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

生成request之后 在通过session 生成task 发送请求。

#### AFHTTPResponseSerializer

这是解析返回值的序列化器，这里AF写了一个父类AFHTTPResponseSerializer 父类主要是校验数据是否正确以及请求是否成功。这里默认写着返回码为100 或200时候请求成功。

后面定义了很多子类来解析不同的数据，其中有AFJSONResponseSerializer、AFXMLParserResponseSerializer等等。而子类的实现也简单，主要是先调用父类的方法判断请求是否成功，数据是否可以解析。然后在调用子类相应数据的解析方法。当然子类里也可以实现一些特性方法，比如AFJSONResponseSerializer里就实现了一个过滤空字段的方法。只需要你设置BOOL类型的值进行开关就可以了。

解析完数据后返回对应的数据。

#### AFNetworkReachabilityManager

这是一个网络监听的类，主要是通过SCNetworkReachabilityRef实现的。其实也没啥东西，就是SCNetworkReachabilityRef的一个检测封装，写了一套枚举，可以设置回调，可以设置一个共享的，但是回调也就一份，需要使用的地方还是自己创建可以比较好。可以监听某个地址，都可以。主要是实现是把监听任务加入的到runloop里。

这里有个坑，我以为AF实现了监听网络 网络不好直接不发请求之类的吊爆了的功能，实际上没有（估计被删了）。在AFURLSessionManager里只有一个AFNetworkReachabilityManager创建的方法 其他啥也没有，说明根本就没有用到这个网络检测类。不过用户自己使用倒是十分不错的。