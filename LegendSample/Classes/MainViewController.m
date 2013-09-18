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

@implementation MainViewController

@synthesize mapView=_mapView;
@synthesize infoButton=_infoButton;
@synthesize legendDataSource=_legendDataSource;
@synthesize legendViewController=_legendViewController;
@synthesize popOverController=_popOverController;

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Register for geometry changed notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToLayerLoaded:) name:AGSLayerDidLoadNotification object:nil];
	
	NSURL *mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Specialty/Soil_Survey_Map/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];

	//A data source that will hold the legend items
	self.legendDataSource = [[LegendDataSource alloc] init];
	
	//Initialize the legend view controller
	//This will be displayed when user clicks on the info button

	self.legendViewController = [[LegendViewController alloc] initWithNibName:@"LegendViewController" bundle:nil];
	self.legendViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	self.legendViewController.legendDataSource = self.legendDataSource;
	
	if([[AGSDevice currentDevice] isIPad]){
        
		self.popOverController = [[UIPopoverController alloc]
								  initWithContentViewController:self.legendViewController];
		[self.popOverController setPopoverContentSize:CGSizeMake(250, 500)];
		self.popOverController.passthroughViews = [NSArray arrayWithObject:self.view];
		self.legendViewController.popOverController = self.popOverController;
	}
}

#pragma mark -
#pragma mark AGSMapViewDelegate


- (void)respondToLayerLoaded:(NSNotification*)notification {
    
	//Add legend for each layer added to the map
	[self.legendDataSource addLegendForLayer:(AGSLayer *)notification.object];
}


- (IBAction) presentLegendViewController: (id) sender{
	//If iPad, show legend in the PopOver, else transition to the separate view controller
	if([[AGSDevice currentDevice] isIPad]){
		[_popOverController presentPopoverFromRect:self.infoButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES ];
		
	}else {
        [self presentViewController:self.legendViewController animated:YES completion:nil];
	}

}
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



@end
