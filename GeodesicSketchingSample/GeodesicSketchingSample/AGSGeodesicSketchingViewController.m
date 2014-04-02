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

#import "AGSGeodesicSketchingViewController.h"
#import "AGSGeodesicSketchLayer.h"

@interface AGSGeodesicSketchingViewController()

@property (nonatomic, assign) double currentDistance;

- (void)enableSketching;

@end

@implementation AGSGeodesicSketchingViewController

#pragma mark - View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Show magnifier to help with sketching
	self.mapView.showMagnifierOnTapAndHold = YES;
    
    // Enable wrap around for the map
	[self.mapView enableWrapAround];
    
    // Assign delegate to this view controller
    self.mapView.layerDelegate = self;
    
	// Load a tiled map service 
	NSURL *mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];

    
    
    //Graphics layer to hold all sketches (points and polylines)
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
	[self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
    
    //A symbol for the graphics layer's renderer to symbolize the sketches
	AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
	lineSymbol.color= [UIColor yellowColor];
	lineSymbol.width = 4;
	
    // Create a renderer with the symbol and set the graphic layer's renderer property
	AGSSimpleRenderer* renderer = [AGSSimpleRenderer simpleRendererWithSymbol:lineSymbol];
	self.graphicsLayer.renderer = renderer;
    
    // Instructions for the user
    self.bannerLabel.text = @"Tap on the map to draw a flight path";
    
    // Start the distance out at zero
    self.currentDistance = 0;
    
    // Add the sketch layer
    self.sketchLayer = [[AGSGeodesicSketchLayer alloc] init];
    [self.mapView addMapLayer:self.sketchLayer withName:@"Sketch layer"]; 
    
    //Register for touch events
    self.mapView.touchDelegate = self.sketchLayer;
}

- (void)enableSketching {
    
    // Don't show the intermediate vertices
    self.sketchLayer.midVertexSymbol = nil;
    self.sketchLayer.vertexSymbol = nil;
    
    AGSPictureMarkerSymbol* plane = [[AGSPictureMarkerSymbol alloc] initWithImageNamed:@"tinyplane.png"];
    self.sketchLayer.selectedVertexSymbol = plane;
    
    // Set the sketch layer's geometry to a mutable polyline
    self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];  
    
    // Reset the distance to 0
    self.currentDistance = 0;
    
}

// Called when the map view has loaded
- (void) mapViewDidLoad:(AGSMapView *)mapView {
    
    // Setup the sketch layer
    [self enableSketching];
    
    //Register for "Geometry Changed" notifications 
    //We want to enable/disable UI elements when sketch geometry is modified
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:nil];
    
    // Get an initialized autoreleased geometry engine
    self.geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    
}

- (void)respondToGeomChanged: (NSNotification*) notification {
    
    
    // Enable/Disable redo, undo, and add buttons
    self.undoButton.enabled = [self.sketchLayer.undoManager  canUndo];
    self.redoButton.enabled = [self.sketchLayer.undoManager canRedo];
    self.addButton.enabled = self.undoButton.enabled;
    
    
    // Get the distance of the flight path in miles
    self.currentDistance = [self.geometryEngine  geodesicLengthOfGeometry:self.sketchLayer.geometry inUnit:AGSSRUnitSurveyMile];
    
    
    // If the current distance is greater than zero we have a line so report it
    // otherwise instruct the user
    if (self.currentDistance > 0) {
        self.bannerLabel.text = [NSString stringWithFormat:@"Distance: %d miles", (int)self.currentDistance];
    }
    else {
        self.bannerLabel.text = @"Tap on the map to draw a flight path";
    }
}

// The undo action gets called when the undo button is pressed 
- (IBAction) undo {
	if([self.sketchLayer.undoManager canUndo]) //extra check, just to be sure
		[self.sketchLayer.undoManager undo];
}

// The redo action gets called when the redo button is pressed
- (IBAction)redo {
    if ([self.sketchLayer.undoManager canRedo])
        [self.sketchLayer.undoManager redo];
    
}

// The reset action gets called when the reset button is pressed
- (IBAction) reset {

	[self.sketchLayer clear];
    
    // Remove all graphics from the graphics layer
    [self.graphicsLayer removeAllGraphics];
    // Reset the distance
    self.currentDistance = 0;
    
    //Start sketching again
    [self enableSketching];
    
}

// The addSketch action gets called when the add button is pressed
- (IBAction) addSketch {
    
	//Get the sketch geometry
	AGSGeometry* sketchGeometry = [self.sketchLayer.geometry copy];
    
    //Add a new graphic to the graphics layer
    AGSGraphic* graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:nil attributes:nil ];
    [self.graphicsLayer addGraphic:graphic];
    
    
    [self.sketchLayer clear];
    
    // Reset the distance
    self.currentDistance = 0;
    
    // Start sketching again
    [self enableSketching];
    
}

// Release any retained subviews of the main view.
- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.bannerLabel = nil;
    self.resetButton = nil;
    self.undoButton = nil;
    self.addButton = nil;
    self.mapView = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
