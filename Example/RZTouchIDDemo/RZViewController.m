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

static NSString* const kRZTouchIDLoginSuccessSegueIdentifier   = @"loginSuccess";
static NSString* const kRZTouchIDDefaultUserName               = @"averageuser";
static NSString* const kRZTouchIDDefaultPassword               = @"password";
NSString* const kRZTouchIdLoggedInUser                         = @"loggedInUser";

@interface RZViewController ()

// Outlets
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIButton *touchIDButton;
@property (weak, nonatomic) IBOutlet UILabel *passwordHint;
@property (weak, nonatomic) IBOutlet UILabel *errorMessage;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *submitButtonRightEdgeConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *touchIdWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordRightEdgeConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordLeftEdgeConstraint;

// State
@property (assign, nonatomic) BOOL touchIDPasswordExists;
@property (assign, nonatomic) BOOL touchIDHasBeenAutoPresented;

// Animation
@property (assign, nonatomic) CGFloat submitButtonRightEdgeConstraintInitialConstant;
@property (assign, nonatomic) CGFloat touchIdWidthConstraintInitialConstant;
@property (assign, nonatomic) BOOL isAnimating;

@end

@implementation RZViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isAnimating = NO;
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
    else if ( ![RZTouchID touchIDAvailable] ) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            UIAlertView *touchIdDemoAlert = [[UIAlertView alloc] initWithTitle:@"Touch ID" message:@"This device doesn't support touch ID - the demo will be a little... boring." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [touchIdDemoAlert rz_showWithCompletionBlock:nil];
        });
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private methods

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
}

/**
 *  Create your own authentication mechanism e.g. webservice call with the userID and password
 *
 *  @return return YES if successful, otherwise NO.
 */
- (BOOL)authenticationSuccessful
{
    return [self.usernameTextField.text isEqualToString:kRZTouchIDDefaultUserName] && [self.passwordTextField.text isEqualToString:kRZTouchIDDefaultPassword];
}

- (IBAction)touchIdLaunchTapped:(id)sender
{
    [self.view endEditing:YES];
    [self presentTouchID];
}

- (IBAction)submitTapped:(id)sender
{
    if ( [self authenticationSuccessful] ) {
        [[NSUserDefaults standardUserDefaults] setObject:self.usernameTextField.text forKey:kRZTouchIdLoggedInUser];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if ( [RZTouchID touchIDAvailable] && !self.touchIDPasswordExists ) {
            __weak __typeof(self)wself = self;
            UIAlertView *useTouchIDAlertView = [[UIAlertView alloc] initWithTitle:@"Touch ID" message:@"Would you like to enable touch ID to make it easier to login in the future?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [useTouchIDAlertView rz_showWithCompletionBlock:^(NSInteger dismissalButtonIndex) {
                if ( dismissalButtonIndex != useTouchIDAlertView.cancelButtonIndex ) {
                    [wself savePasswordToKeychain:wself.passwordTextField.text withCompletion:^(NSString *password, NSError *error){
                        if ( error == nil ) {
                            wself.touchIDPasswordExists = YES;
                        }
                        else {
                            wself.touchIDPasswordExists = NO;
                        }
                        [wself performSegueWithIdentifier:kRZTouchIDLoginSuccessSegueIdentifier sender:wself];
                    }];
                }
                else {
                    [wself removePasswordFromKeychain];
                    wself.touchIDPasswordExists = NO;
                    [wself performSegueWithIdentifier:kRZTouchIDLoginSuccessSegueIdentifier sender:wself];
                }

            }];
        }
        else {
            [self performSegueWithIdentifier:kRZTouchIDLoginSuccessSegueIdentifier sender:self];
        }
    }
    else {
        [self showErrorAnimated:YES];
    }
}

- (void)showErrorAnimated:(BOOL)animated
{
    if ( animated && !self.isAnimating ) {
        self.isAnimating = YES;
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
                            self.isAnimating = NO;
                        }];
                    }];
                }];
            }];
        }];
    }
    else {
        self.errorMessage.alpha = 1.0f;
    }
}

#pragma mark - RZTouchID helpers
- (void)presentTouchID
{
    __weak __typeof(self)wself = self;
    [[RZAppDelegate sharedTouchIDInstance] retrievePasswordWithIdentifier:self.usernameTextField.text withPrompt:@"Access your account" completion:^(NSString *password, NSError *error) {
        if ( password == nil || error != nil ) {
            if ( error.code != RZTouchIDErrorAuthenticationFailed ) {
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
            [wself submitTapped:wself];
        }
    }];
}

- (void)savePasswordToKeychain:(NSString *)password withCompletion:(RZTouchIDCompletion)completion
{
    [[RZAppDelegate sharedTouchIDInstance] addPassword:password withIdentifier:self.usernameTextField.text completion:completion];
}

- (void)removePasswordFromKeychain
{
    [[RZAppDelegate sharedTouchIDInstance] deletePasswordWithIdentifier:self.usernameTextField.text completion:nil];
}

#pragma mark - Segue methods

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ( [identifier isEqualToString:kRZTouchIDLoginSuccessSegueIdentifier] ) {
        return NO;
    }
    return YES;
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
    self.touchIDPasswordExists = !sourceVC.touchIDLoginDisabled;
    
    self.passwordTextField.text = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kRZTouchIdLoggedInUser];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ( [textField isEqual:self.passwordTextField] ) {
        BOOL useTouchID = ( [self.usernameTextField.text length] > 0 && [[RZAppDelegate sharedTouchIDInstance] touchIDAvailableForIdentifier:self.usernameTextField.text] );
        [self showTouchIdReferences:useTouchID];
        if ( useTouchID ) {
            [self presentTouchID];
        }
    }
}

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
