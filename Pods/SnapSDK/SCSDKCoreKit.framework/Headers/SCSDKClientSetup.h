//
//  SCSDKClientSetup.h
//  SCSDKCoreKit
//
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SCSDKFont.h"

@interface SCSDKClientSetup : NSObject

@property (nonatomic, copy, readonly) NSString *clientID;

@property (nonatomic, copy, readonly) NSURL *redirectURL;

@property (nonatomic, strong, readonly) NSArray<NSString *> *scopes;

@property (nonatomic, strong, readonly) SCSDKFont *font;

+ (instancetype)sharedInstance;

- (instancetype)init NS_UNAVAILABLE;

@end
