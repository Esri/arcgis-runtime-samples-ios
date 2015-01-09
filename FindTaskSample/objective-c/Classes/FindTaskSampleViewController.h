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


@interface FindTaskSampleViewController : UIViewController <AGSFindTaskDelegate,UISearchBarDelegate,AGSMapViewLayerDelegate, AGSCalloutDelegate, AGSLayerCalloutDelegate> 

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) AGSDynamicMapServiceLayer *dynamicLayer;
@property (nonatomic, strong) UIView *dynamicLayerView;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSFindTask *findTask;
@property (nonatomic, strong) AGSFindParameters *findParams;
@property (nonatomic, strong) AGSCalloutTemplate *cityCalloutTemplate;
@property (nonatomic, strong) AGSCalloutTemplate *riverCalloutTemplate;
@property (nonatomic, strong) AGSCalloutTemplate *stateCalloutTemplate;

@end

