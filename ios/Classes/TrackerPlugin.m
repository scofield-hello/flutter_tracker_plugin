#import "TrackerPlugin.h"
#import "TrackerManager.h"

@implementation TrackerPlugin{
    TrackerManager *_trackerManager;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"com.chuangdun.flutter/tracker/methods"
            binaryMessenger:[registrar messenger]];
  TrackerPlugin* instance = [[TrackerPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"start" isEqualToString:call.method]) {
      NSDictionary *arguments = call.arguments;
      NSString *postUrl = [arguments objectForKey:@"postUrl"];
      double minDistance = ((NSNumber*)[arguments objectForKey:@"minDistance"]).doubleValue;
      int minTimeInterval = ((NSNumber*)[arguments objectForKey:@"minTimeInterval"]).intValue;
      NSMutableDictionary *headers = [[NSMutableDictionary alloc]initWithDictionary:((NSDictionary*)[arguments objectForKey:@"headers"])];
      NSMutableDictionary *extraBody = [[NSMutableDictionary alloc]initWithDictionary:((NSDictionary*)[arguments objectForKey:@"extraBody"])];
      if (!_trackerManager) {
          _trackerManager = [[TrackerManager alloc]init];
      }
      _trackerManager.postUrl = postUrl;
      _trackerManager.headers = headers;
      _trackerManager.extraBody = extraBody;
      _trackerManager.minDistance = minDistance;
      _trackerManager.minTimeInterval = minTimeInterval;
      NSLog(@"TrackerManager:%@", _trackerManager);
      [_trackerManager start];
  } else if([@"stop" isEqualToString:call.method]) {
      if (_trackerManager) {
          NSLog(@"TrackerManager:%@", _trackerManager);
          [_trackerManager stop];
      }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
