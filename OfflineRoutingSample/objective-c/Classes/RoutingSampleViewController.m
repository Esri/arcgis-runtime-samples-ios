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

@property (nonatomic, strong) AGSGraphicsLayer				*graphicsLayerStops;
@property (nonatomic, strong) AGSGraphicsLayer              *graphicsLayerRoute;
@property (nonatomic, strong) AGSRouteTask					*routeTask;
@property (nonatomic, strong) AGSRouteTaskParameters		*routeTaskParams;
@property (nonatomic, strong) AGSDirectionGraphic			*currentDirectionGraphic;
@property (nonatomic, strong) AGSRouteResult				*routeResult;
@property (nonatomic, strong) AGSGraphic* lastStop;
@property (nonatomic, assign) BOOL isExecuting;
@property (nonatomic, strong) AGSGraphic* routeGraphic;
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
    
    self.mapView.showMagnifierOnTapAndHold = YES;
    self.mapView.allowMagnifierToPanMap = NO;
    self.mapView.layerDelegate = self;

    
    
    // Load a tiled map service
    [self.mapView addMapLayer:[AGSLocalTiledLayer localTiledLayerWithName:@"SanFrancisco.tpk"] ];
	
	// Setup the route task
    NSError* error = nil;
    self.routeTask = [AGSRouteTask routeTaskWithDatabaseName:@"RuntimeSanFrancisco" network:@"Streets_ND" error:&error];
    // assign delegate to this view controller
	self.routeTask.delegate = self;
	
	// kick off asynchronous method to retrieve default parameters
	// for the route task
	[self.routeTask retrieveDefaultRouteTaskParameters];


		
    // add graphics layer for displaying the route
    AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls1.color = [UIColor yellowColor];
	sls1.style = AGSSimpleLineSymbolStyleSolid;
	sls1.width = 8;
	[cs addSymbol:sls1];
	AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls2.color = [UIColor blueColor];
	sls2.style = AGSSimpleLineSymbolStyleSolid;
	sls2.width = 4;
	[cs addSymbol:sls2];
	self.graphicsLayerRoute = [AGSGraphicsLayer graphicsLayer];
    self.graphicsLayerRoute.renderer = [AGSSimpleRenderer simpleRendererWithSymbol:cs];
    [self.mapView addMapLayer:self.graphicsLayerRoute withName:@"Route"];
    
	// add graphics layer for displaying the stops
	self.graphicsLayerStops = [AGSGraphicsLayer graphicsLayer];
	[self.mapView addMapLayer:self.graphicsLayerStops withName:@"Stops"];
	
	// initialize stop counter
	self.numStops = 0;

    
	// update our banner
	[self updateDirectionsLabel:@"Tap & hold on the map to add stops"];
	self.directionsLabel.hidden = NO;

    self.mapView.touchDelegate = self;
    self.isExecuting = NO;
}
#pragma mark - AGSMapViewTouchDelegate

-(void) mapView:(AGSMapView *)mapView didTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features {
    self.lastStop = [self addStop:mappoint];
    if(self.graphicsLayerStops.graphics.count>1){
        self.isExecuting = YES;
        [self solveRoute];
    }
}

-(void) mapView:(AGSMapView *)mapView didMoveTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features {
    if(self.isExecuting)
        return;
    self.lastStop.geometry = mappoint;
    if(self.graphicsLayerStops.graphics.count<2)
        return;
    self.isExecuting = YES;
    [self solveRoute];
}

-(void)mapView:(AGSMapView *)mapView didEndTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    if(self.graphicsLayerStops.graphics.count<2){
        self.reorderBtn.enabled = NO;
    }else{
        self.reorderBtn.enabled = YES;
    }
}

#pragma mark - AGSMapViewLayerDelegate 
-(void)mapViewDidLoad:(AGSMapView *)mapView{
    
	
    AGSPoint* museumOfMA = [AGSPoint pointFromDecimalDegreesString:@"37.785 , -122.400" withSpatialReference:[AGSSpatialReference wgs84SpatialReference]];
    [self addStop:(AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine]projectGeometry:museumOfMA toSpatialReference:self.mapView.spatialReference]];
    
    if(self.routeTaskParams){
        self.routeTaskParams.outSpatialReference = self.mapView.spatialReference;
    }
    
    [self.mapView zoomIn:NO];
}




#pragma mark - AGSRouteTaskDelegate

//
// we got the default parameters from the service
//
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didRetrieveDefaultRouteTaskParameters:(AGSRouteTaskParameters *)routeParams {
	self.routeTaskParams = routeParams;
    
    
	self.routeTaskParams.returnRouteGraphics = YES;
    
	// this returns turn-by-turn directions
	self.routeTaskParams.returnDirections = YES;
	

	self.routeTaskParams.findBestSequence = NO;
    
    
    self.routeTaskParams.impedanceAttributeName = @"Minutes";
    self.routeTaskParams.accumulateAttributeNames = @[@"Meters", @"Minutes"];
	
	// since we used "findBestSequence" we need to
	// get the newly reordered stops
	self.routeTaskParams.returnStopGraphics = NO;
	
	// ensure the graphics are returned in our map's spatial reference
	self.routeTaskParams.outSpatialReference = self.mapView.spatialReference;
	
	// let's ignore invalid locations
	self.routeTaskParams.ignoreInvalidLocations = YES;
}


//
// an error was encountered while getting defaults
//
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didFailToRetrieveDefaultRouteTaskParametersWithError:(NSError *)error {
	
	// Create an alert to let the user know the retrieval failed
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" 
												 message:@"Failed to retrieve default route parameters" 
												delegate:nil
									   cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[av show];
}


//
// route was solved
//
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didSolveWithResult:(AGSRouteTaskResult *)routeTaskResult {
	
    // update our banner with status
    [self updateDirectionsLabel:@"Routing completed"];
	
	// we know that we are only dealing with 1 route...
	self.routeResult = [routeTaskResult.routeResults lastObject];
        
    NSString* resultSummary = [NSString stringWithFormat:@"%.0f mins, %.1f miles",self.routeResult.totalMinutes, self.routeResult.totalMiles];
    [self updateDirectionsLabel:resultSummary];
        
        // add the route graphic to the graphic's layer
        [self.graphicsLayerRoute removeAllGraphics];
		[self.graphicsLayerRoute addGraphic:self.routeResult.routeGraphic];
        

		// enable the next button so the user can traverse directions
		self.nextBtn.enabled = YES;
        
        if(self.routeResult.stopGraphics){
            [self.graphicsLayerStops removeAllGraphics];
            
            for (AGSStopGraphic* reorderedStop in self.routeResult.stopGraphics) {
                BOOL exists;
                NSInteger sequence = [reorderedStop attributeAsIntForKey:@"Sequence" exists:&exists];
                
                // create a composite symbol using the sequence number
                reorderedStop.symbol = [self stopSymbolWithNumber:sequence];
            
                          // add the graphic
                		[self.graphicsLayerStops addGraphic:reorderedStop];
            }
            self.routeTaskParams.findBestSequence = NO;
            self.routeTaskParams.returnStopGraphics = NO;
        }
        self.isExecuting = NO;
}

//
// solve failed
// 
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didFailSolveWithError:(NSError *)error {
	[self updateDirectionsLabel:@"Routing failed"];
	
	// the solve route failed...
	// let the user know

          UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Solve Route Failed"
                                                     message:[NSString stringWithFormat:@"Error: %@", error]
                                                    delegate:nil
                                           cancelButtonTitle:@"Ok"
                                           otherButtonTitles:nil];
        [av show];
}


#pragma mark Misc


//
// create a composite symbol with a number
//
- (AGSCompositeSymbol*)stopSymbolWithNumber:(NSInteger)stopNumber {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
    // create outline
	AGSSimpleLineSymbol *sls = [AGSSimpleLineSymbol simpleLineSymbol];
	sls.color = [UIColor blackColor];
	sls.width = 2;
	sls.style = AGSSimpleLineSymbolStyleSolid;
	
    // create main circle
	AGSSimpleMarkerSymbol *sms = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
	sms.color = [UIColor greenColor];
	sms.outline = sls;
	sms.size = CGSizeMake(20, 20);
	sms.style = AGSSimpleMarkerSymbolStyleCircle;
	[cs addSymbol:sms];
	
//    // add number as a text symbol
	AGSTextSymbol *ts = [[AGSTextSymbol alloc] initWithText:[NSString stringWithFormat:@"%ld", (long)stopNumber]
															   color:[UIColor blackColor]] ;
	ts.vAlignment = AGSTextSymbolVAlignmentMiddle;
	ts.hAlignment = AGSTextSymbolHAlignmentCenter;
	ts.fontSize	= 16;
	[cs addSymbol:ts];
	
	return cs;
}




//
// represents the current direction
//
- (AGSCompositeSymbol*)currentDirectionSymbol {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
	AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls1.color = [UIColor whiteColor];
	sls1.style = AGSSimpleLineSymbolStyleSolid;
	sls1.width = 8;
	[cs addSymbol:sls1];
	
	AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls2.color = [UIColor redColor];
	sls2.style = AGSSimpleLineSymbolStyleDash;
	sls2.width = 4;
	[cs addSymbol:sls2];
	
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
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	AGSSymbol *symbol;
            self.numStops++;
            symbol = [self stopSymbolWithNumber:self.numStops];
			AGSStopGraphic *stopGraphic = [AGSStopGraphic graphicWithGeometry:geometry
																	   symbol:symbol
																   attributes:attributes];
			stopGraphic.sequence = self.numStops;
			//You can set additional properties on the stop here
			//refer to the conceptual helf for Routing task
			[self.graphicsLayerStops addGraphic:stopGraphic];
    return stopGraphic;
	
}
//
// perform the route task's solve operation
//

-(void) solveRoute{
    [self resetDirections];
	
	
	NSMutableArray *stops = [NSMutableArray array];
    
	// get the stop, barriers for the route task
	for (AGSGraphic *g in self.graphicsLayerStops.graphics) {
        // if it's a stop graphic, add the object to stops
		if ([g isKindOfClass:[AGSStopGraphic class]]) {
			[stops addObject:g];
            
		}
        
	}
	
	// set the stop and polygon barriers on the parameters object
	if (stops.count > 0) {
        // update our banner
        [self updateDirectionsLabel:@"Routing..."];
		[self.routeTaskParams setStopsWithFeatures:stops];
        // execute the route task
        [self.routeTask solveWithParameters:self.routeTaskParams];
	}
	
	
}
//
// reset the sample so we can perform another route
//
- (void)reset {
	
	// set stop counter back to 0
	self.numStops = 0;
    
	// remove all graphics
	[self.graphicsLayerStops removeAllGraphics];
    [self.graphicsLayerRoute removeAllGraphics];
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
    [self.graphicsLayerRoute removeGraphic:self.currentDirectionGraphic];
}

#pragma mark Action methods

- (IBAction)routeBtnClicked:(id)sender {
    [self solveRoute];
}

- (IBAction)routePreferenceChanged:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.routeTaskParams.impedanceAttributeName = @"Minutes";
            break;
        case 1:
            self.routeTaskParams.impedanceAttributeName = @"Meters";
        default:
            break;
    }
    [self solveRoute];
}

- (IBAction)reorderStops:(UIBarButtonItem *)sender {
    self.routeTaskParams.findBestSequence = YES;
	self.routeTaskParams.preserveFirstStop = NO;
	self.routeTaskParams.preserveLastStop = NO;

    self.routeTaskParams.returnStopGraphics = YES;
    [self solveRoute];
    
}
//
// move to the next direction in the direction set
//
- (IBAction)nextBtnClicked:(id)sender {
	self.directionIndex++;
	
    // remove current direction graphic, so we can display next one
	if ([self.graphicsLayerRoute.graphics containsObject:self.currentDirectionGraphic]) {
		[self.graphicsLayerRoute removeGraphic:self.currentDirectionGraphic];
	}
	
    // get current direction and add it to the graphics layer
	AGSDirectionSet *directions = self.routeResult.directions;
	self.currentDirectionGraphic = [directions.graphics objectAtIndex:self.directionIndex];
	self.currentDirectionGraphic.symbol = [self currentDirectionSymbol];
	[self.graphicsLayerRoute addGraphic:self.currentDirectionGraphic];
	
    // update banner
	[self updateDirectionsLabel:self.currentDirectionGraphic.text];
	
     [self.mapView zoomToGeometry:self.currentDirectionGraphic.geometry withPadding:20 animated:YES];
	
    // determine if we need to disable a next/prev button
	if (self.directionIndex >= self.routeResult.directions.graphics.count - 1) {
		self.nextBtn.enabled = NO;
	}
	if (self.directionIndex > 0) {
		self.prevBtn.enabled = YES;
	}

}

- (IBAction)prevBtnClicked:(id)sender {
	self.directionIndex--;
	
    // remove current direction
	if ([self.graphicsLayerRoute.graphics containsObject:self.currentDirectionGraphic]) {
		[self.graphicsLayerRoute removeGraphic:self.currentDirectionGraphic];
	}
    
	// get next direction
	AGSDirectionSet *directions = self.routeResult.directions;
	self.currentDirectionGraphic = [directions.graphics objectAtIndex:self.directionIndex];
	self.currentDirectionGraphic.symbol = [self currentDirectionSymbol];
	[self.graphicsLayerRoute addGraphic:self.currentDirectionGraphic];
	
    // update banner text
	[self updateDirectionsLabel:self.currentDirectionGraphic.text];
	
    [self.mapView zoomToGeometry:self.currentDirectionGraphic.geometry withPadding:20 animated:YES];

    // determine if we need to disable next/prev button
	if (self.directionIndex <= 0) {
		self.prevBtn.enabled = NO;
	}
	if (self.directionIndex < self.routeResult.directions.graphics.count - 1) {
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
