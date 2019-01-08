#import <Flutter/Flutter.h>
#import <WebKit/WebKit.h>
#import <AlibabaAuthSDK/ALBBSDK.h>
#import <AlibcTradeSDK/AlibcTradeSDK.h>
#import "AliBaichuanConfig.h"
#import "MyWebview.h"

@interface FlutterWebviewPlugin : NSObject<FlutterPlugin>
@property (nonatomic, retain) UIViewController *viewController;
//@property (nonatomic, retain) WKWebView *webview;
@property (nonatomic, retain) id<MyWebview> myWebview;
@end
