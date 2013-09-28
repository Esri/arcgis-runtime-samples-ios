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
#import "RecentViewController.h"

@interface GeocodingSampleViewController(){
    CGPoint _magnifierOffset;
}

@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSLocator *locator;
@property (nonatomic, strong) AGSCalloutTemplate *calloutTemplate;
@property (nonatomic, strong) NSMutableArray* recentSearches;
@property (nonatomic, strong) AGSAddressCandidate* reverseGeocodeResult;

//This is the method that starts the geocoding operation
- (void)startGeocoding;
@end

@implementation GeocodingSampleViewController



// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];

    self.recentSearches = [NSMutableArray arrayWithObjects:
                           @"1455 Market St, San Francisco, CA 94103",
                           @"2011 Mission St, San Francisco  CA  94110",
                           @"820 Bryant St, San Francisco  CA  94103",
                           @"1 Zoo Rd, San Francisco, 944132",
                           @"1201 Mason Street, San Francisco, CA 94108",
                           @"151 Third Street, San Francisco, CA 94103",
                           @"1050 Lombard Street, San Francisco, CA 94109",
                           nil ];
    
    //set the delegate on the mapView so we get notifications for user interaction with the callout
    self.mapView.callout.delegate = self;
    
    self.mapView.touchDelegate = self;
    self.mapView.showMagnifierOnTapAndHold = YES;
    
	//create an instance of a local tiled layer
	//Add it to the map view
    [self.mapView addMapLayer:[AGSLocalTiledLayer localTiledLayerWithName:@"SanFrancisco"]];
    
    //create the graphics layer that the geocoding result
    //will be stored in and add it to the map
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    
    //create the callout template, used when the user displays the callout
    self.calloutTemplate = [[AGSCalloutTemplate alloc]init];
    //set the text and detail text based on 'Name' and 'Descr' fields in the attributes
    self.calloutTemplate.titleTemplate = @"${Match_addr}";
    self.calloutTemplate.detailTemplate = @"${City}, ${ZIP}";
    self.graphicsLayer.calloutDelegate = self.calloutTemplate;
    
    //create a marker symbol to use in our graphic
    AGSPictureMarkerSymbol *marker = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"BluePushpin.png"];
    marker.offset = CGPointMake(9,16);
    marker.leaderPoint = CGPointMake(-9, 11);
    self.graphicsLayer.renderer = [AGSSimpleRenderer simpleRendererWithSymbol:marker];
    
    //add the graphics layer to the map
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
    
    //create the AGSLocator with the geo locator URL
    //and set the delegate to self, so we get AGSLocatorDelegate notifications
    NSError* error;
    //self.locator = [AGSLocator locatorWithName:@"RedlandsLocator" error:&error];
    self.locator = [AGSLocator locatorWithName:@"SanFranciscoLocator" error:&error];
    self.locator.delegate = self;
    
    
    UIImage* img = [UIImage imageNamed:@"ArcGIS.bundle/Magnifier.png"];
    _magnifierOffset = CGPointMake(0, -img.size.height/2);
    

    
}

#pragma mark - AGSMapViewTouchDelegate

- (void) mapView:(AGSMapView *)mapView didTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features {
    self.mapView.callout.title = @"";
    self.mapView.callout.detail = @"";
    [self.mapView.callout showCalloutAt:mappoint screenOffset:_magnifierOffset animated:YES];
    [self.locator addressForLocation:mappoint maxSearchDistance:25];
}
- (void) mapView:(AGSMapView *)mapView didMoveTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    [self.mapView.callout showCalloutAt:mappoint screenOffset:_magnifierOffset  animated:NO];
    [self.locator addressForLocation:mappoint maxSearchDistance:25];
}
- (void) mapView:(AGSMapView *)mapView didEndTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    [self.mapView.callout showCalloutAt:mappoint screenOffset:CGPointZero  animated:NO];
    
}

- (void)startGeocoding
{
    
    //clear out previous results
    [self.graphicsLayer removeAllGraphics];
    
    //Create the address dictionary with the contents of the search bar
    NSDictionary *addresses = @{
        @"Single Line Input": self.searchBar.text
    };

    //now request the location from the locator for our address
    [self.locator locationsForAddress:addresses returnFields:@[@"*"]];
    
    if(![self.recentSearches containsObject:self.searchBar.text])
        [self.recentSearches insertObject:self.searchBar.text atIndex:0];
}

#pragma mark -
#pragma mark AGSCalloutDelegate

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) 	callout
{
    //The user clicked the callout button, so display the complete set of results
    ResultsViewController *resultsVC = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController" bundle:nil];

    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    if(graphic){
        //set our attributes/results into the results VC
        resultsVC.results = [graphic allAttributes];
    }else{
        //we need to display results for the reverse geocoded location
        resultsVC.results = self.reverseGeocodeResult.attributes;
    }
    
    //display the results vc modally
    [self presentViewController:resultsVC animated:YES completion:nil];
	
}

#pragma mark -
#pragma mark AGSLocatorDelegate

- (void) locator:(AGSLocator *)locator operation:(NSOperation *)op didFetchLocatorInfo:(AGSLocatorInfo *)locatorInfo{
    NSLog(@"%@",locatorInfo.singleLineAddressField);
}

- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFindLocationsForAddress:(NSArray *)candidates
{
    //check and see if we didn't get any results
	if (candidates == nil || [candidates count] == 0)
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
		for (int i=0; i<[candidates count]; i++)
		{            
			AGSAddressCandidate *addressCandidate = (AGSAddressCandidate *)candidates[i];
                        
            //create the graphic
			AGSGraphic *graphic = [[AGSGraphic alloc] initWithGeometry: addressCandidate.location
																symbol:nil
															attributes:addressCandidate.attributes];
            
            //add the graphic to the graphics layer
			[self.graphicsLayer addGraphic:graphic];
			            

		}
        
        [self.mapView zoomToGeometry:self.graphicsLayer.fullEnvelope withPadding:0 animated:YES];
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

-(void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFindAddressForLocation:(AGSAddressCandidate *)candidate{
    self.reverseGeocodeResult = candidate;
    self.mapView.callout.title = candidate.address[@"Street"];
}

-(void) locator:(AGSLocator *)locator operation:(NSOperation *)op didFailAddressForLocation:(NSError *)error{
 /// @todo
    self.mapView.callout.title = @"Address not available";
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

- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar{
    
     RecentViewController* rvc = [[RecentViewController alloc]initWithItems:self.recentSearches];
    rvc.completionBlock = ^(NSString* item){
        if(item)
            self.searchBar.text = item;
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.searchBar becomeFirstResponder];
    };
    
    
    [self presentViewController:[[UINavigationController alloc]initWithRootViewController:rvc] animated:YES completion:nil];
    
}
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}


@end
