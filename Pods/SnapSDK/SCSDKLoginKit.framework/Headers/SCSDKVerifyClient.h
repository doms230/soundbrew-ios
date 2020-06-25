//
//  SCSDKVerifyClient.h
//  SCSDKLoginKit
//
//  Copyright © 2017 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SCSDKVerifyClient : NSObject

/**
* Finish verify with Snapchat.
*
* @param application for singleton app object of calling app
* @param url created by Snapchat.
* @param options for the url to handle
* @return YES if Snapchat can open the the url, NO if it cannot
*/
+ (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;

/**
  Start Verify and Login with Snapchat
 */
+ (void)verifyAndLoginFromViewController:(UIViewController *)viewController
                           phone:(NSString *)phone
                          region:(NSString *)region
                      completion:(void (^)(BOOL success, NSString * _Nullable phoneId, NSString * _Nullable verifyId, NSError * _Nullable))completion;

@end

NS_ASSUME_NONNULL_END
