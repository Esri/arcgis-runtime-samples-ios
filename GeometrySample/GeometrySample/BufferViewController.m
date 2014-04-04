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

#import "BufferViewController.h"

@implementation BufferViewController

#pragma mark -
#pragma mark View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.showMagnifierOnTapAndHold = YES;
    [self.mapView enableWrapAround];
    self.mapView.layerDelegate = self;
    
    // Load a tiled map service 
	NSURL *mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
    
    // Create a graphics layer and add it to the map
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
    
    // Set the bounds of the slider and the initial value
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 5000;
    self.slider.value = 3000;
    
    int value = (int)self.slider.value;
    _bufferDistance = value;
    
    // Display the distance via the title of the bar button item
    self.distance.title = [NSString stringWithFormat:@"%dm", value];


    // Create an envelope and zoom to it
    AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
    AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin:-8139237.214629 ymin:5016257.541842 xmax: -8090341.387563 ymax:5077377.325675 spatialReference:sr];
    [self.mapView zoomToEnvelope:envelope animated:YES];

    self.userInstructions.text = @"Sketch a geometry and tap the buffer button to see the result";
    self.lastBuffer = [NSMutableArray array];
}


- (void) mapViewDidLoad:(AGSMapView *)mapView {
    // Create a sketch layer and add it to the map
    self.sketchLayer = [AGSSketchGraphicsLayer graphicsLayer];
    self.sketchLayer.geometry = [[AGSMutablePoint alloc] initWithSpatialReference:self.mapView.spatialReference];
    [self.mapView addMapLayer:self.sketchLayer withName:@"Sketch layer"]; 
    self.mapView.touchDelegate = self.sketchLayer;
}

#pragma mark -
#pragma mark Toolbar actions


- (IBAction)buffer {
    self.userInstructions.text = @"Reset or add another geometry";
    
    //Get the sketch geometry
	AGSGeometry* sketchGeometry = [self.sketchLayer.geometry copy];
    
    // A symbol for points on the graphics layer
    AGSSimpleMarkerSymbol *pointSymbol = [[AGSSimpleMarkerSymbol alloc] init];
    pointSymbol.color = [UIColor yellowColor];
    pointSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
    
    //A symbol for lines on the graphics layer
	AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
	lineSymbol.color= [UIColor yellowColor];
	lineSymbol.width = 4;
	
    
    // Create the graphic and assign it the correct symbol according to its geometry type
    // Note: Lines and polygons are symbolized with the simple line symbol here
    AGSGraphic* graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:nil attributes:nil];
    
    if ([sketchGeometry isKindOfClass:[AGSPoint class]]) {
        graphic.symbol = pointSymbol;
    }
    else {
        graphic.symbol = lineSymbol;
    }
    
    
    //Add a new graphic to the graphics layer
    [self.graphicsLayer addGraphic:graphic];
    
    // A symbol for the buffer
    AGSSimpleFillSymbol *innerSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
	innerSymbol.color = [[UIColor redColor] colorWithAlphaComponent:0.40];
	innerSymbol.outline.color = [UIColor darkGrayColor];
    
    // Create the buffer graphics using the geometry engine
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    AGSGeometry *newGeometry = [geometryEngine bufferGeometry:sketchGeometry byDistance:_bufferDistance];
    AGSGraphic *newGraphic = [AGSGraphic graphicWithGeometry:newGeometry symbol:innerSymbol attributes:nil];
        
    [self.lastBuffer addObject:newGraphic];
    
    [self.graphicsLayer addGraphic:newGraphic];

    
    [self.sketchLayer clear];
}



- (IBAction)selectGeometry:(UISegmentedControl*)geomControl {
    
    
    // Set the geometry of the sketch layer to match the selected geometry
    switch (geomControl.selectedSegmentIndex) {
        case 0:
            self.sketchLayer.geometry = [[AGSMutablePoint alloc] initWithSpatialReference:self.mapView.spatialReference];
            break;
        case 1:
            self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];
            break;
        case 2:
            self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
            break;
        default:
            break;
    }
    
    [self.sketchLayer clear];
}


-(IBAction)sliderValueChanged:(UISlider*)slider {
    
    // Get the value of the slider and update
    int value = (int)slider.value;
    _bufferDistance = value;
    self.distance.title = [NSString stringWithFormat:@"%dm", value];
    
    // A symbol for the buffer
    AGSSimpleFillSymbol *innerSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
	innerSymbol.color = [[UIColor redColor] colorWithAlphaComponent:0.40];
	innerSymbol.outline.color = [UIColor darkGrayColor];
    
    // Remove old buffers
    for (AGSGraphic *oldGraphic in self.lastBuffer) {
        [self.graphicsLayer removeGraphic:oldGraphic];
    }
    
    // Create the buffer graphics using the geometry engine
    NSMutableArray *newGraphics = [NSMutableArray array];
    for (AGSGraphic *graphic in self.graphicsLayer.graphics) {
        AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
        AGSGeometry *newGeometry = [geometryEngine bufferGeometry:graphic.geometry byDistance:_bufferDistance];
        AGSGraphic *newGraphic = [AGSGraphic graphicWithGeometry:newGeometry symbol:innerSymbol attributes:nil ];
        [newGraphics addObject:newGraphic];
    }
    
    // Remember the buffer graphics so we can remove them
    self.lastBuffer = newGraphics;
    
    // Add the buffer graphics to the graphics layer and notify it of the change
    [self.graphicsLayer addGraphics:newGraphics];
}

- (IBAction)reset {
    self.userInstructions.text = @"Sketch a geometry and tap the buffer button to see the result";
    self.lastBuffer = [NSMutableArray array];
    [self.graphicsLayer removeAllGraphics];
    [self.sketchLayer clear];
}


#pragma mark -
#pragma mark Memory management

- (void)viewDidUnload {
	
    
    self.lastBuffer = nil;
    self.distance =nil;
    self.slider = nil;
    self.geometrySelect = nil;
    self.resetButton = nil;
    self.bufferButton = nil;
    self.graphicsLayer = nil;
    self.sketchLayer = nil;
    self.mapView = nil;
    self.toolbar = nil;
    self.userInstructions = nil;

    [super viewDidUnload];
}


- (void)dealloc {
    self.bufferButton = nil;
}	

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}




@end
