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

//Implement call out and geo view touch delegates 
@interface GraphicsSampleViewController : UIViewController <AGSCalloutDelegate,AGSGeoViewTouchDelegate>

@property (nonatomic, strong) AGSMap *map;
@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSGraphicsOverlay *countyGraphicsLayer;
@property (nonatomic, strong) AGSGraphicsOverlay *cityGraphicsLayer;
@property (nonatomic, strong) AGSServiceFeatureTable *countyTable;
@property (nonatomic, strong) AGSServiceFeatureTable *cityTable;

- (IBAction)toggleGraphicsLayer:(id)sender;

@end
