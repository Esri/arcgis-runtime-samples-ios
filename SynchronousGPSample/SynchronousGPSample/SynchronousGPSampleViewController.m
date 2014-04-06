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

#import "SynchronousGPSampleViewController.h"
#import "SVProgressHUD.h"

#define kDefaultMap @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Shaded_Relief/MapServer"
#define kGPTask @"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Elevation/ESRI_Elevation_World/GPServer/Viewshed"

@implementation SynchronousGPSampleViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    
	//Adding the basemap. 
	NSURL *mapUrl = [NSURL URLWithString:kDefaultMap];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
	
    //Zooming to an initial envelope with the specified spatial reference of the map.
	AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-13639984
                                                ymin:4537387
                                                xmax:-13606734
                                                ymax:4558866 
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:YES];
    
    //important step in detecting the touch events on the map
    self.mapView.touchDelegate = self;
    
    //step to call the mapViewDidLoad method to do the initiation of GP.
    self.mapView.layerDelegate = self;
    
    //add  graphics layer for showing results of the viewshed calculation
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Viewshed"];
    
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    self.vsDistanceSlider = nil;
    self.vsDistanceLabel = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark AGSMapViewLayerDelegate
- (void)mapViewDidLoad:(AGSMapView *) mapView {
    //set up the GP task
    self.gpTask = [AGSGeoprocessor geoprocessorWithURL:[NSURL URLWithString:kGPTask]];
	self.gpTask.delegate = self; //required to respond to the gp response. 
	self.gpTask.processSpatialReference = self.mapView.spatialReference;
	self.gpTask.outputSpatialReference = self.mapView.spatialReference;	
}


#pragma mark AGSMapViewTouchDelegate
- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    
    //clearing the graphic layer before any update.   
	[self.graphicsLayer removeAllGraphics];
    
    //adding a simple marker to the view point on the map.
	AGSSimpleMarkerSymbol *myMarkerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.25]];
    [myMarkerSymbol setSize:CGSizeMake(10,10)];
    [myMarkerSymbol setOutline:[AGSSimpleLineSymbol simpleLineSymbolWithColor:[UIColor redColor] width:1]];
    
    //create a graphic
	AGSGraphic *agsGraphic = [AGSGraphic graphicWithGeometry:mappoint symbol:myMarkerSymbol attributes:nil ];
    
    //add graphic to graphics layer
	[self.graphicsLayer addGraphic:agsGraphic];
    
	//creating a feature set for the input pareameter for the GP.
	AGSFeatureSet *featureSet = [[AGSFeatureSet alloc] init];
	featureSet.features = [NSArray arrayWithObjects:agsGraphic, nil];
	
    //create input parameter
	AGSGPParameterValue *paramloc = [AGSGPParameterValue parameterWithName:@"Input_Observation_Point" type:AGSGPParameterTypeFeatureRecordSetLayer value:featureSet];
    
    //creating the linear unit distance parameter for the GP. 
    AGSGPLinearUnit *vsDistance = [[AGSGPLinearUnit alloc] init];
    vsDistance.distance = self.vsDistanceSlider.value;
    vsDistance.units = AGSUnitsMiles;
    
    //create input parameter
	AGSGPParameterValue *paramdt = [AGSGPParameterValue parameterWithName:@"Viewshed_Distance" type:AGSGPParameterTypeLinearUnit value:vsDistance];
    
    //add parameters to param array
	NSArray *params = [NSArray arrayWithObjects:paramloc, paramdt, nil]; 
    
	//execute the GP task with parameters - synchrounously.
	self.gpOp = [self.gpTask executeWithParameters:params]; // keep track of the gp operation so that we can cancel it if user wants.
    
    //showing activity indicator
    [SVProgressHUD showWithStatus:@"Loading Viewshed..."];
     
}


#pragma mark GeoprocessorDelegate

//this is the delegate method that getscalled when gp task completes successfully.
-(void)geoprocessor:(AGSGeoprocessor *)geoprocessor operation:(NSOperation *)op didExecuteWithResults:(NSArray *)results messages:(NSArray *)messages{
    
	if (results != nil && [results count] > 0) {
		
		//get the first result
		AGSGPParameterValue *result = [results objectAtIndex:0];
		AGSFeatureSet *fs = result.value;
		
		//loop through all graphics in feature set and add them to map
		for(AGSGraphic *graphic in fs.features){
			
			//create and set a symbol to graphic
			AGSSimpleFillSymbol *fillSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
			fillSymbol.color = [[UIColor purpleColor] colorWithAlphaComponent:0.25];
			graphic.symbol = fillSymbol;
			
			//add graphic to graphics layer
			[self.graphicsLayer addGraphic:graphic];
		}

		//stop activity indicator
		[SVProgressHUD dismiss];
		
		//zoom to graphics layer extent
		AGSMutableEnvelope *env = [self.graphicsLayer.fullEnvelope mutableCopy];
		[env expandByFactor:1.2];
		[self.mapView zoomToEnvelope:env animated:YES];   
	}

}

//if there's an error with the gp task give info to user
-(void)geoprocessor:(AGSGeoprocessor *)geoprocessor operation:(NSOperation *)op didFailExecuteWithError:(NSError *)error{
    
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

#pragma mark Action Methods

- (IBAction)vsDistanceSliderChanged:(id)sender {
    //show current distance
    [self.vsDistanceLabel setTitle:[NSString stringWithFormat:@"%.1f miles", self.vsDistanceSlider.value]];
    NSLog(@"slider value %f", self.vsDistanceSlider.value);
}

#pragma mark UIAlertViewDelegate Methods 

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    //cancel the operation
    [self.gpOp cancel];
    self.gpOp = nil;
    
    //clear the graphics layer.
    [self.graphicsLayer removeAllGraphics];
}


@end
