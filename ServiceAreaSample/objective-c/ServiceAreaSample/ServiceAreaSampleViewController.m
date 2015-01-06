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
#import "ServiceAreaSampleViewController.h"
#import "Parameters.h"
#import "SVProgressHUD.h"

#define kDefaultMap @"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
#define kFacilitiesLayerURL @"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Louisville/LOJIC_PublicSafety_Louisville/MapServer/1"
#define kSATask @"http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Network/USA/NAServer/Service%20Area"
#define kSettingsSegueIdentifier @"SettingsSegue"

@interface ServiceAreaSampleViewController ()

@property (nonatomic, strong) Parameters *parameters;

@end

@implementation ServiceAreaSampleViewController

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
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
 	//Add the basemap - the tiled layer 
	NSURL *mapUrl = [NSURL URLWithString:kDefaultMap];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
	
    //Zooming to an initial envelope with the specified spatial reference of the map.
	AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-9555545.779983964 ymin:4593330.340739982 xmax:-9531085.930932742 ymax:4628491.373751115 
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:YES];
    
    //important step in detecting the touch events on the map
    self.mapView.touchDelegate = self;
    
    //step to call the mapViewDidLoad method to do the initiation of Service Area Task.
    self.mapView.layerDelegate = self;
    
    //set the mapView's callout Delegate so we can display callouts
    self.mapView.callout.delegate = self;
    
    //add  graphics layer for showing results of the service area analysis
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"ServiceArea"];
    

    
    //creating the fire stations layer
    self.facilitiesLayer = [AGSFeatureLayer featureServiceLayerWithURL:[NSURL URLWithString:kFacilitiesLayerURL] mode:AGSFeatureLayerModeSnapshot];
    
    //specifying the symbol for the fire stations. 
    AGSSimpleRenderer* renderer = [AGSSimpleRenderer simpleRendererWithSymbol:[AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"FireStation.png"]];
    self.facilitiesLayer.renderer = renderer;    
    self.facilitiesLayer.outFields = [NSArray arrayWithObject:@"*"];    
    
    //adding the fire stations feature layer to the map view. 
    [self.mapView addMapLayer:self.facilitiesLayer withName:@"Facilities"];
    
    // create a custom callout view for barriers using a button with an image and a label
	// this is to remove barriers after we add them to the map
    UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 24)];
	UIButton *removeBarrierButton = [UIButton buttonWithType:UIButtonTypeCustom];
	removeBarrierButton.frame = CGRectMake(0, 0, 24, 24);
	[removeBarrierButton setImage:[UIImage imageNamed:@"remove24.png"] forState:UIControlStateNormal];
	[removeBarrierButton addTarget:self 
					  action:@selector(removeBarrierClicked) 
			forControlEvents:UIControlEventTouchUpInside];    
    [customView addSubview:removeBarrierButton];
    
    //creating the label
    UILabel *removeBarrierLabel = [[UILabel alloc] init];
    removeBarrierLabel.frame = CGRectMake(30, 0, 110, 24);
    removeBarrierLabel.backgroundColor = [UIColor clearColor];
    removeBarrierLabel.textColor = [UIColor redColor];
    removeBarrierLabel.text = @"Delete Barrier";
    [customView addSubview:removeBarrierLabel];

    //assign the custom view as the callout view
	self.barrierCalloutView = customView;
    
    // create a custom callout view for facilities using a button with a title
	// this is to find service area
    UIView *customViewFacilities = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 24)];
	UIButton *findSAButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	findSAButton.frame = CGRectMake(5, 0, 140, 24);
	[findSAButton setTitle:@"Find Service Area" forState:UIControlStateNormal];
	[findSAButton addTarget:self 
                            action:@selector(findServiceArea) 
                  forControlEvents:UIControlEventTouchUpInside];    
    [customViewFacilities addSubview:findSAButton];
    
    //assign the custom view as the callout view
	self.facilitiesCalloutView = customViewFacilities;

    
    //Register for "Geometry Changed" notifications 
	//We want to enable/disable UI elements when sketch geometry is modified
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:nil];
    
    //instantiate a parameter object to feed values to the api
    self.parameters = [[Parameters alloc] init];
    
    // initialize barrier counter
	self.numBarriers = 0;
    
    [super viewDidLoad];
}


- (void)viewDidUnload
{
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
	
    //set up the service area task
    self.saTask = [AGSServiceAreaTask serviceAreaTaskWithURL:[NSURL URLWithString:kSATask]];
	self.saTask.delegate = self; //required to respond to the service area task.
}

#pragma mark AGSCalloutDelegate

- (BOOL) callout:(AGSCallout *)callout willShowForFeature:(id<AGSFeature>)feature layer:(AGSLayer<AGSHitTestable> *)layer mapPoint:(AGSPoint *)mapPoint{
    AGSGraphic* graphic = (AGSGraphic*)feature;
    
    //if the graphic that was tapped on belongs to the "Facilities" layer, show the callout without a custom view
    if([graphic.layer.name isEqualToString:@"Facilities"])
    {
        //we have to make sure that the sketch mode is not on.
        if(!self.sketchLayer)
        {
            self.selectedGraphic = graphic;
            self.mapView.callout.customView = self.facilitiesCalloutView;
            return YES;
        }
    }
    
    //if the graphic that was tapped on belongs to the graphics layer and that it is a barrier graphic, show the callout with a custom view
    else
    {
        //getting the barrier number from the attributes dictionary of the graphic
        NSString *barrierNum = [graphic attributeAsStringForKey:@"barrierNumber"];
        
        if (barrierNum) {
            
            //we have to make sure that the sketch mode is not on.
            if(!self.sketchLayer)
            {
                self.selectedGraphic = graphic;
                
                //assign the custom callout that we created earlier, to the barrier graphic's callout view.
                self.mapView.callout.customView = self.barrierCalloutView;
                
                //at this point, the sketch layer is cleared and the barrier is ready for deletion is required.
                
                return YES;
            }
            
        }
    }
	
	return NO;
}



#pragma mark AGSServiceAreaTaskDelegate

//if the solveServiceAreaTaskWithResult operation completed successfully
- (void)serviceAreaTask:(AGSServiceAreaTask *) serviceAreaTask operation:(NSOperation *) op didSolveServiceAreaWithResult:(AGSServiceAreaTaskResult *) serviceAreaTaskResult {
    
    //remove previous graphics from the graphics layer        
    //if "barrierNumber" exists in the attributes, we know it is a barrier
    //so leave that graphic and go to the next one
    //careful not to attempt to mutate the graphics array while
    //it is being enumerated
    NSMutableArray *graphics = [self.graphicsLayer.graphics mutableCopy];
    for (AGSGraphic *g in graphics) {
        if (![g attributeAsStringForKey:@"barrierNumber"]) {
            [self.graphicsLayer removeGraphic:g];
        }
    }
    
    //iterate through the service area results array in the serviceAreaTaskResult returned by the task     
    for (int i=0; i < [serviceAreaTaskResult.serviceAreaPolygons count]; i++) {
        AGSGraphic *saResultPolygon = [serviceAreaTaskResult.serviceAreaPolygons objectAtIndex:i];
        //if the first one, it is the first time break polygon
        if(i == 0)
            saResultPolygon.symbol = [self serviceAreaSymbolBreak1]; //get the appropriate symbol
        
        //if the second one, it is the second time break polygon
        else
            saResultPolygon.symbol = [self serviceAreaSymbolBreak2]; //get the appropriate symbol
        
        //add the service area graphic to the graphics layer
        [self.graphicsLayer addGraphic:saResultPolygon];
    }
	
    
    //stop activity indicator
    [SVProgressHUD dismiss];
    
    //hide the callout
    self.mapView.callout.hidden = YES;
    
    //zoom to service area graphics layer extent
    AGSMutableEnvelope *env = [self.graphicsLayer.fullEnvelope mutableCopy];
    [env expandByFactor:1.2];
    [self.mapView zoomToEnvelope:env animated:YES];  
    
    
}

//if error encountered while executing sa task
- (void)serviceAreaTask:(AGSServiceAreaTask *) serviceAreaTask operation:(NSOperation *) op didFailSolveWithError:(NSError *) error {
    
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

//if retrieveDefaultServiceAreaTaskParameters operation completed successfully
- (void)serviceAreaTask:(AGSServiceAreaTask *) serviceAreaTask operation:(NSOperation *) op didRetrieveDefaultServiceAreaTaskParameters:(AGSServiceAreaTaskParameters *) serviceAreaParams {
    
    //specify some custom parameters   
    //The kind of the cuttoff attribute - Time, Length etc. We are using Time
    serviceAreaParams.impedanceAttributeName = @"Time";
    
    //Specify the time breaks for the service area of the facility. In minutes.
    NSMutableArray* breaks = [[NSMutableArray alloc] init];
    //getting the breaks from the settingsViewController
    [breaks addObject:[NSNumber numberWithUnsignedInteger:self.parameters.firstTimeBreak]];
    [breaks addObject:[NSNumber numberWithUnsignedInteger:self.parameters.secondTimeBreak]];
    serviceAreaParams.defaultBreaks = breaks;
    
    //adding some restrictions to the service area analysis. Restrictions can be found on the rest endpoint of the service. 
    serviceAreaParams.restrictionAttributeNames = [NSArray arrayWithObjects:@"Non-routeable segments",@"Avoid passenger ferries",@"TurnRestriction",@"OneWay", nil];
    
    //Specify the travel direction. 
    serviceAreaParams.travelDirection = AGSNATravelDirectionFromFacility;
    
    //specifying the spatial reference output
    serviceAreaParams.outSpatialReference = self.mapView.spatialReference;
    
    //specify the selected facility for the service area task. 
    [serviceAreaParams setFacilitiesWithFeatures:[NSArray arrayWithObject:self.selectedGraphic]];
    
    //adding the barriers to the parameters
    NSMutableArray *polygonBarriers = [NSMutableArray array];
    // get the barriers for the service area task
	for (AGSGraphic *g in self.graphicsLayer.graphics) {
        if ([g attributeAsStringForKey:@"barrierNumber"]) {
			[polygonBarriers addObject:g];
		}
	}    
    if (polygonBarriers.count > 0) {
		[serviceAreaParams setPolygonBarriersWithFeatures:polygonBarriers];
	}
    
    //calls the solveServiceAreaWithParameters with modified params. 
    self.saOp = [self.saTask solveServiceAreaWithParameters:serviceAreaParams];
}

//if error encountered while executing sa task's retrieveDefaultServiceAreaTaskParameters operation
- (void)serviceAreaTask:(AGSServiceAreaTask *) serviceAreaTask operation:(NSOperation *) op didFailToRetrieveDefaultServiceAreaTaskParametersWithError:(NSError *) error {
    
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

//if the operation was cancelled. 
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonInde {
    
    //cancel the sa operation
    [self.saOp cancel];
    self.saOp = nil;
}

#pragma mark Action Methods


-(IBAction)findServiceArea {
        
    //retrieves the default parameters for the service area task from the server
    //the saOp property will keep tract of the operationm in case we need to cancel it at any point. 
    self.saOp = [self.saTask retrieveDefaultServiceAreaTaskParameters]; 
    
    //showing activity indicator
    [SVProgressHUD showWithStatus:@"Finding service area"];

}


//performed when the user taps on the remove barrier button on the barrier callout. 
- (IBAction)removeBarrierClicked {
	
    //barrier count decreases
    self.numBarriers--;	
	
    //remove the selected graphic
	[self.graphicsLayer removeGraphic:self.selectedGraphic];
    
    
    //release the selected graphic
	self.selectedGraphic = nil;
    
    //hide the callout
	self.mapView.callout.hidden = YES;
}

//if user clears everything on the map to start over. 
- (IBAction)clearAll:(id)sender {
    
    //set barrier counter back to 0
	self.numBarriers = 0;
    
	//remove all graphics
	[self.graphicsLayer removeAllGraphics];
    
	
	//reset activitySegControl to find service area mode
	self.activitySegControl.selectedSegmentIndex = 0;
	
	//reset status message label
    self.statusMessageLabel.text = @"Select the facility to find its service area";
    
    //nil out the sketch layer if it exists. 
	if (self.sketchLayer) {
        [self.sketchLayer clear];		
	}
	
}



// clear the sketch layer
- (IBAction)clearSketchLayer:(id)sender {    
	[self.sketchLayer clear];    
}

//when the specific activity is selected. 
- (IBAction)activitySegValueChanged:(id)sender {
	
    //getting the sender seg control
	UISegmentedControl *segCtrl = (UISegmentedControl*)sender;
	
	switch (segCtrl.selectedSegmentIndex) {
            //this case is when the mode is "Find Service Area"
		case 0:{
			// update status message label
            self.statusMessageLabel.text = @"Select the facility to find its service area";
            
            // if we have a sketch layer on the map, remove it
            if ([self.mapView.mapLayers containsObject:self.sketchLayer]) {
                [self.mapView removeMapLayerWithName:self.sketchLayer.name];
                self.sketchLayer = nil;       
                //assiging the touch delegate to self instead of sketch layer
                self.mapView.touchDelegate = self;
            }
			break;
            //this case is when the user wants to add barriers. 
		}
        case 1:{
            // update status message label
            self.statusMessageLabel.text = @"Sketch the barriers";
            
            //create the sketch layer with a Spatial Ref and add it to the map. 
			AGSGeometry *geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
            self.sketchLayer = [[AGSSketchGraphicsLayer alloc] initWithGeometry:geometry];
            [self.mapView addMapLayer:self.sketchLayer withName:@"SketchLayer"];
            
            //set the touch delegate to the sketch layer. 
            self.mapView.touchDelegate = self.sketchLayer;
			break;
		}
        default:
			break;
	}
}


//when the user presses the add button to add the sketched barrier to the graphics layer. 
- (IBAction)addBarier:(id)sender {
    
    //grab the geometry, then clear the sketch
	AGSGeometry *geometry = [self.sketchLayer.geometry copy];	
	[self.sketchLayer clear];
	
	//Prepare symbol and attributes for the Stop/Barrier
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	AGSSymbol *symbol;
	
    //increament the barrier count
    self.numBarriers++;
    
    //add the barrier count to the graphic attributes dictionary
    [attributes setValue:[NSNumber numberWithInt:self.numBarriers] forKey:@"barrierNumber"];
    
    //you can set additional properties on the barrier here
    symbol = [self barrierSymbol];
    AGSGraphic *g = [AGSGraphic graphicWithGeometry:geometry 
                                             symbol:symbol
                                         attributes:attributes];
    [self.graphicsLayer addGraphic:g];
}

#pragma mark Helper Methods

- (void)respondToGeomChanged: (NSNotification*) notification {
	//Enable/disable UI elements appropriately
	self.addBarrierButton.enabled = [self.sketchLayer.geometry isValid];
	self.clearSketchButton.enabled = ![self.sketchLayer.geometry isEmpty];
}

#pragma mark Symbols

//generates the symbol for the time break 1. 
- (AGSCompositeSymbol*)serviceAreaSymbolBreak1 {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
    //the outline symbol
	AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls1.color = [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.5];
	sls1.style = AGSSimpleLineSymbolStyleSolid;
	sls1.width = 8;
	[cs addSymbol:sls1];
	
    //the color of the fill. 
	AGSSimpleFillSymbol *sls2 = [AGSSimpleFillSymbol simpleFillSymbol];
	sls2.color = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.25];
	sls2.style = AGSSimpleFillSymbolStyleSolid;
	[cs addSymbol:sls2];
	
	return cs;
}

//generates the symbol for the time break 2. 
- (AGSCompositeSymbol*)serviceAreaSymbolBreak2 {
	AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
	
    //the outline symbol
	AGSSimpleLineSymbol *sls1 = [AGSSimpleLineSymbol simpleLineSymbol];
	sls1.color = [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.5];
	sls1.style = AGSSimpleLineSymbolStyleSolid;
	sls1.width = 8;
	[cs addSymbol:sls1];
	
    //the color of the fill. 
	AGSSimpleFillSymbol *sls2 = [AGSSimpleFillSymbol simpleFillSymbol];
	sls2.color = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.25];
	sls2.style = AGSSimpleFillSymbolStyleSolid;
	[cs addSymbol:sls2];
	
	return cs;
}


// default symbol for the barriers
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

#pragma mark - segues

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSettingsSegueIdentifier]) {
        SettingsViewController *controller = [segue destinationViewController];
        controller.parameters = self.parameters;
        
        //present as form sheet for iPad
        if ([[AGSDevice currentDevice] isIPad]) {
            [controller setModalPresentationStyle:UIModalPresentationFormSheet];
        }
    }
}


@end
