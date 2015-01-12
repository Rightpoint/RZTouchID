//
//  RZLoggedInViewController.m
//  RZTouchIDDemo
//
//  Created by Adam Howitt on 1/9/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZLoggedInViewController.h"
#import "RZTouchID.h"
#import "RZAppDelegate.h"
#import "RZViewController.h"

@interface RZLoggedInViewController ()

@property (weak, nonatomic) IBOutlet UIButton *disableTouchIDButton;

@end

@implementation RZLoggedInViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self ) {
        self.touchIDLoginDisabled = NO;
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.disableTouchIDButton.hidden = self.touchIDLoginDisabled;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)disableTouchID:(id)sender
{
    NSString *loggedInUser = [[NSUserDefaults standardUserDefaults] objectForKey:kRZTouchIdLoggedInUser];
    [[RZAppDelegate sharedTouchIDInstance] deletePasswordWithIdentifier:loggedInUser completion:^(NSString *password, NSError *error) {
        self.disableTouchIDButton.hidden = YES;
        self.touchIDLoginDisabled = YES;
    }];
}

@end
