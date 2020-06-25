//
//  SCSDKNetworkServicesAPI.h
//  SCSDKNetworking
//
//  Created by Duncan Riefler on 2/25/20.
//

#import <Foundation/Foundation.h>
#import <SCSDKNetworking/SCSDKNetworkCallback.h>
#import <SCSDKNetworking/SCSDKCertPinningHandler.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCSDKNetworkServicesAPI : NSObject<NSURLSessionDelegate>

- (instancetype)initWithNSURLSession:(NSURLSession *)sessionConfiguration
                  certPinningHandler:(id<SCSDKCertPinningHandler>)certPinningHandler;

- (void)submitRequest:(NSURLRequest *)request
           completion:(SCSDKNetworkRequestCompletionCallback)callback;

@end

NS_ASSUME_NONNULL_END
