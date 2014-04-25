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

#import <UIKit/UIKit.h>
#import "PortalBasemapHelper.h"

@protocol BasemapsListViewControllerDelegate;

@interface BasemapsListViewController : UIViewController <PortalBasemapHelperDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) id <BasemapsListViewControllerDelegate> delegate;

@end

@protocol BasemapsListViewControllerDelegate

-(void)basemapsListViewController:(BasemapsListViewController*)controller didSelectMapWithItemId:(NSString*)itemId credential:(AGSCredential*)credential;
-(void)basemapsListViewControllerDidCancel:(BasemapsListViewController*)controller;

@end
