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

#import <ArcGIS/ArcGIS.h>
#import "DensifyViewController.h"

@implementation DensifyViewController

// Do any additional setup after loading the view from its nib.
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
    
    AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
	lineSymbol.color= [UIColor yellowColor];
	lineSymbol.width = 4;

    AGSSimpleMarkerSymbol *pointSymbol = [[AGSSimpleMarkerSymbol alloc] init];
    pointSymbol.color = [UIColor redColor];
    pointSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
    pointSymbol.size = CGSizeMake(5, 5);

    // A composite symbol for lines and polygons
    AGSCompositeSymbol *compositeSymbol = [AGSCompositeSymbol compositeSymbol];
    [compositeSymbol addSymbol:lineSymbol];
    [compositeSymbol addSymbol:pointSymbol];
    
    // A renderer for the graphics layer
    AGSSimpleRenderer *simpleRenderer = [AGSSimpleRenderer simpleRendererWithSymbol:compositeSymbol];
    
    // Create a graphics layer and add it to the map.
    // This layer will contain the results of densify operation
    self.resultGraphicsLayer = [AGSGraphicsLayer graphicsLayer];
    self.resultGraphicsLayer.renderer = simpleRenderer;
    [self.mapView addMapLayer:self.resultGraphicsLayer withName:@"Results Layer"];
    
    // Set the limits and current value of the slider
    // Represents the amount by which we want to densify geometries
    self.slider.minimumValue = 1;
    self.slider.maximumValue = 5000;
    self.slider.value = 3000;
    
    int value = (int)self.slider.value;
    self.densifyDistance = value;
    self.distance.title = [NSString stringWithFormat:@"%dm", value];
    
    // Create an envelope and zoom the map to it
    AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
    AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin:-8139237.214629 ymin:5016257.541842 xmax: -8090341.387563 ymax:5077377.325675 spatialReference:sr];
    [self.mapView zoomToEnvelope:envelope animated:YES];
    
    self.userInstructions.text = @"Sketch a geometry and tap the densify button to see the result";
    
    self.sketchGeometries = [NSMutableArray array];
}

- (void) mapViewDidLoad:(AGSMapView *)mapView {
    // Create a sketch layer and add it to the map
    self.sketchLayer = [AGSSketchGraphicsLayer graphicsLayer];
    self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];
    [self.mapView addMapLayer:self.sketchLayer withName:@"Sketch layer"]; 
    self.mapView.touchDelegate = self.sketchLayer;
 
}


-(IBAction)sliderValueChanged:(UISlider*)slider {
    // Get the value of the slider
    // and densify the geometries using the new value
    int value = (int)slider.value;
    self.densifyDistance = value;
    self.distance.title = [NSString stringWithFormat:@"%dm", value];
    
    [self.resultGraphicsLayer removeAllGraphics];
    
    NSMutableArray *newGraphics = [NSMutableArray array];
    
    // Densify the geometries using the geometry engine
    for (AGSGeometry *geometry in self.sketchGeometries) {
        AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
        
        AGSGeometry *newGeometry = [geometryEngine densifyGeometry:geometry withMaxSegmentLength:self.densifyDistance];
        AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:newGeometry symbol:nil attributes:nil ];
        [newGraphics addObject:graphic];
    }
    
    
    [self.resultGraphicsLayer addGraphics:newGraphics];

}

- (IBAction)selectGeometry:(UISegmentedControl*)geomControl {
    
    // Set the geometry of the sketch layer to match 
    // the selected geometry type (polygon or polyline)
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

- (IBAction)reset {
    self.userInstructions.text = @"Sketch a geometry and tap the densify button to see the result";
    
    self.sketchGeometries = [NSMutableArray array];
    [self.resultGraphicsLayer removeAllGraphics];
    [self.sketchLayer clear];
}        


- (IBAction)densify {
    
    self.userInstructions.text = @"Adjust slider to see changes, tap reset to start over ";
    
    // Get the sketch layer's geometry
    AGSGeometry *sketchGeometry = [self.sketchLayer.geometry copy];
    
    // Keep the original geometries to densify again later
    [self.sketchGeometries addObject:sketchGeometry];
    
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    
    // Densify the geometry and create a graphic to add to the result graphics layer
    AGSGeometry *newGeometry = [geometryEngine densifyGeometry:sketchGeometry withMaxSegmentLength:self.densifyDistance];
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:newGeometry symbol:nil attributes:nil ];

    [self.resultGraphicsLayer addGraphic:graphic];
    [self.sketchLayer clear];
    
}


#pragma mark -
#pragma mark Memory management


- (void)viewDidUnload
{
    
    self.userInstructions = nil;
    self.sketchGeometries = nil;
    self.resultGraphicsLayer = nil;
    self.sketchLayer= nil;
    self.toolbar = nil;
    self.distance = nil;
    self.geometryControl = nil;
    self.resetButton = nil;
    self.slider = nil;
    self.mapView = nil;

    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
