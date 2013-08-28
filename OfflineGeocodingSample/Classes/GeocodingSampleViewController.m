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

@implementation GeocodingSampleViewController

//The map service
static NSString *kMapServiceURL = @"http://services.arcgisonline.com/ArcGIS/rest/services/ESRI_StreetMap_World_2D/MapServer";

//The geocode service
static NSString *kGeoLocatorURL = @"http://tasks.arcgisonline.com/ArcGIS/rest/services/Locators/ESRI_Places_World/GeocodeServer";

@synthesize mapView = _mapView;
@synthesize searchBar = _searchBar;
@synthesize graphicsLayer = _graphicsLayer;
@synthesize locator = _locator;
@synthesize calloutTemplate = _calloutTemplate;

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
}

- (void)startGeocoding
{
    
    //clear out previous results
    [self.graphicsLayer removeAllGraphics];
    
    //create the AGSLocator with the geo locator URL
    //and set the delegate to self, so we get AGSLocatorDelegate notifications
    NSError* error;
    //self.locator = [AGSLocator locatorWithName:@"RedlandsLocator" error:&error];
    self.locator = [AGSLocator locatorWithName:@"SanDiegoLocator" error:&error];
    self.locator.delegate = self;
    [self.locator fetchLocatorInfo];
    
    //we want all out fields
    //Note that the "*" for out fields is supported for geocode services of
    //ArcGIS Server 10 and above
    //NSArray *outFields = [NSArray arrayWithObject:@"*"];
    
//    //for pre-10 ArcGIS Servers, you need to specify all the out fields:
//    NSArray *outFields = [NSArray arrayWithObjects:@"Loc_name",
//                          @"Shape",
//                          @"Score",
//                          @"Name",
//                          @"Rank",
//                          @"Match_addr",
//                          @"Descr",
//                          @"Latitude",
//                          @"Longitude",
//                          @"City",
//                          @"County",
//                          @"State",
//                          @"State_Abbr",
//                          @"Country",
//                          @"Cntry_Abbr",
//                          @"Type",
//                          @"North_Lat",
//                          @"South_Lat",
//                          @"West_Lon",
//                          @"East_Lon",
//                          nil];
//    
//    //Create the address dictionary with the contents of the search bar
//    NSDictionary *addresses = [NSDictionary dictionaryWithObjectsAndKeys:self.searchBar.text, @"PlaceName", nil];
//
//    //now request the location from the locator for our address
//    [self.locator locationsForAddress:addresses returnFields:outFields];
}

#pragma mark -
#pragma mark AGSCalloutDelegate

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) 	callout
{

    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    //The user clicked the callout button, so display the complete set of results
    ResultsViewController *resultsVC = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController" bundle:nil];

    //set our attributes/results into the results VC
    resultsVC.results = [graphic allAttributes];
    
    //display the results vc modally
    [self presentModalViewController:resultsVC animated:YES];  
	
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
        //use these to calculate extent of results
        double xmin = DBL_MAX;
        double ymin = DBL_MAX;
        double xmax = -DBL_MAX;
        double ymax = -DBL_MAX;
		
		//create the callout template, used when the user displays the callout
		self.calloutTemplate = [[AGSCalloutTemplate alloc]init];

        //loop through all candidates/results and add to graphics layer
		for (int i=0; i<[candidates count]; i++)
		{            
			AGSAddressCandidate *addressCandidate = (AGSAddressCandidate *)[candidates objectAtIndex:i];

            //get the location from the candidate
            AGSPoint *pt = addressCandidate.location;
            
            //accumulate the min/max
            if (pt.x  < xmin)
                xmin = pt.x;
            
            if (pt.x > xmax)
                xmax = pt.x;
            
            if (pt.y < ymin)
                ymin = pt.y;
            
            if (pt.y > ymax)
                ymax = pt.y;

			//create a marker symbol to use in our graphic
            AGSPictureMarkerSymbol *marker = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"BluePushpin.png"];
            marker.offset = CGPointMake(9,16);
            marker.leaderPoint = CGPointMake(-9, 11);
                        
            //set the text and detail text based on 'Name' and 'Descr' fields in the attributes
            self.calloutTemplate.titleTemplate = @"${Name}";
            self.calloutTemplate.detailTemplate = @"${Descr}";
			
            //create the graphic
			AGSGraphic *graphic = [[AGSGraphic alloc] initWithGeometry: pt
																symbol:marker 
															attributes:[addressCandidate.attributes mutableCopy]
														  infoTemplateDelegate:self.calloutTemplate];
            
            
            //add the graphic to the graphics layer
			[self.graphicsLayer addGraphic:graphic];
			            
            if ([candidates count] == 1)
            {
                //we have one result, center at that point
                [self.mapView centerAtPoint:pt animated:NO];
               
				// set the width of the callout
				self.mapView.callout.width = 250;
 
                //show the callout
                [self.mapView.callout showCalloutAtPoint:(AGSPoint*)graphic.geometry forGraphic:graphic animated:YES];
            }
			
			//release the graphic bb  
		}
        
        //if we have more than one result, zoom to the extent of all results
        int nCount = [candidates count];
        if (nCount > 1)
        {            
            AGSMutableEnvelope *extent = [AGSMutableEnvelope envelopeWithXmin:xmin ymin:ymin xmax:xmax ymax:ymax spatialReference:self.mapView.spatialReference];
            [extent expandByFactor:1.5];
			[self.mapView zoomToEnvelope:extent animated:YES];
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
