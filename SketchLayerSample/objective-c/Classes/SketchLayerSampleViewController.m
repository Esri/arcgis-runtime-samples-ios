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
    //Initial viewpoint for Manhanttan, New York
    self.mapView.map = [AGSMap mapWithBasemapType:AGSBasemapTypeTopographic
                                         latitude:40.768452 longitude:-73.980796 levelOfDetail:16];
	
	//Add Graphics Overlay to the mapView to hold all sketches (points, polylines, and polygons)
    AGSGraphicsOverlay *graphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];
    [self.mapView.graphicsOverlays addObject:graphicsOverlay];

	//Assign sketch editor to mapView
    self.mapView.sketchEditor = [AGSSketchEditor sketchEditor];
	
	//Helper class to manage the UI toolbar, Sketch Layer, and Graphics Layer
	//Basically, where the magic happens
	self.sketchToolbar = [[SketchToolbar alloc] initWithToolbar:self.toolbar
														mapView:self.mapView 
												  graphicsOverlay:graphicsOverlay];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.mapView = nil;
    self.sketchToolbar = nil;
    self.toolbar = nil;
}

@end
