//
//  SnapKitEvents.h
//  SCSDKCoreKit
//
//  Created by Hongjai Cho on 8/17/18.
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#import <SCPicoproto/picoproto.h>
#import <SCSDKMetrics/Event.h>

#import <Foundation/Foundation.h>

@class EncodablePicoproto;

@interface SnapKitEvents : NSObject

+ (picoproto_ctx *)kitEventBaseWithKitType:(KitType)kitType kitVersion:(NSString *)kitVersion;

+ (EncodablePicoproto *)serverEventWithServerEventData:(picoproto_ctx *)serverEventData;

@end