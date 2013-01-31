/*
 AGSGeometry+Additions.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "AGSGeometry+Additions.h"

@implementation AGSGeometry (Additions)

//gets a single point for any geometry type. returns the center point of the envelope for
//polylines and polygons
- (AGSPoint *)getLocationPoint
{
	if ([self isKindOfClass:[AGSPoint class]]){
        return (AGSPoint*)self;
	}
	else if ([self isKindOfClass:[AGSPolyline class]] ||
             [self isKindOfClass:[AGSPolygon class]]){
		return self.envelope.center;
	}
	else if ([self isKindOfClass:[AGSMultipoint class]] &&
             ((AGSMultipoint *)self).numPoints > 0){
        return [((AGSMultipoint*)self) pointAtIndex:0];
    }
    
	return nil;
}

//returns head of geometry, i.e the first point if a line, the first point of a polygon, and just the point for
//a point
- (AGSPoint *)head
{
    if ([self isKindOfClass:[AGSPoint class]]){
        return (AGSPoint*)self;
	}
	else if ([self isKindOfClass:[AGSPolyline class]]){
		AGSPolyline *pl = (AGSPolyline *)self;
        return [pl pointOnPath:0 atIndex:0];
	}
    else if([self isKindOfClass:[AGSPolygon class]])
    {
        AGSPolygon *pl = (AGSPolygon *)self;
        return [pl pointOnRing:0 atIndex:0];
    }
    
	return nil;
}

@end
