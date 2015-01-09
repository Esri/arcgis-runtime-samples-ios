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

#import "CutterViewController.h"

@implementation CutterViewController
	
#pragma mark -
#pragma mark View lifecycle

-(void) viewDidLoad {
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
    
    self.polygonButton.enabled = NO;
    self.cutButton.enabled = NO;
    self.drawButton.enabled = NO;
    
    self.userInstructions.text = @"Tap on the map to sketch a polygon";

}

- (void)mapViewDidLoad:(AGSMapView *)mapView {
    // Create a sketch layer and add it to the map
    self.sketchLayer = [AGSSketchGraphicsLayer graphicsLayer];
    self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
    [self.mapView addMapLayer:self.sketchLayer withName:@"Sketch layer"]; 
    self.mapView.touchDelegate = self.sketchLayer;

    self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
}

- (IBAction)add {
    
    self.drawButton.enabled = YES;
    self.cutButton.enabled = YES;

    
    self.userInstructions.text = @"Tap the line button and sketch a line crossing the polygon";
    
    //Get the sketch geometry
    AGSGeometry *sketchGeometry = [self.sketchLayer.geometry copy];
    
    //Create the graphic and add it to the graphics layer
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:nil attributes:nil ];
    
    AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
	lineSymbol.color= [UIColor yellowColor];
	lineSymbol.width = 4;

    AGSSimpleFillSymbol *innerSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
	innerSymbol.color = [[UIColor redColor] colorWithAlphaComponent:0.40];
    innerSymbol.outline = nil;

    
    //A composite symbol for geometries on the graphics layer
    AGSCompositeSymbol *compositeSymbol = [AGSCompositeSymbol compositeSymbol];
    [compositeSymbol addSymbol:lineSymbol];
    [compositeSymbol addSymbol:innerSymbol];
    graphic.symbol = compositeSymbol;
    
    [self.graphicsLayer addGraphic:graphic];
    [self.sketchLayer clear];
}


- (IBAction)reset {
    
    self.userInstructions.text = @"Tap on the map to sketch a polygon";
    
    self.polygonButton.enabled = NO;
    self.addButton.enabled = YES;
    self.drawButton.enabled = YES;
    self.cutButton.enabled = NO;
    
    [self.graphicsLayer removeAllGraphics];
    [self.sketchLayer clear];
    
    // Reset the sketch layer's geometry to a polygon
    self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];

}

-(IBAction)polygon {
    
    self.userInstructions.text = @"Tap on the map to sketch a polygon";
    
    self.polygonButton.enabled = NO;
    self.addButton.enabled = YES;
    self.cutButton.enabled = NO;
    self.drawButton.enabled = YES;
    
    [self.sketchLayer clear];
    
    // Set the sketch layer's geometry to a polygon
    self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
}

-(IBAction)line {
    self.polygonButton.enabled = YES;
    self.addButton.enabled = NO;
    self.drawButton.enabled = NO;
    self.cutButton.enabled = YES;
    
    self.userInstructions.text = @"Tap the cut button to cut the polygon with the polyline";
    
    // Set the sketch layer's geometry to a line
    self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];

}


-(IBAction)cut {
        
    AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
    lineSymbol.color= [UIColor redColor];
    lineSymbol.width = 4;
    
    AGSSimpleFillSymbol *innerSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
	innerSymbol.color = [[UIColor blueColor] colorWithAlphaComponent:0.40];
    innerSymbol.outline = nil;
    
    // A composite symbol for the new geometry
    AGSCompositeSymbol *compositeSymbol = [AGSCompositeSymbol compositeSymbol];
    [compositeSymbol addSymbol:lineSymbol];
    [compositeSymbol addSymbol:innerSymbol];
    
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    
    // Create the new geometries using the geometry engine to cut the old ones by the cutter
    NSMutableArray *newGraphics = [NSMutableArray array];
    for (AGSGraphic *graphic in self.graphicsLayer.graphics) {
        NSArray *newGeometries = [geometryEngine cutGeometry:graphic.geometry withCutter:(AGSPolyline*)self.sketchLayer.geometry];  
        
        // If the cut was succesful create a graphic and add it to the map
        if (newGeometries.count != 0) {
            for (AGSGeometry *geometry in newGeometries) {
                AGSGraphic *newGraphic = [[AGSGraphic alloc] initWithGeometry:geometry symbol:compositeSymbol attributes:nil ];
                [newGraphics addObject:newGraphic];
            }
        }
        else {
            [newGraphics addObject:graphic];
        }
    }
    
    [self.sketchLayer clear];
    
    [self.graphicsLayer removeAllGraphics];
    [self.graphicsLayer addGraphics:newGraphics];
}

#pragma mark -
#pragma mark Memory management


-(void) viewDidUnload {
	
    self.userInstructions = nil;
    self.drawButton = nil;
    self.toolbar = nil;
    self.polygonButton = nil;
    self.addButton = nil;
    self.resetButton = nil;
    self.cutButton = nil;
    self.mapView = nil;
    self.graphicsLayer = nil;
    self.sketchLayer = nil;

    
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


@end
