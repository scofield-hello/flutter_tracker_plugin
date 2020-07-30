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


-(instancetype) initWithPostUrl:(NSString*)postUrl
                               minDistance:(double) minDistance
                               minTimeInterval:(int) minTimeInterval
                               headers:(NSMutableDictionary*) headers
                               extraBody:(NSMutableDictionary*) extraBody;

-(void) start;

-(void) stop;

@end

NS_ASSUME_NONNULL_END
