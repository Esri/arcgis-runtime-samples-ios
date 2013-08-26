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

#define kTiledMapServiceUrl		@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer" //@"http://services.arcgisonline.com/ArcGIS/rest/services/ESRI_StreetMap_World_2D/MapServer"
#define kRouteTaskUrl			@"http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Network/USA/NAServer/Route"

@implementation RoutingSampleViewController{
    AGSGraphic* _lastStop;
    NSOperation* _op;
    BOOL _isExecuting;
    AGSGraphic* _routeGraphic;
}

@synthesize mapView=_mapView;
@synthesize graphicsLayer=_graphicsLayer;
@synthesize sketchLayer=_sketchLayer;
@synthesize routeTask=_routeTask;
@synthesize routeTaskParams=_routeTaskParams;
@synthesize stopCalloutView=_stopCalloutView;
@synthesize currentStopGraphic=_currentStopGraphic;
@synthesize selectedGraphic=_selectedGraphic;
@synthesize sketchModeSegCtrl=_sketchModeSegCtrl;
@synthesize directionsBannerView=_directionsBannerView;
@synthesize directionsLabel=_directionsLabel;
@synthesize prevBtn=_prevBtn;
@synthesize nextBtn=_nextBtn;
@synthesize addBtn=_addBtn;
@synthesize clearSketchBtn=_clearSketchBtn;
@synthesize routeResult=_routeResult;
@synthesize currentDirectionGraphic=_currentDirectionGraphic;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.showMagnifierOnTapAndHold = YES;
    self.mapView.allowMagnifierToPanMap = NO;
    self.mapView.layerDelegate = self;
	// Load a tiled map service
	NSURL *mapUrl = [NSURL URLWithString:kTiledMapServiceUrl];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
    [self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
	
	// zoom to some location (this is San Francisco)
	AGSSpatialReference *sr = [AGSSpatialReference wgs84SpatialReference];
    //AGSPoint* petcoPark = [AGSPoint pointFromDecimalDegreesString:@"32.7073 , -117.1566" withSpatialReference:sr];
    //AGSPoint* petcoPark  = [AGSPoint pointWithX:-117.1566 y:32.7073 spatialReference:sr];
    AGSEnvelope* env = [AGSEnvelope envelopeWithXmin:-117.1566 ymin:32.70 xmax:-117.1560 ymax:32.75 spatialReference:sr];
    
    
	 [self.mapView zoomToGeometry:env withPadding:0 animated:YES];
//    NSLog(@"%@",petcoPark.envelope);
//    
//    AGSMutableEnvelope* newEnv = [petcoPark.envelope mutableCopy];
//    [newEnv expandByFactor:10];
//    NSLog(@"%@",newEnv);
   // [self.mapView zoomToEnvelope:petcoPark.envelope animated:YES];
   // [self.mapView zoomToGeometry:newEnv withPadding:0 animated:YES];
	
	// Setup the route task
//	NSURL *routeTaskUrl = [NSURL URLWithString:kRouteTaskUrl];
//	self.routeTask = [AGSRouteTask routeTaskWithURL:routeTaskUrl];

    
    NSError* error = nil;
    NSString *documentsDirectory = [[NSBundle mainBundle] resourcePath];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"RuntimeSanDiego.geodatabase"];
    self.routeTask = [AGSRouteTask routeTaskWithDatabasePath:dataPath network:@"Streets_ND" error:&error];
    // assign delegate to this view controller
	self.routeTask.delegate = self;
	
	// kick off asynchronous method to retrieve default parameters
	// for the route task
	[self.routeTask retrieveDefaultRouteTaskParameters];


	

	
	
    
    // set the mapView's calloutDelegate so we can display callouts
	self.mapView.calloutDelegate = self;
		
	// add graphics layer
	self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
	[self.mapView addMapLayer:self.graphicsLayer withName:@"Route results"];
	
	// create a custom callout view using a button with an image
	// this is to remove stops after we add them to the map
	UIButton *removeStopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	removeStopBtn.frame = CGRectMake(0, 0, 24, 24);
	[removeStopBtn setImage:[UIImage imageNamed:@"remove24.png"] forState:UIControlStateNormal];
	[removeStopBtn addTarget:self 
					  action:@selector(removeStopClicked) 
			forControlEvents:UIControlEventTouchUpInside];
	self.stopCalloutView = removeStopBtn;
	
	// initialize stop counter
	_numStops = 0;
	
	// initialize barrier counter
	_numBarriers = 0;
	
	// update our banner
	[self updateDirectionsLabel:@"Tap on the map to add stops & barriers"];
	self.directionsBannerView.hidden = NO;
    
    AGSPoint* p = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:[AGSPoint pointFromDecimalDegreesString:@"32.7073 , -117.1566" withSpatialReference:sr] toSpatialReference:[AGSSpatialReference webMercatorSpatialReference] ];
                              NSLog(@"%@",p);
    [self addStop:p];
    self.mapView.touchDelegate = self;
    _isExecuting = NO;
}

-(void) mapView:(AGSMapView *)mapView didMoveTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features {
    if(_isExecuting)
        return;
    if(_lastStop==nil){
        _lastStop = [self addStop:mappoint];
    }else{
        _lastStop.geometry = mappoint;
    }
    _isExecuting = YES;
    [self routeBtnClicked:nil];
    NSLog(@"ROUTING");
}

#pragma mark - AGSMapViewLayerDelegate 
-(void)mapViewDidLoad:(AGSMapView *)mapView{
//    AGSMutablePoint *mp = [[AGSMutablePoint alloc] initWithSpatialReference:self.mapView.spatialReference];
//	self.sketchLayer = [[AGSSketchGraphicsLayer alloc] initWithGeometry:mp];
//	// add sketch layer to the map
//	[self.mapView addMapLayer:self.sketchLayer withName:@"sketchLayer"];
//    // set the mapView's touchDelegate to the sketchLayer so we get points symbolized when sketching
//	self.mapView.touchDelegate = self.sketchLayer;
//    //Register for "Geometry Changed" notifications
//	//We want to enable/disable UI elements when sketch geometry is modified
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:nil];
	
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
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didRetrieveDefaultRouteTaskParameters:(AGSRouteTaskParameters *)routeParams {
	self.routeTaskParams = routeParams;
    
    // this generalizes the route graphics that are returned
	self.routeTaskParams.outputGeometryPrecision = 5.0;
	self.routeTaskParams.outputGeometryPrecisionUnits = AGSUnitsMeters;
    
    // return the graphic representing the entire route, generalized by the previous
    // 2 properties: outputGeometryPrecision and outputGeometryPrecisionUnits
	self.routeTaskParams.returnRouteGraphics = YES;
    
	// this returns turn-by-turn directions
	self.routeTaskParams.returnDirections = YES;
	
	// the next 3 lines will cause the task to find the
	// best route regardless of the stop input order
	self.routeTaskParams.findBestSequence = YES;
	self.routeTaskParams.preserveFirstStop = YES;
	self.routeTaskParams.preserveLastStop = NO;
	
	// since we used "findBestSequence" we need to
	// get the newly reordered stops
	self.routeTaskParams.returnStopGraphics = YES;
	
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
	// Click Retry to attempt to retrieve the defaults again
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" 
												 message:@"Failed to retrieve default route parameters" 
												delegate:self 
									   cancelButtonTitle:@"Ok" otherButtonTitles:@"Retry",nil];
	[av show];
}


//
// route was solved
//
- (void)routeTask:(AGSRouteTask *)routeTask operation:(NSOperation *)op didSolveWithResult:(AGSRouteTaskResult *)routeTaskResult {
	
    // update our banner with status
    [self updateDirectionsLabel:@"Routing completed"];
	
	// we know that we are only dealing with 1 route...
	AGSRouteResult* newResult = [routeTaskResult.routeResults lastObject];
	if (newResult) {
        
        if(self.routeResult.routeGraphic)
            [self.graphicsLayer removeGraphic:self.routeResult.routeGraphic];
        
        self.routeResult = newResult;
		// symbolize the returned route graphic
		self.routeResult.routeGraphic.symbol = [self routeSymbol];
        
        if(self.routeResult.routeGraphic.geometry.spatialReference!=self.mapView.spatialReference){
            self.routeResult.routeGraphic.geometry = [[AGSGeometryEngine defaultGeometryEngine]projectGeometry:self.routeResult.routeGraphic.geometry toSpatialReference:self.mapView.spatialReference];
        }

        
        // add the route graphic to the graphic's layer
		[self.graphicsLayer addGraphic:self.routeResult.routeGraphic];
        

		// enable the next button so the user can traverse directions
		self.nextBtn.enabled = YES;
		
//        // remove the stop graphics from the graphics layer
//        // careful not to attempt to mutate the graphics array while
//        // it is being enumerated
//		NSMutableArray *graphics = [self.graphicsLayer.graphics mutableCopy];
//		for (AGSGraphic *g in graphics) {
//			if ([g isKindOfClass:[AGSStopGraphic class]]) {
//				[self.graphicsLayer removeGraphic:g];
//			}
//		}
//		
//        // add the returned stops...it's possible these came back in a different order
//        // because we specified findBestSequence
//		for (AGSStopGraphic *sg in self.routeResult.stopGraphics) {
//            
//            // get the sequence from the attribetus
//            BOOL exists;
//			NSInteger sequence = [sg attributeAsIntForKey:@"Sequence" exists:&exists];
//            
//            // create a composite symbol using the sequence number
//			sg.symbol = [self stopSymbolWithNumber:sequence];
//            
//            // add the graphic
//			[self.graphicsLayer addGraphic:sg];
//		}
        _isExecuting = NO;
	}
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

#pragma mark UIAlertViewDelegate

//
// If the user clicks 'Retry' then we should attempt to retrieve the defaults again
//
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	
	// see which button was clicked, Ok or Retry
	// Ok		index 0
	// Retry	index 1
	switch (buttonIndex) {
		case 1:  // Retry
			[self.routeTask retrieveDefaultRouteTaskParameters];
		default:
			break;
	}
}

#pragma mark Misc

- (void)respondToGeomChanged: (NSNotification*) notification {
	//Enable/disable UI elements appropriately
	self.addBtn.enabled = [self.sketchLayer.geometry isValid];
	self.clearSketchBtn.enabled = ![self.sketchLayer.geometry isEmpty];
}

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
//	AGSTextSymbol *ts = [[[AGSTextSymbol alloc] initWithTextTemplate:[NSString stringWithFormat:@"%d", stopNumber] 
//															   color:[UIColor blackColor]] autorelease];
//	ts.vAlignment = AGSTextSymbolVAlignmentMiddle;
//	ts.hAlignment = AGSTextSymbolHAlignmentCenter;
//	ts.fontSize	= 16;
//	ts.fontWeight = AGSTextSymbolFontWeightBold;
//	[cs.symbols addObject:ts];
	
	return cs;
}

//
// default symbol for the barriers
//
- (AGSCompositeSymbol*)barrierSymbol {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
	AGSSimpleLineSymbol *sls = [AGSSimpleLineSymbol simpleLineSymbol];
	sls.color = [UIColor redColor];
	sls.style = AGSSimpleLineSymbolStyleSolid;
	sls.width = 2;
	
	AGSSimpleFillSymbol *sfs = [AGSSimpleFillSymbol simpleFillSymbol];
	sfs.outline = sls;
	sfs.style = AGSSimpleFillSymbolStyleSolid;
	sfs.color = [[UIColor redColor] colorWithAlphaComponent:0.45];
	[cs addSymbol:sfs];
	
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
- (IBAction)resetBtnClicked:(id)sender {
	[self reset];
}

//
// reset the sample so we can perform another route
//
- (void)reset {
	
	// set stop counter back to 0
	_numStops = 0;
	
	// set barrier counter back to 0
	_numBarriers = 0;
	
	// reset direction index
	_directionIndex = 0;
		
	// remove all graphics
	[self.graphicsLayer removeAllGraphics];
	
	// reset sketchModeSegCtrl to point
	self.sketchModeSegCtrl.selectedSegmentIndex = 0;
	for (int i =0; i<self.sketchModeSegCtrl.numberOfSegments; i++) {
		[self.sketchModeSegCtrl setEnabled:YES forSegmentAtIndex:i];
	}
	
	// reset directions label
	[self updateDirectionsLabel:@"Tap on the map to add stops & barriers"];
    
	//
    // if the sketch layer was removed/nil'd out, re-add it
	if (!self.sketchLayer) {
		AGSGeometry *geometry;
		if (self.sketchModeSegCtrl.selectedSegmentIndex == 0) {
			geometry = [[AGSMutablePoint alloc] initWithSpatialReference:self.mapView.spatialReference];
		}
		else {
			geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
		}
		self.sketchLayer = [[AGSSketchGraphicsLayer alloc] initWithGeometry:geometry];
		[self.mapView insertMapLayer:self.sketchLayer withName:@"sketchLayer" atIndex:1];
		self.mapView.touchDelegate = self.sketchLayer;
	}
	else {
		// clear the sketch layer and reset it to a point
		[self.sketchLayer clear];
	}	
	
    // disable the next/prev direction buttons
	self.nextBtn.enabled = NO;
	self.prevBtn.enabled = NO;
}

- (void)removeStopClicked {
	if ([self.selectedGraphic isKindOfClass:[AGSStopGraphic class]]) {
		// we have a stop
		_numStops--;
	}
	else {
		//barrier
		_numBarriers--;
	}
	
	[self.graphicsLayer removeGraphic:self.selectedGraphic];
	self.selectedGraphic = nil;
    
    // hide the callout
	self.mapView.callout.hidden = YES;
}

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
            _numStops++;
            symbol = [self stopSymbolWithNumber:_numStops];
			AGSStopGraphic *stopGraphic = [AGSStopGraphic graphicWithGeometry:geometry
																	   symbol:symbol
																   attributes:attributes
														 infoTemplateDelegate:nil];
			stopGraphic.sequence = _numStops;
			//You can set additional properties on the stop here
			//refer to the conceptual helf for Routing task
			[self.graphicsLayer addGraphic:stopGraphic];
    return stopGraphic;
	
}
#pragma mark IBActions

//
// add a stop or barrier depending on the sketch layer's current geometry
//
- (IBAction)addStopOrBarrier:(id)sender {
	
	//grab the geometry, then clear the sketch
	AGSGeometry *geometry = [self.sketchLayer.geometry copy];	
	[self.sketchLayer clear];
	
	//Prepare symbol and attributes for the Stop/Barrier
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	AGSSymbol *symbol;
	
	switch (AGSGeometryTypeForGeometry(geometry)) {
		//Stop
		case AGSGeometryTypePoint:{
            _numStops++;
            symbol = [self stopSymbolWithNumber:_numStops];
			AGSStopGraphic *stopGraphic = [AGSStopGraphic graphicWithGeometry:geometry 
																	   symbol:symbol 
																   attributes:attributes 
														 infoTemplateDelegate:nil];
			stopGraphic.sequence = _numStops;
			//You can set additional properties on the stop here
			//refer to the conceptual helf for Routing task
			[self.graphicsLayer addGraphic:stopGraphic];
			break;
		//Barrier
		}
        case AGSGeometryTypePolygon:{
			_numBarriers++;
			[attributes setValue:[NSNumber numberWithInt:_numBarriers] forKey:@"barrierNumber"];
			//you can set additional properties on the barrier here
			//refer to the conceptual helf for Routing task
			symbol = [self barrierSymbol];
			AGSGraphic *g = [AGSGraphic graphicWithGeometry:geometry 
													 symbol:symbol
												 attributes:attributes
									   infoTemplateDelegate:nil];
			[self.graphicsLayer addGraphic:g];
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
	
	if (!self.sketchLayer) {
		return;
	}
	
	UISegmentedControl *segCtrl = (UISegmentedControl*)sender;
	
	switch (segCtrl.selectedSegmentIndex) {
		case 0:
			NSLog(@"stops selected");
			[self.sketchLayer clear];
			self.sketchLayer.geometry = [[AGSMutablePoint alloc] initWithSpatialReference:self.mapView.spatialReference];
			break;
		case 1:
			NSLog(@"barriers selected");
			[self.sketchLayer clear];
			self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
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
	
//    // if we have a sketch layer on the map, remove it
//	if ([self.mapView.mapLayers containsObject:self.sketchLayer]) {
//		[self.mapView removeMapLayerWithName:self.sketchLayer.name];
//		self.mapView.touchDelegate = nil;
//		self.sketchLayer = nil;
//		
//		//also disable the sketch control so that user cannot sketch
//		self.sketchModeSegCtrl.selectedSegmentIndex = -1;
//		for (int i =0; i<self.sketchModeSegCtrl.numberOfSegments; i++) {
//			[self.sketchModeSegCtrl setEnabled:NO forSegmentAtIndex:i];
//		}
//		
//		
//	}
	
	NSMutableArray *stops = [NSMutableArray array];
	NSMutableArray *polygonBarriers = [NSMutableArray array];

	// get the stop, barriers for the route task
	for (AGSGraphic *g in self.graphicsLayer.graphics) {
        // if it's a stop graphic, add the object to stops
		if ([g isKindOfClass:[AGSStopGraphic class]]) {
			[stops addObject:g];
		}
        
//        // if "barrierNumber" exists in the attributes, we know it is a barrier
//        // so add the object to our barriers
//		else if ([g attributeAsStringForKey:@"barrierNumber"]) {
//			[polygonBarriers addObject:g];
//		}
	}
	
	// set the stop and polygon barriers on the parameters object
	if (stops.count > 0) {
		[self.routeTaskParams setStopsWithFeatures:stops];
	}
	
//	if (polygonBarriers.count > 0) {
//		[self.routeTaskParams setPolygonBarriersWithFeatures:polygonBarriers];
//	}
	

	
	// you can also set additional properties here that should
	// be considered during analysis.
	// See the conceptual help for Routing task.
	
	// execute the route task
	_op = [self.routeTask solveWithParameters:self.routeTaskParams];
}

//
// clear the sketch layer
//
- (IBAction)clearSketchLayer:(id)sender {
	[self.sketchLayer clear];
}


//
// move to the next direction in the direction set
//
- (IBAction)nextBtnClicked:(id)sender {
	_directionIndex++;
	
    // remove current direction graphic, so we can display next one
	if ([self.graphicsLayer.graphics containsObject:self.currentDirectionGraphic]) {
		[self.graphicsLayer removeGraphic:self.currentDirectionGraphic];
	}
	
    // get current direction and add it to the graphics layer
	AGSDirectionSet *directions = self.routeResult.directions;
	self.currentDirectionGraphic = [directions.graphics objectAtIndex:_directionIndex];
	self.currentDirectionGraphic.symbol = [self currentDirectionSymbol];
	[self.graphicsLayer addGraphic:self.currentDirectionGraphic];
	
    // update banner
	[self updateDirectionsLabel:self.currentDirectionGraphic.text];
	
    // zoom to envelope of the current direction (expanded by factor of 1.3)
	AGSMutableEnvelope *env = [self.currentDirectionGraphic.geometry.envelope mutableCopy];
	[env expandByFactor:1.3];
	[self.mapView zoomToEnvelope:env animated:YES];
	
    // determine if we need to disable a next/prev button
	if (_directionIndex >= self.routeResult.directions.graphics.count - 1) {
		self.nextBtn.enabled = NO;
	}
	if (_directionIndex > 0) {
		self.prevBtn.enabled = YES;
	}

}

- (IBAction)prevBtnClicked:(id)sender {
	_directionIndex--;
	
    // remove current direction
	if ([self.graphicsLayer.graphics containsObject:self.currentDirectionGraphic]) {
		[self.graphicsLayer removeGraphic:self.currentDirectionGraphic];
	}
    
	// get next direction
	AGSDirectionSet *directions = self.routeResult.directions;
	self.currentDirectionGraphic = [directions.graphics objectAtIndex:_directionIndex];
	self.currentDirectionGraphic.symbol = [self currentDirectionSymbol];
	[self.graphicsLayer addGraphic:self.currentDirectionGraphic];
	
    // update banner text
	[self updateDirectionsLabel:self.currentDirectionGraphic.text];
	
    // zoom to env factored by 1.3
	AGSMutableEnvelope *env = [self.currentDirectionGraphic.geometry.envelope mutableCopy];
	[env expandByFactor:1.3];
	[self.mapView zoomToEnvelope:env animated:YES];

    // determine if we need to disable next/prev button
	if (_directionIndex <= 0) {
		self.prevBtn.enabled = NO;
	}
	if (_directionIndex < self.routeResult.directions.graphics.count - 1) {
		self.nextBtn.enabled = YES;
	}
}



@end
