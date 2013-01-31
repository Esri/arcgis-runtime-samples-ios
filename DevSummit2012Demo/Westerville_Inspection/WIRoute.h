/*
 WIRoute.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

/*
 A route is a set of stops (locations) that a user would like to route
 to and the associated directions between those stops.
 */

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@interface WIRoute : NSObject

@property (nonatomic, strong, readonly) NSMutableArray  *stops;
@property (nonatomic, strong) AGSDirectionSet           *directions;
 
- (void)addStop:(AGSStopGraphic *)location;
- (void)removeStop:(AGSStopGraphic *)location;
- (void)removeAllStops;

- (BOOL)canRoute;

- (AGSEnvelope *)envelopeInMapView:(AGSMapView *)mapView;

+ (WIRoute *)route;

@end
