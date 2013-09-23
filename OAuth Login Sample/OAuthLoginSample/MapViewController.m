// Copyright 2013 ESRI
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

#import "MapViewController.h"
#import <ArcGIS/ArcGIS.h>


@interface MapViewController()<AGSMapViewLayerDelegate, AGSWebMapDelegate>

//map view to open the webmap in
@property (nonatomic, strong) IBOutlet AGSMapView *mapView;

//webmap that needs to be opened. 
@property (nonatomic, strong) AGSWebMap *webMap;



@end

@implementation MapViewController



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// set the delegate for the map view
	self.mapView.layerDelegate = self;
	

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    //we're not releasing the portal explorer because a user may have signed in and we don't want to lose that information

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark AGSWebMapDelegate

- (void)webMapDidLoad:(AGSWebMap *)webMap {
	
	//open webmap in mapview
	[self.webMap openIntoMapView:self.mapView];
}

- (void)webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error {
	
    //show the error message in an alert. 
	NSString *err = [NSString stringWithFormat:@"%@",error];	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to load webmap"
													message:err
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

-(void)didFailToLoadLayer:(NSString *)layerTitle url:(NSURL *)url baseLayer:(BOOL)baseLayer withError:(NSError *)error {
    
	//show the error message in an alert. 
	NSString *err = [NSString stringWithFormat:@"%@",error];	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to load layer"
													message:err
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}




- (id)initWithPortalItem:(AGSPortalItem *)portalItem
{
    
    self = [super init];
    if (self) {
        //open the webmap with the portal item as specified
        self.webMap = [AGSWebMap webMapWithPortalItem:portalItem];
        self.webMap.delegate = self;
        self.webMap.zoomToDefaultExtentOnOpen = YES;
        self.navigationItem.title = portalItem.title;
    }
    return self;
}


@end
