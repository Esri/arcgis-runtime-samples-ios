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

@interface RoutingSampleViewController : UIViewController<AGSMapViewLayerDelegate, AGSMapViewTouchDelegate, AGSRouteTaskDelegate, UIAlertViewDelegate, AGSMapViewTouchDelegate> {
	
}

@property (nonatomic, strong) IBOutlet AGSMapView			*mapView;
@property (nonatomic, strong) IBOutlet UIView				*directionsBannerView;
@property (nonatomic, strong) IBOutlet UILabel				*directionsLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem		*prevBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem		*nextBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem		*addBtn;

@property (nonatomic, strong) AGSGraphicsLayer				*graphicsLayerStops;
@property (nonatomic, strong) AGSGraphicsLayer              *graphicsLayerRoute;
@property (nonatomic, strong) AGSRouteTask					*routeTask;
@property (nonatomic, strong) AGSRouteTaskParameters		*routeTaskParams;
@property (nonatomic, strong) AGSStopGraphic				*currentStopGraphic;
@property (nonatomic, strong) AGSGraphic					*selectedGraphic;
@property (nonatomic, strong) AGSDirectionGraphic			*currentDirectionGraphic;
@property (nonatomic, strong) AGSRouteResult				*routeResult;
@property (nonatomic, strong) AGSNetworkDescription        *networkDesc;


- (AGSCompositeSymbol*)stopSymbolWithNumber:(NSInteger)stopNumber;
- (AGSCompositeSymbol*)routeSymbol;
- (AGSCompositeSymbol*)currentDirectionSymbol;
- (void)reset;
- (void)updateDirectionsLabel:(NSString*)newLabel;

- (IBAction)resetBtnClicked:(id)sender;
- (IBAction)nextBtnClicked:(id)sender;
- (IBAction)prevBtnClicked:(id)sender;
- (IBAction)routePreferenceChanged:(UISegmentedControl *)sender;
- (IBAction)reorderStops:(UIBarButtonItem *)sender ;





@end

	