// This file contains the source for the Javascript side of the
// WebViewJavascriptBridge. It is plaintext, but converted to an NSString
// via some preprocessor tricks.
//
// Previous implementations of WebViewJavascriptBridge loaded the javascript source
// from a resource. This worked fine for app developers, but library developers who
// included the bridge into their library, awkwardly had to ask consumers of their
// library to include the resource, violating their encapsulation. By including the
// Javascript as a string resource, the encapsulation of the library is maintained.

#import "WebViewJavascriptBridge_JS.h"

// 这是需要注入的一段js
NSString * WebViewJavascriptBridge_js() {
	#define __wvjb_js_func__(x) #x
	
	// BEGIN preprocessorJSCode
	static NSString * preprocessorJSCode = @__wvjb_js_func__(
;(function() {
    // 如果存在WebViewJavascriptBridge 这个属性则证明初始化过了，直接结束方法
	if (window.WebViewJavascriptBridge) {
		return;
	}
        
    // onerror函数会在页面发生js错误时被调用。 所以如果不存在 给它赋值打印错误日志
	if (!window.onerror) {
		window.onerror = function(msg, url, line) {
			console.log("WebViewJavascriptBridge: ERROR:" + msg + "@" + url + ":" + line);
		}
	}
    // 创建WebViewJavascriptBridge这个对象里面
	window.WebViewJavascriptBridge = {
        // js注册方法
		registerHandler: registerHandler,
        // js调用oc的方法
		callHandler: callHandler,
        // 禁用js超时提示框
		disableJavscriptAlertBoxSafetyTimeout: disableJavscriptAlertBoxSafetyTimeout,
        // 获取数据队列
		_fetchQueue: _fetchQueue,
        // 处理来自OC的消息
		_handleMessageFromObjC: _handleMessageFromObjC
	};

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
        
    //web端注册一个调用的方法
	function registerHandler(handlerName, handler) {
		messageHandlers[handlerName] = handler;
	}
	// 这个是js调用oc的方法
	function callHandler(handlerName, data, responseCallback) {
        // 这里在判断调用的参数 调用的参数只有两个 且第二个参数是个方法，重新设置调用的参数
		if (arguments.length == 2 && typeof data == 'function') {
			responseCallback = data;
			data = null;
		}
        // 把 方法名与参数作为一个输入，回调作为另一个参数r传入
		_doSend({ handlerName:handlerName, data:data }, responseCallback);
	}
    // 这里个bool 是是否使用Timeout 调用
	function disableJavscriptAlertBoxSafetyTimeout() {
		dispatchMessagesWithTimeoutSafety = false;
	}
	
	function _doSend(message, responseCallback) {
        // 如果 responseCallback存在，即需要回调的Id 为 cb_消息id_当前时间 为了唯一
		if (responseCallback) {
			var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
            // 把回调存在responseCallbacks中
			responseCallbacks[callbackId] = responseCallback;
            // 为message 增加 callbackId 字段
			message['callbackId'] = callbackId;
		}
        // 这里就是核心了 这里把消息加入sendMessageQueue 这个数组
		sendMessageQueue.push(message);
        // 设置src 做一个路径跳转
		messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
	}
    // 这个方法是把之前前端通过callHandler 之后调用_doSend存入sendMessageQueue的数据转化为JSON 返回并把sendMessageQueue清空
	function _fetchQueue() {
		var messageQueueString = JSON.stringify(sendMessageQueue);
		sendMessageQueue = [];
		return messageQueueString;
	}

	function _dispatchMessageFromObjC(messageJSON) {
		if (dispatchMessagesWithTimeoutSafety) {
			setTimeout(_doDispatchMessageFromObjC);
		} else {
			 _doDispatchMessageFromObjC();
		}
		//这里其实是OC调用jsd之后的处理方法了
		function _doDispatchMessageFromObjC() {
			var message = JSON.parse(messageJSON);
			var messageHandler;
			var responseCallback;
            // 判断是否存在当初js调用oc的回调如果存在则t调用回到
			if (message.responseId) {
				responseCallback = responseCallbacks[message.responseId];
				if (!responseCallback) {
					return;
				}
				responseCallback(message.responseData);
				delete responseCallbacks[message.responseId];
			} else {
                // 这里其实就是OC 调用js方法
                // 首先有没有需要回调的方法 如果有就设置回调
				if (message.callbackId) {
					var callbackResponseId = message.callbackId;
					responseCallback = function(responseData) {
                        // 其实回调就是通过 _doSend 像oc 发送消息
						_doSend({ handlerName:message.handlerName, responseId:callbackResponseId, responseData:responseData });
					};
				}
				
                // hander 不存在说明 是有错误的 messageHandlers 存储了所有注册的方法
				var handler = messageHandlers[message.handlerName];
				if (!handler) {
					console.log("WebViewJavascriptBridge: WARNING: no handler for message from ObjC:", message);
				} else {
                    // 调用该方法，一个数据，一个回调
					handler(message.data, responseCallback);
				}
			}
		}
	}
	// 这个就是上面的方法
	function _handleMessageFromObjC(messageJSON) {
        _dispatchMessageFromObjC(messageJSON);
	}
    // 初始化messagingIframe对象 然后发送一次消息
	messagingIframe = document.createElement('iframe');
	messagingIframe.style.display = 'none';
	messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
	document.documentElement.appendChild(messagingIframe);
        
    // 注册disableJavscriptAlertBoxSafetyTimeoutd方法
	registerHandler("_disableJavascriptAlertBoxSafetyTimeout", disableJavscriptAlertBoxSafetyTimeout);
	
	setTimeout(_callWVJBCallbacks, 0);
    // 暂时不明这是干啥用的
	function _callWVJBCallbacks() {
		var callbacks = window.WVJBCallbacks;
		delete window.WVJBCallbacks;
		for (var i=0; i<callbacks.length; i++) {
			callbacks[i](WebViewJavascriptBridge);
		}
	}
})();
	); // END preprocessorJSCode

	#undef __wvjb_js_func__
	return preprocessorJSCode;
};
