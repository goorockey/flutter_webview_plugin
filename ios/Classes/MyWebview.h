//
//  MyWebview.h
//  flutter_webview_plugin
//
//  Created by 王贺天 on 2018/12/20.
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>
@protocol MyWebview <NSObject>

- (void) initWebview:(FlutterMethodCall*_Nullable)call viewController:(UIViewController*_Nullable) viewController;
- (void) navigate:(FlutterMethodCall*_Nullable)call;
- (void) evalJavascript:(FlutterMethodCall*_Nullable)call
      completionHandler:(void (^_Nullable)(NSString * _Nullable response))completionHandler;
- (void) resize:(FlutterMethodCall*_Nullable)call;
- (void) closeWebView;
- (void) reloadUrl:(FlutterMethodCall*_Nullable)call;
- (void) show;
- (void) hide;
- (void) stopLoading;
- (void) back;
- (void) forward;
- (void) reload;
- (void) cleanCookies;
- (void) setJavaScriptEnabled:(FlutterMethodCall*)call;

@end
