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

@interface OffsetViewController : UIViewController <AGSMapViewLayerDelegate>

@property (nonatomic, strong) IBOutlet UIToolbar *toolbar1;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar2;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) IBOutlet UISlider *distanceSlider;
@property (nonatomic, strong) IBOutlet UISlider *bevelSlider;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *distance;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *bevel;
@property (nonatomic, strong) IBOutlet UISegmentedControl *geometrySelect;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *addButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *offsetButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *resetButton;
@property (nonatomic, strong) IBOutlet UILabel *userInstructions;

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSSketchGraphicsLayer *sketchLayer;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) NSMutableArray *lastOffset;

@property (nonatomic, assign) int offsetDistance;
@property (nonatomic, assign) double bevelRatio;

@property (nonatomic, assign) AGSGeometryOffsetType offsetType;

@end
