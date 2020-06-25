//
//  SCHashUtils.h
//  SCSDKCoreKit
//
//  Created by Ethan Myers on 4/18/19.
//  Copyright © 2019 Snap, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGBase.h>

extern NSUInteger SCHashFloat(float givenFloat);
extern NSUInteger SCHashDouble(double givenDouble);
extern NSUInteger SCHashCGFloat(CGFloat givenCGFloat);

extern NSUInteger SCRemodelHash(NSUInteger subhashes[], int length);
