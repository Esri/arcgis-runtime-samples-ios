// Copyright 2013 ESRI
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

@interface RoutingSampleViewController : UIViewController<AGSMapViewLayerDelegate, AGSMapViewTouchDelegate, AGSRouteTaskDelegate>

@property (nonatomic, strong) IBOutlet AGSMapView			*mapView;
@property (nonatomic, strong) IBOutlet UIView				*directionsBannerView;
@property (nonatomic, strong) IBOutlet UILabel				*directionsLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem		*prevBtn;
@property (nonatomic, strong) IBOutlet UIBarButtonItem		*nextBtn;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *reorderBtn;


- (IBAction)resetBtnClicked:(id)sender;
- (IBAction)nextBtnClicked:(id)sender;
- (IBAction)prevBtnClicked:(id)sender;
- (IBAction)routePreferenceChanged:(UISegmentedControl *)sender;
- (IBAction)reorderStops:(UIBarButtonItem *)sender ;

@end

	