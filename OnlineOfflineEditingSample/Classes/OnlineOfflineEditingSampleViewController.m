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

#import "OnlineOfflineEditingSampleViewController.h"
#import "FeatureDetailsViewController.h"
#import "CodedValueUtility.h"

#define kFeatureLayerName @"Feature Layer"
#define kSketchLayerName  @"Sketch layer"

#define FEATURE_SERVICE_URL @"http://sampleserver5a.arcgisonline.com/ArcGIS/rest/services/LocalGovernment/Recreation/FeatureServer/1"

@implementation OnlineOfflineEditingSampleViewController

@synthesize mapView = _mapView;
@synthesize featureLayer = _featureLayer;

@synthesize takeOfflineButton = _takeOfflineButton;
@synthesize takeOnlineButton = _takeOnlineButton;
@synthesize commitGeometryButton = _commitGeometryButton;

#pragma mark Edit Mode Helper Methods

-(void)turnOnEditMode{
	//
	// This function turns "edit mode" on and all the UI that is associated with it
	//
	_editingMode = YES;
	
	UIBarButtonItem *cancel = [[[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(turnOffEditMode)]autorelease];
	self.navigationItem.rightBarButtonItem = cancel;

    //Sketch layer	
	AGSSketchGraphicsLayer* sketchLayer = [[[AGSSketchGraphicsLayer alloc] initWithGeometry:nil] autorelease];
    sketchLayer.geometry = [[[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference] autorelease];
	[self.mapView addMapLayer:sketchLayer withName:kSketchLayerName]; 
    
    //set the mapView's touch delege to the sketch layer so it can get the user taps.
    self.mapView.touchDelegate = sketchLayer; 
    
    //hide the callout
    self.mapView.callout.hidden = YES;
    
    //set the left buton to be the 'commit geometry button'
    //make it initially disabled since we don't have a valid polygon yet...
    self.commitGeometryButton.enabled = NO;
    self.navigationItem.leftBarButtonItem = self.commitGeometryButton;
}

-(void)turnOffEditMode{
	//
	// This function turns "edit mode" off and all the UI that is associated with it
	//
	_editingMode = NO;

	UIBarButtonItem *right = [[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(turnOnEditMode)]autorelease];
	self.navigationItem.rightBarButtonItem = right;
    
    //set the left buton
    UIBarButtonItem *leftButton = (self.featureLayer.bOnline) ? self.takeOfflineButton : self.takeOnlineButton;
    self.navigationItem.leftBarButtonItem = leftButton;
    
    //remove the sketch layer from the map
    [self.mapView removeMapLayerWithName:kSketchLayerName];
    
    //rest the mapView's touch delegate
    //not doing this will cause problems,
    //because the sketch layer will have been released...
    self.mapView.touchDelegate = self; 
}

- (void)respondToGeomChanged: (NSNotification*) notification {
	//Enable/disable UI elements appropriately
    AGSSketchGraphicsLayer *sketchLayer = (AGSSketchGraphicsLayer *)[self.mapView mapLayerForName:kSketchLayerName];
    
    self.commitGeometryButton.enabled = [sketchLayer.geometry isValid];
}

#pragma mark UIView methods

-(void)viewWillAppear:(BOOL)animated{
	// anytime the view is shown, we turn edit mode off
	[self turnOffEditMode];
}

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
	self.mapView.touchDelegate = self;
    self.mapView.showMagnifierOnTapAndHold = YES;
	
	//Load the tile package
    AGSLocalTiledLayer* tiledLyr = [AGSLocalTiledLayer localTiledLayerWithName:@"JoshuaTree"];
    tiledLyr.delegate  = self;
	[self.mapView addMapLayer:tiledLyr withName:@"Basemap Layer"];

    
	// Add feature layer
	self.featureLayer = [OnlineOfflineFeatureLayer featureServiceLayerWithURL:[NSURL URLWithString:FEATURE_SERVICE_URL] mode:AGSFeatureLayerModeOnDemand ];
    self.featureLayer.delegate = self;
	self.featureLayer.calloutDelegate = self;
	self.featureLayer.outFields = [NSArray arrayWithObject:@"*"];

    self.featureLayer.onlineOfflineDelegate = self;

    [self.mapView addMapLayer:self.featureLayer withName:kFeatureLayerName];
    
	// zoom to Joshua Tree
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-12996582.593235 ymin:3862103.197183 xmax:-12800903.800820 ymax:4116485.627322 spatialReference:[AGSSpatialReference spatialReferenceWithWKID:102113]];
	[self.mapView zoomToEnvelope:env animated:YES];
    
    //set the color of the navigation bar based on our online state...
    self.navigationController.navigationBar.tintColor = (self.featureLayer.bOnline ?
                                                         [UIColor colorWithRed:0.25 green:0.75 blue:0.25 alpha:1.0] :
                                                         [UIColor colorWithRed:0.75 green:0.25 blue:0.25 alpha:1.0]);
    
    //set up bar button items
    self.takeOfflineButton = [[[UIBarButtonItem alloc]initWithTitle:@"Take Offline" style:UIBarButtonItemStylePlain target:self action:@selector(takeOffline:)]autorelease];
    self.takeOnlineButton = [[[UIBarButtonItem alloc]initWithTitle:@"Take Online" style:UIBarButtonItemStylePlain target:self action:@selector(takeOnline:)]autorelease];

    UIBarButtonItem *leftButton = (self.featureLayer.bOnline) ? self.takeOfflineButton : self.takeOnlineButton;
    self.navigationItem.leftBarButtonItem = leftButton;

    //initialize commit Geometry button...
    self.commitGeometryButton = [[[UIBarButtonItem alloc]initWithTitle:@"Commit Geometry" style:UIBarButtonItemStylePlain target:self action:@selector(commitGeometry:)]autorelease];
    
    //Register for "Geometry Changed" notifications 
    //We want to enable/disable UI elements (commit geometry button) when sketch geometry is modified
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:nil];
    
    [super viewDidLoad];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark -
#pragma mark AGSLayerDelegate methods


- (void) layerDidLoad:(AGSLayer *) 	layer{

	
	//
	// once the feature layer loads, make sure edit mode is off
	if (layer == self.featureLayer){
		[self turnOffEditMode];        
        
        if (self.featureLayer.addedFeaturesArray && [self.featureLayer.addedFeaturesArray count] > 0)
        {
            //we have features that were added.
            //ask user what they want to do...
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Offline Features"
                                                            message:@"Features were added offline.  Would you like to add them to the Server or discard them?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Discard"
                                                  otherButtonTitles:@"Add", nil];
            [alert show];
            [alert release];
        }
	}
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        //user clicked Add
        [self.featureLayer commitOfflineFeatures];
    }
    
    //in both cases, discard the added features now that the user had
    //decided what to do with them
    NSError *error = nil;
    //Commenting out for easy troubleshooting
    [[NSFileManager defaultManager] removeItemAtPath:[self.featureLayer addedFeaturesFilename] error:&error];
}

#pragma mark -
#pragma mark AGSCalloutDelegate

- (void) didClickAccessoryButtonForCallout: (AGSCallout *) 	callout{
    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
	// Show the details for an existing feature	
    FeatureDetailsViewController *fdvc = [[[FeatureDetailsViewController alloc]initWithFeatureLayer:self.featureLayer
                                                                                            feature:graphic
                                                                                    featureGeometry:graphic.geometry] autorelease];
    [self.navigationController pushViewController:fdvc animated:YES];
}

#pragma mark -
#pragma mark AGSLayerCalloutDelegate
- (BOOL) callout:(AGSCallout *)callout willShowForFeature:(id<AGSFeature>)feature layer:(AGSLayer<AGSHitTestable> *)layer mapPoint:(AGSPoint *)mapPoint{
    
    //only show callout if we're not editing
    if(_editingMode)
        return NO;
    
    AGSGraphic* graphic = (AGSGraphic*)feature;
    
    //set title
    NSString *val = [CodedValueUtility getCodedValueFromFeature:graphic forField:@"trailtype" inFeatureLayer:self.featureLayer];
	if ((NSNull*)val != [NSNull null]){
		callout.title = val;
	}
    //set detail
    AGSPoint *centerPoint = graphic.geometry.envelope.center;
    callout.detail =  [NSString stringWithFormat:@"x = %0.2f, y = %0.2f",centerPoint.x,centerPoint.y];
    return YES;
}


#pragma mark -
#pragma mark OnlineOfflineDelegate

- (void) recreateFeatureLayerWithOnlineStatus:(BOOL)online {
    //remove old feature layer from map
    [self.mapView removeMapLayerWithName:kFeatureLayerName];
    
    //create new feature layer, specifying online status...
    self.featureLayer = [OnlineOfflineFeatureLayer featureServiceLayerWithURL:[NSURL URLWithString:FEATURE_SERVICE_URL] mode:AGSFeatureLayerModeOnDemand online:online];
    self.featureLayer.calloutDelegate = self;
    self.featureLayer.outFields = [NSArray arrayWithObject:@"*"];
    self.featureLayer.onlineOfflineDelegate = self;
    self.featureLayer.delegate = self;
    [self.mapView addMapLayer:self.featureLayer withName:kFeatureLayerName];
    ((AGSUniqueValueRenderer*)self.featureLayer.renderer).fields = @[@"trailtype"];
   
    //set the nav bar color...
    self.navigationController.navigationBar.tintColor = (self.featureLayer.bOnline ?
                                                         [UIColor colorWithRed:0.25 green:0.75 blue:0.25 alpha:1.0] :
                                                         [UIColor colorWithRed:0.75 green:0.25 blue:0.25 alpha:1.0]);   
    
    //set up the left button correctly
    UIBarButtonItem *leftButton = online ? self.takeOfflineButton : self.takeOnlineButton;
    self.navigationItem.leftBarButtonItem = leftButton;
    
    //[self layerDidLoad:self.featureLayer];
}

-(void)prepForOfflineUseCompleted:(BOOL)succeeded
{
    if (succeeded)
    {
        [self recreateFeatureLayerWithOnlineStatus:NO];
    }
}

#pragma mark -
#pragma mark Internal

-(void)takeOffline:(id)sender
{
    //hide the callout
    self.mapView.callout.hidden = YES;

    [self.featureLayer prepForOfflineUse:self.mapView.visibleArea.envelope];
    
    //in the 'completed' delegate method, handle recreating the feature layer
}

-(void)takeOnline:(id)sender
{
    //hide the callout
    self.mapView.callout.hidden = YES;

    //there is no prep on the feature layer side, so just recreate it.
    [self recreateFeatureLayerWithOnlineStatus:YES];
}

#pragma mark -
#pragma mark Editing

-(void)commitGeometry:(id)sender
{
    //get sketchLayer from the mapView
    AGSSketchGraphicsLayer *sketchLayer = (AGSSketchGraphicsLayer *)[self.mapView mapLayerForName:kSketchLayerName];
        
    //get the sketch layer geometry
    AGSGeometry *geometry = sketchLayer.geometry;
    
    //now create the feature details vc and display it
    FeatureDetailsViewController *fdvc = [[[FeatureDetailsViewController alloc]initWithFeatureLayer:self.featureLayer
                                                                                            feature:nil
                                                                                    featureGeometry:geometry] autorelease];
    
    //show the details view
    [self.navigationController pushViewController:fdvc animated:YES];
}

#pragma mark dealloc

- (void)dealloc {
	self.mapView = nil;
	self.featureLayer = nil;
    
    self.takeOfflineButton = nil;
    self.takeOnlineButton = nil;
    self.commitGeometryButton = nil;

    [super dealloc];
}

@end
