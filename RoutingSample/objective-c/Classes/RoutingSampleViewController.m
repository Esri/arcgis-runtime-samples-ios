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

#import "RoutingSampleViewController.h"

#define kTiledMapServiceUrl		@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
#define kRouteTaskUrl			@"http://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route"

@implementation RoutingSampleViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	// Load a tiled map service
    self.mapView.map = [AGSMap mapWithBasemapType:AGSBasemapTypeStreets latitude:0 longitude:0 levelOfDetail:0 ];
	
	// zoom to some location (this is San Diego)
    [self.mapView setViewpointCenter:[AGSPoint pointWithX:-117.1618 y:32.7065 spatialReference:[AGSSpatialReference WGS84]] scale:20000 completion:nil];
	
	// Setup the route task
	NSURL *routeTaskUrl = [NSURL URLWithString:kRouteTaskUrl];
	self.routeTask = [AGSRouteTask routeTaskWithURL:routeTaskUrl];
    
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

	// add sketch layer to the map
    self.mapView.sketchEditor = [AGSSketchEditor sketchEditor];
	
	//Register for "Geometry Changed" notifications 
	//We want to enable/disable UI elements when sketch geometry is modified
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchEditorGeometryDidChangeNotification object:nil];
	
	
	//Start the sketch editor
    [self.mapView.sketchEditor startWithCreationMode:AGSSketchCreationModePoint];
    
		
	// add graphics layer
	self.stopGraphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];
    [self.mapView.graphicsOverlays addObject:self.stopGraphicsOverlay];

    self.barrierGraphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];
    [self.mapView.graphicsOverlays addObject:self.barrierGraphicsOverlay];
    
    self.routeGraphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];
    [self.mapView.graphicsOverlays addObject:self.routeGraphicsOverlay];
    
	// create a custom callout view using a button with an image
	// this is to remove stops after we add them to the map
	UIButton *removeStopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	removeStopBtn.frame = CGRectMake(0, 0, 48, 24);
	[removeStopBtn setImage:[UIImage imageNamed:@"remove24.png"] forState:UIControlStateNormal];
	[removeStopBtn addTarget:self 
					  action:@selector(removeStopClicked) 
			forControlEvents:UIControlEventTouchUpInside];
	self.stopCalloutView = removeStopBtn;
	
	// initialize stop counter
	self.numStops = 0;
	
	// initialize barrier counter
	self.numBarriers = 0;
	
	// update our banner
	[self updateDirectionsLabel:@"Tap on the map to add stops & barriers"];
	self.directionsBannerView.hidden = NO;
    
    self.mapView.touchDelegate = self;
}


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



#pragma mark AGSRouteTaskDelegate

//
// we got the default parameters from the service
//
- (void) processRouteParameters:(AGSRouteParameters*)routeParams {
	self.routeTaskParams = routeParams;
}

//
// an error was encountered while getting defaults
//
- (void) processRouteParametersError:(NSError*)error {
	 
	// Create an alert to let the user know the retrieval failed
	// Click Retry to attempt to retrieve the defaults again
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Failed to retrieve default route parameters" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

    __weak __typeof(self) weakSelf = self;

    // If the user clicks 'Retry' then we should attempt to retrieve the defaults again
    [alert addAction:[UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [weakSelf.routeTask defaultRouteParametersWithCompletion:^(AGSRouteParameters * _Nullable routeParams, NSError * _Nullable error) {
            if (routeParams!=nil){
                [weakSelf processRouteParameters:routeParams];
            }else if (error!=nil){
                [weakSelf processRouteParametersError:error];
            }
        }];
        
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}


//
// route was solved
//
- (void) processRouteResult:(AGSRouteResult*)routeTaskResult {

    // update our banner with status
    [self updateDirectionsLabel:@"Routing completed"];
	
	// we know that we are only dealing with 1 route...
    self.routeResult = routeTaskResult.routes[0];
	if (self.routeResult) {
		
        // symbolize the returned route graphic
        AGSGraphic* routeGrapic = [AGSGraphic graphicWithGeometry:self.routeResult.routeGeometry symbol:[self routeSymbol] attributes:nil];
        
        // add the route graphic to the graphic's layer
		[self.routeGraphicsOverlay.graphics addObject:routeGrapic];
		
		// enable the next button so the user can traverse directions
		self.nextBtn.enabled = YES;
		
        // remove the stop graphics from the graphics layer
        // careful not to attempt to mutate the graphics array while
        // it is being enumerated
        [self.stopGraphicsOverlay.graphics removeAllObjects];
		
        // add the returned stops...it's possible these came back in a different order
        // because we specified findBestSequence
        for (AGSStop *stop in self.routeResult.stops) {
            AGSSymbol* symbol = [self stopSymbolWithNumber:stop.sequence];
            AGSGraphic* g = [AGSGraphic graphicWithGeometry:stop.geometry symbol:symbol attributes:nil];
            [self.stopGraphicsOverlay.graphics addObject:g];
        }
        
	}
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

- (void)respondToGeomChanged: (NSNotification*) notification {
	//Enable/disable UI elements appropriately
	self.addBtn.enabled = self.mapView.sketchEditor.isSketchValid;
	self.clearSketchBtn.enabled = ![self.mapView.sketchEditor.geometry isEmpty];
}

//
// create a composite symbol with a number
//
- (AGSCompositeSymbol*)stopSymbolWithNumber:(NSInteger)stopNumber {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
    // create outline
	AGSSimpleLineSymbol *sls = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor blackColor] width:2];
	
    // create main circle
	AGSSimpleMarkerSymbol *sms = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithStyle:AGSSimpleMarkerSymbolStyleCircle color:[UIColor greenColor] size:20];
	sms.style = AGSSimpleMarkerSymbolStyleCircle;

    
    // add number as a text symbol
    AGSTextSymbol *ts = [AGSTextSymbol textSymbolWithText:[NSString stringWithFormat:@"%d",(int)stopNumber] color:[UIColor blackColor] size:9 horizontalAlignment:AGSHorizontalAlignmentCenter verticalAlignment:AGSVerticalAlignmentMiddle];

    cs.symbols = @[sls, sms, ts];
    
	return cs;
}

//
// default symbol for the barriers
//
- (AGSCompositeSymbol*)barrierSymbol {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
	AGSSimpleLineSymbol *sls = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor redColor] width:2];
	AGSSimpleFillSymbol *sfs = [AGSSimpleFillSymbol simpleFillSymbolWithStyle:AGSSimpleFillSymbolStyleSolid color:[[UIColor redColor] colorWithAlphaComponent:0.45] outline:sls];
    
    cs.symbols = @[sfs];
	
//	AGSTextSymbol *ts = [[[AGSTextSymbol alloc] initWithTextTemplate:@"${barrierNumber}" 
//															   color:[UIColor blackColor]] autorelease];
//	ts.vAlignment = AGSTextSymbolVAlignmentMiddle;
//	ts.hAlignment = AGSTextSymbolHAlignmentCenter;
//	ts.fontSize = 20;
//	ts.fontWeight = AGSTextSymbolFontWeightBold;
//	[cs addSymbol:ts];
	
	return cs;
}

//
// create our route symbol
//
- (AGSCompositeSymbol*)routeSymbol {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
    AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor yellowColor] width:8];
    AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor blueColor] width:4];
    cs.symbols = @[sls1,sls2];
    
	return cs;
}

//
// represents the current direction
//
- (AGSCompositeSymbol*)currentDirectionSymbol {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
    AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor whiteColor] width:8];
    AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleDash color:[UIColor redColor] width:4];
    cs.symbols = @[sls1,sls2];

	return cs;
}

//
// reset button clicked
//
- (IBAction)resetBtnClicked:(id)sender {
	[self reset];
}

//
// reset the sample so we can perform another route
//
- (void)reset {
	
	// set stop counter back to 0
	self.numStops = 0;
	
	// set barrier counter back to 0
	self.numBarriers = 0;
	
	// reset direction index
	self.directionIndex = -1;
		
	// remove all graphics
	[self.stopGraphicsOverlay.graphics removeAllObjects];
    [self.barrierGraphicsOverlay.graphics removeAllObjects];
    [self.routeGraphicsOverlay.graphics removeAllObjects];
	
	// reset sketchModeSegCtrl to point
	self.sketchModeSegCtrl.selectedSegmentIndex = 0;
	for (int i =0; i<self.sketchModeSegCtrl.numberOfSegments; i++) {
		[self.sketchModeSegCtrl setEnabled:YES forSegmentAtIndex:i];
	}
	
	// reset directions label
	[self updateDirectionsLabel:@"Tap on the map to add stops & barriers"];
    
	//
    // if the sketch layer was removed/nil'd out, re-add it
	if (!self.mapView.sketchEditor) {
        self.mapView.sketchEditor = [AGSSketchEditor sketchEditor];
	}
	else {
		// clear the sketch layer and reset it to a point
		[self.mapView.sketchEditor clearGeometry];
	}	

    if (self.sketchModeSegCtrl.selectedSegmentIndex == 0) {
        [self.mapView.sketchEditor startWithCreationMode:AGSSketchCreationModePoint];
    }
    else {
        [self.mapView.sketchEditor startWithCreationMode:AGSSketchCreationModePolygon];
    }
    
    // disable the next/prev direction buttons
	self.nextBtn.enabled = NO;
	self.prevBtn.enabled = NO;
}

- (void)removeStopClicked {
    if ([self.stopGraphicsOverlay.graphics containsObject:self.mapView.callout.representedObject]) {
		// we have a stop
		self.numStops--;
        [self.stopGraphicsOverlay.graphics removeObject:self.mapView.callout.representedObject];
    }
	else {
		//barrier
		self.numBarriers--;
        [self.barrierGraphicsOverlay.graphics removeObject:self.mapView.callout.representedObject];
    }
	
    
    // hide the callout
    [self.mapView.callout dismiss];
}

//
// update our banner's text
//
- (void)updateDirectionsLabel:(NSString*)newLabel {
	self.directionsLabel.text = newLabel;
}

#pragma mark IBActions

//
// add a stop or barrier depending on the sketch layer's current geometry
//
- (IBAction)addStopOrBarrier:(id)sender {
	
	//grab the geometry, then clear the sketch
    AGSGeometry *geometry = self.mapView.sketchEditor.geometry;
	[self.mapView.sketchEditor clearGeometry];
	
	//Prepare symbol and attributes for the Stop/Barrier
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	AGSSymbol *symbol;
	
	switch (geometry.geometryType) {
		//Stop
		case AGSGeometryTypePoint:{
            self.numStops++;
            [attributes setValue:[NSNumber numberWithInt:self.numStops] forKey:@"stopNumber"];
            symbol = [self stopSymbolWithNumber:self.numStops];
			AGSGraphic *stopGraphic = [AGSGraphic graphicWithGeometry:geometry
																	   symbol:symbol 
																   attributes:attributes ];
			[self.stopGraphicsOverlay.graphics addObject:stopGraphic];
			break;
		//Barrier
		}
        case AGSGeometryTypePolygon:{
			self.numBarriers++;
			[attributes setValue:[NSNumber numberWithInt:self.numBarriers] forKey:@"barrierNumber"];
			symbol = [self barrierSymbol];
			AGSGraphic *g = [AGSGraphic graphicWithGeometry:geometry 
													 symbol:symbol
												 attributes:attributes];
			[self.barrierGraphicsOverlay.graphics addObject:g];
			break;
        }
        default:
            break;
	}
	
}

//
// if our segment control was changed, then the sketch layer geometry needs to 
// be updated to reflect that (point for stops and polygon for barriers)
//
- (IBAction)stopsBarriersValChanged:(id)sender {
	
	if (!self.mapView.sketchEditor) {
		return;
	}
	
    [self.mapView.sketchEditor clearGeometry];
    
	UISegmentedControl *segCtrl = (UISegmentedControl*)sender;
	
	switch (segCtrl.selectedSegmentIndex) {
		case 0:
            [self.mapView.sketchEditor startWithCreationMode:AGSSketchCreationModePoint];
			break;
		case 1:
            [self.mapView.sketchEditor startWithCreationMode:AGSSketchCreationModePolygon];
            break;
		default:
			break;
	}
}

//
// perform the route task's solve operation
//
- (IBAction)routeBtnClicked:(id)sender {
	
    // update our banner
	[self updateDirectionsLabel:@"Routing..."];
	
    // if we have a sketch layer on the map, remove it
	if (self.mapView.sketchEditor.isStarted) {
        [self.mapView.sketchEditor stop];
        
		//also disable the sketch control so that user cannot sketch
		self.sketchModeSegCtrl.selectedSegmentIndex = -1;
		for (int i =0; i<self.sketchModeSegCtrl.numberOfSegments; i++) {
			[self.sketchModeSegCtrl setEnabled:NO forSegmentAtIndex:i];
		}
		
		
	}
	
	NSMutableArray *stops = [NSMutableArray array];
	NSMutableArray *polygonBarriers = [NSMutableArray array];

	// get the stop, barriers for the route task
	for (AGSGraphic *g in self.stopGraphicsOverlay.graphics) {
        AGSStop* stop = [AGSStop stopWithPoint:(AGSPoint*)g.geometry];
        [stops addObject:stop];
	}
	
	// set the stop on the parameters object
	if (stops.count > 0) {
		[self.routeTaskParams setStops:stops];
	}
	
	
    // get the stop, barriers for the route task
    for (AGSGraphic *g in self.barrierGraphicsOverlay.graphics) {
        // if it's a stop graphic, add the object to stops
        AGSPolygonBarrier* barrier = [AGSPolygonBarrier barrierWithPolygon:(AGSPolygon*)g.geometry];
        [polygonBarriers addObject:barrier];
    }
    
    // set the barriers on the parameters object
    if (polygonBarriers.count > 0) {
		[self.routeTaskParams setPolygonBarriers:polygonBarriers];
	}
	
    
    // return the graphic representing the entire route
    self.routeTaskParams.returnRoutes = YES;

	// this returns turn-by-turn directions
	self.routeTaskParams.returnDirections = YES;
	
	// the next 3 lines will cause the task to find the 
	// best route regardless of the stop input order
	self.routeTaskParams.findBestSequence = YES;
	self.routeTaskParams.preserveFirstStop = YES;
	self.routeTaskParams.preserveLastStop = NO;
	
	// since we used "findBestSequence" we need to 
	// get the newly reordered stops
	self.routeTaskParams.returnStops = YES;
	
	// ensure the graphics are returned in our map's spatial reference
	self.routeTaskParams.outputSpatialReference = self.mapView.spatialReference;
	
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

//
// clear the sketch layer
//
- (IBAction)clearSketchLayer:(id)sender {
	[self.mapView.sketchEditor clearGeometry];
}


//
// move to the next direction in the direction set
//
- (IBAction)nextBtnClicked:(id)sender {
	self.directionIndex++;
	
    // remove current direction graphic, so we can display next one
	if ([self.routeGraphicsOverlay.graphics containsObject:self.currentDirectionGraphic]) {
		[self.routeGraphicsOverlay.graphics removeObject:self.currentDirectionGraphic];
	}
	
    // get current direction and add it to the graphics layer
	self.currentDirctionManeuver = self.routeResult.directionManeuvers[self.directionIndex];
    self.currentDirectionGraphic = [AGSGraphic graphicWithGeometry:self.currentDirctionManeuver.geometry symbol:[self currentDirectionSymbol] attributes:nil];
	[self.routeGraphicsOverlay.graphics addObject:self.currentDirectionGraphic];
	
    // update banner
	[self updateDirectionsLabel:self.currentDirctionManeuver.directionText];
	
    // zoom to envelope of the current direction (expanded by factor of 1.3)
    [self.mapView setViewpointGeometry:self.currentDirctionManeuver.geometry padding:30 completion:nil];
	
    // determine if we need to disable a next/prev button
	if (self.directionIndex >= self.routeResult.directionManeuvers.count - 1) {
		self.nextBtn.enabled = NO;
	}
	if (self.directionIndex > 0) {
		self.prevBtn.enabled = YES;
	}

}

- (IBAction)prevBtnClicked:(id)sender {
	self.directionIndex--;
	
    // remove current direction
	if ([self.routeGraphicsOverlay.graphics containsObject:self.currentDirectionGraphic]) {
		[self.routeGraphicsOverlay.graphics removeObject:self.currentDirectionGraphic];
	}
    
	// get next direction
    self.currentDirctionManeuver = self.routeResult.directionManeuvers[self.directionIndex];
    self.currentDirectionGraphic = [AGSGraphic graphicWithGeometry:self.currentDirctionManeuver.geometry symbol:[self currentDirectionSymbol] attributes:nil];
    [self.routeGraphicsOverlay.graphics addObject:self.currentDirectionGraphic];
    
    // update banner text
    [self updateDirectionsLabel:self.currentDirctionManeuver.directionText];
    
    // zoom to env factored by 1.3
    [self.mapView setViewpointGeometry:self.currentDirctionManeuver.geometry padding:30 completion:nil];
    
    // determine if we need to disable next/prev button
	if (self.directionIndex <= 0) {
		self.prevBtn.enabled = NO;
	}
	if (self.directionIndex < self.routeResult.directionManeuvers.count - 1) {
		self.nextBtn.enabled = YES;
	}
}

#pragma mark AGSGeoViewTouchDelegate

-(void)geoView:(AGSGeoView *)geoView didTouchDownAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint completion:(void (^)(BOOL))completion {
    
    __weak __typeof(self) weakSelf = self;

    [self.mapView identifyGraphicsOverlay:self.stopGraphicsOverlay screenPoint:screenPoint tolerance:22 returnPopupsOnly:NO completion:^(AGSIdentifyGraphicsOverlayResult * _Nonnull identifyResult) {
        
        if (identifyResult!=nil && identifyResult.graphics.count>0) {
            completion(YES);
            [weakSelf showCalloutForGraphic:identifyResult.graphics[0] tapLocation:mapPoint];
            
        }else {
            
            [weakSelf.mapView identifyGraphicsOverlay:self.barrierGraphicsOverlay screenPoint:screenPoint tolerance:22 returnPopupsOnly:NO completion:^(AGSIdentifyGraphicsOverlayResult * _Nonnull identifyResult) {
                
                if (identifyResult!=nil && identifyResult.graphics.count>0) {
                    completion(YES);
                    [weakSelf showCalloutForGraphic:identifyResult.graphics[0] tapLocation:mapPoint];
                }else{
                    completion(NO);
                    [weakSelf.mapView.callout dismiss];
                }
                
            }];
            
        }
        
    }];
}


- (void) showCalloutForGraphic:(AGSGraphic*)graphic tapLocation:(AGSPoint*)mapPoint{
    self.mapView.callout.customView = self.stopCalloutView;
    [self.mapView.callout showCalloutForGraphic:graphic tapLocation:mapPoint animated:YES];
    [self.mapView.sketchEditor clearGeometry];
}

@end
