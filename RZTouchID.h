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

/**
 *  Generic completion block type for returning an error if a method with this completion
 *  block fails.
 *
 *  @param password The password that was added or retrieved, or nil if there was an error. Will also be nil for delete requests.
 *  @param error    Returns NSError for the completion block to handle or nil
 */
typedef void (^RZTouchIDCompletion)(NSString *password, NSError *error);

@interface RZTouchID : NSObject

/**
 *  A unique name representing this login service in the keychain.
 */
@property (copy, nonatomic, readonly) NSString *keychainServicePrefix;

/**
 *  The dispatch queue on which to execute completion blocks. Default is the main queue.
 */
@property (strong, nonatomic) dispatch_queue_t completionQueue;

/**
 *  Whether TouchID is currently available and configured with at least one finger and
 *  a passcode. If this method returns NO, then attempts to retrive passwords from the keychain using TouchID will fail.
 */
+ (BOOL)touchIdAvailable;

/**
 *  Return the RZTouchID object initialized with the service name prefix used to create unique keychain keys.
 *
 *  @param servicePrefix A unique name representing this login service in the keychain.
 */
- (instancetype)initWithKeychainServicePrefix:(NSString *)servicePrefix;

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
