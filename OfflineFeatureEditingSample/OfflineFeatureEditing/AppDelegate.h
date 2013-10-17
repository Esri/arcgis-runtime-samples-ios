//
//  AppDelegate.h
//  offline-holistic
//
//  Created by Eric Ito on 5/17/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@class OfflineTestViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) OfflineTestViewController *viewController;

-(void)logAppStatus:(NSString*)status;

@end
