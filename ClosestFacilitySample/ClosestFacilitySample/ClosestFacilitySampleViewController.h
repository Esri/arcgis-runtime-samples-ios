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

@interface ClosestFacilitySampleViewController : UIViewController 
<AGSMapViewTouchDelegate, AGSClosestFacilityTaskDelegate, UIAlertViewDelegate, AGSMapViewLayerDelegate, AGSFeatureLayerQueryDelegate, AGSCalloutDelegate> {
    AGSMapView *_mapView;   
    AGSFeatureLayer *_facilitiesLayer;
    AGSSketchGraphicsLayer *_sketchLayer;
    AGSGraphic *_selectedGraphic;
	AGSGraphicsLayer *_graphicsLayer;
	AGSClosestFacilityTask *_cfTask;
    NSOperation *_cfOp;
    SettingsViewController *_settingsViewController;
    ActivityAlertView *_activityAlertView;
    
    int	_numIncidents;
	int	_numBarriers;
    
    UILabel *_statusMessageLabel;
    UIView	*_deleteCalloutView; 
    UISegmentedControl *_sketchModeSegCtrl;
    UIBarButtonItem	*_addButton;
    UIBarButtonItem	*_clearSketchButton;
    UIBarButtonItem *_findCFButton;
}

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSFeatureLayer* facilitiesLayer;
@property (nonatomic, strong) AGSSketchGraphicsLayer *sketchLayer;
@property (nonatomic, strong) AGSGraphic *selectedGraphic;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSClosestFacilityTask *cfTask;
@property (nonatomic, strong) NSOperation *cfOp;
@property (nonatomic, strong) SettingsViewController *settingsViewController;
@property (nonatomic, strong) ActivityAlertView *activityAlertView;

@property (nonatomic, strong) IBOutlet UILabel *statusMessageLabel;
@property (nonatomic, strong) UIView	*deleteCalloutView; 
@property (nonatomic, strong) IBOutlet UISegmentedControl *sketchModeSegCtrl;
@property (nonatomic, strong) IBOutlet UIBarButtonItem	*addButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem	*clearSketchButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *findCFButton;


- (IBAction)openSettings:(id)sender;
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
