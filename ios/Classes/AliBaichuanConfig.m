//
//  AliBaichuanConfig.m
//  flutter_webview_plugin
//
//  Created by debug on 2019/09/04.
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
    pid = call.arguments[@"pid"];
    
    // 百川平台基础SDK初始化，加载并初始化各个业务能力插件
    [[AlibcTradeSDK sharedInstance] asyncInitWithSuccess:^{
        NSLog(@"淘客初始化OK");
    } failure:^(NSError *error) {
        NSLog(@"淘客初始化失败， %@", error.description);
    }];
    
    // 开发阶段打开日志开关，方便排查错误信息
    //默认调试模式打开日志,release关闭,可以不调用下面的函数
    [[AlibcTradeSDK sharedInstance] setDebugLogOpen:NO];
    
    // 配置全局的淘客参数
    //如果没有阿里妈妈的淘客账号,setTaokeParams函数需要调用
    AlibcTradeTaokeParams *taokeParams = [[AlibcTradeTaokeParams alloc] init];
    taokeParams.pid = pid; //mm_XXXXX为你自己申请的阿里妈妈淘客pid
    [[AlibcTradeSDK sharedInstance] setTaokeParams:taokeParams];
    
    //设置全局的app标识，在电商模块里等同于isv_code
    //没有申请过isv_code的接入方,默认不需要调用该函数
    [[AlibcTradeSDK sharedInstance] setISVCode:@"your_isv_code"];
    
    // 设置全局配置，是否强制使用h5
//    [[AlibcTradeSDK sharedInstance] setIsForceH5:YES];
    
    _showParams = [[AlibcTradeShowParams alloc] init];
    _showParams.openType = AlibcOpenTypeAuto;
}

- (void)login: (FlutterMethodCall*)call result:(FlutterResult)result
{
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
     webView:nil
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
