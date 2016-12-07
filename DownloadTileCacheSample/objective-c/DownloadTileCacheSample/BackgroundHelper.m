// Copyright 2014 ESRI
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

#import "BackgroundHelper.h"
#import <ArcGIS/ArcGIS.h>
#import "AppDelegate.h"

@implementation BackgroundHelper

+ (void) checkJobStatusInBackground:(void (^)(UIBackgroundFetchResult))completionHandler{
    
    AGSJob *job = ((AppDelegate *)[UIApplication sharedApplication].delegate).currentJob;
    if (job) {
        [job checkStatusWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                completionHandler(UIBackgroundFetchResultFailed);
            }
            else if (job.status == AGSJobStatusFailed || job.status == AGSJobStatusSucceeded) {
                completionHandler(UIBackgroundFetchResultNewData);
            }
            else {
                completionHandler(UIBackgroundFetchResultNoData);
            }
        }];
    }
    else {
        //
        // we should call this right away so the OS sees us as a good citizen.
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

+ (void) downloadJobResultInBackgroundWithURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler{
    //
    // this will allow the AGSApplicationDelegate to monitor status of background download and invoke the AGSExportTileCacheTask
    // completion block when the download is done.
    [[AGSApplicationDelegate sharedApplicationDelegate] application:[UIApplication sharedApplication] handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}

+ (void) postLocalNotificationIfAppNotActive:(NSString*)message{
    //Only post notification if app not active
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state != UIApplicationStateActive)
    {
        UILocalNotification* localNotification = [[UILocalNotification alloc] init];
        localNotification.alertBody = message;
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        
    }

}



@end
