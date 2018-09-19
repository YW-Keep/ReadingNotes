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





请求的封装与SessionManger  他只负责，通过request 创建task