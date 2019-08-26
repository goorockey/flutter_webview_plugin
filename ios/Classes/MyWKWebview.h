//
//  MyWKWebview.h
//  flutter_webview_plugin
//
//  Created by 王贺天 on 2018/12/19.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Flutter/Flutter.h>
#import "MyWebview.h"
#import "AliBaichuanConfig.h"
#import "FlutterWebviewPlugin.h"

@interface MyWKWebview : NSObject <MyWebview>
@property (nonatomic, retain) WKWebView *webview;
@end

