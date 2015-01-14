//
//  RZAppDelegate.m
//  RZTouchIDDemo
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZAppDelegate.h"

#import "RZTouchID.h"

@interface RZAppDelegate () <RZTouchIDDelegate>

@property (copy, nonatomic) NSString *touchIDUserIDKey;

@end

@implementation RZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.touchIDUserIDKey = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingString:@".touchIDLogins"];
    return YES;
}

+ (RZTouchID *)sharedTouchIDInstance
{
    static RZTouchID *s_manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //Switch touchIDMode to RZTouchIDModeBiometricKeychain to try the biometric + passcode version. You'll see a Local Authentication login version if you have tested that first. Login and then disable touch ID and logout after making the touchIDMode switch.
        s_manager = [[RZTouchID alloc] initWithKeychainServicePrefix:[[NSBundle mainBundle] bundleIdentifier] authenticationMode:RZTouchIDModeLocalAuthentication];
        [s_manager setLocalizedFallbackTitle:@"Use yer password instead!"];
        s_manager.delegate = (id <RZTouchIDDelegate>)[[UIApplication sharedApplication] delegate];
    });
    return s_manager;
}

#pragma mark - RZTouchIDDelegate and helper
/**
 *  In this demo app we maintain a list of accounts with touch ID protected passwords to support multiple accounts per user e.g. home and work email.
 */
- (void)touchID:(RZTouchID *)touchID didDeletePasswordForIdentifier:(NSString *)identifier
{
    NSMutableArray *touchIDUserIDCollection = [self currentTouchIDUserIDArray];
    
    if ( identifier != nil && [identifier length] > 0 ) {
        NSUInteger foundUserIndex = [self findUserInArray:touchIDUserIDCollection withIdentifier:identifier];
        if ( foundUserIndex != NSNotFound ) {
            [touchIDUserIDCollection removeObjectAtIndex:foundUserIndex];
            [self saveTouchIDUserIDArray:touchIDUserIDCollection];
        }
    }
}

- (void)touchID:(RZTouchID *)touchID didAddPasswordForIdentifier:(NSString *)identifier
{
    NSMutableArray *touchIDUserIDArray = [self currentTouchIDUserIDArray];

    if ( identifier != nil && [identifier length] > 0 ) {
        NSUInteger foundUserIndex = [self findUserInArray:touchIDUserIDArray withIdentifier:identifier];
        if ( foundUserIndex == NSNotFound ) {
            [touchIDUserIDArray addObject:identifier];
            [self saveTouchIDUserIDArray:touchIDUserIDArray];
        }
    }
}

- (BOOL)touchID:(RZTouchID *)touchID shouldAddPasswordForIdentifier:(NSString *)identifier
{
    BOOL available = NO;
    NSArray *touchIDUserIDArray = [self currentTouchIDUserIDArray];
    
    if ( identifier != nil && [identifier length] > 0 ) {
        NSUInteger foundUserIndex = [self findUserInArray:touchIDUserIDArray withIdentifier:identifier];
        if ( foundUserIndex != NSNotFound ) {
            available = YES;
        }
    }
    
    return available;
}

#pragma mark - NSUserDefaults Touch ID array collection methods
/**
 *  Get the current array of touch ID users
 *
 *  @return Mutable copy of current user IDs
 */
- (NSMutableArray *)currentTouchIDUserIDArray
{
    NSArray *currentTouchIDUserIDCollection = [[NSUserDefaults standardUserDefaults] objectForKey:self.touchIDUserIDKey];
    return ( currentTouchIDUserIDCollection.count > 0 && currentTouchIDUserIDCollection != nil ? [currentTouchIDUserIDCollection mutableCopy] : [NSMutableArray array] );
}

/**
 *  Save the provided array of UserIDs to NSUserDefaults
 *
 *  @param touchIDUserIDArray touchIDUserIDArray NSArray of touch ID user IDs
 */
- (void)saveTouchIDUserIDArray:(NSArray *)touchIDUserIDArray
{
    if ( touchIDUserIDArray!= nil ) {
        [[NSUserDefaults standardUserDefaults] setObject:touchIDUserIDArray forKey:self.touchIDUserIDKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

/**
 *  Searches the provided array of touch ID User IDs for a specific ID
 *
 *  @param touchIDUserIDArray touchIDUserIDArray NSArray of user IDs
 *  @param touchIDUserID      touchIDUserID The User to look for
 *
 *  @return the index of the first match of the provided UserID in the Array, NSNotFound if item is not found
 */
- (NSUInteger)findUserInArray:(NSArray *)touchIDUserIDArray withIdentifier:(NSString *)touchIDUserID
{
    return [touchIDUserIDArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [(NSString *)obj isEqualToString:touchIDUserID];
    }];
}

@end
