//
//  NSData+Helpers.h
//  SCSDKCoreKit
//
//  Copyright © 2017 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Helpers)

+ (instancetype)sc_dataWithBase64EncodedString:(NSString *)base64EncodedString;

+ (instancetype)sc_dataWithBase64UrlEncodedString:(NSString *)base64UrlEncodedString;

+ (instancetype)sc_randomDataWithSize:(size_t)size;

- (NSString *)sc_base64EncodedString;

/**
 * Variant of base64 that is url safe.
 * see https://tools.ietf.org/html/rfc7515#appendix-C for conversion between formats.
 */
- (NSString *)sc_base64UrlEncodedString;
- (NSString *)sc_md5Base64String;
- (NSString *)sc_sha256Base64String;
- (NSString *)sc_sha256Base64Url;
- (NSString *)sc_sha256HexBase64String;

@end
