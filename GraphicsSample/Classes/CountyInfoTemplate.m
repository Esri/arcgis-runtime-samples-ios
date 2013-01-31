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

#import "CountyInfoTemplate.h"


@implementation CountyInfoTemplate

// text for the graphic will be the name attribute of the feature
- (NSString *)titleForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)map {
    
    return [graphic attributeAsStringForKey:@"NAME"];

}

//details for the callout
- (NSString *)detailForGraphic:(AGSGraphic *)graphic screenPoint:(CGPoint)screen mapPoint:(AGSPoint *)map {

    return [NSString stringWithFormat:@"'90: %@, '99: %@", [graphic attributeAsStringForKey:@"POP1990"], [graphic attributeAsStringForKey:@"POP1999"]];

}


@end
