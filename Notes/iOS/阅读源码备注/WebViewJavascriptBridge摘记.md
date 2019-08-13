### WebViewJavascriptBridge摘记

这个库相对简单，其核心文件其实只有2个一个是注入到js中的文件，一个是baseBride文件。

主要的核心思想是:

1.通过拦截URL 进行js与原生代码交互。

2.原生代码可以直接调用Js代码。

3.都走同一个消息方法，在进行分发。

4.js通过html通知原生有消息，然后原生去拉去消息。

5.回调都保存在自己端，通过返回的回调id进行调用。

6.baseBride上层有wkwebview以及uiwebview的bridge,因为代理让bride实现了，所以Bride有个设置代理的方式，如果存在会在调用外层方法，所以外层需要使用webview的代理需要在bride上设置。

其他详情请看源码注释，另外因为UIWebView渐渐被淘汰了 所以这里没有写注释，原理是一样的