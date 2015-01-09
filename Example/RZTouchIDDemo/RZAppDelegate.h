//
//  RZAppDelegate.h
//  RZTouchIDDemo
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import UIKit;
@class RZTouchID;
@interface RZAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) RZTouchID *touchIDService;

+ (RZTouchID *)sharedTouchIDInstance;

@end

