/*
 AGSGeometry+Additions.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm

*/

#import <ArcGIS/ArcGIS.h>

/*
 Category that extents AGSGeometry. Allows to essentially 'cast' any geomtry
 down to a point geomtery.
 */

@interface AGSGeometry (Additions)

/* Returns the center of a geometry */
- (AGSPoint *)getLocationPoint;

/* Returns the first point in a geometry */
- (AGSPoint *)head;

@end
