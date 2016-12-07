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

#define kResultsViewControllerIdentifier @"ResultsViewController"
#define kResultsSegueIdentifier @"ResultsSegue"

@interface IdentifyTaskSampleViewController ()

@property (nonatomic, strong) AGSGraphic *selectedGraphic;

@end

@implementation IdentifyTaskSampleViewController

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
    self.mapImageLayer = [[AGSArcGISMapImageLayer alloc] initWithURL:[NSURL URLWithString:kDynamicMapServiceURL]];

	// set the visible layers on the layer
    __weak __typeof(self) weakSelf = self;
    [self.mapImageLayer loadWithCompletion:^(NSError * _Nullable error) {
        for (AGSArcGISMapImageSublayer *subLayer in weakSelf.mapImageLayer.mapImageSublayers) {
            if (subLayer.sublayerID != 5) {
                subLayer.visible = NO;
            }
        }
    }];
    
	// add the layer to the map
    self.mapView.map = [AGSMap mapWithBasemap:[AGSBasemap basemapWithBaseLayer:self.mapImageLayer]];
		
	// create and add the graphics overlay to the map
	self.graphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];
	[self.mapView.graphicsOverlays addObject:self.graphicsOverlay];
	
    [super viewDidLoad];
}

#pragma mark - AGSGeoViewTouchDelegate methods

- (void)geoView:(AGSGeoView *)geoView didTapAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {

    //store for later use
    self.mapPoint = mapPoint;
    
    __weak __typeof(self) weakSelf = self;
    [self.mapView identifyLayer:self.mapImageLayer screenPoint:screenPoint tolerance:22 returnPopupsOnly:NO completion:^(AGSIdentifyLayerResult * _Nonnull identifyResult) {
        [weakSelf identifyFinishedWithResult:identifyResult];
    }];
}

#pragma mark - AGSCalloutDelegate methods
//show the attributes if accessory button is clicked
- (void)didTapAccessoryButtonForCallout:(AGSCallout *)callout {
    //save the selected graphic, to later assign to the results view controller
    self.selectedGraphic = (AGSGraphic*) callout.representedObject;
    
    [self performSegueWithIdentifier:kResultsSegueIdentifier sender:self];
}


#pragma mark - AGSIdentifyTaskDelegate methods
//results are returned
- (void)identifyFinishedWithResult:(AGSIdentifyLayerResult *)result {
    
    //clear previous results
    [self.graphicsOverlay.graphics removeAllObjects];
    
    if ([result.sublayerResults count] > 0) {
        
        //add new results
        AGSSymbol *symbol = [AGSSimpleFillSymbol simpleFillSymbolWithStyle:AGSSimpleFillSymbolStyleSolid color:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.5] outline:nil];
        
        // for each result, set the symbol and add it to the graphics layer
        for (id<AGSGeoElement> geoElement in result.sublayerResults[0].geoElements) {
            AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:geoElement.geometry symbol:symbol attributes:geoElement.attributes];
            [self.graphicsOverlay.graphics addObject:graphic];
        }
        
        //set the callout content for the first result
        //get the state name
        AGSGraphic *graphic = self.graphicsOverlay.graphics[0];
        NSString *stateName = graphic.attributes[@"STATE_NAME"];
        self.mapView.callout.title = stateName;
        self.mapView.callout.detail = @"Click for more detail..";
        
        //show callout
        [self.mapView.callout showCalloutForGraphic:graphic tapLocation:self.mapPoint animated:YES];
    }
    else {
        [self.mapView.callout dismiss];
    }
    

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

#pragma mark - segues

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kResultsSegueIdentifier]) {
        ResultsViewController *controller = [segue destinationViewController];
        //set our attributes/results into the results VC
        controller.results = self.selectedGraphic.attributes;
    }
}


@end
