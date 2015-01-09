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

#import "SketchLayerSampleViewController.h"

@implementation SketchLayerSampleViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Show magnifier to help with sketching
	self.mapView.showMagnifierOnTapAndHold = YES;
	
	//Tiled basemap layer 
	NSURL *mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
	
	//Graphics layer to hold all sketches (points, polylines, and polygons)
	AGSGraphicsLayer* graphicsLayer = [AGSGraphicsLayer graphicsLayer];
	[self.mapView addMapLayer:graphicsLayer withName:@"Graphics Layer"];

	//A composite symbol for the graphics layer's renderer to symbolize the sketches
	AGSCompositeSymbol* composite = [AGSCompositeSymbol compositeSymbol];
	AGSSimpleMarkerSymbol* markerSymbol = [[AGSSimpleMarkerSymbol alloc] init];
	markerSymbol.style = AGSSimpleMarkerSymbolStyleSquare;
	markerSymbol.color = [UIColor greenColor];
	[composite addSymbol:markerSymbol];
	AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
	lineSymbol.color= [UIColor grayColor];
	lineSymbol.width = 4;
	[composite addSymbol:lineSymbol];
	AGSSimpleFillSymbol* fillSymbol = [[AGSSimpleFillSymbol alloc] init];
	fillSymbol.color = [UIColor colorWithRed:1.0 green:1.0 blue:0 alpha:0.5] ;
	[composite addSymbol:fillSymbol];
	AGSSimpleRenderer* renderer = [AGSSimpleRenderer simpleRendererWithSymbol:composite];
	graphicsLayer.renderer = renderer;

	//Sketch layer	
	AGSSketchGraphicsLayer* sketchLayer = [[AGSSketchGraphicsLayer alloc] initWithGeometry:nil];
	[self.mapView addMapLayer:sketchLayer withName:@"Sketch layer"]; 
	
	//Helper class to manage the UI toolbar, Sketch Layer, and Graphics Layer
	//Basically, where the magic happens
	self.sketchToolbar = [[SketchToolbar alloc] initWithToolbar:self.toolbar 
													sketchLayer:sketchLayer 
														mapView:self.mapView 
												  graphicsLayer:graphicsLayer];
	//Manhanttan, New York
	AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-8235886.761869 
												ymin:4977698.714786 
												xmax:-8235122.391586
												ymax:4978797.497068 
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:YES];
	
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	self.mapView = nil;
    self.sketchToolbar = nil;
    self.toolbar = nil;
}



@end
