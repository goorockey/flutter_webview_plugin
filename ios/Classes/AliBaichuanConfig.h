//
//  AliBaichuanConfig.h
//  flutter_webview_plugin
//
//  Created by 王贺天 on 2018/12/18.
//
#import <Flutter/Flutter.h>
#import <AlibabaAuthSDK/ALBBSDK.h>
#import <AlibcTradeSDK/AlibcTradeSDK.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AliBaichuanConfig : NSObject
@property (nonatomic, retain) AlibcTradeTaokeParams *taokeParams;
@property (nonatomic, retain) AlibcTradeShowParams *showParams;
+ (instancetype)sharedInstance;
- (void)initBcSDK: (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)login: (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)isLogin: (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)getUser: (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)logout: (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)show: (NSString *)page;
- (void)showInWebView:(UIWebView *)webView url:(NSString *)url;
@end

NS_ASSUME_NONNULL_END
