//
//  WKWebViewJavascriptBridge.h
//
//  Created by @LokiMeyburg on 10/15/14.
//  Copyright (c) 2014 @LokiMeyburg. All rights reserved.
//

#if (__MAC_OS_X_VERSION_MAX_ALLOWED > __MAC_10_9 || __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_1)
#define supportsWKWebView
#endif

#if defined supportsWKWebView

#import <Foundation/Foundation.h>
#import "WebViewJavascriptBridgeBase.h"
#import <WebKit/WebKit.h>

@interface WKWebViewJavascriptBridge : NSObject<WKNavigationDelegate, WebViewJavascriptBridgeBaseDelegate>

// 修改
+ (instancetype)bridgeForWebView:(WKWebView*)webView;
// 开启日志
+ (void)enableLogging;
// 注册方法
- (void)registerHandler:(NSString*)handlerName handler:(WVJBHandler)handler;
// 删除方法
- (void)removeHandler:(NSString*)handlerName;
// 调用方法
- (void)callHandler:(NSString*)handlerName;
- (void)callHandler:(NSString*)handlerName data:(id)data;
- (void)callHandler:(NSString*)handlerName data:(id)data responseCallback:(WVJBResponseCallback)responseCallback;
// 重置
- (void)reset;
// 设置webviewdelegate
- (void)setWebViewDelegate:(id)webViewDelegate;

- (void)disableJavscriptAlertBoxSafetyTimeout;

@end

#endif
