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

#import "GeocodingSampleViewController.h"
#import "ResultsViewController.h"

#define kResultsViewController @"ResultsViewController"

@implementation GeocodingSampleViewController

//The map service
static NSString *kMapServiceURL = @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer";

//The geocode service
static NSString *kGeoLocatorURL = @"http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer";

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set the delegate on the mapView so we get notifications for user interaction with the callout
    self.mapView.callout.delegate = self;
    
	//create an instance of a tiled map service layer
	//Add it to the map view
    NSURL *serviceUrl = [NSURL URLWithString:kMapServiceURL];
    AGSTiledMapServiceLayer *tiledMapServiceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:serviceUrl];
    [self.mapView addMapLayer:tiledMapServiceLayer withName:@"World Street Map"];
    
    //create the graphics layer that the geocoding result
    //will be stored in and add it to the map
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
    
    //set the text and detail text based on 'Name' and 'Descr' fields in the results
    //create the callout template, used when the user displays the callout
    self.calloutTemplate = [[AGSCalloutTemplate alloc]init];
    self.calloutTemplate.titleTemplate = @"${Match_addr}";
    self.calloutTemplate.detailTemplate = @"${Place_addr}";
    self.graphicsLayer.calloutDelegate = self.calloutTemplate;
}

- (void)startGeocoding
{
    
    //clear out previous results
    [self.graphicsLayer removeAllGraphics];
    
    //create the AGSLocator with the geo locator URL
    //and set the delegate to self, so we get AGSLocatorDelegate notifications
    self.locator = [AGSLocator locatorWithURL:[NSURL URLWithString:kGeoLocatorURL]];
    self.locator.delegate = self;
    
    //Note that the "*" for out fields is supported for geocode services of
    //ArcGIS Server 10 and above
    //NSArray *outFields = [NSArray arrayWithObject:@"*"];
    AGSLocatorFindParameters *parameters = [[AGSLocatorFindParameters alloc] init];
    parameters.text =self.searchBar.text;
    parameters.outSpatialReference = self.mapView.spatialReference;
    parameters.outFields = @[@"*"];
    [self.locator findWithParameters:parameters];
}

#pragma mark -
#pragma mark AGSCalloutDelegate

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) 	callout
{

    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    //The user clicked the callout button, so display the complete set of results
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    ResultsViewController *resultsVC = [storyboard instantiateViewControllerWithIdentifier:kResultsViewController];

    //set our attributes/results into the results VC
    resultsVC.results = [graphic allAttributes];
    
    //display the results vc modally
    [self presentViewController:resultsVC animated:YES completion:nil];
	
}

#pragma mark -
#pragma mark AGSLocatorDelegate

//- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFindLocationsForAddress:(NSArray *)candidates
- (void)locator:(AGSLocator*)locator operation:(NSOperation*)op didFind:(NSArray*)results
{
    //check and see if we didn't get any results
	if (results == nil || [results count] == 0)
	{
        //show alert if we didn't get results
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results"
                                                         message:@"No Results Found By Locator"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        
        [alert show];
	}
	else
	{
        //loop through all candidates/results and add to graphics layer
		for (int i=0; i<[results count]; i++)
		{            
			//AGSAddressCandidate *addressCandidate = (AGSAddressCandidate *)candidates[i];
            AGSLocatorFindResult *addressCandidate = (AGSLocatorFindResult *)results[i];
           // if ( addressCandidate.score == 100 ) {

            //get the location from the candidate
            AGSPoint *pt = (AGSPoint*)addressCandidate.graphic.geometry;
            
			//create a marker symbol to use in our graphic
            AGSPictureMarkerSymbol *marker = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"BluePushpin.png"];
            marker.offset = CGPointMake(9,16);
            marker.leaderPoint = CGPointMake(-9, 11);
            
            [addressCandidate.graphic setSymbol:marker];
            
            
            //add the graphic to the graphics layer
			[self.graphicsLayer addGraphic:addressCandidate.graphic];
			            
                if ([results count] == 1)
                {
                    //we have one result, center at that point
                    [self.mapView centerAtPoint:pt animated:NO];
                    
                    // set the width of the callout
                    self.mapView.callout.width = 250;
                    
                    //show the callout
                    [self.mapView.callout showCalloutAtPoint:(AGSPoint*)addressCandidate.graphic.geometry forFeature:addressCandidate.graphic layer:addressCandidate.graphic.layer animated:YES];
                }
           // }
			
			  
		}
        
        //if we have more than one result, zoom to the extent of all results
        NSUInteger nCount = [results count];
        if (nCount > 1)
        {  
			[self.mapView zoomToEnvelope:self.graphicsLayer.fullEnvelope animated:YES];
        }
	}
    
}

- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFailLocationsForAddress:(NSError *)error
{
    //The location operation failed, display the error
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Locator Failed"
                                                    message:[NSString stringWithFormat:@"Error: %@", error.description]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"                                          
                                          otherButtonTitles:nil];

    [alert show];
}

#pragma mark _
#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	
	//hide the callout
	self.mapView.callout.hidden = YES;
	
    //First, hide the keyboard, then starGeocoding
    [searchBar resignFirstResponder];
    [self startGeocoding];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    //hide the keyboard
    [searchBar resignFirstResponder];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}


@end
