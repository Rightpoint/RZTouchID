//
//  RZAppDelegate.m
//  RZTouchIDDemo
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAppDelegate.h"

#import "RZTouchID.h"

@implementation RZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

+ (RZTouchID *)sharedTouchIDInstance
{
    static RZTouchID *s_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_manager = [[RZTouchID alloc] initWithKeychainServicePrefix:[[NSBundle mainBundle] bundleIdentifier]];
    });
    return s_manager;
}

@end
