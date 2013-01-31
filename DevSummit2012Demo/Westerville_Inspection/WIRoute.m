/*
 WIRoute.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIRoute.h"

@interface WIRoute () 

@property (nonatomic, strong, readwrite) NSMutableArray     *stops;

@end

@implementation WIRoute

@synthesize stops           = _stops;
@synthesize directions      = _directions;


- (id)init
{
    self = [super init];
    if(self)
    {        
        self.stops = [NSMutableArray arrayWithCapacity:3];
        self.directions = nil;
    }
    
    return self;
}


//Convenience class initializer
+ (WIRoute *)route
{
    WIRoute *r = [[WIRoute alloc] init];
    return r;
}


#pragma mark -
#pragma mark Public Interface
- (void)addStop:(AGSStopGraphic *)location
{    
    [self.stops addObject:location];
}

- (void)removeStop:(AGSStopGraphic *)location
{    
    [self.stops removeObject:location];
}

//Removes all stops. Does not remove their associated graphic from the screen, just
//removes the associated location from the data structure
- (void)removeAllStops
{
    [self.stops removeAllObjects];
}


//Returns YES if we can route. To be able to route there has to be more than two stops (i.e they've 
//specified a transit) or the destination has been specified
- (BOOL)canRoute
{
    return (self.stops.count > 1);
}


#define kPointTargetScale 10000.0

//Returns an enveloped that encapsulates all stops in the route. The scale can be adjusted to be zoomed
//in or out appropriately
- (AGSMutableEnvelope *)envelopeInMapView:(AGSMapView *)mapView
{
    AGSMutableEnvelope *_envelope = nil;
    
    for(int i = 0; i < self.stops.count; i++)
    {
        AGSMutableEnvelope *ftrEnv = nil;
        AGSStopGraphic *result = (AGSStopGraphic *)[self.stops objectAtIndex:i];
        
        //for point features.
        double fRatio = kPointTargetScale / mapView.mapScale;
        
        //get a mutable copy of the map current extent, expand by ratio and center at zoomPoint
        ftrEnv = [mapView.visibleArea.envelope mutableCopy];
        [ftrEnv expandByFactor:fRatio];
        [ftrEnv centerAtPoint:result.geometry.envelope.center];
        
        
        if (_envelope == nil){
            _envelope = [AGSMutableEnvelope envelopeWithXmin:ftrEnv.xmin 
                                                            ymin:ftrEnv.ymin 
                                                            xmax:ftrEnv.xmax 
                                                            ymax:ftrEnv.ymax 
                                                spatialReference:mapView.spatialReference];
        }
        else {
            [_envelope unionWithEnvelope:ftrEnv];
        }
        
        //Explicitly release
    }
    
    //Finally expand by a buffering constant
    [_envelope expandByFactor:1.4];
    
    return _envelope;
}

@end