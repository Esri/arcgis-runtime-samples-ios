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
    self.mapView.map = [[AGSMap alloc]initWithBasemapType:AGSBasemapTypeStreets latitude:0 longitude:0 levelOfDetail:0];
    
    //create the graphics layer that the geocoding result
    //will be stored in and add it to the map
    self.graphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];
    [self.mapView.graphicsOverlays addObject:self.graphicsOverlay];

    self.mapView.touchDelegate = self;
    self.mapView.callout.delegate = self;

    // set the width of the callout
    self.mapView.callout.width = 250;
    
}


- (void)geoView:(AGSGeoView *)geoView didTapAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint
{
        __weak __typeof(self) weakSelf = self;

        [self.mapView identifyGraphicsOverlay:self.graphicsOverlay screenPoint:screenPoint tolerance:22 returnPopupsOnly:NO completion:^(AGSIdentifyGraphicsOverlayResult * _Nonnull identifyResult) {
           
            if(identifyResult.graphics.count>0){
                
                //set the text and detail text based on 'Name' and 'Descr' fields in the results

                AGSGraphic* tappedGraphic = identifyResult.graphics[0];
                weakSelf.mapView.callout.title = tappedGraphic.attributes[@"Match_addr"];
                weakSelf.mapView.callout.detail = tappedGraphic.attributes[@"Place_addr"];
                
                [weakSelf.mapView.callout showCalloutForGraphic:tappedGraphic tapLocation:nil animated:YES];
                
            }else{
                weakSelf.mapView.callout.title = @"";
                weakSelf.mapView.callout.detail = @"";
                [weakSelf.mapView.callout dismiss];
            }
            
        }];
}


- (void)startGeocoding
{
    
    //clear out previous results
    [self.graphicsOverlay.graphics removeAllObjects];
    
    //create the AGSLocatorTask with the geo locator URL
    self.locator = [AGSLocatorTask locatorTaskWithURL:[NSURL URLWithString:kGeoLocatorURL]];
    
    //Note that the "*" for out fields is supported for geocode services of
    //ArcGIS Server 10 and above
    AGSGeocodeParameters *parameters = [[AGSGeocodeParameters alloc] init];
    parameters.outputSpatialReference = self.mapView.spatialReference;
    parameters.resultAttributeNames = @[@"*"];
    
    __weak __typeof(self) weakSelf = self;
    
    [self.locator geocodeWithSearchText:self.searchBar.text parameters:parameters completion:^(NSArray<AGSGeocodeResult *> * _Nullable geocodeResults, NSError * _Nullable error) {
        
        if(geocodeResults!=nil){
            [weakSelf processResults:geocodeResults];
        }else if (error!=nil){
            [weakSelf processError:error];
        }
        
    }];
}

#pragma mark -
#pragma mark AGSCalloutDelegate

- (void)didTapAccessoryButtonForCallout:(AGSCallout *)callout
{

    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    //The user clicked the callout button, so display the complete set of results
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    ResultsViewController *resultsVC = [storyboard instantiateViewControllerWithIdentifier:kResultsViewController];

    //set our attributes/results into the results VC
    resultsVC.results = graphic.attributes;
    
    //display the results vc modally
    [self presentViewController:resultsVC animated:YES completion:nil];
	
}

#pragma mark -
#pragma mark AGSLocatorDelegate

-(void) processResults:(NSArray<AGSGeocodeResult *>*)results
{
    //check and see if we didn't get any results
	if ([results count] == 0)
	{
        //show alert if we didn't get results
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Results" message:@"No Results found by Locator" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
	}
	else
	{
        //loop through all candidates/results and add to graphics layer
		for (int i=0; i<[results count]; i++)
		{            
            AGSGeocodeResult *addressCandidate = (AGSGeocodeResult *)results[i];

            //get the location from the candidate
            
            AGSPoint *pt = addressCandidate.displayLocation;
            
			//create a marker symbol to use in our graphic
            AGSPictureMarkerSymbol *marker = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"BluePushpin.png"]];
            marker.offsetX=9 ;
            marker.offsetY=16 ;
            marker.leaderOffsetX = -9;
            marker.leaderOffsetY = 11;
            
            AGSGraphic* graphic = [AGSGraphic graphicWithGeometry:pt symbol:marker attributes:addressCandidate.attributes];
            
            
            //add the graphic to the graphics layer
            [self.graphicsOverlay.graphics addObject:graphic];
            
                if ([results count] == 1)
                {
                    //we have one result, center at that point
                    [self.mapView setViewpointCenter:pt completion:nil];
                    
                    
                    //show the callout
                    self.mapView.callout.title = graphic.attributes[@"Match_addr"];
                    self.mapView.callout.detail = graphic.attributes[@"Place_addr"];
                    [self.mapView.callout showCalloutForGraphic:graphic tapLocation:nil animated:YES];
                }
			  
		}
        
        //if we have more than one result, zoom to the extent of all results
        NSUInteger nCount = [results count];
        if (nCount > 1)
        {  
			[self.mapView setViewpointGeometry:self.graphicsOverlay.extent padding:25 completion:nil];
        }
	}
    
}

- (void) processError:(NSError*)error
{
    //The location operation failed, display the error
    //show alert if we didn't get results
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Locator Failed" message:[NSString stringWithFormat:@"Error: %@", error.description] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    
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
