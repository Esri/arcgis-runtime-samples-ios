//
//  Parameters.h
//  AsynchronousGPSample
//
//  Created by Gagandeep Singh on 3/20/14.
//
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
