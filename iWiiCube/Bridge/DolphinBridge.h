// Copyright 2016 OatmealDome, WillCobb
// Licensed under GPLV2+
// Refer to the license.txt provided

// Consider making this a singleton

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

@protocol DolphinBridgeDelegate <NSObject>

@end

@interface DolphinBridge : NSObject

- (void)openRomAtPath:(NSString* )path inLayer:(CAEAGLLayer *)layer;
//- (void)openRomAtPath:(NSString* )path inLayer:(CGLayer *)layer;

@end

#pragma GCC diagnostic pop
