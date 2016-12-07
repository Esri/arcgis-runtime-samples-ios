// Copyright 2013 ESRI
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

#import "RoutingSampleViewController.h"

#define kTiledMapServiceUrl		@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer" 

@interface RoutingSampleViewController ()

@property (nonatomic, strong) AGSGraphicsOverlay				*graphicsOverlayStops;
@property (nonatomic, strong) AGSGraphicsOverlay              *graphicsOverlayRoute;
@property (nonatomic, strong) AGSRouteTask					*routeTask;
@property (nonatomic, strong) AGSRouteParameters		*routeTaskParams;
@property (nonatomic, strong) AGSGraphic			*currentDirectionGraphic;
@property (nonatomic, strong) AGSRoute				*route;
@property (nonatomic, strong) AGSGraphic* lastStop;
@property (nonatomic, assign) BOOL isExecuting;
@property (nonatomic, assign) int numStops;
@property (nonatomic, assign) int directionIndex;
@property (nonatomic, assign) BOOL reorderStops;

- (AGSCompositeSymbol*)stopSymbolWithNumber:(NSInteger)stopNumber;
- (AGSCompositeSymbol*)currentDirectionSymbol;
- (void)reset;
- (void)updateDirectionsLabel:(NSString*)newLabel;

@end

@implementation RoutingSampleViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.interactionOptions.magnifierEnabled = YES;
    self.mapView.interactionOptions.allowMagnifierToPan = YES;

    
    
    // Load a tiled package
    AGSArcGISTiledLayer* tiledLayer = [AGSArcGISTiledLayer ArcGISTiledLayerWithTileCache:[AGSTileCache tileCacheWithName:@"SanFrancisco"]];
    AGSBasemap* basemap = [AGSBasemap basemapWithBaseLayer:tiledLayer];
    self.mapView.map = [AGSMap mapWithBasemap:basemap];
	
	// Setup the route task
    self.routeTask = [AGSRouteTask routeTaskWithDatabaseName:@"RuntimeSanFrancisco" networkName:@"Streets_ND"];
	
    __weak __typeof(self) weakSelf = self;
	// kick off asynchronous method to retrieve default parameters
	// for the route task
    [self.routeTask defaultRouteParametersWithCompletion:^(AGSRouteParameters * _Nullable routeParams, NSError * _Nullable error) {
        if (routeParams!=nil){
            [weakSelf processRouteParameters:routeParams];
        }else if (error!=nil){
            [weakSelf processRouteParametersError:error];
        }
    }];


		
    // add graphics layer for displaying the route
    AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
    AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor yellowColor] width:8];
    AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor blueColor] width:4];
    cs.symbols = @[sls1,sls2];
	self.graphicsOverlayRoute = [AGSGraphicsOverlay graphicsOverlay];
    self.graphicsOverlayRoute.renderer = [AGSSimpleRenderer simpleRendererWithSymbol:cs];
    
    [self.mapView.graphicsOverlays addObject:self.graphicsOverlayRoute];
    
	// add graphics layer for displaying the stops
	self.graphicsOverlayStops = [AGSGraphicsOverlay graphicsOverlay];
	[self.mapView.graphicsOverlays addObject:self.graphicsOverlayStops];
	
	// initialize stop counter
	self.numStops = 0;

    
	// update our banner
	[self updateDirectionsLabel:@"Tap & hold on the map to add stops"];
	self.directionsLabel.hidden = NO;

    self.mapView.touchDelegate = self;
    self.isExecuting = NO;
}
#pragma mark - AGSMapViewTouchDelegate

- (void)geoView:(AGSGeoView *)geoView didLongPressAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint
{
    self.lastStop = [self addStop:mapPoint];
    if(self.graphicsOverlayStops.graphics.count>1){
        self.isExecuting = YES;
        [self solveRoute];
    }
}

- (void)geoView:(AGSGeoView *)geoView didMoveLongPressToScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {
    if(self.isExecuting)
        return;
    self.lastStop.geometry = mapPoint;
    if(self.graphicsOverlayStops.graphics.count<2)
        return;
    self.isExecuting = YES;
    [self solveRoute];
}

- (void)geoView:(AGSGeoView *)geoView didEndLongPressAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {
    if(self.graphicsOverlayStops.graphics.count<2){
        self.reorderBtn.enabled = NO;
    }else{
        self.reorderBtn.enabled = YES;
    }
}




#pragma mark - AGSRouteTaskDelegate

//
// we got the default parameters from the service
//
- (void) processRouteParameters:(AGSRouteParameters*)routeParams {
    self.routeTaskParams = routeParams;

    
    self.routeTaskParams.returnRoutes = YES;
    
    // this returns turn-by-turn directions
    self.routeTaskParams.returnDirections = YES;
    
    
    self.routeTaskParams.findBestSequence = NO;
    
    
    self.routeTaskParams.travelMode.impedanceAttributeName = @"Minutes";
    self.routeTaskParams.accumulateAttributeNames = @[@"Meters", @"Minutes"];
    
    // since we used "findBestSequence" we need to
    // get the newly reordered stops
    self.routeTaskParams.returnStops = NO;
    
    // ensure the graphics are returned in our map's spatial reference
    self.routeTaskParams.outputSpatialReference = self.mapView.spatialReference;
    
}

//
// an error was encountered while getting defaults
//
- (void) processRouteParametersError:(NSError*)error {
    
    // Create an alert to let the user know the retrieval failed
    // Click Retry to attempt to retrieve the defaults again
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Failed to retrieve default route parameters" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}




//
// route was solved
//
- (void) processRouteResult:(AGSRouteResult*)routeResult {
	
    // update our banner with status
    [self updateDirectionsLabel:@"Routing completed"];
	
	// we know that we are only dealing with 1 route...
    self.route = routeResult.routes[0];
        
    NSString* resultSummary = [NSString stringWithFormat:@"%.0f mins, %.1f miles",self.route.totalTime, self.route.totalLength*0.000621371];
    [self updateDirectionsLabel:resultSummary];
        
        // add the route graphic to the graphic's layer
        [self.graphicsOverlayRoute.graphics removeAllObjects];
		[self.graphicsOverlayRoute.graphics addObject:[AGSGraphic graphicWithGeometry:self.route.routeGeometry symbol:nil attributes:nil]];
        

		// enable the next button so the user can traverse directions
		self.nextBtn.enabled = YES;
        
        if(self.route.stops!=nil && self.route.stops.count>0){
            [self.graphicsOverlayStops.graphics removeAllObjects];
            
            for (AGSStop* reorderedStop in self.route.stops) {
                
                // create a composite symbol using the sequence number
                AGSSymbol* symbol = [self stopSymbolWithNumber:reorderedStop.sequence];
            
                // add the graphic
                [self.graphicsOverlayStops.graphics addObject:[AGSGraphic graphicWithGeometry:reorderedStop.geometry symbol:symbol attributes:nil]];
            }
            self.routeTaskParams.findBestSequence = NO;
            self.routeTaskParams.returnStops = NO;
        }
        self.isExecuting = NO;
}

//
// solve failed
// 
- (void) processRouteError:(NSError*)error {
    [self updateDirectionsLabel:@"Routing failed"];
	
	// the solve route failed...
	// let the user know

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Solve Route Failed" message:[NSString stringWithFormat:@"Error: %@", error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


#pragma mark Misc


//
// create a composite symbol with a number
//
- (AGSCompositeSymbol*)stopSymbolWithNumber:(NSInteger)stopNumber {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
    // create outline
	AGSSimpleLineSymbol *sls = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor blackColor] width:2];
	
    // create main circle
	AGSSimpleMarkerSymbol *sms = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithStyle:AGSSimpleMarkerSymbolStyleCircle color:[UIColor greenColor] size:20];
	sms.outline = sls;

    
//    // add number as a text symbol
    AGSTextSymbol *ts = [AGSTextSymbol textSymbolWithText:[NSString stringWithFormat:@"%ld", (long)stopNumber] color:[UIColor blackColor] size:16 horizontalAlignment:AGSHorizontalAlignmentCenter verticalAlignment:AGSVerticalAlignmentMiddle];
    

    cs.symbols = @[sms,ts];
	return cs;
}




//
// represents the current direction
//
- (AGSCompositeSymbol*)currentDirectionSymbol {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
	AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor whiteColor] width:8];
	
	AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor redColor] width:4];

    cs.symbols = @[sls1,sls2];
	return cs;	
}

//
// reset button clicked
//



//
// update our banner's text
//
- (void)updateDirectionsLabel:(NSString*)newLabel {
	self.directionsLabel.text = newLabel;
}


- (AGSGraphic*)addStop:(AGSPoint*)geometry {
	
	//grab the geometry, then clear the sketch
	//Prepare symbol and attributes for the Stop/Barrier
	AGSSymbol *symbol;
            self.numStops++;
            symbol = [self stopSymbolWithNumber:self.numStops];
			AGSGraphic *stopGraphic = [AGSGraphic graphicWithGeometry:geometry
																	   symbol:symbol
																   attributes:nil];
			//You can set additional properties on the stop here
			//refer to the conceptual helf for Routing task
			[self.graphicsOverlayStops.graphics addObject:stopGraphic];
    return stopGraphic;
	
}
//
// perform the route task's solve operation
//

-(void) solveRoute{
    [self resetDirections];
	
	
	NSMutableArray *stops = [NSMutableArray array];
    
	// get the stop
	for (AGSGraphic *g in self.graphicsOverlayStops.graphics) {
			[stops addObject:[AGSStop stopWithPoint:(AGSPoint*)g.geometry]];
        
	}
	
	// set the stop and polygon barriers on the parameters object
	if (stops.count > 0) {
        // update our banner
        [self updateDirectionsLabel:@"Routing..."];
		[self.routeTaskParams setStops:stops];

        __weak __typeof(self) weakSelf = self;
        // execute the route task
        [self.routeTask solveRouteWithParameters:self.routeTaskParams completion:^(AGSRouteResult * _Nullable routeResult, NSError * _Nullable error) {
            if(routeResult!=nil){
                [weakSelf processRouteResult:routeResult];
            }else{
                [weakSelf processRouteError:error];
            }
        }];
	}
	
	
}
//
// reset the sample so we can perform another route
//
- (void)reset {
	
	// set stop counter back to 0
	self.numStops = 0;
    
	// remove all graphics
	[self.graphicsOverlayStops.graphics removeAllObjects];
    [self.graphicsOverlayRoute.graphics removeAllObjects];
	[self resetDirections];
    [self updateDirectionsLabel:@"Tap & hold on the map to add stops"];
    self.reorderBtn.enabled = NO;
}

-(void)resetDirections{
    // disable the next/prev direction buttons
    // reset direction index
	self.directionIndex = 0;
	self.nextBtn.enabled = NO;
	self.prevBtn.enabled = NO;
    [self.graphicsOverlayRoute.graphics removeObject:self.currentDirectionGraphic];
}

#pragma mark Action methods

- (IBAction)routeBtnClicked:(id)sender {
    [self solveRoute];
}

- (IBAction)routePreferenceChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.routeTaskParams.travelMode.impedanceAttributeName = @"Minutes";
            break;
        case 1:
            self.routeTaskParams.travelMode.impedanceAttributeName = @"Meters";
        default:
            break;
    }
    [self solveRoute];
}

- (IBAction)reorderStops:(UIBarButtonItem *)sender {
    self.routeTaskParams.findBestSequence = YES;
	self.routeTaskParams.preserveFirstStop = NO;
	self.routeTaskParams.preserveLastStop = NO;

    self.routeTaskParams.returnStops = YES;
    [self solveRoute];
    
}
//
// move to the next direction in the direction set
//
- (IBAction)nextBtnClicked:(id)sender {
	self.directionIndex++;
	
    // remove current direction graphic, so we can display next one
	if ([self.graphicsOverlayRoute.graphics containsObject:self.currentDirectionGraphic]) {
		[self.graphicsOverlayRoute.graphics removeObject:self.currentDirectionGraphic];
	}
	
    // get current direction and add it to the graphics layer
	NSArray<AGSDirectionManeuver*> *directions = self.route.directionManeuvers;
	self.currentDirectionGraphic = [AGSGraphic graphicWithGeometry:directions[self.directionIndex].geometry symbol:[self currentDirectionSymbol] attributes:nil];
	[self.graphicsOverlayRoute.graphics addObject:self.currentDirectionGraphic];
	
    // update banner
	[self updateDirectionsLabel:directions[self.directionIndex].directionText];
	
    [self.mapView setViewpointGeometry:self.currentDirectionGraphic.geometry padding:20 completion:nil];
	
    // determine if we need to disable a next/prev button
	if (self.directionIndex >= self.route.directionManeuvers.count - 1) {
		self.nextBtn.enabled = NO;
	}
	if (self.directionIndex > 0) {
		self.prevBtn.enabled = YES;
	}

}

- (IBAction)prevBtnClicked:(id)sender {
	self.directionIndex--;
	
    // remove current direction
	if ([self.graphicsOverlayRoute.graphics containsObject:self.currentDirectionGraphic]) {
		[self.graphicsOverlayRoute.graphics removeObject:self.currentDirectionGraphic];
	}
    
	// get next direction
    // get current direction and add it to the graphics layer
    NSArray<AGSDirectionManeuver*> *directions = self.route.directionManeuvers;
    self.currentDirectionGraphic = [AGSGraphic graphicWithGeometry:directions[self.directionIndex].geometry symbol:[self currentDirectionSymbol] attributes:nil];
    [self.graphicsOverlayRoute.graphics addObject:self.currentDirectionGraphic];
    
    // update banner
    [self updateDirectionsLabel:directions[self.directionIndex].directionText];
    
    [self.mapView setViewpointGeometry:self.currentDirectionGraphic.geometry padding:20 completion:nil];
    
    // determine if we need to disable next/prev button
	if (self.directionIndex <= 0) {
		self.prevBtn.enabled = NO;
	}
	if (self.directionIndex < self.route.directionManeuvers.count - 1) {
		self.nextBtn.enabled = YES;
	}
}


- (IBAction)resetBtnClicked:(id)sender {
	[self reset];
}



#pragma mark - ViewController methods

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}
@end
