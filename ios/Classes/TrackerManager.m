//
//  TrackerManager.m
//  Pods-Runner
//
//  Created by Nick on 2020/7/30.
//

#import "TrackerManager.h"
#import "AFNetworking.h"
#import <sys/utsname.h>

@interface TrackerManager()<CLLocationManagerDelegate>{
    NSString *_postUrl;
    double _minDistance;
    int _minTimeInterval;
    NSMutableDictionary *_headers;
    NSMutableDictionary *_extraBody;
    CLLocationManager *_locationManager;
    BOOL _isStart;
}
@end

@implementation TrackerManager

- (instancetype)init
{
    [NSException raise:@"initialization error"
    format:@"Use initWithPostUrl:,not init"];
    return nil;
}

- (instancetype)initWithPostUrl:(NSString *)postUrl
                    minDistance:(double)minDistance
                minTimeInterval:(int)minTimeInterval
                        headers:(NSMutableDictionary *)headers
                      extraBody:(NSMutableDictionary *)extraBody{
    self = [super init];
    if (self) {
        _postUrl = postUrl;
        _minDistance = minDistance;
        _minTimeInterval = minTimeInterval;
        _headers = headers;
        _extraBody = extraBody;
        _locationManager = [[CLLocationManager alloc]init];
        _locationManager.delegate = self;
    }
    return self;
}

- (void)start{
    BOOL enabled = [CLLocationManager locationServicesEnabled];
    if (enabled) {
        CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
        if (status == kCLAuthorizationStatusAuthorizedAlways) {
            //开启位置上报
            [self startLocation];
        }else if(status == kCLAuthorizationStatusAuthorizedWhenInUse){
            //申请后台定位权限
            [_locationManager requestAlwaysAuthorization];
            //开启位置上报
            [self startLocation];
        }else if(status == kCLAuthorizationStatusNotDetermined){
            //申请后台定位权限
            [_locationManager requestAlwaysAuthorization];
        }else{
            [self whenPermissionDenied];
        }
    }else{
        [self whenLocationNotAvailable];
    }
}

- (void)whenLocationNotAvailable{
    //上报定位服务不可用.
    NSString *provider = @"gps|network";
    NSString *platform = @"iOS";
    NSString *brand = @"iPhone";
    NSString *model = [self getDeviceModel];
    NSString *version = [NSString stringWithFormat:@"%.1f",
                         [[[UIDevice currentDevice] systemVersion] floatValue]];
    NSDate *dateNow = [NSDate date];
    long timestamp = [[NSNumber numberWithDouble:dateNow.timeIntervalSince1970] longValue];
    [self createDataTaskUsingPostUrl:_postUrl
           status:@"NOT_AVAILABLE"
          headers:_headers
        extraBody:_extraBody
        timestamp:timestamp
         latitude:0.0
        longitude:0.0
         platform:platform
         provider:provider
      deviceBrand:brand
      deviceModel:model
    systemVersion:version];
}

- (void)whenPermissionDenied{
    //上报定位未授予权限.
    NSString *provider = @"gps|network";
    NSString *platform = @"iOS";
    NSString *brand = @"iPhone";
    NSString *model = [self getDeviceModel];
    NSString *version = [NSString stringWithFormat:@"%.1f",
                         [[[UIDevice currentDevice] systemVersion] floatValue]];
    NSDate *dateNow = [NSDate date];
    long timestamp = [[NSNumber numberWithDouble:dateNow.timeIntervalSince1970] longValue];
    [self createDataTaskUsingPostUrl:_postUrl
           status:@"PERMISSION_DENIED"
          headers:_headers
        extraBody:_extraBody
        timestamp:timestamp
         latitude:0.0
        longitude:0.0
         platform:platform
         provider:provider
      deviceBrand:brand
      deviceModel:model
    systemVersion:version];
}

- (void)startLocation{
    if (!_isStart) {
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager.distanceFilter = _minDistance;
        if (@available(iOS 9.0, *)) {
            _locationManager.allowsBackgroundLocationUpdates = YES;
        }
        if (@available(iOS 11.0, *)) {
            _locationManager.showsBackgroundLocationIndicator = YES;
        }
        _locationManager.activityType = CLActivityTypeOtherNavigation;
        [_locationManager startUpdatingLocation];
    }
    _isStart = YES;
}

- (void)stop{
    if (_isStart) {
        [_locationManager stopUpdatingLocation];
    }
    _isStart = NO;
}

- (BOOL) isStar{
    return _isStart;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations{
    CLLocation *location = [locations lastObject];
    double latitude = location.coordinate.latitude;
    double longitude = location.coordinate.longitude;
    long timestamp = [[NSNumber
                       numberWithDouble:location.timestamp.timeIntervalSince1970] longValue];
    NSString *provider = @"gps|network";
    NSString *platform = @"iOS";
    NSString *brand = @"iPhone";
    NSString *model = [self getDeviceModel];
    NSString *version = [NSString stringWithFormat:@"%.1f",
                         [[[UIDevice currentDevice] systemVersion] floatValue]];
    [self createDataTaskUsingPostUrl:_postUrl
                              status:@"LOCATION"
                             headers:_headers
                           extraBody:_extraBody
                           timestamp:timestamp
                            latitude:latitude
                           longitude:longitude
                            platform:platform
                            provider:provider
                         deviceBrand:brand
                         deviceModel:model
                       systemVersion:version];
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self startLocation];
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            [self startLocation];
            break;
        default:
            [self stop];
            break;
    }
}

-(void)createDataTaskUsingPostUrl:(NSString *)postUrl
                           status:(NSString *)status
              headers:(NSMutableDictionary*)headers
            extraBody:(NSMutableDictionary*)extraBody
            timestamp:(long int)timestamp
             latitude:(double)latitude
            longitude:(double)longitude
             platform:(NSString*)platform
             provider:(NSString*)provider
          deviceBrand:(NSString*)brand
          deviceModel:(NSString*)model
        systemVersion:(NSString *)systemVersion{
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
    securityPolicy.allowInvalidCertificates = YES;
    securityPolicy.validatesDomainName = NO;
    manager.securityPolicy = securityPolicy;
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", nil];
    for (id key in headers) {
        id value = [headers objectForKey:key];
        [manager.requestSerializer setValue:value forHTTPHeaderField:key];
    }
    [extraBody setValue:status forKey:@"status"];
    [extraBody setValue:[NSNumber numberWithLong:timestamp] forKey:@"timestamp"];
    [extraBody setValue:[NSNumber numberWithDouble:latitude] forKey:@"latitude"];
    [extraBody setValue:[NSNumber numberWithDouble:longitude] forKey:@"longitude"];
    [extraBody setValue:platform forKey:@"platform"];
    [extraBody setValue:provider forKey:@"provider"];
    [extraBody setValue:brand forKey:@"deviceBrand"];
    [extraBody setValue:model forKey:@"deviceModel"];
    [extraBody setValue:systemVersion forKey:@"systemVersion"];
    [manager POST:postUrl parameters:extraBody progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"位置上传进度:%@", uploadProgress);
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"位置上传成功:%@", responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"位置上传失败.");
    }];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"<postUrl:%@, minInstance:%f, minTimeInterval:%d, headers:%@, extraBody:%@>", _postUrl, _minDistance, _minTimeInterval, _headers, _extraBody];
}

- (NSString *)getDeviceModel{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    //iPhone
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone 2G";
     if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone 3G";
     if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone 3GS";
     if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone 4";
     if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone 4";
     if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
     if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";
     if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
     if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
     if ([platform isEqualToString:@"iPhone5,3"])    return @"iPhone 5c";
     if ([platform isEqualToString:@"iPhone5,4"])    return @"iPhone 5c";
     if ([platform isEqualToString:@"iPhone6,1"])    return @"iPhone 5s";
     if ([platform isEqualToString:@"iPhone6,2"])    return @"iPhone 5s";
     if ([platform isEqualToString:@"iPhone7,2"])    return @"iPhone 6";
     if ([platform isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
     if ([platform isEqualToString:@"iPhone8,1"])    return @"iPhone 6s";
     if ([platform isEqualToString:@"iPhone8,2"])    return @"iPhone 6s Plus";
     if ([platform isEqualToString:@"iPhone8,4"])    return @"iPhone SE";
     if ([platform isEqualToString:@"iPhone9,1"])    return @"iPhone 7";
     if ([platform isEqualToString:@"iPhone9,3"])    return @"iPhone 7";
     if ([platform isEqualToString:@"iPhone9,2"])    return @"iPhone 7 Plus";
     if ([platform isEqualToString:@"iPhone9,4"])    return @"iPhone 7 Plus";
    //2017年9月发布，更新三种机型：iPhone 8、iPhone 8 Plus、iPhone X
     if ([platform isEqualToString:@"iPhone10,1"])  return @"iPhone 8";
     if ([platform isEqualToString:@"iPhone10,4"])  return @"iPhone 8";
     if ([platform isEqualToString:@"iPhone10,2"])  return @"iPhone 8 Plus";
     if ([platform isEqualToString:@"iPhone10,5"])  return @"iPhone 8 Plus";
     if ([platform isEqualToString:@"iPhone10,3"])  return @"iPhone X";
     if ([platform isEqualToString:@"iPhone10,6"])  return @"iPhone X";
     //2018年10月发布，更新三种机型：iPhone XR、iPhone XS、iPhone XS Max
     if ([platform isEqualToString:@"iPhone11,8"])  return @"iPhone XR";
     if ([platform isEqualToString:@"iPhone11,2"])  return @"iPhone XS";
     if ([platform isEqualToString:@"iPhone11,4"])  return @"iPhone XS Max";
     if ([platform isEqualToString:@"iPhone11,6"])  return @"iPhone XS Max";
     //2019年9月发布，更新三种机型：iPhone 11、iPhone 11 Pro、iPhone 11 Pro Max
     if ([platform isEqualToString:@"iPhone12,1"])  return  @"iPhone 11";
     if ([platform isEqualToString:@"iPhone12,3"])  return  @"iPhone 11 Pro";
     if ([platform isEqualToString:@"iPhone12,5"])  return  @"iPhone 11 Pro Max";

    //iPad
    if([platform isEqualToString:@"iPad1,1"])   return @"iPad";
    if([platform isEqualToString:@"iPad1,2"])   return @"iPad 3G";
    if([platform isEqualToString:@"iPad2,1"])   return @"iPad 2 (WiFi)";
    if([platform isEqualToString:@"iPad2,2"])   return @"iPad 2";
    if([platform isEqualToString:@"iPad2,3"])   return @"iPad 2 (CDMA)";
    if([platform isEqualToString:@"iPad2,4"])   return @"iPad 2";
    if([platform isEqualToString:@"iPad2,5"])   return @"iPad Mini (WiFi)";
    if([platform isEqualToString:@"iPad2,6"])   return @"iPad Mini";
    if([platform isEqualToString:@"iPad2,7"])   return @"iPad Mini (GSM+CDMA)";
    if([platform isEqualToString:@"iPad3,1"])   return @"iPad 3 (WiFi)";
    if([platform isEqualToString:@"iPad3,2"])   return @"iPad 3 (GSM+CDMA)";
    if([platform isEqualToString:@"iPad3,3"])   return @"iPad 3";
    if([platform isEqualToString:@"iPad3,4"])   return @"iPad 4 (WiFi)";
    if([platform isEqualToString:@"iPad3,5"])   return @"iPad 4";
    if([platform isEqualToString:@"iPad3,6"])   return @"iPad 4 (GSM+CDMA)";
    if([platform isEqualToString:@"iPad4,1"])   return @"iPad Air (WiFi)";
    if([platform isEqualToString:@"iPad4,2"])   return @"iPad Air (Cellular)";
    if([platform isEqualToString:@"iPad4,4"])   return @"iPad Mini 2 (WiFi)";
    if([platform isEqualToString:@"iPad4,5"])   return @"iPad Mini 2 (Cellular)";
    if([platform isEqualToString:@"iPad4,6"])   return @"iPad Mini 2";
    if([platform isEqualToString:@"iPad4,7"])   return @"iPad Mini 3";
    if([platform isEqualToString:@"iPad4,8"])   return @"iPad Mini 3";
    if([platform isEqualToString:@"iPad4,9"])   return @"iPad Mini 3";
    if([platform isEqualToString:@"iPad5,1"])   return @"iPad Mini 4 (WiFi)";
    if([platform isEqualToString:@"iPad5,2"])   return @"iPad Mini 4 (LTE)";
    if([platform isEqualToString:@"iPad5,3"])   return @"iPad Air 2";
    if([platform isEqualToString:@"iPad5,4"])   return @"iPad Air 2";
    if([platform isEqualToString:@"iPad6,3"])   return @"iPad Pro 9.7";
    if([platform isEqualToString:@"iPad6,4"])   return @"iPad Pro 9.7";
    if([platform isEqualToString:@"iPad6,7"])   return @"iPad Pro 12.9";
    if([platform isEqualToString:@"iPad6,8"])   return @"iPad Pro 12.9";
    if([platform isEqualToString:@"iPad6,11"])  return @"iPad 5 (WiFi)";
    if([platform isEqualToString:@"iPad6,12"])  return @"iPad 5 (Cellular)";
    if([platform isEqualToString:@"iPad7,1"])   return @"iPad Pro 12.9 inch 2nd gen (WiFi)";
    if([platform isEqualToString:@"iPad7,2"])   return @"iPad Pro 12.9 inch 2nd gen (Cellular)";
    if([platform isEqualToString:@"iPad7,3"])   return @"iPad Pro 10.5 inch (WiFi)";
    if([platform isEqualToString:@"iPad7,4"])   return @"iPad Pro 10.5 inch (Cellular)";
    //2019年3月发布，更新二种机型：iPad mini、iPad Air
    if ([platform isEqualToString:@"iPad11,1"])   return @"iPad mini (5th generation)";
    if ([platform isEqualToString:@"iPad11,2"])   return @"iPad mini (5th generation)";
    if ([platform isEqualToString:@"iPad11,3"])   return @"iPad Air (3rd generation)";
    if ([platform isEqualToString:@"iPad11,4"])   return @"iPad Air (3rd generation)";
    
    //iPod
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch (5 Gen)";
    if ([platform isEqualToString:@"iPod7,1"])      return @"iPod touch (6th generation)";
    if ([platform isEqualToString:@"iPod9,1"])      return @"iPod touch (7th generation)";
    if ([platform isEqualToString:@"i386"])      return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])    return @"Simulator";
    return platform;
};
@end
