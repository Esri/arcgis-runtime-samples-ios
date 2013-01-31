/*
 WIRouteSolver.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@class WIRoute;
@protocol AGSRouteSolverDelegate;

/*
 Responsible for getting route parameters, setting them up correctly,
 and solving a route passed in. Uses delegation to pass back information
 about the solved route
 */

@interface WIRouteSolver : NSObject <AGSRouteTaskDelegate>

@property (nonatomic, strong) NSURL                         *routingServiceUrl;
@property (nonatomic, strong) AGSSpatialReference           *spatialReference;
@property (nonatomic, unsafe_unretained) id<AGSRouteSolverDelegate>    delegate;

- (id)initWithSpatialReference:(AGSSpatialReference *)sr routingServiceUrl:(NSURL *)url;

- (void)solveRoute:(WIRoute *)route;

- (BOOL)isRouteTaskReady;

+ (WIRouteSolver *)routeSolverWithSpatialReference:(AGSSpatialReference *)sr routingServiceUrl:(NSURL *)url;

@end

@protocol AGSRouteSolverDelegate <NSObject>

@optional

- (void)routeSolverIsReadyToRoute:(WIRouteSolver *)rs;
- (void)routeSolverNotReadyToRoute:(WIRouteSolver *)rs;
- (void)routeSolverDidFailToInitialize:(WIRouteSolver *)rs;
- (void)routeSolver:(WIRouteSolver *)rs didSolveRoute:(WIRoute *)route;
- (void)routeSolver:(WIRouteSolver *)rs didFailToSolveRoute:(WIRoute *)route error:(NSError *)error;

@end