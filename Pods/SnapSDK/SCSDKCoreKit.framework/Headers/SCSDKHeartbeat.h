//
//  SCSDKHeartbeat.h
//  SCSDKCoreKit
//
//  Created by Hongjai Cho on 12/21/18.
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#import "CommonEnums.h"

#import <Foundation/Foundation.h>

@class EncodablePicoproto;

NS_ASSUME_NONNULL_BEGIN

@interface SCSDKHeartbeat : NSObject

@property (nonatomic, assign, readonly) SdkKitType kitType;

- (instancetype)initWithKitType:(SdkKitType)kitType kitVersion:(NSString *)kitVersion;

- (EncodablePicoproto *)encodeablePicoproto;

@end

NS_ASSUME_NONNULL_END
