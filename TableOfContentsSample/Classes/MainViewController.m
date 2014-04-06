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
#import "CustomSegue.h"
#define kTOCViewControllerSegue @"TOCViewControllerSegue"

@implementation MainViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];    

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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	//Re-show popOver to position it correctly after orientation change
	if([[AGSDevice currentDevice] isIPad] && self.popOverController.popoverVisible) {
		[self.popOverController dismissPopoverAnimated:NO];
		[self.popOverController presentPopoverFromRect:self.infoButton.frame
												inView:self.view
							  permittedArrowDirections:UIPopoverArrowDirectionUp
											  animated:YES ];
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
    if([[AGSDevice currentDevice] isIPad])
        self.popOverController = nil;
}

#pragma mark - segues

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //check for the segue identifier
    if ([segue.identifier isEqualToString:kTOCViewControllerSegue]) {
        //get a reference to the destination controller from the segue
        TOCViewController *controller = [segue destinationViewController];
        controller.mapView = self.mapView;
        //assign the delegate
        controller.delegate = self;
        
        //using custom segue to handle transitions in iPad and iPhone differently
        //in case of iPad, going to show a pop over controller
        //for which we need to assign three attributes on the segue before performing segue
        //view ::: the view in which the pop over controller will be presented
        //rect ::: the CGRect which will be the target, e.g. the frame of the button which fires the segue
        //popOverController ::: the controller which will be shown as the popOverController
        if ([[AGSDevice currentDevice] isIPad]) {
            
            self.popOverController = [[UIPopoverController alloc] initWithContentViewController:controller];
            [self.popOverController setPopoverContentSize:CGSizeMake(320, 500)];
            
            CustomSegue *customSegue = (CustomSegue*)segue;
            
            customSegue.view = self.view;
            customSegue.rect = self.infoButton.frame;
            customSegue.popOverController = self.popOverController;
        }
    }
}

#pragma mark - TOCViewControllerDelegate methods

-(void)dismissTOCViewController:(TOCViewController *)controller {
    //in case of iPad dismiss the pop over controller
	if([[AGSDevice currentDevice] isIPad])
		[self.popOverController dismissPopoverAnimated:YES];
	else    //in case of iphone dismiss the modal view controller
        [self dismissViewControllerAnimated:YES completion:nil];
}

@end
