//
//  OfflineStatus.h
//  offline-holistic
//
//  Created by Ryan Olson on 5/20/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ConnectionModeNone = 0,
    ConnectionModeOffline,
    ConnectionModeOnline,
    ConnectionModeFailedOffline,
    ConnectionModeFailedOnline
} ConnectionMode;

UIKIT_EXTERN NSString *const ConnectionManagerChangedNotification;

@interface ConnectionManager : NSObject

@property (nonatomic, assign, readonly) ConnectionMode currentMode;
@property (nonatomic, assign, readonly) ConnectionMode transitionMode;

@property (nonatomic, strong, readwrite) id offlineObject;
@property (nonatomic, strong, readwrite) id onlineObject;

@property (nonatomic, assign, readonly) BOOL isGoingOffline;
@property (nonatomic, assign, readonly) BOOL isGoingOnline;

@property (nonatomic, assign, readonly) BOOL isOffline;
@property (nonatomic, assign, readonly) BOOL isOnline;

-(void)startGoingOffline;
-(void)successfullyWentOffline;
-(void)failedToGoOffline;

-(void)startGoingOnline;
-(void)successfullyWentOnline;
-(void)failedToGoOnline;

@end
