// Copyright 2012 ESRI
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
#import "LegendDataSource.h"

@protocol LegendViewControllerDelegate <NSObject>

- (void)dismissLegend;

@end

@interface LegendViewController : UIViewController 

@property (nonatomic,strong) IBOutlet UITableView* legendTableView;
@property (nonatomic,strong) LegendDataSource* legendDataSource;
@property (nonatomic,strong) UIPopoverController* popOverController;

@property (weak, nonatomic) id <LegendViewControllerDelegate> delegate;

- (IBAction) dismiss;

@end
