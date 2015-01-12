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

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.touchIDLoginDisabled = NO;
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
