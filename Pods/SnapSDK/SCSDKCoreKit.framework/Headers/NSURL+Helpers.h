//
//  NSURL+Helpers.h
//  SCSDKCoreKit
//
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (Helpers)

+ (NSURL *)buildWithBaseUrlString:(NSString *)baseUrlString queries:(NSDictionary *)queries;
- (NSDictionary *)queryDictionary;

@end
