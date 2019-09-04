##WebViewJavascriptBridge分析

###1.这个库是干啥用的？

这是一个客户端与前端交互的库，主要是提供一些封装，用URL拦截的方式，实现前端调用客户端，至于客户端调用前端js代码，则可以直接调用。在客户端中可以通过该库向前端开放一些协议，比如获取当前客户端的版本号，获取当前网络状态亦或者获取登录状态等等。

###2.这个库主要有那几部分组成，分别有什么作用？

这个库相对比较简单，所用的文件也不多。主要有四个文件：

####WebViewJavascriptBridge_JS

这其实是一个js代码文件，主要的作用就是初始化前端的WebViewJavascriptBridge环境。因为这个库是双向调用的，所以在前端环境里也需要生成WebViewJavascriptBridge对象，前端主要也是通过这个对象来与客户端进行交互。

这里简单介绍一下WebViewJavascriptBridge：

```javascript
   // 创建WebViewJavascriptBridge这个对象里面
	window.WebViewJavascriptBridge = {
		registerHandler: registerHandler,
		callHandler: callHandler,
		disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
		_fetchQueue: _fetchQueue,
		_handleMessageFromObjC: _handleMessageFromObjC
	};
```

而在全局下又定义了如下几个字段：

```JavaScript
    // iframe 对象用来发送URL
	var messagingIframe;
    // 储存消息列表（发送给oc的消息）
	var sendMessageQueue = [];
    // 储存注册方法
	var messageHandlers = {};
	//  这两个字段是为了拼接消息发送的路径
	var CUSTOM_PROTOCOL_SCHEME = 'https';
	var QUEUE_HAS_MESSAGE = '__wvjb_queue_message__';
	// js 调用oc 方法的回调
	var responseCallbacks = {};
    // 消息id
	var uniqueId = 1;
    // 这里个bool 是是否使用Timeout 调用
	var dispatchMessagesWithTimeoutSafety = true;
```

这些全局变量，我们可以先随便看看，具体使用可以在方法里看到。接下来看下每个方法：

#####registerHandler-前端注册方法

```javascript
  //web端注册一个调用的方法
	function registerHandler(handlerName, handler) {
		messageHandlers[handlerName] = handler;
	}
```

这个代码很简单，就是把方法名和方法的实现设置到了messageHandlers对象中。

##### callHandler-前端调用客户端入口

这里是前端调用客户端的统一方法入口:

```javascript
	function callHandler(handlerName, data, responseCallback) {
     
		if (arguments.length == 2 && typeof data == 'function') {
			responseCallback = data;
			data = null;
		}
		_doSend({ handlerName:handlerName, data:data }, responseCallback);
	}
```

第一个参数为方法名，第二个为数据，第三个为回调方法，这里做了一次中转，主要是去判调用有几个参数，如果是两个且最后一个是回调，则重新设置了下参数，最后调用到了_doSend中，我们看下这里做了什么：

```javascript
	function _doSend(message, responseCallback) {
		if (responseCallback) {
			var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
			responseCallbacks[callbackId] = responseCallback;
			message['callbackId'] = callbackId;
		}
		sendMessageQueue.push(message);
		messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
	}
```

这个发送方法主要做了3件事情：

1.如果存在回调方法，则生成一个唯一的回调id，且把这个键值对加到message中(之前已经加了2个字段了一个方法名，一个调用参数)

2.把这个message 加入到sendMessageQueue数组中，等待客户端来取。

3.使用messagingIframe 发送了一个消息。

其实从这里就可以看出一个很重要的点：**客户端拦截只是一个事件，这个事件是告诉客户端前端有方法调用。**这么做其实有很多好处，主要是的好处是拦截请求单一精简，不耦合业务代码。

##### _fetchQueue-客户端调用获取数据的方法

```javascript
function _fetchQueue() {
		var messageQueueString = JSON.stringify(sendMessageQueue);
		sendMessageQueue = [];
		return messageQueueString;
}
```

这个就是个很简单的获取方法，把数据转化成了json。（这个方法加了_其实喻义就是私用）

##### _handleMessageFromObjC-处理来自OC端的消息

```javascript

function _handleMessageFromObjC(messageJSON) {
        _dispatchMessageFromObjC(messageJSON);
}
function _dispatchMessageFromObjC(messageJSON) {
		if (dispatchMessagesWithTimeoutSafety) {
			setTimeout(_doDispatchMessageFromObjC);
		} else {
			 _doDispatchMessageFromObjC();
		}
		function _doDispatchMessageFromObjC() {
			var message = JSON.parse(messageJSON);
			var messageHandler;
			var responseCallback;
			if (message.responseId) {
				responseCallback = responseCallbacks[message.responseId];
				if (!responseCallback) {
					return;
				}
				responseCallback(message.responseData);
				delete responseCallbacks[message.responseId];
			} else {
				if (message.callbackId) {
					var callbackResponseId = message.callbackId;
					responseCallback = function(responseData) {
						_doSend({ handlerName:message.handlerName, responseId:callbackResponseId, responseData:responseData });
					};
				}
				var handler = messageHandlers[message.handlerName];
				if (!handler) {
					console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
				} else {
					handler(message.data, responseCallback);
				}
			}
		}
}
```

这里两个方法很长我们细细梳理下：

第一个方法主要是做了一次转发而已。（猜测跟版本兼容有关系）

第二个方法主内部还有个方法，在方法开始做了一次判断是不是使用setTimeout方式异步调用。

最后调入了内部的方法_doDispatchMessageFromObjC中，我们看看__doDispatchMessageFromObjC做了什么：

1.解析了message消息对象

2.判断是不是存在responseId，如果存在则取出来（说明这是当初前面提到过的前端调用客户的回调），

3.如果不存在responseId，则是说明是客户端调用了前端的方法，这里做的是首先判断有没有callbackId，如果有存在说明需要回调，则封装一个responseCallback的回调。

4.最后通过handlerName即方法名，在messageHandlers中找到注册的方法，如果找不到则打印错误，找到了调用该方法。

从这里，我们也可以发现一件事件：**客户端调用前端方法其实也只有一个方法就是_handleMessageFromObjC其他业务的字段都封装在了message中。**

到这里其实，前端的部分已经完全明了了。我通过WebViewJavascriptBridge这个对象就可以完成对OC调用了。但是其实，这里还有一个问题：那就是这个对象是什么时候注入的？别急我们继续细细分析。

#### WebViewJavascriptBridgeBase

接下来我们看下这个类，这个类主要是客户端的功能类,其实所有的实质性处理都在这个类中，我们来看看他的几个主要的属性和方法：

```objective-c
// 用来存放在初始化之前获得的消息
@property (strong, nonatomic) NSMutableArray* startupMessageQueue;
// 用来存放回调的
@property (strong, nonatomic) NSMutableDictionary* responseCallbacks;
// 用来存放注册方法
@property (strong, nonatomic) NSMutableDictionary* messageHandlers;

- (void)sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName;
- (void)flushMessageQueue:(NSString *)messageQueueString;
- (void)injectJavascriptFile;
- (NSString *)webViewJavascriptFetchQueyCommand;
```

##### 注册方法

```objective-c
- (void)injectJavascriptFile {
    NSString *js = WebViewJavascriptBridge_js();
    [self _evaluateJavascript:js];
    if (self.startupMessageQueue) {
        NSArray* queue = self.startupMessageQueue;
        self.startupMessageQueue = nil;
        for (id queuedMessage in queue) {
            [self _dispatchMessage:queuedMessage];
        }
    }
}
- (void) _evaluateJavascript:(NSString *)javascriptCommand {
    [self.delegate _evaluateJavascript:javascriptCommand];
}
```

这里我们可以看到，读取了我们第一个分析的js文件WebViewJavascriptBridge_js，然后执行了js方法，这里可以看到WebViewJavascriptBridgeBase其实没有能力执行js，只有webView才有，所以设置了一个代理，把方法代理出去了。

另外，这里还有个逻辑就是startupMessageQueue，就是在注入bridge之前，如果客户端调用了前端的方法，则把这些调存在了startupMessageQueue中。在注入之后，则去判断了startupMessageQueue是否是nil,如果不是则把里面保存的调用再次执行了一次。

##### 客户端调用前端

```objective-c
- (void)sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName {
    NSMutableDictionary* message = [NSMutableDictionary dictionary];
    if (data) {
        message[@"data"] = data;
    }
    if (responseCallback) {
        NSString* callbackId = [NSString stringWithFormat:@"objc_cb_%ld", ++_uniqueId];
        self.responseCallbacks[callbackId] = [responseCallback copy];
        message[@"callbackId"] = callbackId;
    }
    if (handlerName) {
        message[@"handlerName"] = handlerName;
    }
    [self _queueMessage:message];
}

- (void)_queueMessage:(WVJBMessage*)message {
    if (self.startupMessageQueue) {
        [self.startupMessageQueue addObject:message];
    } else {
        [self _dispatchMessage:message];
    }
}

- (void)_dispatchMessage:(WVJBMessage*)message {
    NSString *messageJSON = [self _serializeMessage:message pretty:NO];
    [self _log:@"SEND" json:messageJSON];
    // 这里省略了messageJSON字符串的一些替换处理
    NSString* javascriptCommand = [NSString stringWithFormat:@"WebViewJavascriptBridge._handleMessageFromObjC('%@');", messageJSON];
    if ([[NSThread currentThread] isMainThread]) {
        [self _evaluateJavascript:javascriptCommand];

    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self _evaluateJavascript:javascriptCommand];
        });
    }
}
```

这三个方法是一个完整的流程：

第一个方法跟前端一样先组装了一个message：1.判断有没有入参，如果有对message设置。2.判断responseCallback是否存在，如果存在则生成一个唯一的callbackId，然后把responseCallback存入responseCallbacks字典中。对message设置callbackId。3.设置方法名。

第二个方法则判断了是否已经注入了bridge（因为注入之后startupMessageQueue是nil），没有注入则保存这个message，注入了直接调用发送。

第三方法则是正在的发送方法：1.先把message转化成string，处理了这个string。2.调用了之前WebViewJavascriptBridge中的_handleMessageFromObjC方法。3.通过代理执行这段js。(这里确保了在主线程中执行) 

至此我们可以看到客户端调用前端的流程已经完成了。

##### 前端调用客户端

```objective-c
- (NSString *)webViewJavascriptFetchQueyCommand {
    return @"WebViewJavascriptBridge._fetchQueue();";
}
```

首先，在webViewJavascriptFetchQueyCommand里有个方法是获取这么一段字符串的，前面我们已经讲过了这是获取前端所有消息的方法。

```objective-c
- (void)flushMessageQueue:(NSString *)messageQueueString{
    if (messageQueueString == nil || messageQueueString.length == 0) {
        NSLog(@"WebViewJavascriptBridge: WARNING: ObjC got nil while fetching the message queue JSON from webview. This can happen if the WebViewJavascriptBridge JS is not currently present in the webview, e.g if the webview just loaded a new page.");
        return;
    }

    id messages = [self _deserializeMessageJSON:messageQueueString];
    for (WVJBMessage* message in messages) {
        if (![message isKindOfClass:[WVJBMessage class]]) {
            NSLog(@"WebViewJavascriptBridge: WARNING: Invalid %@ received: %@", [message class], message);
            continue;
        }
        [self _log:@"RCVD" json:message];
        NSString* responseId = message[@"responseId"];
        if (responseId) {
            WVJBResponseCallback responseCallback = _responseCallbacks[responseId];
            responseCallback(message[@"responseData"]);
            [self.responseCallbacks removeObjectForKey:responseId];
        } else {
            WVJBResponseCallback responseCallback = NULL;
            NSString* callbackId = message[@"callbackId"];
            if (callbackId) {
                responseCallback = ^(id responseData) {
                    if (responseData == nil) {
                        responseData = [NSNull null];
                    }
                    
                    WVJBMessage* msg = @{ @"responseId":callbackId, @"responseData":responseData };
                    [self _queueMessage:msg];
                };
            } else {
                responseCallback = ^(id ignoreResponseData) {
                    // Do nothing
                };
            }
            WVJBHandler handler = self.messageHandlers[message[@"handlerName"]];
            
            if (!handler) {
                NSLog(@"WVJBNoHandlerException, No handler for message from JS: %@", message);
                continue;
            }
            handler(message[@"data"], responseCallback);
        }
    }
}
```

上面这个方法就是处理，获取信息的方法，我们分析下做了什么事情：

1.解析获取到的string，转成字典，这里的WVJBMessage是字典的别名。

2.获取了responseId，如果存在则是回调，那么从_responseCallbacks中获取回调，执行该回调，执行后删除回调记录。

3.如果没有就说明是前端调用的客户端，先看看是否存在callbackId如果存在则是需要回调的，封装好回调方法，如果不存在不做处理。

4.通过方法名取出方法，如果方法不存在，则输出错误。如果存在则传入数据与回调调用该方法。

从这里我们也能看到客户端如何去获取以及处理前端的调用了。

##### 总结

其实到这里，我们所需的功能已经全部通了。正如我上句话说的其实WebViewJavascriptBridgeBase就是一个基础的功能类。它里面还有几个方法我们没有细说比如：

```objective-c
- (BOOL)isWebViewJavascriptBridgeURL:(NSURL*)url {
    if (![self isSchemeMatch:url]) {
        return NO;
    }
    return [self isBridgeLoadedURL:url] || [self isQueueMessageURL:url];
}

- (BOOL)isSchemeMatch:(NSURL*)url {
    NSString* scheme = url.scheme.lowercaseString;
    return [scheme isEqualToString:kNewProtocolScheme] || [scheme isEqualToString:kOldProtocolScheme];
}

- (BOOL)isQueueMessageURL:(NSURL*)url {
    NSString* host = url.host.lowercaseString;
    return [self isSchemeMatch:url] && [host isEqualToString:kQueueHasMessage];
}

- (BOOL)isBridgeLoadedURL:(NSURL*)url {
    NSString* host = url.host.lowercaseString;
    return [self isSchemeMatch:url] && [host isEqualToString:kBridgeLoaded];
}
```

这几个是用来判断是是否需要拦截的URL。其实到这里我们还是没有解决上个类分析完之后的问题-这个对象是什么时候注入的？还多了个问题什么时候去获取webViewJavascriptFetchQueyCommand呢？

####WebViewJavascriptBridge与WKWebViewJavascriptBridge

这两个类其实可以说是一样的，对客户端来说WebViewJavascriptBridge针对的是UIWebView而WKWebViewJavascriptBridge针对的是WKWebview，这里我们就分析一个WKWebview吧，一样的方式先来看属性：

```objective-c
    __weak WKWebView* _webView;
    __weak id<WKNavigationDelegate> _webViewDelegate;
    long _uniqueId;
    WebViewJavascriptBridgeBase *_base;
```

不难看出是干嘛的，不过我们继续看下方法：

##### WebViewJavascriptBridgeBase相关

```objective-c
+ (instancetype)bridgeForWebView:(WKWebView*)webView {
    WKWebViewJavascriptBridge* bridge = [[self alloc] init];
    [bridge _setupInstance:webView];
    [bridge reset];
    return bridge;
}
- (void) _setupInstance:(WKWebView*)webView {
    _webView = webView;
    _webView.navigationDelegate = self;
    _base = [[WebViewJavascriptBridgeBase alloc] init];
    _base.delegate = self;
}
- (void)registerHandler:(NSString *)handlerName handler:(WVJBHandler)handler {
    _base.messageHandlers[handlerName] = [handler copy];
}
- (void)callHandler:(NSString *)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback {
    [_base sendData:data responseCallback:responseCallback handlerName:handlerName];
}
```

上面的代码比较简单，前两个是创建WKWebViewJavascriptBridge，从代码里可可以看到其实主要引用了wkwebview以及代理了它的navigationDelegate，还有就是初始化了base这个我们之前分析过的类，之后两个方法一个是注册，一个是调用，可以明显的看出来其实都是交给base来处理的。这和我们之前分析的吻合。

##### delegate相关

这里我们就可以解答之前的问题了：

```objective-c
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (webView != _webView) { return; }
    NSURL *url = navigationAction.request.URL;
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;

    if ([_base isWebViewJavascriptBridgeURL:url]) {
        if ([_base isBridgeLoadedURL:url]) {
            [_base injectJavascriptFile];
        } else if ([_base isQueueMessageURL:url]) {
            [self WKFlushMessageQueue];
        } else {
            [_base logUnkownMessage:url];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [_webViewDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}
- (void)WKFlushMessageQueue {
    [_webView evaluateJavaScript:[_base webViewJavascriptFetchQueyCommand] completionHandler:^(NSString* result, NSError* error) {
        if (error != nil) {
            NSLog(@"WebViewJavascriptBridge: WARNING: Error when trying to fetch data from WKWebView: %@", error);
        }
        [_base flushMessageQueue:result];
    }];
}
```

在WKWebView请求发送之前（加载的第一步），这个方法中进行了拦截，我们看看做了什么

1.校验是不是加载bridge的或者是消息的url，如果是则拦截。

2.如果是加载bridge，则通过base加载，如果是消息，则获取消息。

3.如果不是，则判断是不是设置了代理，如果设置了则代理出去。

到这里我们就能很好的解释之前的问题了，原来是通过webview的代理，去做了设置，而且这里有个特殊的信号去注入js代码，也就是说前端通过：

```js
     var WVJBIframe = document.createElement('iframe');
        WVJBIframe.style.display = 'none';
        WVJBIframe.src = 'https://__bridge_loaded__';
```

这样的跳转方式就可以让客户端完成初始化工作。

这里还有另外一个点要注意下：

因为代理了webview的方法，如果外面要用呢？

```objective-c
- (void)setWebViewDelegate:(id<WKNavigationDelegate>)webViewDelegate {
    _webViewDelegate = webViewDelegate;
}
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView != _webView) { return; }
    
    __strong typeof(_webViewDelegate) strongDelegate = _webViewDelegate;
    if (strongDelegate && [strongDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [strongDelegate webView:webView didFinishNavigation:navigation];
    }
}

```

从上面的代码就找到了答案，源码中实现了所有的代理方法，再通过你设置setWebViewDelegate：把新的代理代理进来，在当前代理方法中会去判断新的代理是否存在，如果存在则完美的代理了出去。

到这里我们可算是把这个简单的三方库分析完了。

### 3.思维导图?

这个库相对简单，就不画思维导图了，这里我们理一遍前端调用客户端获取一个版本号的逻辑。至于客户端调用前端其实原理是一样的。

1.客户端打开A页面（这时候已经注册了获取版本号方法）

2.前端页面打开通过Iframe发送bridge_loaded。

3.客户端webview页面加载拦截到了这个信息，加载了webviewbridge。（到这里其实前端的bridge已经有了）

4.前端调用获取方法。

5.前端的bridge封装message,把方法名，参数，回调id封装进message中，把message存到sendMessageQueue数组中，同时把回调存到responseCallbacks中。

6.前端的bridge通过Iframe发送wvjb_queue_message。

7.客户端的webview页面加载拦截到该信息通过执行js代码获取_fetchQueue信息。

8.客户端通过_handleMessageFromObjC处理获取来的message,封装了回调，从messageHandlers取出了方法进行调用。

9.客户端从方法里获取了版本号，然后通过回调调把获得版本号封装到message中的data里用_dispatchMessage方法回传给前端。

10.前端获取到了message，通过message中的callbackId获取到了对应的回调方法，回调该方法。

11.前端方法里获得了版本号。

### 4.还有哪些细节？

##### 1.WebViewJavascriptBridge与WKWebViewJavascriptBridge的统一

我们来看下WebViewJavascriptBridge中的创建方法：

```objective-c
+ (instancetype)bridge:(id)webView {
#if defined supportsWKWebView
    if ([webView isKindOfClass:[WKWebView class]]) {
        return (WebViewJavascriptBridge*) [WKWebViewJavascriptBridge bridgeForWebView:webView];
    }
#endif
    if ([webView isKindOfClass:[WVJB_WEBVIEW_TYPE class]]) {
        WebViewJavascriptBridge* bridge = [[self alloc] init];
        [bridge _platformSpecificSetup:webView];
        return bridge;
    }
    [NSException raise:@"BadWebViewType" format:@"Unknown web view type."];
    return nil;
}
```

这里能看出来，其实是判断了传入的webview，如果是WKWebview则直接返回WKWebViewJavascriptBridge的创建。这里要注意的点是WebViewJavascriptBridge与WKWebViewJavascriptBridge其实是两个可以说没有关系的NSObject。但是他们的方法名完全一样。这就是通过运行时很好的完成了统一。我们使用的时候不需要使用WKWebViewJavascriptBridge都用WebViewJavascriptBridge就可以了。

#####2.前端的保护机制

其实在注入的js代码中最开始的是：

```javascript
if (window.WebViewJavascriptBridge) {
		return;
	}
```

这样就很好的防止了多次注入的问题。还有个WVJBCallbacks，其实是为了防止在注入完成之前调用了一些方法的暂存机制，在客户端其实也有类似的：startupMessageQueue。

##### 3.日志系统

客户端这里其实是可以打印的日志的，这里通过类的方法设置一个静态量的方式做了一个比较好的解耦合。

```objective-c
//base中
static bool logging = false;
static int logMaxLength = 500;
+ (void)enableLogging { logging = true; }
- (void)_log:(NSString *)action json:(id)json {
    if (!logging) { return; }
    if (![json isKindOfClass:[NSString class]]) {
        json = [self _serializeMessage:json pretty:YES];
    }
    if ([json length] > logMaxLength) {
        NSLog(@"WVJB %@: %@ [...]", action, [json substringToIndex:logMaxLength]);
    } else {
        NSLog(@"WVJB %@: %@", action, json);
    }
}
```

##### 4.最后说个人认为不太合理的点

```objective-c
if (!handler) {
    NSLog(@"WVJBNoHandlerException, No handler for message from JS: %@", message);
    continue;
}
```

这代码是截取自客户端处理前端调用时，其实前端bridge中的也是一样，如果发现方法没有注册则直接只打印了错误没有做处理。

其实我是建议这里回调一个错误给前端的（如果前端是向客户端要数据的话）。

这样做的好处是比较容易控制新增加的方法，比如我新版本增加了获取客户端版本号协议，那老版本其实是没有的，这样前端在调用获取的时候老版本是没反应的，不太友好。