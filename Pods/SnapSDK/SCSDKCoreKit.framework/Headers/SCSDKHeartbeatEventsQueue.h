//
//  SCSDKHeartbeatEventsQueue.h
//  SCSDKCoreKit
//
//  Created by Hongjai Cho on 12/21/18.
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SCSDKHeartbeat;

NS_ASSUME_NONNULL_BEGIN

@interface SCSDKHeartbeatEventsQueue : NSObject

+ (instancetype)sharedInstance;

- (void)addEvent:(SCSDKHeartbeat *)event;

@end

NS_ASSUME_NONNULL_END
