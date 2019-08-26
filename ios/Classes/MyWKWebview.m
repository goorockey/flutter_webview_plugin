//
//  MyWKWebview.m
//  flutter_webview_plugin
//
//  Created by 王贺天 on 2018/12/19.
//

#import "MyWKWebview.h"
@interface MyWKWebview() <WKNavigationDelegate, UIScrollViewDelegate> {
    BOOL _enableAppScheme;
    BOOL _enableZoom;
}
@end
@implementation MyWKWebview

- (void) initWebview:(FlutterMethodCall*)call viewController:(UIViewController*) viewController
{
    NSNumber *clearCache = call.arguments[@"clearCache"];
    NSNumber *clearCookies = call.arguments[@"clearCookies"];
    NSNumber *hidden = call.arguments[@"hidden"];
    NSDictionary *rect = call.arguments[@"rect"];
    _enableAppScheme = call.arguments[@"enableAppScheme"];
    NSString *userAgent = call.arguments[@"userAgent"];
    NSNumber *withZoom = call.arguments[@"withZoom"];
    NSNumber *scrollBar = call.arguments[@"scrollBar"];
    BOOL javaScriptEnabled = call.arguments[@"withJavascript"];
    
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
    WKPreferences *preferences = [[WKPreferences alloc] init];
    preferences.javaScriptEnabled = javaScriptEnabled;
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.preferences = preferences;
    self.webview = [[WKWebView alloc] initWithFrame:rc configuration:configuration];
    self.webview.navigationDelegate = self;
    self.webview.scrollView.delegate = self;
    self.webview.hidden = [hidden boolValue];
    self.webview.scrollView.showsHorizontalScrollIndicator = [scrollBar boolValue];
    self.webview.scrollView.showsVerticalScrollIndicator = [scrollBar boolValue];
    _enableZoom = [withZoom boolValue];
    
    [viewController.view addSubview:self.webview];
    
    [self navigate:call];
}
- (void)navigate:(FlutterMethodCall*)call {
    if (self.webview != nil) {
        NSString *url = call.arguments[@"url"];
        NSNumber *withLocalUrl = call.arguments[@"withLocalUrl"];
        if ( [withLocalUrl boolValue]) {
            NSURL *htmlUrl = [NSURL fileURLWithPath:url isDirectory:false];
            if (@available(iOS 9.0, *)) {
                [self.webview loadFileURL:htmlUrl allowingReadAccessToURL:htmlUrl];
            } else {
                @throw @"not available on version earlier than ios 9.0";
            }
        } else {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSDictionary *headers = call.arguments[@"headers"];
            
            if (headers != nil) {
                [request setAllHTTPHeaderFields:headers];
            }
            
            [self.webview loadRequest:request];
        }
    }
}
- (void)evalJavascript:(FlutterMethodCall*)call
     completionHandler:(void (^_Nullable)(NSString * response))completionHandler {
    if (self.webview != nil) {
        NSString *code = call.arguments[@"code"];
        [self.webview evaluateJavaScript:code
                       completionHandler:^(id _Nullable response, NSError * _Nullable error) {
                           completionHandler([NSString stringWithFormat:@"%@", response]);
                       }];
    } else {
        completionHandler(nil);
    }
}

- (void)resize:(FlutterMethodCall*)call {
    if (self.webview != nil) {
        NSDictionary *rect = call.arguments[@"rect"];
        CGRect rc = [self parseRect:rect];
        self.webview.frame = rc;
    }
}

- (void)closeWebView {
    if (self.webview != nil) {
        [self.webview stopLoading];
        [self.webview removeFromSuperview];
        self.webview.navigationDelegate = nil;
        self.webview = nil;
        
        // manually trigger onDestroy
        [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onDestroy" arguments:nil];
    }
}

- (void)reloadUrl:(FlutterMethodCall*)call {
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

- (void) setJavaScriptEnabled:(FlutterMethodCall*)call {
    if (self.webview != nil) {
        BOOL _enabled = call.arguments[@"enabled"];
        self.webview.configuration.preferences.javaScriptEnabled = _enabled;
    }
}

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

#pragma mark -- WkWebView Delegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    id data = @{@"url": navigationAction.request.URL.absoluteString,
                @"type": @"shouldStart",
                @"navigationType": [NSNumber numberWithInt:navigationAction.navigationType]};
    [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onState" arguments:data];
    
    if (navigationAction.navigationType == WKNavigationTypeBackForward) {
        [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onBackPressed" arguments:nil];
    } else {
        id data = @{@"url": navigationAction.request.URL.absoluteString};
        [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onUrlChanged" arguments:data];
    }
    
    if (_enableAppScheme ||
        ([webView.URL.scheme isEqualToString:@"http"] ||
         [webView.URL.scheme isEqualToString:@"https"] ||
         [webView.URL.scheme isEqualToString:@"about"])) {
            decisionHandler(WKNavigationActionPolicyAllow);
        } else {
            decisionHandler(WKNavigationActionPolicyCancel);
        }
}


- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onState" arguments:@{@"type": @"startLoad", @"url": webView.URL.absoluteString}];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onState" arguments:@{@"type": @"finishLoad", @"url": webView.URL.absoluteString}];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", error.code], @"error": error.localizedDescription}];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse * response = (NSHTTPURLResponse *)navigationResponse.response;
        
        [[FlutterWebviewPlugin sharedInstance].channel invokeMethod:@"onHttpError" arguments:@{@"code": [NSString stringWithFormat:@"%ld", response.statusCode], @"url": webView.URL.absoluteString}];
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

#pragma mark -- UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView.pinchGestureRecognizer.isEnabled != _enableZoom) {
        scrollView.pinchGestureRecognizer.enabled = _enableZoom;
    }
}

@end


