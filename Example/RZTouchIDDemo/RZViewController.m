//
//  RZViewController.m
//  RZTouchIDDemo
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZViewController.h"

@implementation RZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.touchID = [[RZTouchID alloc] initWithKeychainServicePrefix:@"com.raizlabs.demo"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( ![RZTouchID touchIDAvailable] ) {
        [self showAlertViewWithTitle:@"TouchID Unavailable" message:@"This demo MUST be run on a device with TouchID (iPhone 5s, iPhone 6, iPhone 6+)"];
        
        self.contentView.hidden = YES;
    }
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

@end
