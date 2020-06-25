//
//  EventWrapper.h
//  SCSDKCoreKit
//
//  Created by Hongjai Cho on 9/4/18.
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EncodablePicoproto;

@interface EventWrapper : NSObject<NSSecureCoding>

- (instancetype)initWithSequenceId:(NSUInteger)sequenceId
                             event:(EncodablePicoproto *)event;

@property(nonatomic, assign, readonly) NSUInteger sequenceId;

@property(nonatomic, strong, readonly, nonnull) EncodablePicoproto *event;

@property(nonatomic, assign, readonly) BOOL isRetry;

@property(nonatomic, assign, readonly) NSUInteger numRetried;

@property(nonatomic, assign, readonly) int64_t nextRetryTimeMillis;

@end
