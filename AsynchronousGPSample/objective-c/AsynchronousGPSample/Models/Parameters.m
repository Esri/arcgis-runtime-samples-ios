// Copyright 2011 ESRI
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

#import "Parameters.h"

@implementation Parameters

-(id)init {
    if (self = [super init]) {
        //set default values
        self.windDirection = [NSDecimalNumber decimalNumberWithString:@"90"];
        self.materialType = @"Anhydrous ammonia";
        self.dayOrNightIncident = @"Day";
        self.largeOrSmallSpill = @"Large";
    }
    return self;
}

- (NSArray*)parametersArray {
    
    //create parameters
    AGSGPParameterValue *paramloc = [AGSGPParameterValue parameterWithName:@"Incident_Point" type:AGSGPParameterTypeFeatureRecordSetLayer value:self.featureSet];
	AGSGPParameterValue *paramDegree = [AGSGPParameterValue parameterWithName:@"Wind_Bearing__direction_blowing_to__0_-_360_" type:AGSGPParameterTypeDouble value:[NSNumber numberWithDouble:[self.windDirection doubleValue]]];
    AGSGPParameterValue *paramMaterial = [AGSGPParameterValue parameterWithName:@"Material_Type" type:AGSGPParameterTypeString value:self.materialType];
    AGSGPParameterValue *paramTime = [AGSGPParameterValue parameterWithName:@"Day_or_Night_incident" type:AGSGPParameterTypeString value:self.dayOrNightIncident];
    AGSGPParameterValue *paramType = [AGSGPParameterValue parameterWithName:@"Large_or_Small_spill" type:AGSGPParameterTypeString value:self.largeOrSmallSpill];
    
    //add parameters to arrary
	NSArray *params = @[paramloc, paramDegree, paramTime, paramType, paramMaterial];
    
    return params;
}

@end
