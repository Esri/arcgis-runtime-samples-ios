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

#import "ClosestFacilitySampleViewController.h"
#import "Parameters.h"

#define kBaseMap @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
#define kFacilitiesLayerURL @"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Louisville/LOJIC_PublicSafety_Louisville/MapServer/1"

#define kCFTask @"http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Network/USA/NAServer/Closest%20Facility"

#define kSettingsSegueName @"SettingsSegue"

@interface ClosestFacilitySampleViewController ()

@property (nonatomic, strong) Parameters *parameters;

@end

@implementation ClosestFacilitySampleViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    
	//Add the basemap - the tiled layer 
	NSURL *mapUrl = [NSURL URLWithString:kBaseMap];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
	
    //Zooming to an initial envelope with the specified spatial reference of the map.
	AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-9555545.779983964 ymin:4593330.340739982 xmax:-9531085.930932742 ymax:4628491.373751115 
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:YES];
    
    //important step in detecting the touch events on the map
    self.mapView.touchDelegate = self;
    
    //step to call the mapViewDidLoad method to do the initiation of Closest Facility Task.
    self.mapView.layerDelegate = self;
    
    
    //add  graphics layer for showing results of the closest facility analysis
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"ClosestFacility"];

    // set the callout delegate so we can display callouts
    // updated the callout to the map instead of the layer.
    self.mapView.callout.delegate = self;
    
    
    //creating the facilities (fire stations) layer
    self.facilitiesLayer = [AGSFeatureLayer featureServiceLayerWithURL:[NSURL URLWithString:kFacilitiesLayerURL] mode:AGSFeatureLayerModeSnapshot];
    
    //specifying the symbol for the fire stations. 
    AGSSimpleRenderer* renderer = [AGSSimpleRenderer simpleRendererWithSymbol:[AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"FireStation.png"]];
    self.facilitiesLayer.renderer = renderer;    
    self.facilitiesLayer.outFields = @[@"*"]; 
    
    //adding the fire stations feature layer to the map view. 
    [self.mapView addMapLayer:self.facilitiesLayer withName:@"Facilities"];
    
    // add sketch layer to the map
	AGSMutablePoint *mp = [[AGSMutablePoint alloc] initWithSpatialReference:[AGSSpatialReference webMercatorSpatialReference]];
	self.sketchLayer = [[AGSSketchGraphicsLayer alloc] initWithGeometry:mp];
	[self.mapView addMapLayer:self.sketchLayer withName:@"sketchLayer"];
	
	//Register for "Geometry Changed" notifications 
	//We want to enable/disable UI elements when sketch geometry is modified
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:nil];
	
	
	// set the mapView's touchDelegate to the sketchLayer so we get points symbolized when sketching
	self.mapView.touchDelegate = self.sketchLayer;
    
    // create a custom callout view using a button with an image
	// this is to remove incidents and barriers after we add them to the map
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 24)];
	UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	deleteBtn.frame = CGRectMake(8, 0, 24, 24);
	[deleteBtn setImage:[UIImage imageNamed:@"remove24.png"] forState:UIControlStateNormal];
	[deleteBtn addTarget:self 
					  action:@selector(removeIncidentBarrierClicked) 
			forControlEvents:UIControlEventTouchUpInside];
    [customView addSubview:deleteBtn];
	self.deleteCalloutView = customView;
    
    
    // initialize incident counter
	_numIncidents = 0;
	
	// initialize barrier counter
	_numBarriers = 0;

    //preparing the Settings View Controller
    self.settingsViewController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
    
    
    //instantiate the parameters object
    self.parameters = [[Parameters alloc] init];
    
    [super viewDidLoad];
}


- (void)viewDidUnload
{
 
    //remove the notification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark AGSMapViewLayerDelegate

- (void)mapViewDidLoad:(AGSMapView *) mapView {
	
    //set up the cf task
    self.cfTask = [AGSClosestFacilityTask closestFacilityTaskWithURL:[NSURL URLWithString:kCFTask]];
	self.cfTask.delegate = self; //required to respond to the cf task.
}


#pragma mark AGSCalloutDelegate

- (BOOL) callout:(AGSCallout *)callout willShowForFeature:(id<AGSFeature>)feature layer:(AGSLayer<AGSHitTestable> *)layer mapPoint:(AGSPoint *)mapPoint{
    AGSGraphic* graphic = (AGSGraphic*)feature;
    NSString *incidentNum = [graphic attributeAsStringForKey:@"incidentNumber"];
	NSString *barrierNum = [graphic attributeAsStringForKey:@"barrierNumber"];
    
    self.selectedGraphic = graphic;
    [self.sketchLayer clear];
    
	if (incidentNum || barrierNum) {
		self.mapView.callout.customView = self.deleteCalloutView;
        return YES;
    }
    else{
        return NO;
    }
}

 
//// determine if we should show a callout
//- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForGraphic:(AGSGraphic *)graphic {
//	
//    
//    
//	NSString *incidentNum = [graphic attributeAsStringForKey:@"incidentNumber"];
//	NSString *barrierNum = [graphic attributeAsStringForKey:@"barrierNumber"];
//    
//    self.selectedGraphic = graphic;
//    [self.sketchLayer clear];
//    
//	if (incidentNum || barrierNum) {
//		self.mapView.callout.customView = self.deleteCalloutView;
//        return YES;
//    }
//    else{
//        return NO;
//    }
//    
//}
//
//// if we showed a callout, clear the sketch layer
//- (void)mapView:(AGSMapView *)mapView didShowCalloutForGraphic:(AGSGraphic *)graphic {
//	[self.sketchLayer clear];
//}

#pragma mark AGSClosestFacilityTaskDelegate

//if the solveClosestFacilityWithResult operation completed successfully
- (void)closestFacilityTask:(AGSClosestFacilityTask *) closestFacilityTask operation:(NSOperation *) op didSolveClosestFacilityWithResult:(AGSClosestFacilityTaskResult *) closestFacilityTaskResult {
    
    //remove previous graphics from the graphics layer        
    //if "barrierNumber" exists in the attributes, we know it is a barrier graphic
    //if "incidentNumber" exists in the attributes, we know it is an incident graphic
    //so leave that graphic and go to the next one
    //careful not to attempt to mutate the graphics array while
    //it is being enumerated
    NSMutableArray *graphics = [self.graphicsLayer.graphics mutableCopy];
    for (AGSGraphic *g in graphics) {
        if (!([g attributeAsStringForKey:@"barrierNumber"] ||
              [g attributeAsStringForKey:@"incidentNumber"])) {
            [self.graphicsLayer removeGraphic:g];
        }
    }

    
    //iterate through the closest facility results array in the closestFacilityTaskResult returned by the task
    for (AGSClosestFacilityResult *cfResult in closestFacilityTaskResult.closestFacilityResults) {
        if (cfResult) {
            
            //symbolize the returned route graphic
            cfResult.routeGraphic.symbol = [self routeSymbol];
            
            //add the route graphic to the graphics layer
            [self.graphicsLayer addGraphic:cfResult.routeGraphic];
            
        }
    }
	
    //stop activity indicator
    [SVProgressHUD dismiss];
    
    //changing the status message label. 
    self.statusMessageLabel.text = @"Tap reset to start over";
    
    //zoom to graphics layer extent
    AGSMutableEnvelope *env = [self.graphicsLayer.fullEnvelope mutableCopy];
    [env expandByFactor:1.2];
    [self.mapView zoomToEnvelope:env animated:YES];     
}

//if error encountered while executing cf task
- (void)closestFacilityTask:(AGSClosestFacilityTask *) closestFacilityTask operation:(NSOperation *) op didFailSolveWithError:(NSError *) error {
    //stop activity indicator
    [SVProgressHUD dismiss];
    
    //show error message
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                     message:[error localizedDescription]
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];

}

//if retrieveDefaultClosestFacilityTaskParameters operation completed successfully
- (void)closestFacilityTask:(AGSClosestFacilityTask *) closestFacilityTask operation:(NSOperation *) op didRetrieveDefaultClosestFacilityTaskParameters:(AGSClosestFacilityTaskParameters *) closestFacilityParams {
    
    //specify some custom parameters
    
    //Number of facilities to be returned
    closestFacilityParams.defaultTargetFacilityCount = [self.parameters.facilityCount intValue];
    
    //The kind of the cuttoff attribute - Time, Length etc. We are using Time
    closestFacilityParams.impedanceAttributeName = @"Time";
    //Specify the cuttoff travelling time to the facility. In minutes.
    closestFacilityParams.defaultCutoffValue = [self.parameters.cutoffTime doubleValue];
    
    //Specify the travel direction. 
    closestFacilityParams.travelDirection = AGSNATravelDirectionFromFacility;
    
    //specifying the spatial reference output
    closestFacilityParams.outSpatialReference = self.mapView.spatialReference;
    
    //setting the incidents for the CF task. We have only one here - the tapped location.
    
    NSMutableArray *incidents = [NSMutableArray array];
	NSMutableArray *polygonBarriers = [NSMutableArray array];
    
	// get the incidents, barriers for the cf task
	for (AGSGraphic *g in self.graphicsLayer.graphics) {
        // if it's a incident graphic, add the object to incidents
		if ([g attributeAsStringForKey:@"incidentNumber"]) {
			[incidents addObject:g];
		}
        
        // if "barrierNumber" exists in the attributes, we know it is a barrier
        // so add the object to our barriers
		else if ([g attributeAsStringForKey:@"barrierNumber"]) {
			[polygonBarriers addObject:g];
		}
	}
	
	// set the incidents and polygon barriers on the parameters object
	if (incidents.count > 0) {
		[closestFacilityParams setIncidentsWithFeatures:incidents];
	}
	
	if (polygonBarriers.count > 0) {
		[closestFacilityParams setPolygonBarriersWithFeatures:polygonBarriers];
	}
    
    //specify the features that need to be used as the facilities. We use the fire stations layer features. 
    [closestFacilityParams setFacilitiesWithFeatures:self.facilitiesLayer.graphics];
    
    //calls the solveClosestFacilityWithParameters with modified params. 
    self.cfOp = [self.cfTask solveClosestFacilityWithParameters:closestFacilityParams];
}

//if error encountered while executing cf task's retrieveDefaultClosestFacilityTaskParameters operation
- (void)closestFacilityTask:(AGSClosestFacilityTask *) closestFacilityTask operation:(NSOperation *) op didFailToRetrieveDefaultClosestFacilityTaskParametersWithError:(NSError *) error {
    
    //stop activity indicator
    [SVProgressHUD dismiss];
    
    //show error message
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                     message:[error localizedDescription]
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];

}

#pragma mark UIAlertViewDelegate Methods 

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonInde {
    
    //cancel the cf operation
    [self.cfOp cancel];
    self.cfOp = nil;
    
}

#pragma mark Action Methods

// reset button clicked
- (IBAction)resetBtnClicked:(id)sender {
	[self reset];
}

//
// add a incident or barrier depending on the sketch layer's current geometry
//
- (IBAction)addIncidentOrBarrier:(id)sender {
	
	//grab the geometry, then clear the sketch
	AGSGeometry *geometry = [self.sketchLayer.geometry copy];	
	[self.sketchLayer clear];
	
	//Prepare symbol and attributes for the Incident/Barrier
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	AGSSymbol *symbol;
	AGSGraphic *g;
	switch (AGSGeometryTypeForGeometry(geometry)) {
            //Incident
		case AGSGeometryTypePoint:
            _numIncidents++;
            //ading an attribute for the incident graphic
            [attributes setValue:@(_numIncidents) forKey:@"incidentNumber"];
            
            //getting the symbol for the incident graphic
            symbol = [self incidentSymbol];
            g = [AGSGraphic graphicWithGeometry:geometry symbol:symbol attributes:attributes];
			//You can set additional properties on the incident here
			[self.graphicsLayer addGraphic:g];
            //enable the findFCButton
            self.findCFButton.enabled = YES;
            
			break;
            //Barrier
		case AGSGeometryTypePolygon:
			_numBarriers++;
            
			[attributes setValue:@(_numBarriers) forKey:@"barrierNumber"];
			//getting the symbol for the incident graphic
			symbol = [self barrierSymbol];
			g = [AGSGraphic graphicWithGeometry:geometry 
													 symbol:symbol
												 attributes:attributes];
			[self.graphicsLayer addGraphic:g];
			break;
        default:
            break;
	}
	
}

//
// if our segment control was changed, then the sketch layer geometry needs to 
// be updated to reflect that (point for incidents and polygon for barriers)
//
- (IBAction)incidentsBarriersValChanged:(id)sender {
	
	if (!self.sketchLayer) {
		return;
	}
	
	UISegmentedControl *segCtrl = (UISegmentedControl*)sender;
	
	switch (segCtrl.selectedSegmentIndex) {
		case 0:
			[self.sketchLayer clear];
            
            //geometry for sketching incident points
			self.sketchLayer.geometry = [[AGSMutablePoint alloc] initWithSpatialReference:self.mapView.spatialReference];
			break;
		case 1:
			[self.sketchLayer clear];
            
            //geometry for sketching barrier polygons
			self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
			break;
            
		default:
			break;
	}
}


// perform the cf task's retrieve default parameters operation
- (IBAction)findCFButtonClicked:(id)sender {
	
    // update the status message
	self.statusMessageLabel.text = @"Finding closest facilities";
	
    // if we have a sketch layer on the map, remove it
	if ([self.mapView.mapLayers containsObject:self.sketchLayer]) {
		[self.mapView removeMapLayerWithName:self.sketchLayer.name];
		self.mapView.touchDelegate = nil;
		self.sketchLayer = nil;
		
		//also disable the sketch control so that user cannot sketch
		self.sketchModeSegCtrl.selectedSegmentIndex = -1;
		for (int i =0; i<self.sketchModeSegCtrl.numberOfSegments; i++) {
			[self.sketchModeSegCtrl setEnabled:NO forSegmentAtIndex:i];
		}
		
		
	}
    
    //retrieves the default parameters for the closest facility task from the server
    //the caOp property will keep tract of the operation in case we need to cancel it at any point. 
    self.cfOp = [self.cfTask retrieveDefaultClosestFacilityTaskParameters]; 
    
#warning
    [SVProgressHUD showWithStatus:@"Search for closest facilities" ];
//	[self.activityAlertView show];
	
}


// clear the sketch layer
- (IBAction)clearSketchLayer:(id)sender {
	[self.sketchLayer clear];
}

- (IBAction)resetButttonClicked:(id)sender {
    [self reset];
}



#pragma mark Helper Methods

- (void)respondToGeomChanged: (NSNotification*) notification {
	//Enable/disable UI elements appropriately
	self.addButton.enabled = [self.sketchLayer.geometry isValid];
	self.clearSketchButton.enabled = ![self.sketchLayer.geometry isEmpty];
}


// reset the sample so we can perform another analysis
- (void)reset {
	
	// set incident counter back to 0
	_numIncidents = 0;
	
	// set barrier counter back to 0
	_numBarriers = 0;
    
	// remove all graphics
	[self.graphicsLayer removeAllGraphics];
	
	// reset sketchModeSegCtrl to point
	self.sketchModeSegCtrl.selectedSegmentIndex = 0;
	for (int i =0; i<self.sketchModeSegCtrl.numberOfSegments; i++) {
		[self.sketchModeSegCtrl setEnabled:YES forSegmentAtIndex:i];
	}
    
    //disable the findCFButton
    self.findCFButton.enabled = NO;
	
	// reset directions label
	self.statusMessageLabel.text = @"Tap on the map to create incidents";
    
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
    
    self.statusMessageLabel.text = @"Add incidents and barriers";
}

- (void)removeIncidentBarrierClicked {
    
    //get the incident number and the barrier number
    NSString *incidentNum = [self.selectedGraphic attributeAsStringForKey:@"incidentNumber"];
	NSString *barrierNum = [self.selectedGraphic attributeAsStringForKey:@"barrierNumber"];
    
    //redunce the incident number is the removed item is an incident point
	if (incidentNum) {
		_numIncidents--;
        if(_numIncidents == 0)
            //disable the findCFButton
            self.findCFButton.enabled = NO;
    }
    
     //redunce the barrier number is the removed item is a barrier polygon
    if(barrierNum)        
		_numBarriers--;
	
    //remove the selected graphic from the layer
	[self.graphicsLayer removeGraphic:self.selectedGraphic];
    
    
    //nil out the selected graphic property. 
	self.selectedGraphic = nil;
    
    // hide the callout
	self.mapView.callout.hidden = YES;
}

// create a composite symbol with a number
- (AGSCompositeSymbol*)incidentSymbol {
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
	
    // add number as a text symbol
//	AGSTextSymbol *ts = [[[AGSTextSymbol alloc] initWithTextTemplate:@"${incidentNumber}" 
//                          
//															   color:[UIColor blackColor]] autorelease];
//	ts.vAlignment = AGSTextSymbolVAlignmentMiddle;
//	ts.hAlignment = AGSTextSymbolHAlignmentCenter;
//	ts.fontSize	= 16;
//	ts.fontWeight = AGSTextSymbolFontWeightBold;
//	[cs.symbols addObject:ts];
	
	return cs;
}

//generates the symbol for the routes. 
- (AGSCompositeSymbol*)routeSymbol {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
    //the outline symbol
	AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls1.color = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
	sls1.style = AGSSimpleLineSymbolStyleSolid;
	sls1.width = 8;
	[cs addSymbol:sls1];
	
    //the color of the route. 
	AGSSimpleLineSymbol *sls2 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls2.color = [UIColor colorWithRed:0.3 green:0.3 blue:1.0 alpha:0.5];
	sls2.style = AGSSimpleLineSymbolStyleSolid;
	sls2.width = 4;
	[cs addSymbol:sls2];
	
	return cs;
}

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
//	[cs.symbols addObject:ts];
	
	return cs;
    
}

#pragma mark -

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSettingsSegueName]) {
        SettingsViewController *controller = [segue destinationViewController];
        controller.parameters = self.parameters;
        
        //if ipad show formsheet
        if ([[AGSDevice currentDevice] isIPad]) {
            controller.modalPresentationStyle = UIModalPresentationFormSheet;
            controller.view.superview.bounds = CGRectMake(0, 0, 400, 300);
        }
    }
}


@end
