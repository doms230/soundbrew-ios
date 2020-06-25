//
//  NSString+Helpers.h
//  SCSDKCoreKit
//
//  Copyright © 2017 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Helpers)

+ (NSString *)urlEncodeString:(NSString *)string;

+ (NSString *)randomUrlSafeStringWithSize:(NSUInteger)size;

+ (NSString *)randomBase64EncodedStringOfLength:(size_t)length;

@end
