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
    
    //Set map view's callout delegate (delegate method is implemented when callout's accessory button is tapped. This method is used to display more information about the graphic)
    self.mapView.callout.delegate = self;
    
    //Set map view's touch delegate (delegate method is implemented when user taps on map. This method is used to identify graphics at tap point and get results)
    self.mapView.touchDelegate = self;
    
    
	//create an instance of a tiled layer
    NSURL *serviceUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"];
    AGSArcGISTiledLayer *tiledMapServiceLayer = [[AGSArcGISTiledLayer alloc] initWithURL:serviceUrl];
    
    // create an instance of basemap with tiled layer
    AGSBasemap *basemap = [AGSBasemap basemapWithBaseLayer:tiledMapServiceLayer];
    
    //set map's basemap
    self.map = [[AGSMap alloc] initWithBasemap:basemap];
    
    //load the map
    [self.map loadWithCompletion:^(NSError * _Nullable error) {
       
        if (error) {
            //Check if loading returned an error
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
        else {
            
            //Assign map to map view
            self.mapView.map = self.map;
            
            //Call the helper method to query County and City layers
            [self queryLayers];
        }
    }];
    
    
    //COUNTY
	//add county graphics layer
    self.countyGraphicsLayer = [AGSGraphicsOverlay graphicsOverlay];
    [self.mapView.graphicsOverlays addObject:self.countyGraphicsLayer];

    //CITY
    self.cityGraphicsLayer = [AGSGraphicsOverlay graphicsOverlay];
    
	//renderer for cities
	AGSUniqueValueRenderer *cityRenderer = [[AGSUniqueValueRenderer alloc] init];
    cityRenderer.defaultSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithStyle:AGSSimpleMarkerSymbolStyleCircle color:[UIColor blackColor] size:10.0];
	cityRenderer.fieldNames = [NSArray arrayWithObject:@"TYPE"];
	
    //census designated place, city, town
	//create marker symbols for census, cities and towns and apply to renderer
    AGSSimpleMarkerSymbol *censusMarkeySymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithStyle:AGSSimpleMarkerSymbolStyleCircle color:[UIColor yellowColor] size:12.0];
    censusMarkeySymbol.outline = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor blueColor] width:1.0];
    
    AGSSimpleMarkerSymbol *cityMarkerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithStyle:AGSSimpleMarkerSymbolStyleDiamond color:[UIColor colorWithRed:255 green:0 blue:0 alpha:1.0] size:12.0];
    cityMarkerSymbol.outline = [AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor blueColor] width:1.0];
    
    
    AGSSimpleMarkerSymbol *townMarkerSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithStyle:AGSSimpleMarkerSymbolStyleCross color:[UIColor blackColor] size:16.0];
    
    cityRenderer.uniqueValues = [NSArray arrayWithObjects:
                                 [AGSUniqueValue uniqueValueWithDescription:@"Unique Value for census designated place" label:@"Census" symbol:censusMarkeySymbol values:[NSArray arrayWithObject:@"census designated place"]],
                                 [AGSUniqueValue uniqueValueWithDescription:@"Unique Value for city" label:@"City" symbol:cityMarkerSymbol values:[NSArray arrayWithObject:@"city"]],
                                 [AGSUniqueValue uniqueValueWithDescription:@"Unique Value for town" label:@"Town" symbol:townMarkerSymbol values:[NSArray arrayWithObject:@"town"]],
                                 nil];
    
	//apply city renderer
    self.cityGraphicsLayer.renderer = cityRenderer;
    
	//add cities graphics layer
    [self.mapView.graphicsOverlays addObject:self.cityGraphicsLayer];

    self.cityGraphicsLayer.visible = FALSE;
    self.countyGraphicsLayer.visible = TRUE;
    
	
    //Zoom To Envelope
	//create extent to be used as default
    AGSEnvelope *envelope = [AGSEnvelope envelopeWithXMin:-124.83145667
                                                     yMin:30.49849464
                                                     xMax:-113.91375495
                                                     yMax:44.69150688
                                         spatialReference:[AGSSpatialReference spatialReferenceWithWKID:4326]];
    
	//Create a view point and set it on map view so map zooms to that extent
    AGSViewpoint *viewpoint = [AGSViewpoint viewpointWithTargetExtent:envelope];
    [self.mapView setViewpoint:viewpoint completion:nil];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    self.mapView = nil;
    self.countyGraphicsLayer = nil;
    self.cityGraphicsLayer = nil;
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


#pragma mark - Helper method to query

- (void)queryLayers {
	
    self.mapView.callout.width = 235.0f;
    
	//set up query task for counties and perform query returning all atrributes
    self.countyTable = [[AGSServiceFeatureTable alloc] initWithURL:[NSURL URLWithString:@"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StateCityHighway_USA/MapServer/2"]];

    //Create query parameters for counties
    AGSQueryParameters *countyQuery = [AGSQueryParameters queryParameters];
    countyQuery.whereClause = @"STATE_NAME = 'California'";
	countyQuery.returnGeometry = YES;
    countyQuery.outSpatialReference = self.mapView.spatialReference;
    
    [self.countyTable queryFeaturesWithParameters:countyQuery fields:AGSQueryFeatureFieldsLoadAll completion:^(AGSFeatureQueryResult * _Nullable result, NSError * _Nullable error) {
        
        if (error) {
            //Check if query returned an error
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
        }
        else {
            
            //create extent
            AGSEnvelope *envelope = [AGSEnvelope envelopeWithXMin:-124.83145667
                                                             yMin:30.49849464
                                                             xMax:-113.91375495
                                                             yMax:44.69150688
                                                 spatialReference:[AGSSpatialReference spatialReferenceWithWKID:4326]];

            //Create a view point and set it on map view so map zooms to that extent
            AGSViewpoint *viewpoint = [AGSViewpoint viewpointWithTargetExtent:envelope];
            [self.mapView setViewpoint:viewpoint completion:nil];
            
            
            AGSSimpleFillSymbol *fillSymbol = [AGSSimpleFillSymbol simpleFillSymbolWithStyle:AGSSimpleFillSymbolStyleSolid color:[[UIColor blackColor] colorWithAlphaComponent:0.25] outline:[AGSSimpleLineSymbol simpleLineSymbolWithStyle:AGSSimpleLineSymbolStyleSolid color:[UIColor darkGrayColor] width:1.0]];
            
            
            //Get features from result, create graphics out of them and add graphics to county graphics overlay
            NSArray *features = [result featureEnumerator].allObjects;
            
            for (AGSArcGISFeature *feature in features) {

                AGSGraphic *graphic =[AGSGraphic graphicWithGeometry:feature.geometry symbol:fillSymbol attributes:feature.attributes];
                [self.countyGraphicsLayer.graphics addObject:graphic];
            }
        }
        
    }];

	//set up query task for cities and perform query returning all atrributes
    self.cityTable = [[AGSServiceFeatureTable alloc] initWithURL:[NSURL URLWithString:@"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/0"]];
    
    AGSQueryParameters *cityQuery = [AGSQueryParameters queryParameters];
    cityQuery.whereClause = @"STATE_NAME = 'California'";
	cityQuery.returnGeometry = YES;
    cityQuery.outSpatialReference = self.mapView.spatialReference;
    
    [self.cityTable queryFeaturesWithParameters:cityQuery fields:AGSQueryFeatureFieldsLoadAll completion:^(AGSFeatureQueryResult * _Nullable result, NSError * _Nullable error) {
        
        
        if (error) {
            //Check if query returned an error
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:[error localizedDescription]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
        }
        else {
            
            //create extent
            AGSEnvelope *envelope = [AGSEnvelope envelopeWithXMin:-124.83145667
                                                             yMin:30.49849464
                                                             xMax:-113.91375495
                                                             yMax:44.69150688
                                                 spatialReference:[AGSSpatialReference spatialReferenceWithWKID:4326]];
            
            //Create a view point and set it on map view so map zooms to that extent
            AGSViewpoint *viewpoint = [AGSViewpoint viewpointWithTargetExtent:envelope];
            [self.mapView setViewpoint:viewpoint completion:nil];
        
       
            //Get features from result, create graphics out of them and add graphics to city graphics overlay
            NSArray *features = [result featureEnumerator].allObjects;
           
            for (AGSArcGISFeature *feature in features) {
                
                AGSGraphic *graphic =[AGSGraphic graphicWithGeometry:feature.geometry symbol:nil attributes:feature.attributes];
                [self.cityGraphicsLayer.graphics addObject:graphic];
            }
        }
        
    }];
}

#pragma mark - AGSGeoViewTouchDelegate

//Gets called when user taps on map
- (void)geoView:(AGSGeoView *)geoView didTapAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {
    
    //callouts are only available for counties layer in this sample. Hence only that is identified. Identify returns graphics at the tap location
    [self.mapView identifyGraphicsOverlay:self.countyGraphicsLayer screenPoint:screenPoint tolerance:5.0 returnPopupsOnly:false completion:^(AGSIdentifyGraphicsOverlayResult * _Nonnull identifyResult) {
        
        if (identifyResult.graphics.count > 0) {
            
            AGSGraphic *graphic = identifyResult.graphics[0];
            
            //Set callout's properties
            self.mapView.callout.title =  [[graphic attributes]valueForKey:@"NAME"];
            self.mapView.callout.detail = [NSString stringWithFormat:@"'90: %@, '99: %@", [[graphic attributes] valueForKey:@"POP1990"], [[graphic attributes]valueForKey:@"POP1999"]];
            
            //Show callout for this graphic
            [self.mapView.callout showCalloutForGraphic:graphic tapLocation:mapPoint animated:YES];
        }
    }];
}

#pragma mark - AGSCalloutDelegate

//Gets called when a user clicks the detail disclosure button on the call out
- (
   void) didTapAccessoryButtonForCallout:(AGSCallout *)callout {
    //instantiate an object of the FeatureDetailsViewController
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    FeatureDetailsViewController *featureDetailsViewController = [storyboard instantiateViewControllerWithIdentifier:kFeatureDetailControllerIdentifier];

    //assign the feature to be presented in the details view
	featureDetailsViewController.feature = (AGSGraphic*)callout.representedObject;
    featureDetailsViewController.displayFieldName = @"NAME";
    
    //in case of an iPad present as a form sheet
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [featureDetailsViewController setModalPresentationStyle:UIModalPresentationFormSheet];
    }
    
    [self.navigationController presentViewController:featureDetailsViewController animated:YES completion:nil];
}

@end
