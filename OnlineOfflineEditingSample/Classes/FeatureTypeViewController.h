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

@interface FeatureTypeViewController : UITableViewController {
	AGSFeatureLayer *_featureLayer;
	AGSGraphic *_feature;
    
    id  _completedDelegate;
}

@property (nonatomic, retain) AGSFeatureLayer *featureLayer;
@property (nonatomic, retain) AGSGraphic *feature;
@property (nonatomic, assign) id completedDelegate;

@end
