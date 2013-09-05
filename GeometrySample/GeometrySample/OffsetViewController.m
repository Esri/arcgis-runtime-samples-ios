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

#import "OffsetViewController.h"

@interface OffsetViewController () {
    UIToolbar *_toolbar1;
    UIToolbar *_toolbar2;
    UISegmentedControl *_segmentedControl;
    UISlider *_distanceSlider;
    UISlider *_bevelSlider;
    UIBarButtonItem *_distance;
    UIBarButtonItem *_bevel;
    UISegmentedControl *_geometrySelect;
    UIBarButtonItem *_addButton;
    UIBarButtonItem *_offsetButton;
    UIBarButtonItem *_resetButton;
    UILabel *_userInstructions;
    
    AGSMapView *_mapView;
    AGSSketchGraphicsLayer *_sketchLayer;
    AGSGraphicsLayer *_graphicsLayer;
    NSMutableArray *_lastOffset;
    
    int _offsetDistance;
    double _bevelRatio;
    AGSGeometryOffsetType _offsetType;
    
}

- (void)updateOffset;

@end

@implementation OffsetViewController

@synthesize segmentedControl = _segmentedControl;
@synthesize userInstructions = _userInstructions;
@synthesize lastOffset = _lastOffset;
@synthesize toolbar1 = _toolbar1;
@synthesize toolbar2 = _toolbar2;
@synthesize distanceSlider = _distanceSlider;
@synthesize bevelSlider = _bevelSlider;
@synthesize distance = _distance;
@synthesize bevel = _bevel;
@synthesize geometrySelect = _geometrySelect;
@synthesize addButton = _addButton;
@synthesize offsetButton = _offsetButton;
@synthesize resetButton = _resetButton;
@synthesize mapView = _mapView;
@synthesize sketchLayer = _sketchLayer;
@synthesize graphicsLayer = _graphicsLayer;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.showMagnifierOnTapAndHold = YES;
    [self.mapView enableWrapAround];
    self.mapView.layerDelegate = self;
    
    // Load a tiled map service 
	NSURL *mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
    
    // Create a graphics layer and add it to the map
    // this layer will hold the orginal geometries and the offset results
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Result Layer"];

    // Set the bounds of the slider for distance and the initial value
    // Represents the amount by which we want to offset geometries
    self.distanceSlider.minimumValue = -2000;
    self.distanceSlider.maximumValue = 2000;
    self.distanceSlider.value = 1000;
    
    int distValue = (int)self.distanceSlider.value;
    _offsetDistance = distValue;
    
    // Display the distance via the title of the bar button item
    self.distance.title = [NSString stringWithFormat:@"%dm", distValue];
    
    // Set the bounds of the slider for bevel ratio and the initial value
    self.bevelSlider.minimumValue = 0;
    self.bevelSlider.maximumValue = 3;
    self.bevelSlider.value = 0.5;
    
    double bevelValue = self.bevelSlider.value;
    _bevelRatio = bevelValue;
    
    // Display the bevel ratio via the title of the bar button item
    self.bevel.title = [NSString stringWithFormat:@"%fm", bevelValue];
    
    _offsetType = AGSGeometryOffsetTypeMitered;
    
    // Create an envelope and zoom to it
    AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];    
    AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin:-8139237.214629 ymin:5016257.541842 xmax: -8090341.387563 ymax:5077377.325675 spatialReference:sr];
    [self.mapView zoomToEnvelope:envelope animated:YES];
    
    self.userInstructions.text = @"Sketch a geometry and tap the offset button to see the result";
    
    self.lastOffset = [NSMutableArray array];


}

- (void)mapViewDidLoad:(AGSMapView *)mapView    {
    // Create a sketch layer and add it to the map
    self.sketchLayer = [AGSSketchGraphicsLayer graphicsLayer];
    self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];
    [self.mapView addMapLayer:self.sketchLayer withName:@"Sketch layer"]; 
    self.mapView.touchDelegate = self.sketchLayer;

}


-(IBAction)offsetType:(UISegmentedControl*)control {
    
    //Set the offset type to match the selected offset type
    switch (control.selectedSegmentIndex) {
        case 0:
            _offsetType = AGSGeometryOffsetTypeMitered;
            break;
        case 1:
            _offsetType = AGSGeometryOffsetTypeRounded;
            break;
        case 2:
            _offsetType = AGSGeometryOffsetTypeSquare;
            break;
        case 3:
            _offsetType = AGSGeometryOffsetTypeBevelled;
        
        default:
            break;
    }
    
    [self updateOffset];
}


- (IBAction)offset {
    
    self.userInstructions.text = @"Adjust distance and bevel ratio, tap reset to start over";

    
    //Get the sketch geometry
    AGSGeometry *sketchGeometry = [self.sketchLayer.geometry copy];
    
    //A symbol for lines on the graphics layer
    AGSSimpleLineSymbol* sketchLineSymbol = [[AGSSimpleLineSymbol alloc] init];
    sketchLineSymbol.color= [UIColor redColor];
    sketchLineSymbol.width = 4;
    
    // Create the graphic and assign it the correct symbol according to its geometry type
    // Note: Lines and polygons are symbolized with the simple line symbol here
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:sketchLineSymbol attributes:nil ];
    
    //Add a new graphic to the graphics layer
    [self.graphicsLayer addGraphic:graphic];
	
    // Symbol for the offset
    AGSSimpleLineSymbol* offsetLineSymbol = [[AGSSimpleLineSymbol alloc] init];
    offsetLineSymbol.color= [UIColor blueColor];
    offsetLineSymbol.width = 4;
    
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    AGSGeometry *offsetGeometry = [geometryEngine offsetGeometry:sketchGeometry byDistance:_offsetDistance withJointType:_offsetType bevelRatio:_bevelRatio flattenError:0];
    AGSGraphic *offsetGraphic = [AGSGraphic graphicWithGeometry:offsetGeometry symbol:offsetLineSymbol attributes:nil ];

    [self.lastOffset addObject:offsetGraphic];
    
    [self.graphicsLayer addGraphic:offsetGraphic];
    
    [self.sketchLayer clear];

    
        
}

- (void)updateOffset {
    // Remove old graphics
    for (AGSGraphic *oldGraphic in self.lastOffset) {
        [self.graphicsLayer removeGraphic:oldGraphic];
    }
    
    // Symbol for the offset
    AGSSimpleLineSymbol* offsetLineSymbol = [[AGSSimpleLineSymbol alloc] init];
    offsetLineSymbol.color= [UIColor blueColor];
    offsetLineSymbol.width = 4;
    
    // Create the offset graphics using the geometry engine
    NSMutableArray *newGraphics = [NSMutableArray array];
    for (AGSGraphic *graphic in self.graphicsLayer.graphics) {
        AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
        AGSGeometry *newGeometry = [geometryEngine offsetGeometry:graphic.geometry byDistance:_offsetDistance withJointType:_offsetType bevelRatio:_bevelRatio flattenError:0];
        AGSGraphic *newGraphic = [AGSGraphic graphicWithGeometry:newGeometry symbol:offsetLineSymbol attributes:nil ];
        [newGraphics addObject:newGraphic];
    }
    
    // Remember the offset graphics so we can remove them
    self.lastOffset = newGraphics;
    
    // Add the offset graphics to the graphics layer and notify it of the change
    [self.graphicsLayer addGraphics:newGraphics];

}

- (IBAction)selectGeometry:(UISegmentedControl*)geomControl {
    
    // Set the geometry of the sketch layer to match the selected geometry
    switch (geomControl.selectedSegmentIndex) {
        case 0:
            self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];
            break;
        case 1:
            self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
            break;
        default:
            break;
    }
    
    [self.sketchLayer clear];
}



-(IBAction)distanceSliderValueChanged:(UISlider*)slider {
    
    // Get the value of the slider and update
    int value = (int)slider.value;
    _offsetDistance = value;
    self.distance.title = [NSString stringWithFormat:@"%dm", value];
    
    [self updateOffset];
    
}

-(IBAction)bevelSliderValueChanged:(UISlider*)slider {
    
    // Get the value of the slider and update
    double value = (double)slider.value;
    _bevelRatio = value;
    self.bevel.title = [NSString stringWithFormat:@"%fm", value];
   
    [self updateOffset];
}



- (IBAction)reset {
    self.userInstructions.text = @"Sketch a geometry and tap the offset button to see the result";
    self.lastOffset = [NSMutableArray array];
    [self.graphicsLayer removeAllGraphics];
    [self.sketchLayer clear];
}



#pragma mark -
#pragma mark Memory management



- (void)viewDidUnload
{
    
    self.userInstructions = nil;
    self.lastOffset = nil;
    self.toolbar1 = nil;
    self.toolbar2 = nil;
    self.distanceSlider = nil;
    self.bevelSlider = nil;
    self.distance = nil;
    self.bevel = nil;
    self.geometrySelect = nil;
    self.addButton = nil;
    self.offsetButton = nil;
    self.resetButton = nil;
    self.mapView = nil;
    self.sketchLayer = nil;
    self.graphicsLayer = nil;
    self.segmentedControl = nil;
    
    [super viewDidUnload];
   
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
