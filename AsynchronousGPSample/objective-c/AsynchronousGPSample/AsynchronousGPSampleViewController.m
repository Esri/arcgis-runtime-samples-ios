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

#import "AsynchronousGPSampleViewController.h"
#import "Parameters.h"

#define kBaseMap @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
#define kGPTask @"http://sampleserver2.arcgisonline.com/ArcGIS/rest/services/PublicSafety/EMModels/GPServer/ERGByChemical"
#define kSettingsSegueName @"SettingsSegue"

@interface AsynchronousGPSampleViewController ()

@property (nonatomic, strong) Parameters *parameters;

@end

@implementation AsynchronousGPSampleViewController

#pragma mark - View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
 	//Add the basemap. 
	NSURL *mapUrl = [NSURL URLWithString:kBaseMap];
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
    
    //add  graphics layer for showing results of the chemical spill analysis
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    
    [self.mapView addMapLayer:self.graphicsLayer withName:@"ChemicalERG"];
    
    //instantiate Parameter Object
    self.parameters = [[Parameters alloc] init];
    
    [super viewDidLoad];
    
}

- (void)viewDidUnload {
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark AGSMapViewLayerDelegate

- (void)mapViewDidLoad:(AGSMapView *) mapView {
	
    //set up the gp task
    self.gpTask = [AGSGeoprocessor geoprocessorWithURL:[NSURL URLWithString:kGPTask]];
	self.gpTask.delegate = self; //required to respond to the gp response. 
	self.gpTask.processSpatialReference = self.mapView.spatialReference;
	self.gpTask.outputSpatialReference = self.mapView.spatialReference;	
}

#pragma mark AGSMapViewTouchDelegate

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    //clear graphic layer before any update.   
	[self.graphicsLayer removeAllGraphics];
    
    //create a symbol to show user tap location on map.  
	AGSSimpleMarkerSymbol *myMarkerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:0.25]];
	
    [myMarkerSymbol setSize:CGSizeMake(10,10)];
    [myMarkerSymbol setOutline:[AGSSimpleLineSymbol simpleLineSymbolWithColor:[UIColor redColor] width:1]];
	
	//create a graphic
	AGSGraphic *agsGraphic = [AGSGraphic graphicWithGeometry:mappoint symbol:myMarkerSymbol attributes:nil];
	
	//add graphic to graphics layer
	[self.graphicsLayer addGraphic:agsGraphic];
	
    //create a feature set for the input pareameter
	AGSFeatureSet *featureSet = [[AGSFeatureSet alloc] init];
	featureSet.features = [NSArray arrayWithObjects:agsGraphic, nil];

    //assign the new feature set and wind direction values to the parameter object
    self.parameters.featureSet = featureSet;
    self.parameters.windDirection = [[NSDecimalNumber alloc] initWithDouble:self.wdDegreeSlider.value];
    
    //get the parameters array from the parameters object
    NSArray *parametersArray = [self.parameters parametersArray];
    
    //submit the gp job.
	//the interval property of the gptask is not set to a value explicitly. default is 5 secs.
    [self.gpTask submitJobWithParameters:parametersArray];
}

#pragma mark GeoprocessorDelegate

//this is the delegate method that gets called when job completes successfully
- (void)geoprocessor:(AGSGeoprocessor *)geoprocessor operation:(NSOperation *)op didSubmitJob:(AGSGPJobInfo *)jobInfo {
    
	//update status
    self.statusMsgLabel.text = @"Geoprocessing Job Submitted!";  
}

//this is the delegate method that gets called when gp job completes successfully.
- (void)geoprocessor:(AGSGeoprocessor *) geoprocessor operation:(NSOperation *) op jobDidSucceed:(AGSGPJobInfo *) jobInfo {
	
	//job succeed..query result data
    [geoprocessor queryResultData:jobInfo.jobId paramName:@"outerg_shp"];
}

- (void)geoprocessor:(AGSGeoprocessor *) geoprocessor operation:(NSOperation *) op didQueryWithResult:(AGSGPParameterValue *) result forJob:(NSString *) jobId {
	
	//get the result
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
    
	//zoom to graphics layer extent    
	AGSMutableEnvelope *env = [self.graphicsLayer.fullEnvelope mutableCopy];
    [env expandByFactor:1.2];
    [self.mapView zoomToEnvelope:env animated:YES];
    
    //showing status
    self.statusMsgLabel.text = @"Job Succeeded with Results!";
    
	//update status
    [self performSelector:@selector(changeStatusLabel:) withObject:@"Tap on the map to get the spill analysis" afterDelay:4];
}

//if error encountered while executing gp task
- (void)geoprocessor:(AGSGeoprocessor *) geoprocessor operation:(NSOperation *) op ofType:(AGSGPAsyncOperationType) opType didFailWithError:(NSError *) error forJob:(NSString *) jobId {
	
	//show error message if gp task fails
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                     message:[error localizedDescription]
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}

//if there's an error with the gp task give info to user
- (void)geoprocessor:(AGSGeoprocessor *) geoprocessor operation:(NSOperation *) op jobDidFail:(AGSGPJobInfo *) jobInfo {
	
    for (AGSGPMessage* msg in jobInfo.messages) {
        NSLog(@"%@", msg.description);
    }
    
    //update staus
    self.statusMsgLabel.text = @"Job Failed!";
    
	//reset the status
    [self performSelector:@selector(changeStatusLabel:) withObject:@"Tap on the map to get the spill analysis" afterDelay:4];
}

#pragma mark Action Methods

- (IBAction)degreeSliderChanged:(id)sender {
	
	//show direction angle
    self.wdDegreeLabel.text = [NSString stringWithFormat:@"%0.0f degrees", self.wdDegreeSlider.value];
}

- (void)changeStatusLabel:(id)message {
	
	//show status
    self.statusMsgLabel.text = (NSString*) message;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kSettingsSegueName]) {
        SettingsViewController *controller = [segue destinationViewController];
        controller.parameters = self.parameters;
        
        //if ipad show formsheet
        if ([[AGSDevice currentDevice] isIPad]) {
            controller.modalPresentationStyle = UIModalPresentationFormSheet;
        }
    }
}

@end
