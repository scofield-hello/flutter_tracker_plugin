//
//  TrackerManager.h
//  Pods-Runner
//
//  Created by Nick on 2020/7/30.
//

#import <Foundation/Foundation.h>
#import "CoreLocation/CoreLocation.h"

NS_ASSUME_NONNULL_BEGIN

@interface TrackerManager : NSObject
@property (nonatomic, copy) NSString *postUrl;
@property (nonatomic) double minDistance;
@property (nonatomic) int minTimeInterval;
@property (nonatomic) NSMutableDictionary *headers;
@property (nonatomic) NSMutableDictionary *extraBody;

-(void) start;

-(void) stop;

@end

NS_ASSUME_NONNULL_END
