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

@import LocalAuthentication.LAContext;
#import "RZTouchID.h"

@interface RZTouchID ()

@property (copy, nonatomic, readwrite) NSString *keychainServicePrefix;

@end

@implementation RZTouchID

#pragma mark - public methods

+ (BOOL)touchIdAvailable
{
    BOOL available = NO;
    
#if !TARGET_IPHONE_SIMULATOR
    Class contextClass = NSClassFromString(@"LAContext");
    if ( contextClass != nil ) {
        static id context;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            context = [[contextClass alloc] init];
        });
        
        NSError *error;
        //Check each time since canEvaluatePolicy can change within an app session if a user ads or removes fingers
        BOOL biometricsAvailable = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
        available = (error == nil && biometricsAvailable);
    }
#endif
    
    return available;
}

- (instancetype)initWithKeychainServicePrefix:(NSString *)servicePrefix
{
    self = [super init];
    if ( self ) {
        self.keychainServicePrefix = servicePrefix;
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
        NSDictionary *attributes = @{
                                     (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                     (__bridge id)kSecAttrService: [self serviceNameForIdentifier:identifier],
                                     (__bridge id)kSecValueData: [password dataUsingEncoding:NSUTF8StringEncoding],
                                     (__bridge id)kSecUseNoAuthenticationUI: @NO,
                                     (__bridge id)kSecAttrAccessControl: (__bridge id)accessObject
                                     };
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, nil);
            CFRelease(accessObject);
            
            NSError *error = [self errorForOsStatus:status];

            if ( completion != nil ) {
                dispatch_async(self.completionQueue, ^{
                    completion(password, error);
                });
            }
        });
    }];
}

- (void)retrievePasswordWithIdentifier:(NSString *)identifier withPrompt:(NSString *)prompt completion:(RZTouchIDCompletion)completion
{
    if ( [[self class] touchIdAvailable] ) {
        CFErrorRef error = NULL;
        SecAccessControlRef accessObject;
        
        accessObject = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, kSecAccessControlUserPresence, &error);
        
        //Check if password exists
        NSDictionary *query = @{
                                (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrService: [self serviceNameForIdentifier:identifier],
                                (__bridge id)kSecReturnData: @YES,
                                (__bridge id)kSecUseOperationPrompt: prompt,
                                (__bridge id)kSecAttrAccessControl: (__bridge id)accessObject
                                };
        
        
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            CFTypeRef passwordData = NULL;
            
            OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)(query), &passwordData);
            
            NSString *password = [[NSString alloc] initWithData:(__bridge NSData *)passwordData encoding:NSUTF8StringEncoding];
            NSError *error = [self errorForOsStatus:status];
            
            CFRelease(accessObject);
            CFRelease(passwordData);
            
            if ( completion != nil ) {
                dispatch_async(self.completionQueue, ^{
                    completion(password, error);
                });
            }
        });
    }
    else if ( completion != nil )  {
        completion(nil, [self errorForOsStatus:errSecNotAvailable]);
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
        
        NSError *error = [self errorForOsStatus:status];
        
        if ( completion != nil ) {
            dispatch_async(self.completionQueue, ^{
                completion(nil, error);
            });
        }
    });
}

#pragma mark - private methods

- (NSString *)serviceNameForIdentifier:(NSString *)identifier
{
    return [NSString stringWithFormat:@"%@.%lu",self.keychainServicePrefix, (unsigned long)identifier.hash];
}

- (NSError *)errorForOsStatus:(OSStatus)status
{
    if ( status != errSecSuccess ) {
        return [NSError errorWithDomain:@"com.raizlabs.touchID" code:status userInfo:@{ NSLocalizedDescriptionKey : [self keychainErrorToString:status]}];
    }
    else {
        return nil;
    }
}

- (NSString *)keychainErrorToString:(OSStatus)error
{
    NSString *msg = nil;
    
    switch (error) {
        case errSecNotAvailable:
            msg = NSLocalizedString(@"ERROR_KEYCHAIN_UNAVAILABLE", nil);
            break;
            
        case errSecDuplicateItem:
            msg = NSLocalizedString(@"ERROR_ITEM_ALREADY_EXISTS", nil);
            break;
            
        case errSecItemNotFound :
            msg = NSLocalizedString(@"ERROR_ITEM_NOT_FOUND", nil);
            break;
            
        case errSecAuthFailed:
            msg = NSLocalizedString(@"ERROR_ITEM_AUTHENTICATION_FAILED", nil);
            
        default:
            msg = [@(error) stringValue];
            break;
    }
    
    return msg;
}

@end
