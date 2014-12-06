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
#import "BasemapPickerDelegate.h"

@interface BasemapsListViewController : UIViewController <PortalBasemapHelperDelegate, AGSWebMapDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) id <BasemapPickerDelegate> delegate;

@end
