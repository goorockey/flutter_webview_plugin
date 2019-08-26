//
//  MyUIWebview.h
//  flutter_webview_plugin
//
//  Created by 王贺天 on 2018/12/19.
//

#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>
#import "MyWebview.h"
#import <Foundation/Foundation.h>
#import "AliBaichuanConfig.h"
#import "FlutterWebviewPlugin.h"
#import <AlipaySDK/AlipaySDK.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyUIWebview : NSObject <MyWebview>
@property (nonatomic, retain) UIWebView *webview;
@end

NS_ASSUME_NONNULL_END
