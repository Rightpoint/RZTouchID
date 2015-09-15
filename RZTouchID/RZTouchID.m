//
//  RZTouchID.m
//
//  Created by Rob Visentin on 1/7/15.

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

@import LocalAuthentication;
#import "RZTouchID.h"

NSString* const kRZTouchIDErrorDomain = @"com.raizlabs.touchID";

@interface RZTouchID ()

@property (copy, nonatomic, readwrite) NSString *keychainServicePrefix;
@property (assign, nonatomic) RZTouchIDMode touchIDMode;
@property (copy, nonatomic) NSString *localizedFallbackTitle;

@end

@implementation RZTouchID

#pragma mark - public methods

+ (BOOL)touchIDAvailable
{
    BOOL available = NO;
    
#if !TARGET_IPHONE_SIMULATOR
    Class contextClass = [LAContext class];
    if ( contextClass != nil ) {
        //User a new context for each check otherwise you may get a cached response.
        id context = [contextClass new];
        
        NSError *error;
        //Check each time since canEvaluatePolicy can change within an app session if a user ads or removes fingers
        BOOL biometricsAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
        available = (error == nil && biometricsAvailable);
    }
#endif
    
    return available;
}

- (BOOL)touchIDAvailableForIdentifier:(NSString *)identifier
{
    return (identifier != nil && identifier.length > 0 && [self.class touchIDAvailable] && (![self.delegate respondsToSelector:@selector(touchID:shouldAddPasswordForIdentifier:)] || [self.delegate touchID:self shouldAddPasswordForIdentifier:identifier]));
}

- (instancetype)initWithKeychainServicePrefix:(NSString *)servicePrefix authenticationMode:(RZTouchIDMode)touchIDMode
{
    self = [super init];
    if ( self ) {
        self.keychainServicePrefix = servicePrefix;
        self.completionQueue = dispatch_get_main_queue();
        self.touchIDMode = touchIDMode;
    }
    return self;
}

- (void)addPassword:(NSString *)password withIdentifier:(NSString *)identifier completion:(RZTouchIDCompletion)completion
{
    //Delete the old password first if one exists
    [self deletePasswordWithIdentifier:identifier completion:^(NSString *pword, NSError *error) {
        CFErrorRef addError = NULL;
        SecAccessControlRef accessObject;
        
        accessObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, &addError);
        
        if( accessObject == NULL || addError != NULL)
        {
            if ( completion != nil ) {
                dispatch_async(self.completionQueue, ^{
                    completion(nil, (__bridge NSError *)addError);
                });
            }
            return;
        }
        
        // we want the operation to fail if there is an item which needs authentication so we will use
        // kSecUseNoAuthenticationUI
        NSMutableDictionary *attributes = [@{
                         (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                         (__bridge id)kSecAttrService: [self serviceNameForIdentifier:identifier],
                         (__bridge id)kSecValueData: [password dataUsingEncoding:NSUTF8StringEncoding],
                         (__bridge id)kSecUseNoAuthenticationUI: @NO
                         } mutableCopy];

        if ( self.touchIDMode == RZTouchIDModeBiometricKeychain ) {
            [attributes setObject:(__bridge id)accessObject forKey:(__bridge id)kSecAttrAccessControl];
        }
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
            CFRelease(accessObject);
            
            NSError *error = [self errorForSecStatus:status];

            if ( completion != nil ) {
                dispatch_async(self.completionQueue, ^{
                    if ( error == nil && [self.delegate respondsToSelector:@selector(touchID:didAddPasswordForIdentifier:)] ) {
                        [self.delegate touchID:self didAddPasswordForIdentifier:identifier];
                    }
                    completion(password, error);
                });
            }
        });
    }];
}

- (void)retrievePasswordWithIdentifier:(NSString *)identifier withPrompt:(NSString *)prompt completion:(RZTouchIDCompletion)completion
{
    if ( [self touchIDAvailableForIdentifier:identifier] ) {
        if ( self.touchIDMode ==  RZTouchIDModeLocalAuthentication ) {
            //New context each time to avoid cached responses
            LAContext *laContext = [LAContext new];
            laContext.localizedFallbackTitle = self.localizedFallbackTitle;
            __weak __typeof(self)wself = self;
            [laContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:prompt reply:^(BOOL success, NSError *error) {
                if ( error == nil ) {
                    [wself queryPasswordWithIdentifier:identifier withPrompt:prompt completion:completion];
                }
                else if ( completion != nil ) {
                    completion(nil,[self errorForLAStatus:error]);
                }
            }];
            
        }
        else {
            [self queryPasswordWithIdentifier:identifier withPrompt:prompt completion:completion];
        }
    }
    else if ( completion != nil )  {
        completion(nil, [self errorForSecStatus:errSecNotAvailable]);
    }
}

- (void)deletePasswordWithIdentifier:(NSString *)identifier completion:(RZTouchIDCompletion)completion
{
    NSDictionary *query = @{
                            (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                            (__bridge id)kSecAttrService: [self serviceNameForIdentifier:identifier]
                            };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)(query));
        
        NSError *error = [self errorForSecStatus:status];

        if ( completion != nil ) {
            dispatch_async(self.completionQueue, ^{
                // If we don't find the item in the keychain, it has the same net result as success
                if ( (error == nil || error.code == RZTouchIDErrorItemNotFound) && [self.delegate respondsToSelector:@selector(touchID:didDeletePasswordForIdentifier:)] ) {
                    [self.delegate touchID:self didDeletePasswordForIdentifier:identifier];
                }
                completion(nil, error);
            });
        }
    });
}

#pragma mark - private methods

- (void)queryPasswordWithIdentifier:(NSString *)identifier withPrompt:(NSString *)prompt completion:(RZTouchIDCompletion)completion
{
    CFErrorRef error = NULL;
    SecAccessControlRef accessObject;
    
    accessObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, &error);
    
    //Check if password exists
    NSMutableDictionary *query = [@{
                                         (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                         (__bridge id)kSecAttrService: [self serviceNameForIdentifier:identifier],
                                         (__bridge id)kSecReturnData: @YES,
                                         (__bridge id)kSecUseOperationPrompt: prompt
                                         } mutableCopy];
    
    if ( self.touchIDMode == RZTouchIDModeBiometricKeychain ) {
        [query setObject:(__bridge id)accessObject forKey:(__bridge id)kSecAttrAccessControl];
    }
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        CFTypeRef passwordData = NULL;
        
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &passwordData);
        
        NSString *password = [[NSString alloc] initWithData:(__bridge NSData *)passwordData encoding:NSUTF8StringEncoding];
        NSError *error = [self errorForSecStatus:status];

        CFRelease(accessObject);
        if ( passwordData != NULL ) {
            CFRelease(passwordData);
        }
        
        if ( completion != nil ) {
            dispatch_async(self.completionQueue, ^{
                completion(password, error);
            });
        }
    });
}

- (NSString *)serviceNameForIdentifier:(NSString *)identifier
{
    return [NSString stringWithFormat:@"%@.%lu",self.keychainServicePrefix, (unsigned long)identifier.hash];
}

- (NSError *)errorForLAStatus:(NSError *)error
{
    RZTouchIDError rzTouchIDError;
    NSString *msg = nil;
    switch ((LAError)error.code) {
        case kLAErrorAuthenticationFailed:
        case kLAErrorUserCancel:
        case kLAErrorUserFallback:
        case kLAErrorSystemCancel: {
            msg = NSLocalizedString(@"ERROR_ITEM_AUTHENTICATION_FAILED", nil);
            rzTouchIDError = RZTouchIDErrorAuthenticationFailed;
            break;
        }
        case kLAErrorPasscodeNotSet:
        case kLAErrorTouchIDNotAvailable:
        case kLAErrorTouchIDNotEnrolled: {
            msg = NSLocalizedString(@"ERROR_KEYCHAIN_UNAVAILABLE", nil);
            rzTouchIDError = RZTouchIDErrorTouchIDNotAvailable;
            break;
        }
        default: {
            msg = NSLocalizedString(@"UNKNOWN_ERROR", nil);
            rzTouchIDError = RZTouchIDErrorUnknownError;
            break;
        }
    }
    if ( msg != nil ) {
        return [NSError errorWithDomain:kRZTouchIDErrorDomain code:rzTouchIDError userInfo:@{ NSLocalizedDescriptionKey : msg,
                                                                                     NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:@"LAError:%ld, %@",(long)error.code,error.localizedFailureReason]}];
    }
    else {
        return nil;
    }
}

- (NSError *)errorForSecStatus:(OSStatus)error
{
    if ( error != errSecSuccess ) {
        NSString *msg = nil;
        RZTouchIDError rzTouchIDError;

        switch (error) {
            case errSecNotAvailable: {
                msg = NSLocalizedString(@"ERROR_KEYCHAIN_UNAVAILABLE", nil);
                rzTouchIDError = RZTouchIDErrorTouchIDNotAvailable;
                break;
            }
            case errSecDuplicateItem: {
                msg = NSLocalizedString(@"ERROR_ITEM_ALREADY_EXISTS", nil);
                rzTouchIDError = RZTouchIDErrorItemAlreadyExists;
                break;
            }
            case errSecItemNotFound: {
                msg = NSLocalizedString(@"ERROR_ITEM_NOT_FOUND", nil);
                rzTouchIDError = RZTouchIDErrorItemNotFound;
                break;
            }
            case errSecUserCanceled: {
                msg = NSLocalizedString(@"ERROR_USER_CANCELED", nil);
                rzTouchIDError = RZTouchIDErrorUserCanceled;
                break;
            }
            case errSecAuthFailed: {
                msg = NSLocalizedString(@"ERROR_ITEM_AUTHENTICATION_FAILED", nil);
                rzTouchIDError = RZTouchIDErrorAuthenticationFailed;
            }
            default: {
                msg = [@(error) stringValue];
                rzTouchIDError = RZTouchIDErrorUnknownError;
                break;
            }
        }
        return [NSError errorWithDomain:kRZTouchIDErrorDomain code:rzTouchIDError userInfo:@{ NSLocalizedDescriptionKey : msg}];
    }
    return nil;
}

@end
