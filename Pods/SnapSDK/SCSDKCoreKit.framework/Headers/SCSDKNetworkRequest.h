//
//  SCSDKNetworkRequest.h
//  SCSDKCoreKit
//
//  Copyright © 2017 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SCAuthHeaderProvider;

@interface SCSDKNetworkRequest : NSObject

@property (nonatomic, copy, readonly) NSString *path;

@property (nonatomic, copy, readonly) NSString *method;

@property (nonatomic, assign, readonly) NSInteger expectedStatusCode;

@property (nonatomic, copy, readonly) NSString *identifier;

@property (nonatomic, strong) NSMutableDictionary *headers;

@property (nonatomic, strong) NSDictionary *queryParams;

@property (nonatomic, copy) NSData *httpBody;

@property (nonatomic, copy) NSString *contentType;

@property (nonatomic, strong) id<SCAuthHeaderProvider> authHeaderProvider;

- (instancetype)initWithPath:(NSString *)path
                      method:(NSString *)method
          authHeaderProvider:(id<SCAuthHeaderProvider>)authHeaderProvider;

- (NSURLRequest *)toUrlRequest;

- (NSURLRequest *)toUrlRequestWithBaseUrl:(NSString *)baseUrl;

+ (NSString *)userAgent;

@end
