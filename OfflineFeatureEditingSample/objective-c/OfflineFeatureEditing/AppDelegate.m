// Copyright 2013 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import "AppDelegate.h"

#import "MainViewController.h"
#import "BackgroundHelper.h"

@interface AppDelegate()

@property (nonatomic, strong) NSString *logPath;

@end

@implementation AppDelegate

-(void)logAppStatus:(NSString *)status{
    //If we don't already have a log file, let's set one up
    if (!self.logPath.length){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths objectAtIndex:0];
        self.logPath = [path stringByAppendingPathComponent:@"appLog.txt"];
    }

    //Write to the file
    NSFileHandle *logFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logPath];
    if (logFileHandle){
        [logFileHandle seekToEndOfFile];
        [logFileHandle writeData:[status dataUsingEncoding:NSUTF8StringEncoding]];
    }
    else{
        // have to create the file...
        [status writeToFile:self.logPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

//This will get called periodically by the system when the app is background'ed if
//the app declares it supports "Background Fetch" capability in XCode project settings
- (void) application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    [BackgroundHelper checkJobStatusInBackground:completionHandler];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    [BackgroundHelper downloadJobResultInBackgroundWithURLSession:identifier completionHandler:completionHandler];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    //request permission for local notifications in iOS 8
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
#endif
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
    

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

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
