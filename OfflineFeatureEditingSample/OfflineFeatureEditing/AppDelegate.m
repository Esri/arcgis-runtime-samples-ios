//
//  AppDelegate.m
//  offline-holistic
//
//  Created by Eric Ito on 5/17/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "AppDelegate.h"

#import "OfflineTestViewController.h"

@interface AppDelegate(){
    NSString *_logPath;
}

@end

@implementation AppDelegate

- (void)registerDefaultsFromSettingsBundle {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = settings[@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = prefSpecification[@"Key"];
        if(key) {
            defaultsToRegister[key] = prefSpecification[@"DefaultValue"];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

-(void)logAppStatus:(NSString *)status{
    if (!_logPath.length){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths objectAtIndex:0];
        _logPath = [path stringByAppendingPathComponent:@"appLog.txt"];
    }

    NSFileHandle *logFileHandle = [NSFileHandle fileHandleForWritingAtPath:_logPath];
    if (logFileHandle){
        [logFileHandle seekToEndOfFile];
        [logFileHandle writeData:[status dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else{
        // have to create the file...
        [status writeToFile:_logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    [self registerDefaultsFromSettingsBundle];
//    
//    NSString *urlstring = [[NSUserDefaults standardUserDefaults] stringForKey:@"URL"];
//    NSLog(@"fsURL: %@", urlstring);
//    NSURL *fsURL = [NSURL URLWithString:urlstring];
//    
//    NSString *tpkurlstring = [[NSUserDefaults standardUserDefaults] stringForKey:@"TPKURL"];
//    NSLog(@"tpkURL: %@", tpkurlstring);
//    NSURL *tpkURL = [NSURL URLWithString:tpkurlstring];
//    
//    [self logAppStatus:@"===================================================\n"];
//    
//    NSDateFormatter *df = [[NSDateFormatter alloc]init];
//    df.dateStyle = NSDateFormatterShortStyle;
//    df.timeStyle = NSDateFormatterMediumStyle;
//    NSString *status = [NSString stringWithFormat:@"%@ - %@, %@\n", [df stringFromDate:[NSDate date]], @"app launched", urlstring];
//    [self logAppStatus:status];
//    
//    [self logAppStatus:@"===================================================\n\n"];
//    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    NSURL* fsURL = nil;
    NSURL* tpkURL = nil;
    
    self.viewController = [[OfflineTestViewController alloc] initWithFSURL:fsURL TPKURL:tpkURL];

    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
//    [self logAppStatus:@"---------------------------------------------------\n"];
//    
//    NSDateFormatter *df = [[NSDateFormatter alloc]init];
//    df.dateStyle = NSDateFormatterShortStyle;
//    df.timeStyle = NSDateFormatterMediumStyle;
//    NSString *status = [NSString stringWithFormat:@"%@ - %@\n", [df stringFromDate:[NSDate date]], @"app entering background"];
//    [self logAppStatus:status];
//    
//    [self logAppStatus:@"---------------------------------------------------\n\n"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
//    [self logAppStatus:@"---------------------------------------------------\n"];
//    
//    NSDateFormatter *df = [[NSDateFormatter alloc]init];
//    df.dateStyle = NSDateFormatterShortStyle;
//    df.timeStyle = NSDateFormatterMediumStyle;
//    NSString *status = [NSString stringWithFormat:@"%@ - %@\n", [df stringFromDate:[NSDate date]], @"app entering foreground"];
//    [self logAppStatus:status];
//    
//    [self logAppStatus:@"---------------------------------------------------\n\n"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
}

@end
