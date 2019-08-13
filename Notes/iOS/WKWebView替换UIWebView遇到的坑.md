### WKWebView替换UIWebView遇到的坑（大纲）

https://mp.weixin.qq.com/s/rhYKLIbXOsUJC_n6dt9UfA

除去上面的坑，在适配过程中还遇到了几个坑：

1.H5调用拨打拨打电话需要自己拦截判断来实现。

2.alert上面的文章也提起了，需要实现WKUIDelegate实现。

3.<a target=_blank href="xxxxxxx">这类在窗口打开连接WKWebView发现没有窗口就不在请求，所以在拦截处做了navigationAction.targetFrame == nil的判断，如果是这样则让webView发起该请求。 

4.wkwebview 在input readonly 仍会获取焦点 只能h5 获取焦点的方法 立马失去焦点。

5.jscontext 这套完全变了，wkwebview也有方式实现jscontext的效果，但是如果需要前端不改代码还有一种方式实现那就是用注入对象，用桥接的方式转化掉调用的方法。

