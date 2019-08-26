#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@implementation AppDelegate {
  GeneratedPluginRegistrant *plugins;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    // Override point for customization after application launch.
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
  return YES;
}

@end
