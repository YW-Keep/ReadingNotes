//
//  WebViewJavascriptBridgeBase.h
//
//  Created by @LokiMeyburg on 10/15/14.
//  Copyright (c) 2014 @LokiMeyburg. All rights reserved.
//

#import <Foundation/Foundation.h>

// 初始宏，链接的头部
#define kOldProtocolScheme @"wvjbscheme"
#define kNewProtocolScheme @"https"
// 这个是有消息的那个识别符 与JS 一直
#define kQueueHasMessage   @"__wvjb_queue_message__"
// 一个加载brid的标志符
#define kBridgeLoaded      @"__bridge_loaded__"

typedef void (^WVJBResponseCallback)(id responseData);
typedef void (^WVJBHandler)(id data, WVJBResponseCallback responseCallback);
typedef NSDictionary WVJBMessage;

@protocol WebViewJavascriptBridgeBaseDelegate <NSObject>
// 传入js 代码
- (NSString*) _evaluateJavascript:(NSString*)javascriptCommand;
@end

@interface WebViewJavascriptBridgeBase : NSObject


@property (weak, nonatomic) id <WebViewJavascriptBridgeBaseDelegate> delegate;

// 用来存放需要发送的消息
@property (strong, nonatomic) NSMutableArray* startupMessageQueue;
// 用来存放回调的
@property (strong, nonatomic) NSMutableDictionary* responseCallbacks;
// 用来存放方法名
@property (strong, nonatomic) NSMutableDictionary* messageHandlers;
// 这个暂时不知道干啥用的。
@property (strong, nonatomic) WVJBHandler messageHandler;

// 启用日志
+ (void)enableLogging;
// 设置日志最大长度
+ (void)setLogMaxLength:(int)length;
// 重置
- (void)reset;
// 这个方法是把数据组装好，如果有回调则存入回调 然后调用发送消息
- (void)sendData:(id)data responseCallback:(WVJBResponseCallback)responseCallback handlerName:(NSString*)handlerName;
//  这里是处理js过来的消息数据的
- (void)flushMessageQueue:(NSString *)messageQueueString;
//  注入js文件
- (void)injectJavascriptFile;
// 这是判断这个URL是不是JavascriptBridge标志的URL
- (BOOL)isWebViewJavascriptBridgeURL:(NSURL*)url;
// 是不是消息
- (BOOL)isQueueMessageURL:(NSURL*)urll;
// 是不是首次加载
- (BOOL)isBridgeLoadedURL:(NSURL*)urll;
// 打印未知消息
- (void)logUnkownMessage:(NSURL*)url;
// 这个是检查WebViewJavascriptBridge 是不是存在
- (NSString *)webViewJavascriptCheckCommand;
// 获取fetchQueue的sstring
- (NSString *)webViewJavascriptFetchQueyCommand;
//  这个之前JS代码里是有的就是是不是使用Timeout调用
- (void)disableJavscriptAlertBoxSafetyTimeout;

@end
