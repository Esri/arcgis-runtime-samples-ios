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
#import <ArcGIS/ArcGIS.h>

//this class representas the table view that will display all the attributes from a callout window 
@interface FeatureDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *detailsTable;

@property (nonatomic, strong) AGSGraphic *feature;
@property (nonatomic, copy) NSString *displayFieldName;

- (void)setFieldAliases:(NSDictionary *)fa;

@end
