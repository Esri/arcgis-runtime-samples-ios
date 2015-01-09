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
#import "CustomSegue.h"

#define kLegendViewControllerSegue @"LegendViewControllerSegue"

@implementation MainViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	NSURL *mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Specialty/Soil_Survey_Map/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Soils"];

	//A data source that will hold the legend items for all the map contents (layers)
	self.legendDataSource = [[LegendDataSource alloc] initWithLayerTree:[[AGSMapContentsTree alloc]initWithMapView:self.mapView manageLayerVisibility:NO]];
    
    [self.mapView addMapLayer:[AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:[NSURL URLWithString:@"http://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/MapServer"]] withName:@"Recreation"];
    
    [self.mapView addMapLayer:[AGSFeatureLayer featureServiceLayerWithURL:[NSURL URLWithString:@"http://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0"] mode:AGSFeatureLayerModeOnDemand] withName:@"Incidents"];
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
	self.legendDataSource = nil;
	self.legendViewController = nil;
	if([[AGSDevice currentDevice] isIPad])
		self.popOverController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AGSLayerDidLoadNotification object:nil];
}

#pragma mark - LegendViewControllerDelegate methods

- (void)dismissLegend {
    //in case of iPad dismiss the pop over controller
	if([[AGSDevice currentDevice] isIPad])
		[self.popOverController dismissPopoverAnimated:YES];
	else    //in case of iphone dismiss the modal view controller
        [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - segues

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //check for the segue identifier
    if ([segue.identifier isEqualToString:kLegendViewControllerSegue]) {
        //get a reference to the destination controller from the segue
        LegendViewController *controller = [segue destinationViewController];
        //assign the data source
        controller.legendDataSource = self.legendDataSource;
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
            [self.popOverController setPopoverContentSize:CGSizeMake(200, 600)];
            [controller.legendTableView setBackgroundColor:[UIColor whiteColor]];
            CustomSegue *customSegue = (CustomSegue*)segue;
            
            customSegue.view = self.view;
            customSegue.rect = self.infoButton.frame;
            customSegue.popOverController = self.popOverController;
        }
    }
}



@end
