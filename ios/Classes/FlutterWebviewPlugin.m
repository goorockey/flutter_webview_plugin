#import "FlutterWebviewPlugin.h"
#import "MyWKWebview.h"
#import "MyUIWebview.h"

static NSString *const CHANNEL_NAME = @"flutter_webview_plugin";

// UIWebViewDelegate
@interface FlutterWebviewPlugin() {
    BOOL _enableAppScheme;
    BOOL _enableZoom;
}
@end

@implementation FlutterWebviewPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    channel = [FlutterMethodChannel
               methodChannelWithName:CHANNEL_NAME
               binaryMessenger:[registrar messenger]];
    
    FlutterWebviewPlugin* instance = [[FlutterWebviewPlugin sharedInstance] initWithChannel:channel];
    [registrar addApplicationDelegate:instance];
    
    [registrar addMethodCallDelegate:instance channel:channel];
}

+ (instancetype) sharedInstance
{
    static FlutterWebviewPlugin *instance = nil;
    if (!instance) {
        instance = [[FlutterWebviewPlugin alloc] init];
    }
    return instance;
}

- (instancetype)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        self.channel = channel;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"tbinit" isEqualToString:call.method]){
        [AliBaichuanConfig.sharedInstance initBcSDK:call result:result];
    }else if ([@"tblogin" isEqualToString:call.method]){
        [AliBaichuanConfig.sharedInstance login:call result:result];
    }else if ([@"tbislogin" isEqualToString:call.method]){
        [AliBaichuanConfig.sharedInstance isLogin:call result:result];
    }else if ([@"tbgetuser" isEqualToString:call.method]){
        [AliBaichuanConfig.sharedInstance getUser:call result:result];
    }else if ([@"tblogout" isEqualToString:call.method]){
        [AliBaichuanConfig.sharedInstance logout:call result:result];
    }else if ([@"opentb" isEqualToString:call.method]){
        NSString *url = call.arguments[@"url"];
        [AliBaichuanConfig.sharedInstance show:url];
        result(@"success");
    }else if ([@"launch" isEqualToString:call.method]) {
        if (!self.myWebview)
            [self initWebview:call];
        else
            [self navigate:call];
        result(nil);
    } else if ([@"close" isEqualToString:call.method]) {
        [self closeWebView];
        result(nil);
    } else if ([@"eval" isEqualToString:call.method]) {
        [self evalJavascript:call completionHandler:^(NSString * response) {
            result(response);
        }];
    } else if ([@"resize" isEqualToString:call.method]) {
        [self resize:call];
        result(nil);
    } else if ([@"reloadUrl" isEqualToString:call.method]) {
        [self reloadUrl:call];
        result(nil);
    } else if ([@"show" isEqualToString:call.method]) {
        [self show];
        result(nil);
    } else if ([@"hide" isEqualToString:call.method]) {
        [self hide];
        result(nil);
    } else if ([@"stopLoading" isEqualToString:call.method]) {
        [self stopLoading];
        result(nil);
    } else if ([@"cleanCookies" isEqualToString:call.method]) {
        [self cleanCookies];
    } else if ([@"back" isEqualToString:call.method]) {
        [self back];
        result(nil);
    } else if ([@"forward" isEqualToString:call.method]) {
        [self forward];
        result(nil);
    } else if ([@"reload" isEqualToString:call.method]) {
        [self reload];
        result(nil);
    } else if ([@"setJavaScriptEnabled" isEqualToString:call.method]){
        [self setJavaScriptEnabled:call];
        result(nil);
    }else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)initWebview:(FlutterMethodCall*)call {
    NSNumber *istb = call.arguments[@"istb"];
    if ([istb isEqual:[NSNumber numberWithInteger:1]]) {
        self.myWebview = [[MyUIWebview alloc] init];
    }else {
        self.myWebview = [[MyWKWebview alloc] init];
    }
    
    [self.myWebview initWebview:call viewController:[UIApplication sharedApplication].delegate.window.rootViewController];
}

- (void)navigate:(FlutterMethodCall*)call {
    if (self.myWebview != nil) {
        [self.myWebview navigate:call];
    }
}

- (void)evalJavascript:(FlutterMethodCall*)call
     completionHandler:(void (^_Nullable)(NSString * response))completionHandler {
    if (self.myWebview != nil) {
        [self.myWebview evalJavascript:call completionHandler:completionHandler];
    }
}

- (void)resize:(FlutterMethodCall*)call {
    if (self.myWebview != nil) {
        [self.myWebview resize:call];
    }
}

- (void)closeWebView {
    if (self.myWebview != nil) {
        [self.myWebview closeWebView];
        _myWebview = nil;
    }
}

- (void)reloadUrl:(FlutterMethodCall*)call {
    if (self.myWebview != nil) {
        [self.myWebview resize:call];
    }
}
- (void)show {
    if (self.myWebview != nil) {
        [self.myWebview show];
    }
}

- (void)hide {
    if (self.myWebview != nil) {
        [self.myWebview hide];
    }
}
- (void)stopLoading {
    if (self.myWebview != nil) {
        [self.myWebview stopLoading];
    }
}
- (void)back {
    if (self.myWebview != nil) {
        [self.myWebview back];
    }
}
- (void)forward {
    if (self.myWebview != nil) {
        [self.myWebview forward];
    }
}
- (void)reload {
    if (self.myWebview != nil) {
        [self.myWebview reload];
    }
}

- (void)cleanCookies {
    [self.myWebview cleanCookies];
}

- (void) setJavaScriptEnabled:(FlutterMethodCall*)call
{
    [self.myWebview setJavaScriptEnabled:call];
}

// AppDelegate

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    // 新接口写法
    if (@available(iOS 9.0, *)) {
        if (![[AlibcTradeSDK sharedInstance] application:application
                                                 openURL:url
                                                 options:options]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    NSLog(@"%@", url.absoluteURL);
    //如果极简开发包不可用，会跳转支付宝钱包进行支付，需要将支付宝钱包的支付结果回传给开发包
    if ([url.host isEqualToString:@"safepay"]) {
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);
        }];
        return YES;
    }
    if ([url.host isEqualToString:@"platformapi"]){//支付宝钱包快登授权返回authCode

        [[AlipaySDK defaultService] processAuthResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);
        }];
        return YES;
    }

    // 新接口写法
    if (![[AlibcTradeSDK sharedInstance] application:application
                                             openURL:url
                                   sourceApplication:sourceApplication
                                          annotation:annotation]) {
        return YES;
    }
    return NO;
}

@end
