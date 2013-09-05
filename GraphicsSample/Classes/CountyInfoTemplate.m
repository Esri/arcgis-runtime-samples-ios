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


- (BOOL)callout:(AGSCallout *)callout willShowForFeature:(id<AGSFeature>)feature layer:(AGSLayer<AGSHitTestable> *)layer mapPoint:(AGSPoint *)mapPoint{
    AGSGraphic* graphic = (AGSGraphic*)feature;
    callout.title =  [graphic attributeAsStringForKey:@"NAME"];
    callout.detail = [NSString stringWithFormat:@"'90: %@, '99: %@", [graphic attributeAsStringForKey:@"POP1990"], [graphic attributeAsStringForKey:@"POP1999"]];
    return YES;
}


@end
