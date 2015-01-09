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

#import "GraphicsSampleViewController.h"
#import "CountyInfoTemplate.h"
#import "FeatureDetailsViewController.h"

#define kFeatureDetailControllerIdentifier @"FeatureDetailViewController"

@implementation GraphicsSampleViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.layerDelegate = self;
    self.mapView.callout.delegate = self;
    
	//create an instance of a tiled map service layer
	//Add it to the map view
    NSURL *serviceUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"];
    AGSTiledMapServiceLayer *tiledMapServiceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:serviceUrl];
    [self.mapView addMapLayer:tiledMapServiceLayer withName:@"World Street Map"];
    
    //COUNTY
	//add county graphics layer (data is loaded in mapViewDidLoad method)
    self.countyGraphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.countyGraphicsLayer withName:@"States Graphics Layer"];

    //callouts are only availabl efor counties layer in this sample
    //create an instance of the callout template
    self.countyInfoTemplate = [[CountyInfoTemplate alloc] init];
    self.countyGraphicsLayer.calloutDelegate = self.countyInfoTemplate;

    //CITY
    self.cityGraphicsLayer = [AGSGraphicsLayer graphicsLayer];
    
	//renderer for cities
	AGSUniqueValueRenderer *cityRenderer = [[AGSUniqueValueRenderer alloc] init];
	cityRenderer.defaultSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
	cityRenderer.fields = [NSArray arrayWithObject:@"TYPE"];
	
    //census designated place, city, town
	//create marker symbols for census, cities and towns and apply to renderer
    AGSSimpleMarkerSymbol *censusMarkeySymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
    censusMarkeySymbol.color = [UIColor yellowColor];
	
    AGSSimpleMarkerSymbol *cityMarkerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
    cityMarkerSymbol.style = AGSSimpleMarkerSymbolStyleDiamond;
    cityMarkerSymbol.outline.color = [UIColor blueColor];

    AGSSimpleMarkerSymbol *townMarkerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
    townMarkerSymbol.style = AGSSimpleMarkerSymbolStyleCross;
    townMarkerSymbol.outline.width = 3.0;

    cityRenderer.uniqueValues = [NSArray arrayWithObjects:
                                 [AGSUniqueValue uniqueValueWithValue:@"census designated place" symbol:censusMarkeySymbol],
                                 [AGSUniqueValue uniqueValueWithValue:@"city" symbol:cityMarkerSymbol],
                                 [AGSUniqueValue uniqueValueWithValue:@"town" symbol:townMarkerSymbol],
                                 nil];
    
	//apply city renderer
    self.cityGraphicsLayer.renderer = cityRenderer;
    
	//add cities graphics layer (data is loaded in mapViewDidLoad method)
    [self.mapView addMapLayer:self.cityGraphicsLayer withName:@"City Graphics Layer"];

    self.cityGraphicsLayer.visible = FALSE;
    self.countyGraphicsLayer.visible = TRUE;
    
	
    //Zoom To Envelope
	//create extent to be used as default
	AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin:-124.83145667
                                                     ymin:30.49849464
                                                     xmax:-113.91375495
                                                     ymax:44.69150688
                                         spatialReference:[AGSSpatialReference spatialReferenceWithWKID:4326]];
    
	//call method to set extent, pass in envelope
	[self.mapView zoomToEnvelope:envelope animated:YES];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    self.mapView = nil;
    self.countyGraphicsLayer = nil;
    self.countyQueryTask = nil;
    self.countyInfoTemplate = nil;
    self.cityGraphicsLayer = nil;
    self.cityQueryTask = nil;
}

- (IBAction)toggleGraphicsLayer:(id)sender {
	
	//toggles between Cities and Counties graphics layer
          
    if (((UISegmentedControl *)sender).selectedSegmentIndex == 0) {
        self.cityGraphicsLayer.visible = FALSE;
        self.countyGraphicsLayer.visible = TRUE;
        self.mapView.callout.hidden = NO;
    }
    else {
        self.cityGraphicsLayer.visible = TRUE;
        self.countyGraphicsLayer.visible = FALSE;
        self.mapView.callout.hidden = YES;
    }
}


#pragma mark - AGSMapViewLayerDelegate

//called when the map view is loaded (after the view is loaded) 
- (void)mapViewDidLoad:(AGSMapView *)mapView {
	
    self.mapView.callout.width = 235.0f;
    
	//set up query task for counties and perform query returning all atrributes
    self.countyQueryTask = [AGSQueryTask queryTaskWithURL:[NSURL URLWithString:@"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StateCityHighway_USA/MapServer/2"]];
    self.countyQueryTask.delegate = self;
    
    AGSQuery *countyQuery = [AGSQuery query];
    countyQuery.whereClause = @"STATE_NAME = 'California'";
    countyQuery.outFields = [NSArray arrayWithObject:@"*"];
	countyQuery.returnGeometry = YES;
    countyQuery.outSpatialReference = self.mapView.spatialReference;
    [self.countyQueryTask executeWithQuery:countyQuery];

	//set up query task for cities and perform query returning all atrributes
    self.cityQueryTask = [AGSQueryTask queryTaskWithURL:[NSURL URLWithString:@"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/0"]];
    self.cityQueryTask.delegate = self;
    
    AGSQuery *cityQuery = [AGSQuery query];
    cityQuery.whereClause = @"STATE_NAME = 'California'";
    cityQuery.outFields = [NSArray arrayWithObject:@"*"];
	cityQuery.returnGeometry = YES;
    cityQuery.outSpatialReference = self.mapView.spatialReference;
    [self.cityQueryTask executeWithQuery:cityQuery];
}


#pragma mark - AGSCalloutDelegate

//when a user clicks the detail disclosure button on the call out
- (void) didClickAccessoryButtonForCallout:		(AGSCallout *) 	callout	{
    //instantiate an object of the FeatureDetailsViewController
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    FeatureDetailsViewController *featureDetailsViewController = [storyboard instantiateViewControllerWithIdentifier:kFeatureDetailControllerIdentifier];

    //assign the feature to be presented in the details view
	featureDetailsViewController.feature = (AGSGraphic*)callout.representedObject;
    featureDetailsViewController.displayFieldName = @"NAME";
    
    //in case of an iPad present as a form sheet
    if ([[AGSDevice currentDevice] isIPad]) {
        [featureDetailsViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    }
    
    [self.navigationController presentViewController:featureDetailsViewController animated:YES completion:nil];
}



#pragma mark- AGSQueryTaskDelegate

//when query is executed ....
- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didExecuteWithFeatureSetResult:(AGSFeatureSet *)featureSet {
    
	//create extent to be used as default
	AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin:-124.83145667
                                                     ymin:30.49849464
                                                     xmax:-113.91375495
                                                     ymax:44.69150688
                                         spatialReference:[AGSSpatialReference spatialReferenceWithWKID:4326]];
    
	//call method to set extent, pass in envelope
	[self.mapView zoomToEnvelope:envelope animated:YES];
	
	//determine if it's a query on counties or cities then assign to applicable layer
	if (YES == [featureSet.displayFieldName isEqualToString:@"CITY_NAME"]) {
        for (AGSGraphic *graphic in featureSet.features) {
            [self.cityGraphicsLayer addGraphic:graphic];
        }

        self.cityQueryTask = nil;
    }
    else {
        AGSSimpleFillSymbol *fillSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
        fillSymbol.color = [[UIColor blackColor] colorWithAlphaComponent:0.25];
        fillSymbol.outline.color = [UIColor darkGrayColor];
        

        
		//display counties on graphics layer and specify callout template
        for (AGSGraphic *graphic in featureSet.features) {
            graphic.symbol = fillSymbol;
            [self.countyGraphicsLayer addGraphic:graphic];
        }

        self.countyQueryTask = nil;
    }
}

//if there's an error with the query task give info to user
- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didFailWithError:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}


@end
