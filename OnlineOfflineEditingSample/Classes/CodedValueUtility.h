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

#import <Foundation/Foundation.h>

@class AGSGraphic;
@class AGSFeatureLayer;
@class AGSField;

@interface CodedValueUtility : NSObject {

}

+(NSString *)getCodedValueFromFeature:(AGSGraphic *)feature forField:(NSString *)fieldName inFeatureLayer:(AGSFeatureLayer *)featureLayer;
+(AGSField*)findField:(NSString *)fieldName inFeatureLayer:(AGSFeatureLayer *)featureLayer;

@end
