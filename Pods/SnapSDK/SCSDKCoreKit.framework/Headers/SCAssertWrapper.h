//
//  SCAssertWrapper.h
//  SCSDKCoreKit
//
//  Created by Ethan Myers on 7/18/18.
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCSDKClientSetup.h"

@protocol SCHandledExceptionLogger <NSObject>

// Exceptions
+ (void)logHandledException:(NSException *)exception;

@end

extern void SCLogAssertAsHandledException(NSString *title, NSString *description);
extern void SCSetHandledExceptionLogger(Class<SCHandledExceptionLogger> handledExceptionLogger);

#if !defined(SCAssert)
#if !defined(NS_BLOCK_ASSERTIONS)
#define SCAssert(condition, desc, ...) NSAssert((condition), @"ASSERT-" desc, ##__VA_ARGS__)
#define SCCAssert(condition, desc, ...) NSCAssert((condition), @"ASSERT-" desc, ##__VA_ARGS__)
static inline BOOL SCAssertEnabled(void)
{
    return YES;
}
// Using the new API for dispatch_assert_queue.
#define SCAssertQueuePerformer(performer)                                                                              \
do {                                                                                                               \
if (&dispatch_assert_queue) {                                                                                  \
dispatch_assert_queue(performer.queue);                                                                    \
}                                                                                                              \
} while (0)
#else
static inline BOOL SCAssertEnabled(void)
{
    return NO;
}
#define SCCAssert(condition, desc, ...)                                                                                \
do {                                                                                                               \
if (!(condition)) {                                                                                            \
NSString *title = [NSString stringWithFormat:@"Assertion failure in %s", __PRETTY_FUNCTION__];          \
NSString *descriptionFormat =                                                                              \
[NSString stringWithFormat:@"[ClientID=%@] Condition not satisfied: %%s, reason: '%@'", SCSDKClientSetup.sharedInstance.clientID, desc];                    \
NSString *description = [NSString stringWithFormat:descriptionFormat, #condition, ##__VA_ARGS__];       \
SCLogAssertAsHandledException(title, description);                                                         \
}                                                                                                              \
} while (0)
// Because we don't use class specific information in our handled exception, therefore, SCAssert in this branch
// is only an alias of SCCAssert.
#define SCAssert(condition, desc, ...) SCCAssert((condition), (desc), ##__VA_ARGS__)
#define SCAssertQueuePerformer(performer)
#endif
#endif


#define SCAssertFail(desc, ...) SCAssert(NO, desc, ##__VA_ARGS__)
#define SCAssertTrue(condition) SCAssert((condition), @ #condition)

#define SCAssertClass(INSTANCE, CLASSNAME)                                                                             \
SCAssert([INSTANCE isKindOfClass:[CLASSNAME class]],                                                               \
@"Expecting an instance of class: %@, but the provided instance is of class: %@",                         \
NSStringFromClass([CLASSNAME class]), NSStringFromClass([INSTANCE class]))

#define SCCAssertClass(INSTANCE, CLASSNAME)                                                                            \
SCCAssert([INSTANCE isKindOfClass:[CLASSNAME class]],                                                              \
@"Expecting an instance of class: %@, but the provided instance is of class: %@",                        \
NSStringFromClass([CLASSNAME class]), NSStringFromClass([INSTANCE class]))

#define SCParameterAssert(condition) SCAssert((condition), @"Invalid parameter not satisfying: %@", @ #condition)

#define SCAssertEqualObjects(param1, param2)                                                                           \
SCAssert([@(param1) isEqual:@(param2)], @"Error: %@ and %@ are not equal.", @(param1), @(param2))

#define SC_STATIC_ASSERT(condition, msg) typedef char _static_assert_##msg[((condition) ? 1 : -1)]

#define SCAssertMainThread() SCAssert([NSThread isMainThread], @"Error: Observed values changed off main thread.")

#define SCAssertNotMainThread() SCAssert(![NSThread isMainThread], @"Error: Should be called off the main thread.")

#define SCCAssertFail(desc, ...) SCCAssert(NO, desc, ##__VA_ARGS__)

#define SCCAssertMainThread() SCCAssert([NSThread isMainThread], @"Error: Observed values changed off main thread.")

#define SCCAssertNotMainThread() SCCAssert(![NSThread isMainThread], @"Error: Should be called off the main thread.")

#define SCCParameterAssert(condition) SCCAssert((condition), @"Invalid parameter not satisfying: %@", @ #condition)

#define SCCAssertPerformer(performer)                                                                                  \
SCCAssert([performer isCurrentPerformer], @"Error: Action must be performed on class' performer");

#define SCAssertPerformer(performer)                                                                                   \
SCAssert([performer isCurrentPerformer], @"Error: Action must be performed on class' performer")

#define SCAssertImplementedBySubclass()                                                                                \
SCAssert(NO, @"Error: %@ should be implemented by subclass.", NSStringFromSelector(_cmd))
