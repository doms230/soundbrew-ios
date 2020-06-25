//
//  SCSDKTweakEnabled.h
//  SCSDKCoreKit
//
//  Created by Yang Gao on 6/26/18.
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

static inline BOOL FBTweakEnabled(void) {
#if FB_TWEAK_ENABLED
    return YES;
#else
    return NO;
#endif
}
