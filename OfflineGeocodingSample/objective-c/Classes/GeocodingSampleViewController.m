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
#define kResultsViewSegueIdentifier @"ResultsViewSegue"

@interface GeocodingSampleViewController()

@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSLocator *locator;
@property (nonatomic, strong) AGSCalloutTemplate *geocodeResultCalloutTemplate;
@property (nonatomic, strong) AGSCalloutTemplate* revGeoResultCalloutTemplate;
@property (nonatomic, strong) NSMutableArray* recentSearches;
@property (nonatomic, strong) AGSGraphic *selectedGraphic;
@property (nonatomic, assign) CGPoint magnifierOffset;

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
    self.graphicsLayer.calloutDelegate = self;
    
    
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
    self.locator = [AGSLocator locatorWithName:@"SanFranciscoLocator" error:&error];
    self.locator.delegate = self;
    
    
    //the amount by which we will need to offset the callout along y-axis
    //from the center of the magnifier to the head of the pushpin
    int pushpinHeadOffset = 60;
    
    //the total amount by which we will need to offset the callout along y-axis
    //to show it correctly centered on the pushpin's head in the magnifier
    UIImage* img = [UIImage imageNamed:@"ArcGIS.bundle/Magnifier.png"];
    self.magnifierOffset = CGPointMake(0, -(img.size.height/2+pushpinHeadOffset)); //
    

    
}

#pragma mark - AGSMapViewTouchDelegate

- (void) mapView:(AGSMapView *)mapView didTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features {
    //clear out any previous information in the callout
    self.mapView.callout.title = @"";
    self.mapView.callout.detail = @"";
    
    //remove any previous results from the layer
    [self.graphicsLayer removeAllGraphics];
    
    //reverse-geocode the location
    [self.locator addressForLocation:mappoint maxSearchDistance:25];

    //add a graphic where the user began tap&hold & show callout
    [self.graphicsLayer addGraphic:[AGSGraphic graphicWithGeometry:mappoint symbol:nil attributes:nil]];
    
    //show callout for the graphic taking into account the enlarged map in the magnifier
    [self.mapView.callout showCalloutAt:mappoint screenOffset:self.magnifierOffset  animated:YES];
}
- (void) mapView:(AGSMapView *)mapView didMoveTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
    
    //update the graphic & callout location as user moves tap&hold
    [(AGSGraphic*)[self.graphicsLayer graphics][0] setGeometry:mappoint];
    
    //reverse-geocode new location
    [self.locator addressForLocation:mappoint maxSearchDistance:25];
}
- (void) mapView:(AGSMapView *)mapView didEndTapAndHoldAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{

    //update callout's position to show it correctly on the regular map display (not enlarged)
    [self.mapView.callout showCalloutAtPoint:mappoint forFeature:self.graphicsLayer.graphics[0] layer:self.graphicsLayer animated:NO];
    

    
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
    [self.locator locationsForAddress:addresses returnFields:@[@"*"] outSpatialReference:self.mapView.spatialReference];
    
    if(![self.recentSearches containsObject:self.searchBar.text])
        [self.recentSearches insertObject:self.searchBar.text atIndex:0];
}

#pragma mark -
#pragma mark AGSCalloutDelegate

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) 	callout
{
    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    //save a reference to the selected graphic, in order to pass it to the results view controller in prepareForSegue method
    self.selectedGraphic = graphic;
    
    //perform the segue to transition to Results view controller
    [self performSegueWithIdentifier:kResultsViewSegueIdentifier sender:self];
}

#pragma mark -
#pragma mark AGSLayerCalloutDelegate

-(BOOL)callout:(AGSCallout*)callout willShowForFeature:(id<AGSFeature>)feature layer:(AGSLayer<AGSHitTestable>*)layer mapPoint:(AGSPoint *)mapPoint {
    
    //If the result does not have any attributes, don't show the callout
    if(![feature allAttributes] || [[feature allAttributes]allKeys].count == 0){
        return NO;
    }
    
    //The locator we are using in this sample returns 'Match_addr' attribute for geocoded results and
    //'Street' for reverse-geocoded results
    if ([feature hasAttributeForKey:@"Match_addr"]) {
        callout.title = [feature attributeForKey:@"Match_addr"];
    }else if([feature hasAttributeForKey:@"Street"]){
        callout.title = [feature attributeForKey:@"Street"];
    }
    
    //It also returns 'City' and 'ZIP' for both kind of results
    self.mapView.callout.detail = [ (NSString*)[feature attributeForKey:@"City"] stringByAppendingFormat:@", %@", [feature attributeForKey:@"ZIP"] ];
    return  YES;
    
    
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

        
        //sort the results based on score
        candidates = [candidates sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            double first = [(AGSAddressCandidate*)a score];
            double second = [(AGSAddressCandidate*)b score];
            return (first>second? NSOrderedAscending : NSOrderedDescending);
        }];
        
        //loop through all candidates/results and add to graphics layer
		for (AGSAddressCandidate* addressCandidate in candidates) {
            //create the graphic
			AGSGraphic *graphic = [[AGSGraphic alloc] initWithGeometry: addressCandidate.location
																symbol:nil
															attributes:addressCandidate.attributes];
            
            //add the graphic to the graphics layer
			[self.graphicsLayer addGraphic:graphic];
            
            //if we have a 90% confidence in the first result.
            if (addressCandidate.score>90) {
                //show the callout for the one result we have
                [self.mapView.callout showCalloutAtPoint:addressCandidate.location forFeature:graphic layer:self.graphicsLayer animated:YES];
                //don't process anymore results
                break;
            }

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
    //display callout
    [self.mapView.callout showCalloutAt:candidate.location screenOffset:self.magnifierOffset  animated:NO];

    //show the Street, City, and ZIP attributes in the callout
    self.mapView.callout.title = candidate.attributes[@"Street"];
    self.mapView.callout.detail =  [candidate.attributes[@"City"] stringByAppendingFormat:@", %@",candidate.attributes[@"ZIP"]];
    
    [self.graphicsLayer.graphics[0] setAttributes:candidate.attributes];
}

-(void) locator:(AGSLocator *)locator operation:(NSOperation *)op didFailAddressForLocation:(NSError *)error{
    //dismiss the callout because we don't have an address to display
    [self.mapView.callout dismiss];
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

#pragma mark - segues

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kResultsViewSegueIdentifier]) {
        ResultsViewController *controller = [segue destinationViewController];
        controller.results = [self.selectedGraphic allAttributes];
    }
}

@end
