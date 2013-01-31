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

#import "FindTaskSampleViewController.h"
#import "ResultsViewController.h"

//constants for title, search bar placeholder text and data layer
#define kViewTitle @"US State/City/River"
#define kSearchBarPlaceholder @"Find State/City/River"
#define kDynamicMapServiceURL @"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer"
#define kTiledMapServiceURL @"http://services.arcgisonline.com/ArcGIS/rest/services/ESRI_StreetMap_World_2D/MapServer"

@implementation FindTaskSampleViewController
@synthesize mapView=_mapView, dynamicLayer=_dynamicLayer;
@synthesize graphicsLayer=_graphicsLayer, searchBar=_searchBar;
@synthesize findTask=_findTask,findParams=_findParams;
@synthesize cityCalloutTemplate=_cityCalloutTemplate,riverCalloutTemplate=_riverCalloutTemplate,stateCalloutTemplate=_stateCalloutTemplate;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];

	//title for the navigation controller
    self.title = kViewTitle;
	
	//text in search bar before user enters in query
	self.searchBar.placeholder = kSearchBarPlaceholder;
	
	//set map view delegate
	self.mapView.layerDelegate = self;
	self.mapView.callout.delegate = self;

	//create and add a base layer to map
    AGSTiledMapServiceLayer *tiledMapServiceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:kTiledMapServiceURL]];
    [self.mapView addMapLayer:tiledMapServiceLayer withName:@"World Street Map"];
	
	//create and add dynamic layer to map
	self.dynamicLayer = [[AGSDynamicMapServiceLayer alloc] initWithURL:[NSURL URLWithString:kDynamicMapServiceURL]];
    [self.mapView addMapLayer:self.dynamicLayer withName:@"Dynamic Layer"];
	
	//create and add graphics layer to map
	self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
	[self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
	
	//create find task and set the delegate
	self.findTask = [[AGSFindTask alloc] initWithURL:[NSURL URLWithString:kDynamicMapServiceURL]];
	self.findTask.delegate = self;
	
	//create find task parameters
	self.findParams = [[AGSFindParameters alloc]init];
}

#pragma mark -
#pragma mark AGSMapViewLayerDelegate

- (void)mapViewDidLoad:(AGSMapView *)mapView {
		
	//zoom to dynamic layer
	AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin:-178.217598362366 ymin:18.9247817993164 xmax:-66.9692710360024 ymax:71.4062353532712 spatialReference:self.mapView.spatialReference];
	[self.mapView zoomToEnvelope:envelope animated:YES];
}

#pragma mark -
#pragma mark AGSCalloutDelegate

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) 	callout {
    
    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    //The user clicked the callout button, so display the complete set of results
    ResultsViewController *resultsVC = [[ResultsViewController alloc] initWithNibName:@"ResultsViewController" bundle:nil];
	
    //set our attributes/results into the results VC
    resultsVC.results = graphic.allAttributes;
    
    //display the results vc modally
    [self presentModalViewController:resultsVC animated:YES]; 

}

#pragma mark - UISearchBarDelegate

//when the user searches
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	
	//hide the callout
	self.mapView.callout.hidden = YES;
	
	//set find task parameters
	self.findParams.contains = YES;
	self.findParams.layerIds = [NSArray arrayWithObjects:@"2",@"1",@"0",nil];
	self.findParams.outSpatialReference = self.mapView.spatialReference;
	self.findParams.returnGeometry = TRUE;
	self.findParams.searchFields = [NSArray arrayWithObjects:@"CITY_NAME",@"NAME",@"STATE_ABBR",@"STATE_NAME",nil];
	self.findParams.searchText = searchBar.text;
	
	//execute find task
	[self.findTask executeWithParameters:self.findParams];
	
	[searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
	[searchBar resignFirstResponder];
}

#pragma mark - AGSFindTaskDelegate

-(void)findTask:(AGSFindTask *)findTask operation:(NSOperation *)op didExecuteWithFindResults:(NSArray *)results {
	
	//clear previous results
    [self.graphicsLayer removeAllGraphics];
	
	//set callout width
	self.mapView.callout.width = 200;
	
	//create the city callout template, used when the user displays the callout
	self.cityCalloutTemplate = [[AGSCalloutTemplate alloc]init];
	self.cityCalloutTemplate.titleTemplate = @"${CITY_NAME}";
	self.cityCalloutTemplate.detailTemplate = @"Click for more detail..";
	
	//create the river callout template, used when the user displays the callout
	self.riverCalloutTemplate = [[AGSCalloutTemplate alloc]init];
	self.riverCalloutTemplate.titleTemplate = @"${NAME}";
	self.riverCalloutTemplate.detailTemplate = @"Click for more detail..";
	
	//create the state callout template, used when the user displays the callout
	self.stateCalloutTemplate = [[AGSCalloutTemplate alloc]init];
	self.stateCalloutTemplate.titleTemplate = @"${STATE_NAME}";
	self.stateCalloutTemplate.detailTemplate = @"Click for more detail..";

	//use these to calculate extent of results
	double xmin = DBL_MAX;
	double ymin = DBL_MAX;
	double xmax = -DBL_MAX;
	double ymax = -DBL_MAX;
	
	//result object
	AGSFindResult *result = nil;
	
	//loop through all results
	for (int i=0;i<[results count];i++) {
		
		//set the result object
		result = [results objectAtIndex:i];
		
		//accumulate the min/max
		if (result.feature.geometry.envelope.xmin < xmin)
			xmin = result.feature.geometry.envelope.xmin;
		
		if (result.feature.geometry.envelope.xmax > xmax)
			xmax = result.feature.geometry.envelope.xmax;
		
		if (result.feature.geometry.envelope.ymin < ymin)
			ymin = result.feature.geometry.envelope.ymin;
		
		if (result.feature.geometry.envelope.ymax > ymax)
			ymax = result.feature.geometry.envelope.ymax;
		
		//if result feature geometry is point/polyline/polygon
		if ([result.feature.geometry isKindOfClass:[AGSPoint class]]) {
			
			//create and set marker symbol
			AGSSimpleMarkerSymbol *symbol = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
			symbol.color = [UIColor yellowColor];
			symbol.style = AGSSimpleMarkerSymbolStyleDiamond;
			result.feature.symbol = symbol;
			
			//set the city callout
			result.feature.infoTemplateDelegate = self.cityCalloutTemplate;
		}
		else if ([result.feature.geometry isKindOfClass:[AGSPolyline class]]) {
			
			//create and set simple line symbol
			AGSSimpleLineSymbol *symbol = [AGSSimpleLineSymbol simpleLineSymbol];
			symbol.style = AGSSimpleLineSymbolStyleSolid;
			symbol.color = [UIColor blueColor];
			symbol.width = 2;
			result.feature.symbol = symbol;
			
			//set the river callout
			result.feature.infoTemplateDelegate = self.riverCalloutTemplate;
		}
		else if ([result.feature.geometry isKindOfClass:[AGSPolygon class]]) {
			
			//create and set simple line symbol
			AGSSimpleLineSymbol *outline = [AGSSimpleLineSymbol simpleLineSymbol];
			outline.style = AGSSimpleLineSymbolStyleSolid;
			outline.color = [UIColor redColor];
			outline.width = 2;
			
			AGSSimpleFillSymbol *symbol = [AGSSimpleFillSymbol simpleFillSymbol];
			symbol.outline = outline;
			
			result.feature.symbol = symbol;
			
			//set the state callout
			result.feature.infoTemplateDelegate = self.stateCalloutTemplate;
		}
				
		//add graphic to graphics layer
		[self.graphicsLayer addGraphic:result.feature];
    }
	
	if ([results count] == 1)
	{
		//we have one result, center at that point
		[self.mapView centerAtPoint:result.feature.geometry.envelope.center animated:NO];
		
		//show the callout
		[self.mapView.callout showCalloutAtPoint:(AGSPoint *)result.feature.geometry.envelope.center forGraphic:result.feature animated:YES];
	}
	
	//if we have more than one result, zoom to the extent of all results
	int nCount = [results count];
	if (nCount > 1)
	{            
		AGSMutableEnvelope *extent = [AGSMutableEnvelope envelopeWithXmin:xmin ymin:ymin xmax:xmax ymax:ymax spatialReference:self.mapView.spatialReference];
		[extent expandByFactor:1.5];
		[self.mapView zoomToEnvelope:extent animated:YES];
	}

}

//if there's an error with the find display it to the user
-(void)findTask:(AGSFindTask *)findTask operation:(NSOperation *)op didFailWithError:(NSError *)error {

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
													message:[error localizedDescription]
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
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
}


@end
