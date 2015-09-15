//
//  RZTouchID.h
//
//  Created by Adam Howitt on 8/18/14.

// Copyright 2014 Raizlabs and other contributors
// http://raizlabs.com/
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

@class RZTouchID;

/**
 *  RZTouchIDDelegate allows you to provide a custom mechanism for storing the identifier (typically representing a user) associated with the password you are storing and protecting with touch ID.
 * 
 *  Typically you might store the username using NSUserDefaults but you have freedom to implement this in however you see fit.  
 *  
 *  Be aware that if the mechanism you use is replicated to the cloud the identifier might persist onto other devices but the keychain might not. In this case the user would experience login failures and have to manually enter the password.
 */
@protocol RZTouchIDDelegate <NSObject>

@optional

/**
 *  Called by deletePasswordWithIdentifier:completion: 
 * 
 *  You would typically remove the provided identifier from your store of touch ID enabled identifiers to avoid presenting touch ID UI for an identifier without a stored password.
 *
 *  @param identifier Typically a string representing a user. This might be an email, a UUID or a username.
 */
- (void)touchID:(RZTouchID *)touchID didDeletePasswordForIdentifier:(NSString *)identifier;

/**
 *  Called by addPassword:withIdentifier:completion: on successfully writing the password to the keychain. If the keychain write fails you should not store the identifier as having a stored keychain password.
 *
 *  @param identifier Typically a string representing a user. This might be an email, a UUID or a username.
 */
- (void)touchID:(RZTouchID *)touchID didAddPasswordForIdentifier:(NSString *)identifier;

/**
 *  Called by touchIDAvailableForIdentifier: to determine if the device has touch ID enabled for the identifier provided
 *
 *  @param identifier Typically a string representing a user. This might be an email, a UUID or a username.
 */
- (BOOL)touchID:(RZTouchID *)touchID shouldAddPasswordForIdentifier:(NSString *)identifier;

@end

/**
 *  Generic completion block type for returning an error if a method with this completion
 *  block fails.
 *
 *  @param password The password that was added or retrieved, or nil if there was an error. Will also be nil for delete requests.
 *  @param error    Returns NSError for the completion block to handle or nil
 */
typedef void (^RZTouchIDCompletion)(NSString *password, NSError *error);

/**
 *  Either touch ID unlocks access to the keychain methods or the password item itself is touch ID protected. 
 *
 *  IMPORTANT: If keychain sharing is enabled for your app, any device using iCloud Keychain and the same Apple ID with touch ID running your app will have access to the same secure keychain item protected here.
 */
typedef NS_ENUM(NSUInteger, RZTouchIDMode){
    /**
     *  Touch ID unlocks access to the keychain but fallback option is configurable
     *  @see RZTouchIDMode for an important caveat regarding keychain sharing
     */
    RZTouchIDModeLocalAuthentication,
    /**
     *  The actual password item is protected by touch ID but the fallback option is passcode
     */
    RZTouchIDModeBiometricKeychain
};

/**
 *  Maps OSSStatus (Security framework) and LAError (LocalAuthentication framework) objects to common response
 *
 *  Inspect the localizedFailureReason for further details on each message
 */
typedef NS_ENUM(NSUInteger, RZTouchIDError){
    /**
     *  Touch ID not available for one of these reasons:
     *
     *  - Passcode not set on device
     *
     *  - Not available for this device
     *
     *  - No fingers enrolled in touch ID
     * 
     */
    RZTouchIDErrorTouchIDNotAvailable,
    /**
     *  The keychain item exists. Typically not returned by RZTouchID public methods since we delete an item if it exists before adding it each time.
     */
    RZTouchIDErrorItemAlreadyExists,
    /**
     *  The requested password wasn't found for the provided identifier
     */
    RZTouchIDErrorItemNotFound,
    /**
     *  User canceled the system prompt to authenticate with Touch ID.
     */
    RZTouchIDErrorUserCanceled,
    /**
     *  Touch ID authentication failure - either user hit the fallback option, system cancelled auth (e.g. another app came to foreground) or the user failed to match their fingerprint or passcode
     */
    RZTouchIDErrorAuthenticationFailed,
    /**
     *  Something else happened - check the localizedFailureReason for further details and refer to OSStatus or LAError for resolution steps.
     */
    RZTouchIDErrorUnknownError
};

/**
 *  The domain for errors returned in RZTouchIDCompletion blocks.
 */
OBJC_EXTERN NSString* const kRZTouchIDErrorDomain;

@interface RZTouchID : NSObject

/**
 *  A unique name representing this login service in the keychain.
 */
@property (copy, nonatomic, readonly) NSString *keychainServicePrefix;

/**
 *  The mode of touch ID you are using e.g. localauth or biometric.
 */
@property (assign, nonatomic, readonly) RZTouchIDMode touchIDMode;

/**
 *  The TouchID protocol conforming delegate called to manage the collection of touch ID enabled users.
 */
@property (weak, nonatomic) id <RZTouchIDDelegate> delegate;

/**
 *  The dispatch queue on which to execute completion blocks. Default is the main queue.
 */
@property (strong, nonatomic) dispatch_queue_t completionQueue;

/**
 *  Whether TouchID is currently available and configured with at least one finger and
 *  a passcode. If this method returns NO, then attempts to retrive passwords from the keychain using TouchID will fail.
 *
 *  @return True if a passcode is set, the device supports touch ID
 */
+ (BOOL)touchIDAvailable;

/**
 *  Whether TouchID is currently available and configured with at least one finger and
 *  a passcode. If this method returns NO, then attempts to retrive passwords from the keychain using TouchID will fail.
 *
 *  @param identifier A string representing an identifier. This could be an email, a UUID or a username.
 *
 *  @return Returns YES if a passcode is set, the device supports touch ID and the identifier provided has a password stored in the keychain.
 */
- (BOOL)touchIDAvailableForIdentifier:(NSString *)identifier;

/**
 *  Return the RZTouchID object initialized with the service name prefix used to create unique keychain keys.
 *
 *  @param servicePrefix A unique name representing this login service in the keychain.
 */
- (instancetype)initWithKeychainServicePrefix:(NSString *)servicePrefix authenticationMode:(RZTouchIDMode)touchIDMode;

/**
 *  Provides a way of changing the title of the fallback option from the default or hiding it altogether.
 *
 *  Only valid for RZTouchIDModeLocalAuthentication
 *  @param localizedFallbackTitle Set to nil to use the default "Enter Password" or the empty string to hide the option.
 */
- (void)setLocalizedFallbackTitle:(NSString *)localizedFallbackTitle;

/**
 *  Store a password in the keychain for this TouchID service with a given identifier. The identifier can be any string used
 *  to identify the password, but might commonly be a username, email, etc.
 *
 *  @param password     The password to store in the keychain.
 *  @param identifier   An identifier associated with the password so it can be referenced later.
 *  @param completion   Called on the completionQueue when the keychain request is complete.
 *
 */
- (void)addPassword:(NSString *)password withIdentifier:(NSString *)identifier completion:(RZTouchIDCompletion)completion;

/**
 *  Query the keychain for the password with the given identifier. If a password exists for this TouchID service with the identifier,
 *  it is returned in the completion block.
 *
 *  @param identifier   The identifier for the password to retreive.
 *  @param prompt       The text to show in the TouchID dialog.
 *  @param completion   Called on the completionQueue when the keychain request is complete.
 */
- (void)retrievePasswordWithIdentifier:(NSString *)identifier withPrompt:(NSString *)prompt completion:(RZTouchIDCompletion)completion;

/**
 *  Deletes the password that was previously added to the TouchID service with the given identifier.
 *  A failed delete typically means there was no password stored for the service.
 *
 *  @param identifier   The identifier used when the password was added.
 *  @param completion   Called on the completionQueue when the keychain request is complete.
 */
- (void)deletePasswordWithIdentifier:(NSString *)identifier completion:(RZTouchIDCompletion)completion;

@end
