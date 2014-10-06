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

@implementation BackgroundHelper

+ (void) checkJobStatusInBackground:(void (^)(UIBackgroundFetchResult))completionHandler{
    if ([[[AGSTask activeResumeIDs] allKeys] count]) {
        //
        // this allow AGSExportTileCacheTask to trigger status checks for any active jobs. If a job is done
        // and a download is available, a download will be kicked off
        [AGSTask checkStatusForAllResumableTaskJobsWithCompletion:completionHandler];
    }
    else {
        //
        // we should call this right away so the OS sees us as a good citizen.
        completionHandler(UIBackgroundFetchResultNoData);
    }

}

+ (void) downloadJobResultInBackgroundWithURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler{
    //
    // this will allow the AGSGDBSyncTask to monitor status of background download and invoke its own
    // completion block when the download is done.
    [[AGSURLSessionManager sharedManager] setBackgroundURLSessionCompletionHandler:completionHandler forIdentifier:identifier];
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
