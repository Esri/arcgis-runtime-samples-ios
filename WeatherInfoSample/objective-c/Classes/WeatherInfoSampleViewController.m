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

#import "WeatherInfoSampleViewController.h"

@implementation WeatherInfoSampleViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Add layers
	NSURL *mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer 1"];

    
	mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer"];
	tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer 2"];
	
	
	//initialize the operation queue which will make webservice requests in the background
	self.queue = [[NSOperationQueue alloc] init];
	
	//Set the touch delegate so we can respond when user taps on the map
	self.mapView.touchDelegate = self;
		
	//hide the accessory button because we won't be needing it
	self.mapView.callout.accessoryButtonHidden = YES;
	
	self.mapView.callout.color = [UIColor whiteColor];
	self.mapView.callout.titleColor = [UIColor blueColor];
    self.mapView.callout.detailColor = [UIColor blackColor];
    
    //Prepare the view we will display while loading weather information
    self.loadingView =  [[[NSBundle mainBundle] loadNibNamed:@"LoadingView" owner:nil options:nil] objectAtIndex:0];
    

}


- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
	
	//Cancel any outstanding operations for previous webservice requests
	[self.queue cancelAllOperations];
	
	
    //Show an activity indicator while we initiate a new request
	self.mapView.callout.customView = self.loadingView;
	[self.mapView.callout showCalloutAt:mappoint screenOffset:CGPointZero animated:YES];

    AGSPoint* latLong = (AGSPoint*) [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:mappoint toSpatialReference:[AGSSpatialReference wgs84SpatialReference]];
	//Set up the parameters to send the webservice
	NSMutableDictionary* params = [NSMutableDictionary dictionary];
	[params setObject:[NSNumber numberWithDouble:latLong.x] forKey:@"lon"];
	[params setObject:[NSNumber numberWithDouble:latLong.y] forKey:@"lat"];
    [params setObject:@"imperial" forKey:@"units"];

	//Set up an operation for the current request
	NSURL* url = [NSURL URLWithString:@"http://api.openweathermap.org/data/2.5/weather/"];
	self.currentJsonOp = [[AGSJSONRequestOperation alloc]initWithURL:url queryParameters:params];
	self.currentJsonOp.target = self;
	self.currentJsonOp.action = @selector(operation:didSucceedWithResponse:);
	self.currentJsonOp.errorAction = @selector(operation:didFailWithError:);
	
	//Add operation to the queue to execute in the background
	[self.queue addOperation:self.currentJsonOp];
    	
	
}


- (void)operation:(NSOperation*)op didSucceedWithResponse:(NSDictionary *)weatherInfo {
	//The webservice was invoked successfully.
	//Print the response to see what the JSON payload looks like.
	NSLog(@"%@", weatherInfo);
	
    NSString *placeName = weatherInfo[@"name"];
    NSString *country = weatherInfo[@"sys"][@"country"];
    NSString *temp = weatherInfo[@"main"][@"temp"];
    NSString *humidity = weatherInfo[@"main"][@"humidity"];
    
    self.mapView.callout.customView = nil;
    self.mapView.callout.title = [NSString stringWithFormat:@"%@, %@", placeName, country];
    self.mapView.callout.detail = [NSString stringWithFormat:@"%@\u00B0F, %@%% Humidity", temp, humidity];
    
}

- (void)operation:(NSOperation*)op didFailWithError:(NSError *)error {
	//Error encountered while invoking webservice. Alert user 
	self.mapView.callout.hidden = YES;
	UIAlertView* av = [[UIAlertView alloc] initWithTitle:@"Sorry" 
												 message:[error localizedDescription] 
												delegate:nil cancelButtonTitle:@"OK" 
									   otherButtonTitles:nil];
	[av show];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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
    self.mapView = nil;
    self.queue = nil;
    self.loadingView = nil;
    self.currentJsonOp = nil;
}

@end
