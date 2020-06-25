//
//  SCLogMacros.h
//  SCSDKCoreKit
//
//  Created by Hongjai Cho on 1/18/18.
//  Copyright © 2018 Snap, Inc. All rights reserved.
//

#ifndef SCLogMacros_h
#define SCLogMacros_h

#define __SCLog(level, fmt, ...) NSLog((@"%s [Line %d] [%s] " fmt), __PRETTY_FUNCTION__, __LINE__, level, ##__VA_ARGS__)

#ifdef DEBUG
#   define SCLogDebug(fmt, ...) __SCLog("DEBUG", fmt, ##__VA_ARGS__)
#   define SCLogWarning(fmt, ...) __SCLog("WARNING", fmt, ##__VA_ARGS__)
#   define SCLogError(fmt, ...) __SCLog("ERROR", fmt, ##__VA_ARGS__)
#else
#   define SCLogDebug(...)
#   define SCLogWarning(...)
#   define SCLogError(...)
#endif

#define SCLogExternal(fmt, ...) NSLog((@"[SnapKit] " fmt), ##__VA_ARGS__)

#endif /* SCLogMacros_h */
