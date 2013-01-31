/*
 WIRouteSolver.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIRouteSolver.h"
#import "WIRoute.h"

@interface WIRouteSolver () 
{
@private
    BOOL                    _routeTaskReady;
    BOOL                    _solvingRoute;
}

@property (nonatomic, strong) AGSRouteTask              *routeTask;
@property (nonatomic, strong) AGSRouteTaskParameters    *routeTaskParams;
@property (nonatomic, strong) WIRoute                  *routeToSolve;

@end

@implementation WIRouteSolver

@synthesize routingServiceUrl   = _routingServiceUrl;
@synthesize spatialReference    = _spatialReference;
@synthesize routeTaskParams     = _routeTaskParams;
@synthesize routeToSolve        = _routeToSolve;
@synthesize routeTask           = _routeTask;
@synthesize delegate            = _delegate;


- (id)initWithSpatialReference:(AGSSpatialReference *)sr routingServiceUrl:(NSURL *)url
{
    self = [super init];
    if (self) {
        
        _routeTaskReady = NO;
        _solvingRoute = NO;
        
        self.spatialReference = sr;
        self.routingServiceUrl = url;
        
        self.routeTask = [AGSRouteTask routeTaskWithURL:url];
        self.routeTask.delegate = self;
        [self.routeTask performSelector:@selector(retrieveDefaultRouteTaskParameters) 
                             withObject:nil 
                             afterDelay:0.0];
    }
    
    return self;
}

+ (WIRouteSolver *)routeSolverWithSpatialReference:(AGSSpatialReference *)sr routingServiceUrl:(NSURL *)url
{
    WIRouteSolver *rs = [[WIRouteSolver alloc] initWithSpatialReference:sr routingServiceUrl:url];
    return rs;
}

#pragma mark -
#pragma mark AGSRouteTaskDelegate
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didRetrieveDefaultRouteTaskParameters:(AGSRouteTaskParameters *)routeParams {
        
    _routeTaskReady = YES;
    
    self.routeTaskParams = routeParams;
    self.routeTaskParams.directionsLengthUnits = AGSNAUnitMeters;
    self.routeTaskParams.outputGeometryPrecision = 0.0;
    self.routeTaskParams.findBestSequence = NO;
    self.routeTaskParams.outputGeometryPrecisionUnits = AGSUnitsMeters;
    self.routeTaskParams.outSpatialReference = self.spatialReference;
    self.routeTaskParams.directionsStyleName = @"NA Navigation";
    self.routeTaskParams.returnDirections = YES;
    self.routeTaskParams.returnRouteGraphics = YES;
    self.routeTaskParams.ignoreInvalidLocations = NO;
    
    if([self.delegate respondsToSelector:@selector(routeSolverIsReadyToRoute:)])
    {
        [self.delegate routeSolverIsReadyToRoute:self];
    }
}

- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didFailToRetrieveDefaultRouteTaskParametersWithError:(NSError *)error {
    if([self.delegate respondsToSelector:@selector(routeSolverDidFailToInitialize:)])
    {
        [self.delegate routeSolverDidFailToInitialize:self];
    }
}

- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didSolveWithResult:(AGSRouteTaskResult *)routeTaskResult {
    
    NSLog(@"Solved route!");
    _solvingRoute = NO;
    
    //populate route with directions!!
    AGSRouteResult *routeResult = [routeTaskResult.routeResults objectAtIndex:0];
    
    /*  Print out ALL directions
    for (AGSDirectionGraphic *dg in routeResult.directions.graphics)
    {
        NSLog(@"%@",dg.text);
    }  */
    
    self.routeToSolve.directions = routeResult.directions;
    
    if([self.delegate respondsToSelector:@selector(routeSolver:didSolveRoute:)])
    {
        [self.delegate routeSolver:self didSolveRoute:self.routeToSolve];
    }
    
    self.routeToSolve = nil;
}

- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didFailSolveWithError:(NSError *)error {
    
    if([self.delegate respondsToSelector:@selector(routeSolver:didFailToSolveRoute:error:)])
    {
        [self.delegate routeSolver:self didFailToSolveRoute:self.routeToSolve error:error];
    }
    
    self.routeToSolve = nil;
    _solvingRoute = NO;
}


#pragma mark -
#pragma mark Route Stops
- (void)routeStops:(WIRoute *)rs didFinishWithStopGraphics:(NSArray *)stops
{    
    [self.routeTaskParams setStopsWithFeatures:stops];
    [self.routeTask solveWithParameters:self.routeTaskParams];
    
}

#pragma mark -
#pragma mark Public Interface

- (void)solveRoute:(WIRoute *)route
{
    if (_solvingRoute || !_routeTaskReady)
    {
        if([self.delegate respondsToSelector:@selector(routeSolverNotReadyToRoute:)])
        {
            [self.delegate routeSolverNotReadyToRoute:self];
        }
    }
    else
    {
        self.routeToSolve = route;
        _solvingRoute = YES;   
        
        [self.routeTaskParams setStopsWithFeatures:self.routeToSolve.stops];
        [self.routeTask solveWithParameters:self.routeTaskParams];
    }
}

- (BOOL)isRouteTaskReady
{
    return _routeTaskReady;
}

@end