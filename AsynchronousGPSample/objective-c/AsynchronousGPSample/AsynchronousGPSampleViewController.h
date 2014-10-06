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
#import "SettingsViewController.h"

#define kDefaultMap @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
#define kGPTask @"http://sampleserver2.arcgisonline.com/ArcGIS/rest/services/PublicSafety/EMModels/GPServer/ERGByChemical"

@interface AsynchronousGPSampleViewController : UIViewController 
<AGSMapViewTouchDelegate, AGSGeoprocessorDelegate, UIAlertViewDelegate, AGSMapViewLayerDelegate> 

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSGeoprocessor *gpTask;

@property (nonatomic, strong) IBOutlet UISlider *wdDegreeSlider;
@property (nonatomic, strong) IBOutlet UILabel *wdDegreeLabel;
@property (nonatomic, strong) IBOutlet UILabel *statusMsgLabel;

- (IBAction)degreeSliderChanged:(id)sender;

@end