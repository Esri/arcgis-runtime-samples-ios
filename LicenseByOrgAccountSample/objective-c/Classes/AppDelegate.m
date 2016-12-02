/*
 Copyright 2014 Esri
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "AppDelegate.h"
#import "ViewController.h"
#import "LicenseHelperConstants.h"

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    // set our portalURL property
    _portalURL = [NSURL URLWithString:kPortalUrl];
    
    // First thing we need to do is set our OAuth config for the portalURL we want to log in to
    //
    AGSOAuthConfiguration *OAuthConfig = [AGSOAuthConfiguration OAuthConfigurationWithPortalURL:_portalURL clientID:kClientID redirectURL:nil];
    OAuthConfig.refreshTokenExpirationInterval = -1; // request a permanent refresh token so user doesn't have to login in
    
    // add our config to the authentication manager's OAuth configurations
    [[AGSAuthenticationManager sharedAuthenticationManager].OAuthConfigurations addObject:OAuthConfig];
    
    
    // Tell the AGSAuthenticationManager to automatically sync credentials from the singleton
    // in-memory credentialCache to the keychain
    //
    [[AGSAuthenticationManager sharedAuthenticationManager].credentialCache enableAutoSyncToKeychainWithIdentifier:kKeyChainKey accessGroup:nil acrossDevices:NO];

}

@end
