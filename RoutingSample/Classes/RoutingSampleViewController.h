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

@interface RoutingSampleViewController : UIViewController< AGSLayerCalloutDelegate, AGSMapViewTouchDelegate, AGSRouteTaskDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) IBOutlet AGSMapView			*mapView;
@property (nonatomic, strong) IBOutlet UISegmentedControl	*sketchModeSegCtrl;
@property (nonatomic, strong) IBOutlet UIView				*directionsBannerView;
@property (nonatomic, strong) IBOutlet UILabel				*directionsLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem		*prevBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem		*nextBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem		*addBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem		*clearSketchBtn;

@property (nonatomic, strong) AGSGraphicsLayer				*graphicsLayer;
@property (nonatomic, strong) AGSSketchGraphicsLayer		*sketchLayer;
@property (nonatomic, strong) AGSRouteTask					*routeTask;
@property (nonatomic, strong) AGSRouteTaskParameters		*routeTaskParams;
@property (nonatomic, strong) AGSStopGraphic				*currentStopGraphic;
@property (nonatomic, strong) AGSGraphic					*selectedGraphic;
@property (nonatomic, strong) AGSDirectionGraphic			*currentDirectionGraphic;
@property (nonatomic, strong) UIView						*stopCalloutView;
@property (nonatomic, strong) AGSRouteResult				*routeResult;

@property (nonatomic, assign) int                             numStops;
@property (nonatomic, assign) int                             numBarriers;
@property (nonatomic, assign) int                             directionIndex;

- (AGSCompositeSymbol*)stopSymbolWithNumber:(NSInteger)stopNumber;
- (AGSCompositeSymbol*)barrierSymbol;
- (AGSCompositeSymbol*)routeSymbol;
- (AGSCompositeSymbol*)currentDirectionSymbol;

- (void)respondToGeomChanged: (NSNotification*) notification ;
- (IBAction)addStopOrBarrier:(id)sender;
- (IBAction)resetBtnClicked:(id)sender;
- (IBAction)stopsBarriersValChanged:(id)sender;
- (IBAction)routeBtnClicked:(id)sender;
- (IBAction)clearSketchLayer:(id)sender;
- (IBAction)nextBtnClicked:(id)sender;
- (IBAction)prevBtnClicked:(id)sender;

- (void)reset;
- (void)removeStopClicked;
- (void)updateDirectionsLabel:(NSString*)newLabel;




@end

	