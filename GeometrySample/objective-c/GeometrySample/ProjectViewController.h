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

@interface ProjectViewController : UIViewController <AGSMapViewLayerDelegate>
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UISegmentedControl *geometrySelect;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *projectButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *resetButton;
@property (nonatomic, strong) IBOutlet UILabel *userInstructions;
@property (nonatomic, strong) IBOutlet AGSMapView *mapView1;
@property (nonatomic, strong) IBOutlet AGSMapView *mapView2;
@property (nonatomic, strong) IBOutlet AGSMapView *mapView3;
@property (nonatomic, strong) AGSSketchGraphicsLayer *sketchLayer;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer1;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer2;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer3;


@end
