/*
 Copyright 2015 Esri
 
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

#define kPortalUrl @"https://www.arcgis.com"
#define kClientID @"pqN3y96tSb1j8ZAY"

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
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
    [[AGSAuthenticationManager sharedAuthenticationManager].credentialCache enableAutoSyncToKeychainWithIdentifier:@"com.esri.OAuthLoginSample" accessGroup:nil acrossDevices:NO];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
