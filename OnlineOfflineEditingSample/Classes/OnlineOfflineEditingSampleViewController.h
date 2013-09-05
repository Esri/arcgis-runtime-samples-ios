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
#import "OnlineOfflineFeatureLayer.h"

@interface OnlineOfflineEditingSampleViewController : UIViewController<AGSLayerDelegate,AGSMapViewTouchDelegate, AGSLayerCalloutDelegate, AGSCalloutDelegate, OnlineOfflineDelegate,
UIAlertViewDelegate> {
	AGSMapView *_mapView;
	OnlineOfflineFeatureLayer *_featureLayer;
	BOOL _editingMode;							// Flag that tells us if the user is in the process of adding a feature    
    UIBarButtonItem *_takeOfflineButton;
    UIBarButtonItem *_takeOnlineButton;
    UIBarButtonItem *_commitGeometryButton;
}

@property (nonatomic, retain) IBOutlet AGSMapView *mapView;
@property (nonatomic, retain) OnlineOfflineFeatureLayer *featureLayer;

@property (nonatomic, retain) UIBarButtonItem *takeOfflineButton;
@property (nonatomic, retain) UIBarButtonItem *takeOnlineButton;
@property (nonatomic, retain) UIBarButtonItem *commitGeometryButton;

@end

