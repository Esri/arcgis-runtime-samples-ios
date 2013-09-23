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


#import "IdentifyTaskSampleViewController.h"
#define kDynamicMapServiceURL @"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer"

@implementation IdentifyTaskSampleViewController
@synthesize mapView=_mapView;
@synthesize graphicsLayer=_graphicsLayer;
@synthesize identifyTask=_identifyTask,identifyParams=_identifyParams; 
@synthesize mappoint = _mappoint;

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	self.mapView.touchDelegate = self;
    self.mapView.callout.delegate = self;
	
	// create a dynamic map service layer
	AGSDynamicMapServiceLayer *dynamicLayer = [[AGSDynamicMapServiceLayer alloc] initWithURL:[NSURL URLWithString:kDynamicMapServiceURL]];
	
	// set the visible layers on the layer
	dynamicLayer.visibleLayers = [NSArray arrayWithObjects:[NSNumber numberWithInt:5], nil];
	
	// add the layer to the map
	[self.mapView addMapLayer:dynamicLayer withName:@"Dynamic Layer"];
	
	// since we alloc-init the layer, we must release it
	
	// create and add the graphics layer to the map
	self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
	[self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
	
	//create identify task
	self.identifyTask = [AGSIdentifyTask identifyTaskWithURL:[NSURL URLWithString:kDynamicMapServiceURL]];
	self.identifyTask.delegate = self;
	
	//create identify parameters
	self.identifyParams = [[AGSIdentifyParameters alloc] init];
	
    [super viewDidLoad];
}

#pragma mark - AGSMapViewTouchDelegate methods

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{


    //store for later use
    self.mappoint = mappoint;
    
	//the layer we want is layer ‘5’ (from the map service doc)
	self.identifyParams.layerIds = [NSArray arrayWithObjects:[NSNumber numberWithInt:5], nil];
	self.identifyParams.tolerance = 3;
	self.identifyParams.geometry = self.mappoint;
	self.identifyParams.size = self.mapView.bounds.size;
	self.identifyParams.mapEnvelope = self.mapView.visibleArea.envelope;
	self.identifyParams.returnGeometry = YES;
	self.identifyParams.layerOption = AGSIdentifyParametersLayerOptionAll;
	self.identifyParams.spatialReference = self.mapView.spatialReference;

	//execute the task
	[self.identifyTask executeWithParameters:self.identifyParams];
	
}
#pragma mark - AGSCalloutDelegate methods
//show the attributes if accessory button is clicked
- (void) didClickAccessoryButtonForCallout:(AGSCallout *)callout	{
    

    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    //The user clicked the callout button, so display the complete set of results
    ResultsViewController *resultsVC = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController" bundle:nil];
	
    //set our attributes/results into the results VC
    resultsVC.results = [graphic allAttributes];
    
    //display the results vc modally
    [self presentViewController:resultsVC animated:YES completion:nil];
	
	//cleanup
}


#pragma mark - AGSIdentifyTaskDelegate methods
//results are returned
- (void)identifyTask:(AGSIdentifyTask *)identifyTask operation:(NSOperation *)op didExecuteWithIdentifyResults:(NSArray *)results {
    
    //clear previous results
    [self.graphicsLayer removeAllGraphics];
    
    if ([results count] > 0) {
        
        //add new results
        AGSSymbol* symbol = [AGSSimpleFillSymbol simpleFillSymbol];
        symbol.color = [UIColor colorWithRed:0 green:0 blue:1 alpha:0.5];
        
        // for each result, set the symbol and add it to the graphics layer
        for (AGSIdentifyResult* result in results) {
            result.feature.symbol = symbol;
            [self.graphicsLayer addGraphic:result.feature];
        }
        
        //set the callout content for the first result
        //get the state name
        NSString *stateName = [((AGSIdentifyResult*)[results objectAtIndex:0]).feature  attributeAsStringForKey:@"STATE_NAME"];
        self.mapView.callout.title = stateName;
        self.mapView.callout.detail = @"Click for more detail..";
        
        //show callout
        [self.mapView.callout showCalloutAtPoint:self.mappoint forFeature:((AGSIdentifyResult*)[results objectAtIndex:0]).feature layer:((AGSIdentifyResult*)[results objectAtIndex:0]).feature.layer animated:YES];
    }
    

}


//if there's an error with the query display it to the user
- (void)identifyTask:(AGSIdentifyTask *)identifyTask operation:(NSOperation *)op didFailWithError:(NSError *)error {
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
													message:[error localizedDescription]
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

#pragma mark 

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
	return YES;
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
