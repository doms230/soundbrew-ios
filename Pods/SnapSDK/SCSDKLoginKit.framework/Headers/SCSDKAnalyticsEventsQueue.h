//
//  SCSDKAnalyticsEventsQueue.h
//  SCSDKCoreKit
//
//  Created by Hongjai Cho on 5/24/18.
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#import <SCSDKCoreKit/SCAuthHeaderProvider.h>
#import <Foundation/Foundation.h>
#import <SCSDKCoreKit/SCSDKNetworkServicesAPI.h>

@class EncodablePicoproto;

@interface SCSDKAnalyticsEventsQueue : NSObject

+ (instancetype)sharedInstance;
- (instancetype)initWithNetworkServicesAPI:(SCSDKNetworkServicesAPI *) networkServicesAPI;

- (void)addEvent:(EncodablePicoproto *)event;

@end
