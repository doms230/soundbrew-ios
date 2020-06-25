//
//  UIApplication+Helpers.h
//  SCSDKCoreKit
//
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Helpers)

@property (class, nonatomic, readonly) BOOL isRTL;
@property (class, nonatomic, readonly, nullable) UIViewController *topViewController;

+ (void)openURL:(nonnull NSURL *)url completion:(nullable void (^)(BOOL success))completion;

@end
