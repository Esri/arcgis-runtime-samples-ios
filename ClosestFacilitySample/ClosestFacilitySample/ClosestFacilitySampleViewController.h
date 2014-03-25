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
#import "SVProgressHUD.h"

@interface ClosestFacilitySampleViewController : UIViewController
<AGSMapViewTouchDelegate, AGSClosestFacilityTaskDelegate, UIAlertViewDelegate, AGSMapViewLayerDelegate, AGSFeatureLayerQueryDelegate, AGSCalloutDelegate>

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSFeatureLayer* facilitiesLayer;
@property (nonatomic, strong) AGSSketchGraphicsLayer *sketchLayer;
@property (nonatomic, strong) AGSGraphic *selectedGraphic;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSClosestFacilityTask *cfTask;
@property (nonatomic, strong) NSOperation *cfOp;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, assign) int numIncidents;
@property (nonatomic, assign) int numBarriers;

@property (nonatomic, strong) IBOutlet UILabel *statusMessageLabel;
@property (nonatomic, strong) UIView	*deleteCalloutView; 
@property (nonatomic, strong) IBOutlet UISegmentedControl *sketchModeSegCtrl;
@property (nonatomic, strong) IBOutlet UIBarButtonItem	*addButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem	*clearSketchButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *findCFButton;


- (void)respondToGeomChanged:(NSNotification*) notification ;
- (IBAction)addIncidentOrBarrier:(id)sender;
- (IBAction)resetButttonClicked:(id)sender;
- (IBAction)incidentsBarriersValChanged:(id)sender;
- (IBAction)findCFButtonClicked:(id)sender;
- (IBAction)clearSketchLayer:(id)sender;

- (void)reset;
- (void)removeIncidentBarrierClicked;


- (AGSCompositeSymbol*)incidentSymbol;
- (AGSCompositeSymbol*)barrierSymbol;
- (AGSCompositeSymbol*)routeSymbol;

@end
