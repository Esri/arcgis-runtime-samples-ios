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
#import "ActivityAlertView.h"

@interface ServiceAreaSampleViewController : UIViewController 
<AGSMapViewTouchDelegate, AGSServiceAreaTaskDelegate, UIAlertViewDelegate, AGSMapViewLayerDelegate, AGSFeatureLayerQueryDelegate, AGSInfoTemplateDelegate, AGSMapViewCalloutDelegate> {
    AGSMapView *_mapView;      
    AGSFeatureLayer *_facilitiesLayer;
	AGSGraphicsLayer *_graphicsLayer;
    AGSSketchGraphicsLayer *_sketchLayer;
    AGSGraphic *_selectedGraphic;
	AGSServiceAreaTask *_saTask;
    NSOperation *_saOp;
    SettingsViewController *_settingsViewController;
    ActivityAlertView *_activityAlertView;
    UIView *_barrierCalloutView; 
    UIView *_facitlitiesCalloutView; 
    
    //used to contain the number of barriers on the map at one time. 
    int _numBarriers;
    
    UILabel *_statusMessageLabel;
    UISegmentedControl *_activitySegControl;
    UIBarButtonItem *_addBarrierButton;
    UIBarButtonItem *_clearSketchButton;
}

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSFeatureLayer* facilitiesLayer;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSSketchGraphicsLayer *sketchLayer;
@property (nonatomic, strong) AGSGraphic *selectedGraphic;
@property (nonatomic, strong) AGSServiceAreaTask *saTask;
@property (nonatomic, strong) NSOperation *saOp;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) ActivityAlertView *activityAlertView;
@property (nonatomic, strong) UIView *barrierCalloutView;
@property (nonatomic, strong) UIView *facilitiesCalloutView;

@property (nonatomic, strong) IBOutlet UILabel *statusMessageLabel;
@property (nonatomic, strong) IBOutlet UISegmentedControl *activitySegControl;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *addBarrierButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *clearSketchButton;

- (void)respondToGeomChanged:(NSNotification*)notification;

- (AGSCompositeSymbol*)barrierSymbol;
- (AGSCompositeSymbol*)serviceAreaSymbolBreak1;
- (AGSCompositeSymbol*)serviceAreaSymbolBreak2;

- (IBAction)findServiceArea;
- (IBAction)removeBarrierClicked;
- (IBAction)openSettings:(id)sender;
- (IBAction)clearAll:(id)sender;
- (IBAction)clearSketchLayer:(id)sender;
- (IBAction)activitySegValueChanged:(id)sender;
- (IBAction)addBarier:(id)sender;

@end
