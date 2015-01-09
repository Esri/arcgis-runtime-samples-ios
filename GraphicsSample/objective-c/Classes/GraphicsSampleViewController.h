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

@class CountyInfoTemplate;

//map view and query task delegates to get at behavior for map and query task
@interface GraphicsSampleViewController : UIViewController <AGSMapViewLayerDelegate, AGSQueryTaskDelegate, AGSCalloutDelegate> 

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;

@property (nonatomic, strong) AGSGraphicsLayer *countyGraphicsLayer;
@property (nonatomic, strong) AGSQueryTask *countyQueryTask;
@property (nonatomic, strong) CountyInfoTemplate *countyInfoTemplate;

@property (nonatomic, strong) AGSGraphicsLayer *cityGraphicsLayer;
@property (nonatomic, strong) AGSQueryTask *cityQueryTask;

- (IBAction)toggleGraphicsLayer:(id)sender;

@end
