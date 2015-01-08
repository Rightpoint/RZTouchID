//
//  RZViewController.h
//  RZTouchIDDemo
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import UIKit;
#import "RZTouchID.h"

@interface RZViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@property (strong, nonatomic) RZTouchID *touchID;

@end

