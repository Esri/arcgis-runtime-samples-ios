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
#import "RootViewController.h"

@interface CutterViewController : UIViewController <AGSMapViewLayerDelegate>
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *addButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *resetButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *polygonButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *cutButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *drawButton;
@property (nonatomic, strong) IBOutlet UILabel *userInstructions;

@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSSketchGraphicsLayer *sketchLayer;



@end
