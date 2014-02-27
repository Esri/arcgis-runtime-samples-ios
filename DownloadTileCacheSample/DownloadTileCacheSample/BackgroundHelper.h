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
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BackgroundHelper : NSObject

+ (void) checkJobStatusInBackground:(void (^)(UIBackgroundFetchResult))completionHandler;
+ (void) downloadJobResultInBackgroundWithURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;
+ (void) postLocalNotificationIfAppNotActive:(NSString*)message;

@end
