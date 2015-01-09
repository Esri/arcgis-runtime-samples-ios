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

#import "UnionDifferenceViewController.h"

@implementation UnionDifferenceViewController

#pragma mark -
#pragma mark View lifecycle


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
    
    
    // Symbols to display geometries
    AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
	lineSymbol.color= [UIColor yellowColor];
	lineSymbol.width = 4;
    
    AGSSimpleMarkerSymbol *pointSymbol = [[AGSSimpleMarkerSymbol alloc] init];
    pointSymbol.color = [UIColor redColor];
    pointSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
    
    AGSSimpleFillSymbol *innerSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
	innerSymbol.color = [[UIColor redColor] colorWithAlphaComponent:0.40];
    innerSymbol.outline = nil;
    
    AGSCompositeSymbol *compositeSymbol = [AGSCompositeSymbol compositeSymbol];
    [compositeSymbol addSymbol:lineSymbol];
    [compositeSymbol addSymbol:pointSymbol];
    [compositeSymbol addSymbol:innerSymbol];
    
    
    // A renderer for the graphics layer
    AGSSimpleRenderer *simpleRenderer = [AGSSimpleRenderer simpleRendererWithSymbol:compositeSymbol];
    
    // Create and add a graphics layer to the map
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    self.graphicsLayer.renderer = simpleRenderer;
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
    
    self.userInstructions.text = @"Draw two intersecting polygons by tapping on the map";
    
}
  
- (void) mapViewDidLoad:(AGSMapView *)mapView {
    
    // Create and add a sketch layer
    self.sketchLayer = [AGSSketchGraphicsLayer graphicsLayer];
    self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
    [self.mapView addMapLayer:self.sketchLayer withName:@"Sketch layer"]; 
    self.mapView.touchDelegate = self.sketchLayer;

}


#pragma mark -
#pragma mark Toolbar actions

- (IBAction)add {
    
    //Get the geometry of the sketch layer
    AGSGeometry *sketchGeometry = [self.sketchLayer.geometry copy];
    
    //Create the graphic and add it to the graphics layer
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:nil attributes:nil ];
    
    [self.graphicsLayer addGraphic:graphic];
    
    [self.sketchLayer clear];
    
    // If we have two graphics
    if (self.graphicsLayer.graphics.count == 2) {
        self.addButton.enabled = NO;
        AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
        
        // Get the geometries from the graphics layer
        AGSGeometry *geometry1 = [[self.graphicsLayer.graphics objectAtIndex:0] geometry];
        AGSGeometry *geometry2 = [[self.graphicsLayer.graphics objectAtIndex:1] geometry];

        // Make a new graphic with the difference of the two geometries
        AGSGeometry *differenceGeometry = [geometryEngine differenceOfGeometry:geometry1 andGeometry:geometry2];   
        self.differenceGraphic = [AGSGraphic graphicWithGeometry:differenceGeometry symbol:nil attributes:nil ];
        
        NSArray *geometries = [NSArray arrayWithObjects:geometry1,geometry2, nil];
        
        // Make a new graphic with the union of the geometries
        self.unionGraphic = [AGSGraphic graphicWithGeometry:[geometryEngine unionGeometries:geometries]
                                                          symbol:nil 
                                                      attributes:nil
                                            ];
        
        [self unionDifference:self.segmentedControl];
        self.userInstructions.text = @"Toggle union and difference";
    }
}

- (IBAction)reset {
    [self.graphicsLayer removeAllGraphics];
    [self.sketchLayer clear];
    
    self.unionGraphic = nil;
    self.differenceGraphic = nil;
    
    self.addButton.enabled = YES;
    self.userInstructions.text = @"Draw two intersecting polygons by tapping on the map";
    
}



-(IBAction)unionDifference:(UISegmentedControl*)segmentedControl {
   
    // Set the graphic for the selected operation
    if (self.unionGraphic && self.differenceGraphic) {
        if (segmentedControl.selectedSegmentIndex == 0) {
            [self.graphicsLayer removeAllGraphics];
            [self.graphicsLayer addGraphic:self.unionGraphic];
        }
        else {
            [self.graphicsLayer removeAllGraphics];
            [self.graphicsLayer addGraphic:self.differenceGraphic];
            
        }
    }
}

#pragma mark -
#pragma mark Memory management

- (void)viewDidUnload
{
    self.userInstructions = nil;
    self.addButton = nil;
    self.resetButton = nil;
    self.mapView = nil;
    self.sketchLayer = nil;
    self.graphicsLayer = nil;
    self.toolbar = nil;
    self.unionGraphic = nil;
    self.differenceGraphic = nil;
    self.segmentedControl = nil;

    [super viewDidUnload];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
