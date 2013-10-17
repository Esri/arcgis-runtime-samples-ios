//
//  OfflineStatus.m
//  offline-holistic
//
//  Created by Ryan Olson on 5/20/13.
//  Copyright (c) 2013 Esri. All rights reserved.
//

#import "ConnectionManager.h"

NSString *const ConnectionManagerChangedNotification = @"ConnectionManagerChangedNotification";

@interface ConnectionManager (){
}
@property (nonatomic, assign, readwrite) ConnectionMode currentMode;
@property (nonatomic, assign, readwrite) ConnectionMode transitionMode;
@end


@implementation ConnectionManager

//-(void)startTransitionToConnectionMode:(ConnectionMode)connectionMode{
//    self.transitionMode = connectionMode;
//}
//
//-(void)transitionComplete:(ConnectionMode)connectionMode{
//    self.currentMode = connectionMode;
//}

-(void)setCurrentMode:(ConnectionMode)currentMode{
    _currentMode = currentMode;
    _transitionMode = ConnectionModeNone;
    [[NSNotificationCenter defaultCenter]postNotificationName:ConnectionManagerChangedNotification object:self userInfo:nil];
}

-(void)setTransitionMode:(ConnectionMode)transitionMode{
    _transitionMode = transitionMode;
    [[NSNotificationCenter defaultCenter]postNotificationName:ConnectionManagerChangedNotification object:self userInfo:nil];
}

-(BOOL)isGoingOffline{
    return self.transitionMode == ConnectionModeOffline;
}

-(BOOL)isGoingOnline{
    return self.transitionMode == ConnectionModeOnline;
}

-(BOOL)isOffline{
    return self.currentMode == ConnectionModeOffline || self.currentMode == ConnectionModeFailedOffline;
}

-(BOOL)isOnline{
    return self.currentMode == ConnectionModeOnline || self.currentMode == ConnectionModeFailedOnline;
}

-(void)startGoingOffline{
    self.transitionMode = ConnectionModeOffline;
}
-(void)successfullyWentOffline{
    self.currentMode = ConnectionModeOffline;
}
-(void)failedToGoOffline{
    self.currentMode = ConnectionModeFailedOffline;
}

-(void)startGoingOnline{
    self.transitionMode = ConnectionModeOnline;
}
-(void)successfullyWentOnline{
    self.currentMode = ConnectionModeOnline;
}
-(void)failedToGoOnline{
    self.currentMode = ConnectionModeFailedOnline;
}

@end
