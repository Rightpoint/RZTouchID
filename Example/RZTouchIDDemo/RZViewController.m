//
//  RZViewController.m
//  RZTouchIDDemo
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZViewController.h"
#import "RZAppDelegate.h"
#import "UIAlertView+RZCompletionBlocks.h"
#import "RZLoggedInViewController.h"


NSString* const kRZTouchIDLoginSuccessSegueIdentifier   = @"loginSuccess";
NSString* const kRZTouchIdLoggedInUser                  = @"loggedInUser";
NSString* const kRZTouchIDDefaultUserName               = @"averageuser";
NSString* const kRZTouchIDDefaultPassword               = @"password";

@interface RZViewController ()

// Outlets
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIButton *touchIDButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *submitButtonRightEdgeConstraint;
@property (weak, nonatomic) IBOutlet UILabel *passwordHint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *touchIdWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordRightEdgeConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordLeftEdgeConstraint;
@property (weak, nonatomic) IBOutlet UILabel *errorMessage;

// State
@property (assign, nonatomic) BOOL touchIDPasswordExists;
@property (assign, nonatomic) BOOL touchIDHasBeenAutoPresented;

// Animation constants
@property (assign, nonatomic) CGFloat submitButtonRightEdgeConstraintInitialConstant;
@property (assign, nonatomic) CGFloat touchIdWidthConstraintInitialConstant;

@end

@implementation RZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.usernameTextField.text = kRZTouchIDDefaultUserName;
    self.passwordHint.text = [NSString stringWithFormat:@"Try the username \"%@\"\n and password \"%@\"",kRZTouchIDDefaultUserName,kRZTouchIDDefaultPassword];

    self.errorMessage.alpha = 0.0f;
    self.touchIDPasswordExists = NO;
    self.touchIDHasBeenAutoPresented = NO;
    self.submitButtonRightEdgeConstraintInitialConstant = self.submitButtonRightEdgeConstraint.constant;
    self.touchIdWidthConstraintInitialConstant = self.touchIdWidthConstraint.constant;

    [self showTouchIdReferences:[RZTouchID touchIDAvailable]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( [RZTouchID touchIDAvailable] && !self.touchIDHasBeenAutoPresented ) {
        [self presentTouchID];
    }
}

- (void)showTouchIdReferences:(BOOL)show
{
    if ( show ) {
        self.submitButtonRightEdgeConstraint.constant = self.submitButtonRightEdgeConstraintInitialConstant;
        self.touchIdWidthConstraint.constant = self.touchIdWidthConstraintInitialConstant;
        self.touchIDButton.hidden = NO;
    }
    else {
        self.submitButtonRightEdgeConstraint.constant = 0.0f;
        self.touchIdWidthConstraint.constant = 0.0f;
        self.touchIDButton.hidden = YES;
    }
//    [self.view layoutIfNeeded];
}

- (BOOL)authenticationSuccessful
{
    return [self.usernameTextField.text isEqualToString:kRZTouchIDDefaultUserName] && [self.passwordTextField.text isEqualToString:kRZTouchIDDefaultPassword];
}

- (IBAction)touchIdLaunchTapped:(id)sender
{
    [self.view endEditing:YES];
    [self presentTouchID];
}

- (void)showErrorAnimated:(BOOL)animated
{
    
    CGFloat leftEdgeInitial = self.passwordLeftEdgeConstraint.constant;
    CGFloat rightEdgeInitial = self.passwordRightEdgeConstraint.constant;
    CGFloat animationDuration = 0.1f;
    CGFloat damping = 0.65f;
    CGFloat springVelocity = 1.0f;
    self.passwordRightEdgeConstraint.constant = rightEdgeInitial - 10.0f;
    self.passwordLeftEdgeConstraint.constant = leftEdgeInitial + 10.0f;
    
    [UIView animateWithDuration:animationDuration delay:0.0f usingSpringWithDamping:damping initialSpringVelocity:springVelocity options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.errorMessage.alpha = 1.0f;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.passwordRightEdgeConstraint.constant = rightEdgeInitial + 10.0f;
        self.passwordLeftEdgeConstraint.constant = leftEdgeInitial - 10.0f;
        [UIView animateWithDuration:animationDuration delay:0.0f usingSpringWithDamping:damping initialSpringVelocity:springVelocity options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.passwordRightEdgeConstraint.constant = rightEdgeInitial - 10.0f;
            self.passwordLeftEdgeConstraint.constant = leftEdgeInitial + 10.0f;
            [UIView animateWithDuration:animationDuration delay:0.0f usingSpringWithDamping:damping initialSpringVelocity:springVelocity options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                self.passwordRightEdgeConstraint.constant = rightEdgeInitial ;
                self.passwordLeftEdgeConstraint.constant = leftEdgeInitial ;
                [UIView animateWithDuration:animationDuration delay:0.0f usingSpringWithDamping:damping initialSpringVelocity:springVelocity options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    [self.view layoutIfNeeded];
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:1.4f animations:^{
                        self.errorMessage.alpha = 0.0f;
                    }];
                }];
            }];
        }];
    }];
}

#pragma mark - RZTouchID helpers
- (void)presentTouchID
{
    __weak __typeof(self)wself = self;
    [[RZAppDelegate sharedTouchIDInstance] retrievePasswordWithIdentifier:self.usernameTextField.text withPrompt:@"Access your account" completion:^(NSString *password, NSError *error) {
        if ( password == nil || error != nil ) {
            if ( error.code != errSecAuthFailed ) {
                [wself showTouchIdReferences:NO];
                wself.touchIDPasswordExists = NO;
            }
            else {
                wself.touchIDPasswordExists = YES;
            }
        }
        else {
            wself.touchIDHasBeenAutoPresented = YES;
            wself.touchIDPasswordExists = YES;
            wself.passwordTextField.text = password;
            if ( [wself shouldPerformSegueWithIdentifier:kRZTouchIDLoginSuccessSegueIdentifier sender:wself] ) {
                [wself performSegueWithIdentifier:kRZTouchIDLoginSuccessSegueIdentifier sender:wself];
            }
        }
    }];
}

- (void)savePasswordToKeychain:(NSString *)password withCompletion:(RZTouchIDCompletion)completion
{
    [[RZAppDelegate sharedTouchIDInstance] addPassword:password withIdentifier:self.usernameTextField.text completion:^(NSString *password, NSError *error) {
        if ( completion != nil ) {
            completion(password,nil);
        }
    }];
}

- (void)removePasswordFromKeychain
{
    [[RZAppDelegate sharedTouchIDInstance] deletePasswordWithIdentifier:self.usernameTextField.text completion:nil];
}

#pragma mark - Segue methods

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ( [identifier isEqualToString:kRZTouchIDLoginSuccessSegueIdentifier] ) {
        if ( [self authenticationSuccessful] ) {
            [[NSUserDefaults standardUserDefaults] setObject:self.usernameTextField.text forKey:kRZTouchIdLoggedInUser];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if ( [RZTouchID touchIDAvailable] && !self.touchIDPasswordExists ) {
                __weak __typeof(self)wself = self;
                UIAlertView *useTouchIDAlertView = [[UIAlertView alloc] initWithTitle:@"Touch ID" message:@"Would you like to enable touch ID to make it easier to login in the future?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
                [useTouchIDAlertView rz_showWithCompletionBlock:^(NSInteger dismissalButtonIndex) {
                    if ( dismissalButtonIndex != useTouchIDAlertView.cancelButtonIndex ) {
                        [wself savePasswordToKeychain:wself.passwordTextField.text withCompletion:nil];
                        wself.touchIDPasswordExists = YES;
                    }
                    else {
                        [wself removePasswordFromKeychain];
                        wself.touchIDPasswordExists = NO;
                    }
                }];
            }
            return YES;
        }
        else {
            [self showErrorAnimated:YES];
        }
    }
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    RZLoggedInViewController *destinationVC = (RZLoggedInViewController *)segue.destinationViewController;
    destinationVC.touchIDLoginDisabled = !self.touchIDPasswordExists;
}

- (IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    RZLoggedInViewController *sourceVC = (RZLoggedInViewController *)unwindSegue.sourceViewController;
    [self showTouchIdReferences:!sourceVC.touchIDLoginDisabled];
    self.touchIDPasswordExists = NO;
    
    self.passwordTextField.text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRZTouchIdLoggedInUser];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ( [textField isEqual:self.usernameTextField] ) {
        [self.passwordTextField becomeFirstResponder];
    }
    else {
        [self.view endEditing:YES];
    }
    return NO;
}

@end
