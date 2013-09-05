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

#import "ProjectViewController.h"

@interface ProjectViewController () {
    UIToolbar *_toolbar;
    UISegmentedControl *_geometrySelect;
    UIBarButtonItem *_resetButton;
    UIBarButtonItem *_projectButton;
    UILabel *_userInstructions;
    
    AGSMapView *_mapView1;
    AGSMapView *_mapView2;
    AGSMapView *_mapView3;
    
    AGSSketchGraphicsLayer  *_sketchLayer;
    AGSGraphicsLayer *_graphicsLayer1;
    AGSGraphicsLayer *_graphicsLayer2;
    AGSGraphicsLayer *_graphicsLayer3;
}

@end

@implementation ProjectViewController

@synthesize userInstructions = _userInstructions;
@synthesize toolbar = _toolbar;
@synthesize geometrySelect = _geometrySelect;
@synthesize resetButton = _resetButton;
@synthesize projectButton = _projectButton;
@synthesize mapView1 = _mapView1;
@synthesize mapView2 = _mapView2;
@synthesize mapView3 = _mapView3;
@synthesize sketchLayer = _sketchLayer;
@synthesize graphicsLayer1 = _graphicsLayer1;
@synthesize graphicsLayer2 = _graphicsLayer2;
@synthesize graphicsLayer3 = _graphicsLayer3;



#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Map 1
    
    self.mapView1.layerDelegate = self;

    // Load a Dynamic map service with spatial reference 4326
	NSURL *map1Url = [NSURL URLWithString:@"http://mobilesampleserver.arcgisonline.com/ArcGIS/rest/services/UCDemo/World/MapServer"];
    AGSDynamicMapServiceLayer *dynamicLyr1 = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:map1Url];
    [self.mapView1 addMapLayer:dynamicLyr1 withName:@"Dynamic Layer 1"];
    
    // Add a graphics layer
    self.graphicsLayer1 = [AGSGraphicsLayer graphicsLayer];
    [self.mapView1 addMapLayer:self.graphicsLayer1 withName:@"GraphicsLayer 1"];
    
        
    // Map 2
    
    self.mapView2.layerDelegate = self;
    self.mapView2.userInteractionEnabled = NO;
    
    // Load a Dynamic map service with spatial reference 54024
    NSURL *map2Url = [NSURL URLWithString:@"http://mobilesampleserver.arcgisonline.com/ArcGIS/rest/services/UCDemo/WorldAitoff/MapServer"];
    AGSDynamicMapServiceLayer *dynamicLyr2 = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:map2Url];
    [self.mapView2 addMapLayer:dynamicLyr2 withName:@"Dynamic Layer 2"];
    
    // Add a graphics layer
    self.graphicsLayer2 = [AGSGraphicsLayer graphicsLayer];
    [self.mapView2 addMapLayer:self.graphicsLayer2 withName:@"Graphics Layer 2"];
    
    // Map 3
    
    self.mapView3.layerDelegate = self;
    self.mapView3.userInteractionEnabled = NO;
    
    // Load a Dynamic map service with spatial reference 54021
    NSURL *map3Url = [NSURL URLWithString:@"http://mobilesampleserver.arcgisonline.com/ArcGIS/rest/services/UCDemo/WorldPolyconic/MapServer"];
    AGSDynamicMapServiceLayer *dynamicLyr3 = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:map3Url];    
    [self.mapView3 addMapLayer:dynamicLyr3 withName:@"Dynamic Layer 3"];
    
     // Add a graphics layer
    self.graphicsLayer3 = [AGSGraphicsLayer graphicsLayer];
    [self.mapView3 addMapLayer:self.graphicsLayer3 withName:@"Graphics Layer 3"];
    
    // A composite symbol to represent the geometries
    AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
	lineSymbol.color= [UIColor yellowColor];
	lineSymbol.width = 4;
    
    AGSSimpleFillSymbol *innerSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
	innerSymbol.color = [[UIColor redColor] colorWithAlphaComponent:0.40];
    innerSymbol.outline = nil;
    
    
    AGSCompositeSymbol *compositeSymbol = [AGSCompositeSymbol compositeSymbol];
    [compositeSymbol addSymbol:lineSymbol];
    [compositeSymbol addSymbol:innerSymbol];

    // A renderer for the graphics layers
    AGSSimpleRenderer *renderer = [AGSSimpleRenderer simpleRendererWithSymbol:compositeSymbol];
    
    self.graphicsLayer1.renderer = renderer;
    self.graphicsLayer2.renderer = renderer;
    self.graphicsLayer3.renderer = renderer;
    
    self.userInstructions.text = @"Sketch a geometry on the upper map and tap the project button";
    
}


- (void) mapViewDidLoad:(AGSMapView *)mapView {
    
    // Add a sketch layer to the top map view
    if (mapView == self.mapView1) {
        AGSMutablePolyline *polyline = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView1.spatialReference];
        self.sketchLayer = [[AGSSketchGraphicsLayer alloc] initWithGeometry:polyline]; 
        [self.mapView1 addMapLayer:self.sketchLayer withName:@"Sketch Layer"];
        self.mapView1.touchDelegate = self.sketchLayer;

    }
   
}


#pragma mark -
#pragma mark Toolbar actions

- (IBAction)project {
    
    
    //Get the sketch geometry
    AGSGeometry *sketchGeometry = [self.sketchLayer.geometry copy];
    
    // Create the graphic and add it to the top graphics layer
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:nil attributes:nil ];
    
    [self.graphicsLayer1 addGraphic:graphic];
    
    
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    
    // Project the geometry to the spatial references of the other mapViews and create new graphics from the projected geometries
    AGSGeometry *map2Geometry = [geometryEngine projectGeometry:graphic.geometry toSpatialReference:self.mapView2.spatialReference];
    AGSGraphic *map2Graphic = [AGSGraphic graphicWithGeometry:map2Geometry symbol:nil attributes:nil ];

    AGSGeometry *map3Geometry = [geometryEngine projectGeometry:graphic.geometry toSpatialReference:self.mapView3.spatialReference];
    AGSGraphic *map3Graphic = [AGSGraphic graphicWithGeometry:map3Geometry symbol:nil attributes:nil ];

    
    // Add the new graphics to the graphics layers
    [self.graphicsLayer2 addGraphic:map2Graphic];

    [self.graphicsLayer3 addGraphic:map3Graphic];
    
    [self.sketchLayer clear];
    
    self.userInstructions.text = @"Sketch another geometry or tap the reset button to start over";
    
}


- (IBAction)selectGeometry:(UISegmentedControl*)geomControl {
    
    // Set the geometry of the sketch layer to match the selected geometry
    switch (geomControl.selectedSegmentIndex) {
        case 0:
            self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView1.spatialReference];
            break;
        case 1:
            self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView1.spatialReference];
            break;
        default:
            break;
    }
    
    [self.sketchLayer clear];
}


- (IBAction)reset {
    [self.graphicsLayer1 removeAllGraphics];
    [self.graphicsLayer2 removeAllGraphics];
    [self.graphicsLayer3 removeAllGraphics];
    [self.sketchLayer clear];
    
    self.userInstructions.text = @"Sketch a geometry on the upper map and tap the project button";
    
}


#pragma mark -
#pragma mark Memory management


- (void)viewDidUnload
{
    self.userInstructions = nil;
    self.toolbar = nil;
    self.geometrySelect = nil;
    self.resetButton = nil;
    self.projectButton = nil;
    self.mapView1 = nil;
    self.mapView2 = nil;    
    self.mapView3 = nil;
    self.sketchLayer = nil;
    self.graphicsLayer1 = nil;
    self.graphicsLayer2 = nil;
    self.graphicsLayer3 = nil;

    
    [super viewDidUnload];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
