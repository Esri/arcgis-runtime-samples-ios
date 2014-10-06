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

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>


@interface MainViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *mapContainer;
@property (weak, nonatomic) IBOutlet UILabel *logsLabel;
@property (strong, nonatomic) IBOutlet UIView *leftContainer;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addFeatureButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteGDBButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *syncButton;
@property (strong, nonatomic) IBOutlet UILabel *offlineStatusLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *goOfflineButton;


- (IBAction)deleteGDBAction:(id)sender;
- (IBAction)addFeatureAction:(id)sender;
- (IBAction)syncAction:(id)sender;
- (IBAction)switchModeAction:(id)sender;

@end
