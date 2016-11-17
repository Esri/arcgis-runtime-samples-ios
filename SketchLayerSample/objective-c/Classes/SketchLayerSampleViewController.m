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
	
	//Create Map with Tiled basemap layer and set it on the mapView
    self.mapView.map = [AGSMap mapWithBasemapType:AGSBasemapTypeTopographic latitude:0 longitude:0 levelOfDetail:0];
	
	//Add Graphics Overlay to the mapView to hold all sketches (points, polylines, and polygons)
    AGSGraphicsOverlay *graphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];

	//A composite symbol for the graphics layer's renderer to symbolize the sketches
    NSMutableArray *syms = [NSMutableArray array];
	AGSSimpleMarkerSymbol* markerSymbol = [[AGSSimpleMarkerSymbol alloc] init];
	markerSymbol.style = AGSSimpleMarkerSymbolStyleSquare;
	markerSymbol.color = [UIColor greenColor];
	[syms addObject:markerSymbol];
	AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
	lineSymbol.color= [UIColor grayColor];
	lineSymbol.width = 4;
	[syms addObject:lineSymbol];
	AGSSimpleFillSymbol* fillSymbol = [[AGSSimpleFillSymbol alloc] init];
	fillSymbol.color = [UIColor colorWithRed:1.0 green:1.0 blue:0 alpha:0.5] ;
	[syms addObject:fillSymbol];
    
    AGSCompositeSymbol* composite = [AGSCompositeSymbol compositeSymbolWithSymbols:syms];
	AGSSimpleRenderer* renderer = [AGSSimpleRenderer simpleRendererWithSymbol:composite];
	graphicsOverlay.renderer = renderer;

	// Assign sketch editor to mapView
    self.mapView.sketchEditor = [AGSSketchEditor sketchEditor];
	
	//Helper class to manage the UI toolbar, Sketch Layer, and Graphics Layer
	//Basically, where the magic happens
	self.sketchToolbar = [[SketchToolbar alloc] initWithToolbar:self.toolbar
														mapView:self.mapView 
												  graphicsOverlay:graphicsOverlay];
//	//Manhanttan, New York
//	AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
//	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-8235886.761869 
//												ymin:4977698.714786 
//												xmax:-8235122.391586
//												ymax:4978797.497068 
//									spatialReference:sr];
//	[self.mapView zoomToEnvelope:env animated:YES];
	
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
