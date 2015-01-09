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

@interface DensifyViewController : UIViewController <AGSMapViewLayerDelegate>

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *geometryControl;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *resetButton;
@property (nonatomic, strong) IBOutlet UISlider *slider;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *distance;
@property (nonatomic, strong) AGSGraphicsLayer *resultGraphicsLayer;
@property (nonatomic, strong) AGSSketchGraphicsLayer *sketchLayer;
@property (nonatomic, strong) IBOutlet UILabel *userInstructions;
@property (nonatomic, strong) NSMutableArray *sketchGeometries;
@property (nonatomic, assign) int densifyDistance;

@end
