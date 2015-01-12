# RZTouchID

[![Version](https://img.shields.io/cocoapods/v/RZTouchID.svg?style=flat)](http://cocoadocs.org/docsets/RZTouchID)

## Overview
Touch ID is a fingerprint recognition feature available on the iPhone 5S, the iPhone 6/6+, and newest iPad models. It allows a user to unlock a device or make a payment using a fingerprint for authentication. Because Touch ID is primarily an authentication mechanism, it is also great for verifying user identity in lieu of a username and password combination in your application. Fingerprints are stored in the device's [Secure Enclave](http://support.apple.com/en-us/HT5949), so Touch ID allows users to fly through the login screen while still maintaining a high level of security.

![RZTouchID in action](https://github.com/Raizlabs/RZTouchID/blob/master/rztouchid.gif "RZTouchID Demo Project")

## Installation
Install using [CocoaPods](http://cocoapods.org) (recommended) by adding the following line to your Podfile:

`pod "RZTouchID"`

## Demo Project
An example project is available in the Example directory. You can quickly check it out with

`pod try RZTouchID`

Or download the zip from github and run it manually.

## Usage
Check that Touch ID is available on the device and that there are currently registered fingerprints:

`+ (BOOL)touchIDAvailable;`

Create a new Touch ID service with a unique keychain prefix:

`- (instancetype)initWithKeychainServicePrefix:(NSString *)servicePrefix;`

Add a password to the keychain:
``` obj-c
// Store a password in the keychain for this TouchID service with an identifier. 
// The identifier can be any string used to identify the password, 
// but might commonly be a username, email, etc.
- (void)addPassword:(NSString *)password 
     withIdentifier:(NSString *)identifier 
         completion:(RZTouchIDCompletion)completion;
```

Retrieve a password using Touch ID:
``` obj-c 
// Presents the Touch ID authentication prompt and upon successful authentication
// queries the keychain for the password with the given identifier. 
// If a password exists for this Touch ID service with the identifier,
// it is returned in the completion block.
- (void)retrievePasswordWithIdentifier:(NSString *)identifier
                            withPrompt:(NSString *)prompt
                            completion:(RZTouchIDCompletion)completion;
```

Delete a password from the keychain:
``` obj-c
// Deletes the password that was previously added to the Touch ID service.
// A failed delete typically means there was no password stored for the service.
- (void)deletePasswordWithIdentifier:(NSString *)identifier
                          completion:(RZTouchIDCompletion)completion;
```

## Author
Adam Howitt, adam.howitt@raizlabs.com, [@earnshavian](https://twitter.com/earnshavian)

## License
RZTouchID is available under the MIT license. See the LICENSE file for more info.
