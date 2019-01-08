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
    
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    FlutterWebviewPlugin* instance = [[FlutterWebviewPlugin alloc] initWithViewController:viewController];
    
    [registrar addMethodCallDelegate:instance channel:channel];
}



- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        self.viewController = viewController;
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
    } else {
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

    [self.myWebview initWebview:call viewController:_viewController];
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

@end
