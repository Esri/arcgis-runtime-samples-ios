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

#import "CodedValueUtility.h"
#import <ArcGIS/ArcGIS.h>

@implementation CodedValueUtility

+(NSString *)getCodedValueFromFeature:(AGSGraphic *)feature forField:(NSString *)fieldName inFeatureLayer:(AGSFeatureLayer *)featureLayer
{
    NSString *codedValue = @"";
    
    if (!feature)
    {
        //no feature yet, just return empty string
        return codedValue;
    }
    
    //get the field
    AGSField *field = [CodedValueUtility findField:fieldName inFeatureLayer:featureLayer];
    
    //get the domain for the field
    AGSCodedValueDomain *cvd = (AGSCodedValueDomain*)field.domain;
    
    //get the attribute value
    id attributeValue = [feature attributeForKey:fieldName];
    if (cvd && attributeValue && (attributeValue != (id)[NSNull null])){
        //loop through all the coded values and compare to our attribute value
        for (int i=0; i<cvd.codedValues.count; i++){
            AGSCodedValue *val = [cvd.codedValues objectAtIndex:i];
            
            //must switch on kind of object val.code is...
            if ([val.code isKindOfClass:[NSNumber class]])
            {                    
                if ([(NSNumber *)val.code intValue] == [(NSNumber *)attributeValue intValue]){
                    //we found our value, get the coded value for that...
                    codedValue = val.name;
                    break;
                }
            }
            else if ([val.code isKindOfClass:[NSString class]])
            {
                if ([val.code isEqualToString:attributeValue]){
                    //we found our value, get the coded value for that...
                    codedValue = val.name;
                    break;
                }
            }
            else {
                NSLog(@"Not implemented.");
            }
        }
    }
    
    return codedValue;
}

+(AGSField*)findField:(NSString *)fieldName inFeatureLayer:(AGSFeatureLayer *)featureLayer
{
	// helper method to find the status field
	for (int i=0; i<featureLayer.fields.count; i++){
		AGSField *field = [featureLayer.fields objectAtIndex:i];
		if ([field.name isEqualToString:fieldName]){
			return field;
		}
	}
	return nil;
}

@end
