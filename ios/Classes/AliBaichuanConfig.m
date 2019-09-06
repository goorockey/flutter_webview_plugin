//
//  AliBaichuanConfig.m
//  flutter_webview_plugin
//
//  Created by debug on 2019/09/04. hongtang.online
//

#import "AliBaichuanConfig.h"
#import "FlutterWebviewPlugin.h"

@implementation AliBaichuanConfig{
    NSString *pid;
}
+ (instancetype) sharedInstance
{
    static AliBaichuanConfig *instance = nil;
    if (!instance) {
        instance = [[AliBaichuanConfig alloc] init];
    }
    return instance;
}

- (void)initBcSDK: (FlutterMethodCall*)call result:(FlutterResult)result
{
    // 百川平台基础SDK初始化，加载并初始化各个业务能力插件
    [[AlibcTradeSDK sharedInstance] setDebugLogOpen:YES];//开发阶段打开日志开关，方便排查错误信息
    
    [[AlibcTradeSDK sharedInstance] setIsvVersion:@"2.2.2"];
    [[AlibcTradeSDK sharedInstance] setIsvAppName:@"baichuanDemo"];
    [[AlibcTradeSDK sharedInstance] asyncInitWithSuccess:^{
        //      openSDKSwitchLog(NO);
        TLOG_INFO(@"百川SDK初始化成功");
    } failure:^(NSError *error) {
        TLOG_INFO(@"百川SDK初始化失败");
        result([FlutterError errorWithCode:[NSString stringWithFormat:@"%ld", (long)error.code] message:error.description details:@""]);
    }];
    

    
}

- (void)login: (FlutterMethodCall*)call result:(FlutterResult)result
{
    [[ALBBSDK sharedInstance]setAuthOption: NormalAuth];
    [[ALBBSDK sharedInstance] auth:[UIApplication sharedApplication].delegate.window.rootViewController
           successCallback:^(ALBBSession *session) {
               ALBBUser *s = [session getUser];
               NSDictionary *ret = @{
                                     @"nick": s.nick,
                                     @"avatar_url":s.avatarUrl,
                                     @"open_id":s.openId,
                                     @"open_sid":s.openSid,
                                     @"access_token": s.topAccessToken,
                                     @"auth_code": s.topAuthCode
                                     };

               result(ret);
           }
           failureCallback:^(ALBBSession *session, NSError *error) {
               result([FlutterError errorWithCode:[NSString stringWithFormat:@"%ld", (long)error.code] message:error.description details:@""]);
           }
     ];
}

- (void)isLogin: (FlutterMethodCall*)call result:(FlutterResult)result
{
    BOOL islogin = [[ALBBSession sharedInstance] isLogin];
    result([NSNumber numberWithBool: islogin]);
}

- (void)getUser: (FlutterMethodCall*)call result:(FlutterResult)result
{
    if([[ALBBSession sharedInstance] isLogin]){
        ALBBUser *s = [[ALBBSession sharedInstance] getUser];
        NSDictionary *ret = @{
                              @"nick": s.nick,
                              @"avatar_url":s.avatarUrl,
                              @"open_id":s.openId,
                              @"open_sid":s.openSid,
                              @"access_token": s.topAccessToken,
                              @"auth_code": s.topAuthCode
                              };
        
        result(ret);
    } else {
        result([FlutterError errorWithCode:@"101" message:@"请先登录淘宝账户" details:@""]);
    }
}

- (void)logout: (FlutterMethodCall*)call result:(FlutterResult)result
{
    [[ALBBSDK sharedInstance] logout];
    result(@"success");
}

- (void)show: (NSString *)url
{
    id<AlibcTradeService> service = [AlibcTradeSDK sharedInstance].tradeService;
    AlibcTradeShowParams *showParamsNatice = [[AlibcTradeShowParams alloc] init];
    showParamsNatice.openType = AlibcOpenTypeNative;
//    id<AlibcTradePage> page = [AlibcTradePageFactory page:url];


    [service
     openByUrl:url
     identity:@"trade"
     webView:nil
     parentController: [UIApplication sharedApplication].delegate.window.rootViewController
     showParams:showParamsNatice
     taoKeParams:_taokeParams
     trackParam:nil
     tradeProcessSuccessCallback:^(AlibcTradeResult * _Nullable result) {
         if (result.result == AlibcTradeResultTypeAddCard) {
             NSDictionary *ret = @{@"type": @"card"};
             [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onTaobaoOrderChange" arguments:ret];
         } else if (result.result == AlibcTradeResultTypePaySuccess) {
             NSDictionary *ret = @{@"type": @"pay", @"orders": result.payResult.paySuccessOrders};
             [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onTaobaoOrderChange" arguments:ret];
         }
     } tradeProcessFailedCallback:^(NSError * _Nullable error) {
         [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", error.code], @"error": error.localizedDescription}];
     }];
}

- (void) showInWebView:(UIWebView *)webView url:(NSString *)url
{
    id<AlibcTradeService> service = [AlibcTradeSDK sharedInstance].tradeService;
//    id<AlibcTradePage> page = [AlibcTradePageFactory page:url];
    [service
     openByUrl:url
     identity:@"trade"
     webView:webView
     parentController: [UIApplication sharedApplication].delegate.window.rootViewController
     showParams: [AliBaichuanConfig.sharedInstance showParams]
     taoKeParams:[AliBaichuanConfig.sharedInstance taokeParams]
     trackParam:nil
     tradeProcessSuccessCallback:^(AlibcTradeResult * _Nullable result) {
         if (result.result == AlibcTradeResultTypeAddCard) {
             [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onTaobaoOrderChange" arguments:@{@"type": @"card",}];
         } else if (result.result == AlibcTradeResultTypePaySuccess) {
             NSDictionary *ret = @{
                                   @"type": @"pay",
                                   @"orders": result.payResult.paySuccessOrders
                                   };
             [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onTaobaoOrderChange" arguments:ret];
         }
     } tradeProcessFailedCallback:^(NSError * _Nullable error) {
         [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", error.code], @"error": error.localizedDescription}];
     }];
}

@end
