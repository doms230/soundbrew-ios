//
//  SCAppEnvironment.h
//  SCSDKCoreKit
//
//  Created by Khoi Tran on 10/3/15.
//  Copyright © 2015 Snapchat, Inc. All rights reserved.
//

#import "SCMacros.h"

#import <Foundation/Foundation.h>

static SC_ALWAYS_INLINE BOOL SCIsDebugBuild(void)
{
#ifdef DEBUG
    return YES;
#else
    return NO;
#endif
}

static SC_ALWAYS_INLINE BOOL SCIsSimulator(void)
{
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    return NO;
#endif
}

static SC_ALWAYS_INLINE BOOL SCIsRunningUITests(void)
{
    if (!SCIsDebugBuild()) {
        return NO;
    } else {
        static dispatch_once_t onceToken;
        static BOOL isUITest;
        dispatch_once(&onceToken, ^{
            isUITest = [[NSProcessInfo processInfo].arguments containsObject:@"isUITest"];
        });
        return isUITest;
    }
}

// Convert the app flavor to a string to send along with the apns token,
// so that the server knows which push certificate to use when sending pushes
static SC_ALWAYS_INLINE NSString *SCDeviceTokenType(void)
{
#if defined PROTOTYPING
    return @"prototyping";
#elif defined DEBUG
    return @"debug";
#elif defined MASTER
    return @"master";
#elif defined ALPHA
    return @"alpha";
#else
    return @"production";
#endif
}

SC_EXTERN_C_BEGIN

FOUNDATION_EXTERN BOOL SCIsRunningTests(void);
FOUNDATION_EXTERN BOOL SCIsRunningExtension(void);
FOUNDATION_EXTERN BOOL SCIsRunningWithDebugger(void);
FOUNDATION_EXTERN BOOL SCIsAppStoreReceiptSandbox(void);
FOUNDATION_EXTERN NSString *SCLocale(void);
FOUNDATION_EXTERN NSString *SCArchitecture(void);
FOUNDATION_EXTERN NSString *SCKitVersionForClass(Class clazz);

SC_EXTERN_C_END
