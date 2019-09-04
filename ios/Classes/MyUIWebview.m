//
//  MyUIWebview.m
//  flutter_webview_plugin
//
//  Created by 王贺天 on 2018/12/19. WKNavigationDelegate
//

#import "MyUIWebview.h"

@interface MyUIWebview() <UIWebViewDelegate, UIScrollViewDelegate> {
    BOOL _enableAppScheme;
    BOOL _enableZoom;
    BOOL _iscoupon;
}
@end
@implementation MyUIWebview
- (void) initWebview:(FlutterMethodCall*)call viewController:(UIViewController*) viewController
{
    _iscoupon = false;
    NSNumber *clearCache = call.arguments[@"clearCache"];
    NSNumber *clearCookies = call.arguments[@"clearCookies"];
    NSNumber *hidden = call.arguments[@"hidden"];
    NSDictionary *rect = call.arguments[@"rect"];
    _enableAppScheme = call.arguments[@"enableAppScheme"];
    NSString *userAgent = call.arguments[@"userAgent"];
    NSNumber *withZoom = call.arguments[@"withZoom"];
    NSNumber *scrollBar = call.arguments[@"scrollBar"];
    
    if (clearCache != (id)[NSNull null] && [clearCache boolValue]) {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
    
    if (clearCookies != (id)[NSNull null] && [clearCookies boolValue]) {
        [[NSURLSession sharedSession] resetWithCompletionHandler:^{
        }];
    }
    
    if (userAgent != (id)[NSNull null]) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"UserAgent": userAgent}];
    }
    
    CGRect rc;
    if (rect != (id)[NSNull null]) {
        rc = [self parseRect:rect];
    } else {
        rc = viewController.view.bounds;
    }
    
    self.webview = [[UIWebView alloc] initWithFrame:rc];
    self.webview.delegate = self;
    self.webview.scrollView.delegate = self;
    self.webview.hidden = [hidden boolValue];
    self.webview.scrollView.showsHorizontalScrollIndicator = [scrollBar boolValue];
    self.webview.scrollView.showsVerticalScrollIndicator = [scrollBar boolValue];
    _enableZoom = [withZoom boolValue];
    
    [viewController.view addSubview:self.webview];
    NSString *url = call.arguments[@"url"];
    
    [AliBaichuanConfig.sharedInstance showInWebView:self.webview url:url];
//    [self navigate:call];
}
- (void) navigate:(FlutterMethodCall*)call
{
    if (self.webview != nil) {
        NSString *url = call.arguments[@"url"];
        NSNumber *withLocalUrl = call.arguments[@"withLocalUrl"];
        
        if ( [withLocalUrl boolValue]) {
            NSFileHandle *readHandle = [NSFileHandle fileHandleForReadingAtPath:url];
            
            NSString *htmlString = [[NSString alloc] initWithData:
                                    [readHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
            NSURL *htmlUrl = [NSURL fileURLWithPath:url isDirectory:false];
            [self.webview loadHTMLString:htmlString baseURL:htmlUrl];
        } else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSDictionary *headers = call.arguments[@"headers"];

            if (headers != nil) {
                [request setAllHTTPHeaderFields:headers];
            }
//
            [self.webview loadRequest:request];

        }
    }
}
- (void) evalJavascript:(FlutterMethodCall*)call
      completionHandler:(void (^_Nullable)(NSString * response))completionHandler
{
    if (self.webview != nil) {
        NSString *code = call.arguments[@"code"];
        NSString *response = [self.webview stringByEvaluatingJavaScriptFromString:code];
        completionHandler(response);
    } else {
        completionHandler(nil);
    }
}
- (void) resize:(FlutterMethodCall*)call
{
    if (self.webview != nil) {
        NSDictionary *rect = call.arguments[@"rect"];
        CGRect rc = [self parseRect:rect];
        self.webview.frame = rc;
    }
}
- (void) closeWebView
{
    if (self.webview != nil) {
        self.webview.delegate = nil;
        [self.webview loadHTMLString:@"" baseURL:nil];
        [self.webview stopLoading];
        [self.webview removeFromSuperview];
        _webview = nil;
    
        
        // manually trigger onDestroy
        [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onDestroy" arguments:nil];
    }
}
- (void) reloadUrl:(FlutterMethodCall*)call
{
    if (self.webview != nil) {
        NSString *url = call.arguments[@"url"];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [self.webview loadRequest:request];
    }
}
- (void)show {
    if (self.webview != nil) {
        self.webview.hidden = false;
    }
}

- (void)hide {
    if (self.webview != nil) {
        self.webview.hidden = true;
    }
}
- (void)stopLoading {
    if (self.webview != nil) {
        [self.webview stopLoading];
    }
}
- (void)back {
    if (self.webview != nil) {
        [self.webview goBack];
    }
}
- (void)forward {
    if (self.webview != nil) {
        [self.webview goForward];
    }
}
- (void)reload {
    if (self.webview != nil) {
        [self.webview reload];
    }
}

// UIWebView 不支持设置禁用JS渲染
- (void) setJavaScriptEnabled:(FlutterMethodCall*)call {}

- (void)cleanCookies {
    [[NSURLSession sharedSession] resetWithCompletionHandler:^{
    }];
}

- (CGRect)parseRect:(NSDictionary *)rect {
    return CGRectMake([[rect valueForKey:@"left"] doubleValue],
                      [[rect valueForKey:@"top"] doubleValue],
                      [[rect valueForKey:@"width"] doubleValue],
                      [[rect valueForKey:@"height"] doubleValue]);
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    id xDirection = @{@"xDirection": @(scrollView.contentOffset.x) };
    [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onScrollXChanged" arguments:xDirection];
    
    id yDirection = @{@"yDirection": @(scrollView.contentOffset.y) };
    [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onScrollYChanged" arguments:yDirection];
}

//-(void)getJsContext{
//    self.jsContext = [self.webview valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//}
//
//-(void)webView:(id)webView didCreateJavaScriptContext:(JSContext *)context forFrame:(id)frame{
//    [self getJsContext];
//}

#pragma mark -- UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView.pinchGestureRecognizer.isEnabled != _enableZoom) {
        scrollView.pinchGestureRecognizer.enabled = _enableZoom;
    }
}

// 解析URL Query 方便查询GET参数
- (NSMutableDictionary *) analysisUrlQuery:(NSString *)url
{
    NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
    NSString *query = [[NSURL alloc] initWithString:url].query;
    NSArray<NSString *> *params = [query componentsSeparatedByString:@"&"];
    for(NSString *item in params) {
        NSArray<NSString *> *kv = [item componentsSeparatedByString:@"="];
        [res setValue:kv[1] forKey:kv[0]];
    }
    return res;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString* url = request.URL.absoluteString;
    
    if ([url rangeOfString:@"https://h5.m.taobao.com/ww/index.htm"].location != NSNotFound) {
        [AliBaichuanConfig.sharedInstance show:url];
        return NO;
    }
    
    // 如果是是从优惠券页面打开则拦截商品页跳转
    if (_iscoupon == true) {
        if (
            [url rangeOfString:@"taobao.com"].location != NSNotFound &&
            [url rangeOfString:@"detail.htm"].location != NSNotFound
            ){
            _iscoupon = false;
            [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onTaobaoCouponSuccess" arguments:@""];
            return NO;
        }else if (
              [url rangeOfString:@"tmall.com"].location != NSNotFound &&
              [url rangeOfString:@"item.htm"].location != NSNotFound
            ){
            _iscoupon = false;
            [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onTaobaoCouponSuccess" arguments:@""];
            return NO;
        }
    }
    
    // 标记是访问的优惠券页面
    if ([url rangeOfString:@"uland.taobao.com/coupon/edetail"].location != NSNotFound) {
        _iscoupon = true;
    }
    
    
    // 调起支付宝支付 需要更新最新支付宝SDK
    BOOL isIntercepted = [[AlipaySDK defaultService] payInterceptorWithUrl:[request.URL absoluteString] fromScheme:@"cnganen" callback:^(NSDictionary *result) {
        
        NSString* urlStr = result[@"returnUrl"];
        
        NSDictionary *iRes;
        switch ([result[@"resultCode"] integerValue]) {
            case 6002:
                iRes = @{
                         @"type": @"error",
                         @"code": @(6004),
                         @"msg": @"网络连接出错",
                         };
                break;
            case 6001:
                iRes = @{
                         @"type": @"error",
                         @"code": @(6004),
                         @"msg": @"用户中途取消",
                         };
                break;
            case 4000:
                iRes = @{
                         @"type": @"error",
                         @"code": @(6004),
                         @"msg": @"订单支付失败",
                         };
                break;
            case 9000:
                iRes = @{
                         @"type": @"pay",
                         @"returnUrl": urlStr,
                         };
                break;
            default:
                iRes = @{
                         @"type": @"error",
                         @"code": @(6004),
                         @"msg": @"支付结果未知",
                         };
                break;
        }
        [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onTaobaoOrderChange" arguments:iRes];
    }];
   
   // BOOL isIntercepted = false;
    if (isIntercepted) {
        return NO;
    }
    
    if ([url hasPrefix:@"http://"]  ||
        [url hasPrefix:@"https://"] ||
        [url hasPrefix:@"file://"]) {
        return YES;
    }
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    // 标记是访问的优惠券页面
    if ([webView.request.URL.absoluteString rangeOfString:@"uland.taobao.com/coupon/edetail"].location != NSNotFound) {
        _iscoupon = true;
    }
    [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onState" arguments:@{@"type": @"startLoad", @"url": webView.request.URL.absoluteString}];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onState" arguments:@{@"type": @"finishLoad", @"url": webView.request.URL.absoluteString}];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", error.code], @"error": error.localizedDescription}];
}
@end
