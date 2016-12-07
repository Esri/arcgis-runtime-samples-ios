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

@property (nonatomic, strong) AGSGraphicsOverlay *graphicsOverlay;
@property (nonatomic, strong) AGSLocatorTask *locator;
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
    self.mapView.interactionOptions.magnifierEnabled = YES;
    
	//create an instance of a local tiled layer
	//Add it to the map view
    AGSArcGISTiledLayer* tiledLayer = [AGSArcGISTiledLayer ArcGISTiledLayerWithTileCache:[AGSTileCache tileCacheWithName:@"SanFrancisco"]];
    self.mapView.map = [AGSMap mapWithBasemap:[AGSBasemap basemapWithBaseLayer:tiledLayer]];
    
    //create the graphics layer that the geocoding result
    //will be stored in and add it to the map
    self.graphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];
    
    
    //create a marker symbol to use in our graphic
    AGSPictureMarkerSymbol *marker = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"BluePushpin.png"]];
    marker.offsetX=9 ;
    marker.offsetY=16 ;
    marker.leaderOffsetX = -9;
    marker.leaderOffsetY = 11;
    self.graphicsOverlay.renderer = [AGSSimpleRenderer simpleRendererWithSymbol:marker];
    
    //add the graphics layer to the map
    [self.mapView.graphicsOverlays addObject:self.graphicsOverlay];
    
    //create the AGSLocator with the geo locator URL
    //and set the delegate to self, so we get AGSLocatorDelegate notifications
    self.locator = [AGSLocatorTask locatorTaskWithName:@"SanFranciscoLocator"];
    
    
    //the amount by which we will need to offset the callout along y-axis
    //from the center of the magnifier to the head of the pushpin
    int pushpinHeadOffset = 60;
    
    //the total amount by which we will need to offset the callout along y-axis
    //to show it correctly centered on the pushpin's head in the magnifier
    UIImage* img = [UIImage imageNamed:@"ArcGIS.bundle/Magnifier.png"];
    self.magnifierOffset = CGPointMake(0, -(img.size.height/2+pushpinHeadOffset)); //
    

    
}

#pragma mark - AGSGeoViewTouchDelegate
- (void) geoView:(AGSGeoView *)geoView didLongPressAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {

    //clear out any previous information in the callout
    self.mapView.callout.title = @"";
    self.mapView.callout.detail = @"";
  
    //remove any previous results from the layer
    [self.graphicsOverlay.graphics removeAllObjects];
  
    //add a graphic where the user began tap&hold & show callout
    [self.graphicsOverlay.graphics addObject:[AGSGraphic graphicWithGeometry:mapPoint symbol:nil attributes:nil]];
    
    //show callout for the graphic taking into account the enlarged map in the magnifier
    self.mapView.callout.title = @"Loading...";
    [self.mapView.callout showCalloutAt:mapPoint screenOffset:self.magnifierOffset rotateOffsetWithMap:YES animated:YES];
    
    
    //reverse-geocode the location
    AGSReverseGeocodeParameters* params = [AGSReverseGeocodeParameters reverseGeocodeParameters];
    params.resultAttributeNames = @[@"*"];
    params.outputSpatialReference = self.mapView.spatialReference;
    
    __weak __typeof(self) weakSelf = self;

    [self.locator reverseGeocodeWithLocation:mapPoint parameters:params completion:^(NSArray<AGSGeocodeResult *> * _Nullable geocodeResults, NSError * _Nullable error) {
        
        if(geocodeResults!=nil){
            [weakSelf processReverseGeocodeResults:geocodeResults];
        }else if (error!=nil){
            [weakSelf processReverseGeocodeError:error];
        }
    }];

}

- (void)geoView:(AGSGeoView *)geoView didMoveLongPressToScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {
    
    //update the graphic & callout location as user moves tap&hold
    self.graphicsOverlay.graphics[0].geometry = mapPoint;
    
    AGSReverseGeocodeParameters* params = [AGSReverseGeocodeParameters reverseGeocodeParameters];
    params.resultAttributeNames = @[@"*"];
    params.outputSpatialReference = self.mapView.spatialReference;
    
    __weak __typeof(self) weakSelf = self;

    //reverse-geocode new location
    [self.locator reverseGeocodeWithLocation:mapPoint parameters:params completion:^(NSArray<AGSGeocodeResult *> * _Nullable geocodeResults, NSError * _Nullable error) {
        if(geocodeResults!=nil){
            [weakSelf processReverseGeocodeResults:geocodeResults];
        }else if (error!=nil){
            [weakSelf processReverseGeocodeError:error];
        }

    }];
}

- (void)geoView:(AGSGeoView *)geoView didEndLongPressAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {

    //update callout's position to show it correctly on the regular map display (not enlarged)
    [self.mapView.callout showCalloutForGraphic:self.graphicsOverlay.graphics[0] tapLocation:mapPoint animated:YES];
}

- (void) geoView:(AGSGeoView *)geoView didTapAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {

    __weak __typeof(self) weakSelf = self;

   [self.mapView identifyGraphicsOverlay:self.graphicsOverlay screenPoint:screenPoint tolerance:22 returnPopupsOnly:NO completion:^(AGSIdentifyGraphicsOverlayResult * _Nonnull identifyResult) {
        
        if(identifyResult.graphics.count>0){
            
            AGSGraphic* tappedGraphic = identifyResult.graphics[0];
            if(tappedGraphic.attributes[@"Match_addr"]){
                weakSelf.mapView.callout.title = tappedGraphic.attributes[@"Match_addr"];
            }else if(tappedGraphic.attributes[@"Street"]){
                weakSelf.mapView.callout.title = tappedGraphic.attributes[@"Street"];
            }
            
            weakSelf.mapView.callout.detail = [ (NSString*)(tappedGraphic.attributes[@"City"]) stringByAppendingFormat:@", %@",  tappedGraphic.attributes[@"ZIP"] ];
            [weakSelf.mapView.callout showCalloutForGraphic:tappedGraphic tapLocation:mapPoint animated:YES ];
            
        } else {
            //dismiss the callout
            if(!weakSelf.mapView.callout.hidden)
                [weakSelf.mapView.callout dismiss];
        }
        
            
    }];
    
}

- (void)startGeocoding
{
    
    //clear out previous results
    [self.graphicsOverlay.graphics removeAllObjects];
    
    //Create the address dictionary with the contents of the search bar
    NSDictionary *addresses = @{
        @"Single Line Input": self.searchBar.text
    };
    
    AGSGeocodeParameters* params = [AGSGeocodeParameters geocodeParameters];
    params.resultAttributeNames = @[@"*"];
    params.outputSpatialReference = self.mapView.spatialReference;

    __weak __typeof(self) weakSelf = self;

    //now request the location from the locator for our address
    [self.locator geocodeWithSearchValues:addresses parameters:params completion:^(NSArray<AGSGeocodeResult *> * _Nullable geocodeResults, NSError * _Nullable error) {
        if(geocodeResults!=nil){
            [weakSelf processGeocodeResults:geocodeResults];
        }else if (error!=nil){
            [weakSelf processGeocodeError:error];
        }

    }];
    
    if(![self.recentSearches containsObject:self.searchBar.text])
        [self.recentSearches insertObject:self.searchBar.text atIndex:0];
}

#pragma mark -
#pragma mark AGSCalloutDelegate

- (void)didTapAccessoryButtonForCallout:(AGSCallout *)callout {

    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    //save a reference to the selected graphic, in order to pass it to the results view controller in prepareForSegue method
    self.selectedGraphic = graphic;
    
    //perform the segue to transition to Results view controller
    [self performSegueWithIdentifier:kResultsViewSegueIdentifier sender:self];
}


- (void) processGeocodeResults:(NSArray<AGSGeocodeResult *> *) geocodeResults {
    //check and see if we didn't get any results
	if (geocodeResults == nil || [geocodeResults count] == 0)
	{
        //show alert if we didn't get results
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Results" message:@"No Results found by Locator" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
	else
	{

        
        //loop through all candidates/results and add to graphics layer
		for (AGSGeocodeResult* result in geocodeResults) {
            //create the graphic
			AGSGraphic *graphic = [[AGSGraphic alloc] initWithGeometry:result.displayLocation
																symbol:nil
															attributes:result.attributes];
            
            //add the graphic to the graphics layer
			[self.graphicsOverlay.graphics addObject:graphic];
            
            //if we have a 90% confidence in the first result.
            if (result.score>90) {
                //show the callout for the one result we have
                self.mapView.callout.title = graphic.attributes[@"Match_addr"];
                self.mapView.callout.detail = [ (NSString*)(graphic.attributes[@"City"]) stringByAppendingFormat:@", %@",  graphic.attributes[@"ZIP"] ];
                [self.mapView.callout showCalloutForGraphic:graphic tapLocation:nil animated:YES];
                //don't process anymore results
                break;
            }

		}
        
        [self.mapView setViewpointGeometry:self.graphicsOverlay.extent completion:nil];

	}
    
}

- (void) processGeocodeError:(NSError*)error {

    //The location operation failed, display the error
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Results" message:@"No Results found by Locator" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) processReverseGeocodeResults:(NSArray<AGSGeocodeResult *> *) geocodeResults {
    //show the Street, City, and ZIP attributes in the callout
    self.mapView.callout.title = geocodeResults[0].attributes[@"Street"];
    self.mapView.callout.detail =  [geocodeResults[0].attributes[@"City"] stringByAppendingFormat:@", %@",geocodeResults[0].attributes[@"ZIP"]];
    //display callout
    [self.mapView.callout showCalloutAt:geocodeResults[0].inputLocation screenOffset:self.magnifierOffset rotateOffsetWithMap:YES animated:NO];
    
    [self.graphicsOverlay.graphics[0].attributes setDictionary:geocodeResults[0].attributes];
}

-(void) processReverseGeocodeError:(NSError*)error {
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

    __weak __typeof(self) weakSelf = self;

    RecentViewController* rvc = [[RecentViewController alloc]initWithItems:self.recentSearches];
    rvc.completionBlock = ^(NSString* item){
        if(item)
            weakSelf.searchBar.text = item;
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
        [weakSelf.searchBar becomeFirstResponder];
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
        controller.results = self.selectedGraphic.attributes;
    }
}

@end
