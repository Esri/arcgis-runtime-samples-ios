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

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@interface Parameters : NSObject

@property (nonatomic, strong) AGSFeatureSet *featureSet;
@property (nonatomic, strong) NSDecimalNumber *windDirection;
@property (nonatomic, strong) NSString *materialType;
@property (nonatomic, strong) NSString *dayOrNightIncident;
@property (nonatomic, strong) NSString *largeOrSmallSpill;

- (NSArray*)parametersArray;

@end
