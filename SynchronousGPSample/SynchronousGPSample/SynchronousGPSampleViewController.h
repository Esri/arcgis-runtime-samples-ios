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

@interface SynchronousGPSampleViewController : UIViewController 
<AGSMapViewTouchDelegate, AGSGeoprocessorDelegate, UIAlertViewDelegate, AGSMapViewLayerDelegate> 

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) UIView *graphicsView;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSGeoprocessor *gpTask;
@property (nonatomic, strong) NSOperation *gpOp;

@property (nonatomic, strong) IBOutlet UISlider *vsDistanceSlider;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *vsDistanceLabel;

- (IBAction)vsDistanceSliderChanged:(id)sender;

@end
