#import <Flutter/Flutter.h>
#import <WebKit/WebKit.h>
#import <AlibabaAuthSDK/ALBBSDK.h>
#import <AlipaySDK/AlipaySDK.h>
#import <AlibcTradeSDK/AlibcTradeSDK.h>
#import "AliBaichuanConfig.h"
#import "MyWebview.h"

static FlutterMethodChannel *channel;
@interface FlutterWebviewPlugin : NSObject<FlutterPlugin>
+ (instancetype) sharedInstance;
@property (nonatomic, retain) FlutterMethodChannel *channel;
//@property (nonatomic, retain) WKWebView *webview;
@property (nonatomic, retain) id<MyWebview> myWebview;
@end
