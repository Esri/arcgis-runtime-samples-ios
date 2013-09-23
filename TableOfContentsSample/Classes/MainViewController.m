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
#import "MainViewController.h"
#import "TOCViewController.h"

@interface MainViewController()

@property (nonatomic, strong) TOCViewController *tocViewController;

@end

@implementation MainViewController

@synthesize mapView=_mapView;
@synthesize infoButton=_infoButton;
@synthesize tocViewController = _tocViewController;
@synthesize popOverController = _popOverController;

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];    

    
    //create the toc view controller
    self.tocViewController = [[TOCViewController alloc] initWithMapView:self.mapView]; 
	
    //add the base map. 
	NSURL *mapUrl = [NSURL URLWithString:@"http://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Base Map"];
    
    //add open street map. 
    AGSOpenStreetMapLayer *osmLayer = [AGSOpenStreetMapLayer openStreetMapLayer];
    [self.mapView addMapLayer:osmLayer withName:@"Open Street Map"];
    
    //add the bing map. Please use your own key. Here are the instructions: http://help.arcgis.com/en/arcgismobile/10.0/apis/iOS/2.1/concepts/index.html#/Bing_Maps_Layer/00pw0000004p000000/
    
    //	AGSBingMapLayer *bmLayer = [[AGSBingMapLayer alloc] initWithAppID:@"<---Your Key Here--->" style:AGSBingMapLayerStyleRoad];
    //	[self.mapView addMapLayer:bmLayer withName:@"Bing Maps"]; 

    NSURL *mapUrl3 = [NSURL URLWithString:@"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer"];
	AGSDynamicMapServiceLayer *dynamicLyr3 = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:mapUrl3];
	[self.mapView addMapLayer:dynamicLyr3 withName:@"Census"];   
    
    //add a tiled layer
    NSURL *mapUrl5 = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Specialty/Soil_Survey_Map/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr5 = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl5];
	[self.mapView addMapLayer:tiledLyr5 withName:@"Soil Survey"];
    
    //add a feature layer. 
    AGSFeatureLayer *featureLayer = [AGSFeatureLayer featureServiceLayerWithURL:[NSURL URLWithString:@"http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/SanFrancisco/311Incidents/FeatureServer/0"] mode:AGSFeatureLayerModeOnDemand];
    [self.mapView addMapLayer:featureLayer withName:@"Incidents"];
    
    //Zooming to an initial envelope with the specified spatial reference of the map.
	AGSSpatialReference *sr = [AGSSpatialReference webMercatorSpatialReference];
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-13639984
                                                ymin:4537387
                                                xmax:-13606734
                                                ymax:4558866 
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:YES];
        
}


#pragma mark -



- (IBAction)presentTableOfContents:(id)sender
{
    //If iPad, show legend in the PopOver, else transition to the separate view controller
	if([[AGSDevice currentDevice] isIPad]) {
        if(!self.popOverController) {
            self.popOverController = [[UIPopoverController alloc] initWithContentViewController:self.tocViewController];
            self.tocViewController.popOverController = self.popOverController;
            self.popOverController.popoverContentSize = CGSizeMake(320, 500);
            self.popOverController.passthroughViews = [NSArray arrayWithObject:self.view];
        }        
		[self.popOverController presentPopoverFromRect:self.infoButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES ];		
	}
    else {
        [self presentViewController:self.tocViewController animated:YES completion:nil];
	}    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {

    [super viewDidUnload];
	self.mapView = nil;
	self.infoButton = nil;
    self.tocViewController = nil;
    if([[AGSDevice currentDevice] isIPad])
        self.popOverController = nil;
}



@end
