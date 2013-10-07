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


@interface GeocodingSampleViewController : UIViewController <UISearchBarDelegate, AGSLocatorDelegate, AGSCalloutDelegate, AGSMapViewTouchDelegate, AGSLayerCalloutDelegate> {
    
}

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;



@end

