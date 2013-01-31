/*
 WIViewController.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

//for protocol declaration
#import "WIContactsView.h"
#import "WICustomCalloutView.h"
#import "WIRouteSolver.h"
#import "WIRouteStopsView.h"
#import "WIDirectionsView.h"
#import "WIBasemapsView.h"
#import "WIListTableView.h"
#import "WIFeatureView.h"
#import "WIInspectionView.h"
#import "WIInspectionsView.h"
#import "WIPinchableContainerView.h"

/*
 Main View Controller. Houses all relevant views for the application, including the map, 
 the layered views for contacts, list of stops,etc., basemaps
 */

@interface WIDeskViewController : UIViewController <AGSMapViewLayerDelegate, AGSMapViewTouchDelegate, AGSMapViewCalloutDelegate, 
                                                    AGSPortalDelegate, AGSWebMapDelegate, WIContactsViewDelegate, WICustomCalloutDelegate, 
                                                    AGSRouteSolverDelegate, WIRouteStopsViewDelegate, AGSInfoTemplateDelegate, 
                                                    WIBasemapsViewDelegate, UIGestureRecognizerDelegate, WIListTableViewDelegate,
                                                    WIDirectionsViewDelegate, WIFeatureViewDelegate, WIInspectionsViewDelegate, WIInspectionViewDelegate,
                                                    AGSFeatureLayerQueryDelegate, WIPinchableContainerViewDelegate>

/* Method to handle opening a file from another appplication */
- (void)handleDocumentOpenURL:(NSURL *)url;

/* Method to handle when a URL is hit that we can handle with our app
 i.e inspectiondemo://featureLayer-objectid
 */
- (void)handleApplicationURL:(NSURL *)url;

@end
