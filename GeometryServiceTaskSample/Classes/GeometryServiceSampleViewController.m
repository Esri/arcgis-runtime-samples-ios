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

#import "GeometryServiceSampleViewController.h"

@implementation GeometryServiceSampleViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(IBAction) clearGraphicsBtnClicked:(id)sender {
	
	// remove previously buffered geometries
	[self.geometryArray removeAllObjects];

	// clear the graphics layer
	[self.graphicsLayer removeAllGraphics];
	
	// tell the graphics layer that we have modified graphics
	// and it needs to be redrawn
	[self.graphicsLayer refresh];
	
	// reset the number of clicked points
	self.numPoints = 0;
	
	// reset our "directions" label
	self.statusLabel.text = @"Click points to buffer around";
}


-(IBAction) goBtnClicked:(id)sender {
	

	// Make sure the user has clicked at least 1 point
	if ([self.geometryArray count] == 0) {
		UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" 
													 message:@"Please click on at least 1 point" 
													delegate:self 
										   cancelButtonTitle:@"OK" 
										   otherButtonTitles:nil];
		[av show];
		return;
	}
	
	
	self.gst = [[AGSGeometryServiceTask alloc] initWithURL:[NSURL URLWithString:kGeometryBufferService]];
	
	AGSSpatialReference *sr = [[AGSSpatialReference alloc] initWithWKID:kWebMercator WKT:nil];
	
	// assign the delegate so we can respond to AGSGeometryServiceTaskDelegate methods
	self.gst.delegate = self;
	
	AGSBufferParameters *bufferParams = [[AGSBufferParameters alloc] init];
	
	// set the units to buffer by to meters
	bufferParams.unit = kesriSRUnit_Meter;
	bufferParams.bufferSpatialReference = sr;
	
	// set our buffer distances to 100m and 300m respectively
	bufferParams.distances = [NSArray arrayWithObjects:
							  [NSNumber numberWithUnsignedInteger:100],
							  [NSNumber numberWithUnsignedInteger:300],
							  nil];
	
	// assign the geometries to be buffered...
	// self.geometryArray contains the points we clicked
	bufferParams.geometries = self.geometryArray;
	bufferParams.outSpatialReference = sr;
	bufferParams.unionResults = FALSE;
	
	// execute the task 
	[self.gst bufferWithParameters:bufferParams];
	
	// IMPORTANT: since we alloc'd/init'd bufferParams and gst
	// we must explicitly release them

}


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// assign the mapView's delegate to self so we can respond to appropriate events
	self.mapView.layerDelegate = self;
	self.mapView.touchDelegate = self;
	
	NSError *error = nil;
	
	// Create map service info with URL of base map
	AGSMapServiceInfo *msi = [[AGSMapServiceInfo alloc] initWithURL:[NSURL URLWithString:kBaseMapService] error:&error];
	
	if (error != nil) {
		// some error occurred
		// handle it here
		NSLog(@"There was an error!");
		return;
	}
	
	// Create the base layer 
	AGSTiledMapServiceLayer *baseLayer = [[AGSTiledMapServiceLayer alloc] initWithMapServiceInfo:msi];
	
	// Add base layer to the mapView
	[self.mapView addMapLayer:baseLayer withName:@"baseLayer"];
	
	// initialize the graphics layer
	self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
	
	// Add the graphics layer to the mapView
	[self.mapView addMapLayer:self.graphicsLayer withName:@"graphicsLayer"];
	
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}




#pragma mark -
#pragma mark AGSGeometryServiceTaskDelegate Methods

- (void)geometryServiceTask:(AGSGeometryServiceTask *)geometryServiceTask operation:(NSOperation*)op didReturnBufferedGeometries:(NSArray *)bufferedGeometries {
	
	
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Results" 
												 message:[NSString stringWithFormat:@"Returned %lu buffered geometries", (unsigned long)[bufferedGeometries count]]
												delegate:self 
									   cancelButtonTitle:@"Ok" 
									   otherButtonTitles:nil];
	[av show];
	
	[self.graphicsLayer removeAllGraphics];
	[self.graphicsLayer refresh];
	
	// Create a SFS for the inner buffer zone
	AGSSimpleFillSymbol *innerSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
	innerSymbol.color = [[UIColor redColor] colorWithAlphaComponent:0.40];
	innerSymbol.outline.color = [UIColor darkGrayColor];
	
	// Create a SFS for the outer buffer zone
	AGSSimpleFillSymbol *outerSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
	outerSymbol.color = [[UIColor yellowColor] colorWithAlphaComponent:0.25];
	outerSymbol.outline.color = [UIColor darkGrayColor];
	
	// counter to help us determine if the geometry returned is inner/outer
	NSUInteger i = 0;
	
	// NOTE: the bufferedGeometries returned are in order based on buffer distance...
	//
	// so if you clicked 3 points, the order would be:
	// 
	// objectAtIndex		bufferedGeometry
	//
	//		0				pt1 buffered at 100m
	//		1				pt2 buffered at 100m
	//		2				pt3 buffered at 100m
	//		3				pt1 buffered at 300m
	//		4				pt2 buffered at 300m
	//		5				pt3 buffered at 300m
	for (AGSGeometry* g	in bufferedGeometries) {
		
		// initialize the graphic for geometry
		AGSGraphic *graphic = [[AGSGraphic alloc] initWithGeometry:g symbol:nil attributes:nil ];
		
		// since we have 2 buffer distances, we know that 0-2 will be 100m buffer and 3-5 will be 300m buffer
		if (i < [bufferedGeometries count]/2) {
			graphic.symbol = innerSymbol;
		}
		else {
			graphic.symbol = outerSymbol;
		}

		// add graphic to the graphic layer
		[self.graphicsLayer addGraphic:graphic];
		
		// release our alloc'd graphic
		
		// increment counter so we know which index we are at
		i++;
	}
	
	// get rid of the pushpins that were marking our points
	for (AGSGraphic *pushpin in self.pushpins) {
		[self.graphicsLayer removeGraphic:pushpin];
	}
	self.pushpins = nil;
	
	// let the graphics layer know it has new graphics to draw
	[self.graphicsLayer refresh];
}

// Handle the case where the buffer task fails
- (void)geometryServiceTask:(AGSGeometryServiceTask *)geometryServiceTask operation:(NSOperation*)op didFailBufferWithError:(NSError *)error {
	UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" 
												 message:@"There was an error with the buffer task" 
												delegate:self 
									   cancelButtonTitle:@"Ok" 
									   otherButtonTitles:nil];
	[av show];
}

#pragma mark -
#pragma mark AGSMapViewTouchDelegate methods

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{

	
	// create our geometry array if needed
	if (self.geometryArray == nil) {
		self.geometryArray = [NSMutableArray array];
	}

	// add user-clicked point to the geometry array
	[self.geometryArray addObject:mappoint];
	
	// create pushpins array if needed
	if (self.pushpins == nil) {
		self.pushpins = [NSMutableArray array];
	}
	
	// create a PictureMarkerSymbol (pushpin)
	AGSPictureMarkerSymbol *pt = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"pushpin.png"];
	
	// this offset is to line the symbol up with the map was actually clicked
	pt.offset = CGPointMake(8,18);
    
	// init pushpin with the AGSPictureMarkerSymbol we just created
	AGSGraphic *pushpin = [[AGSGraphic alloc] initWithGeometry:mappoint symbol:pt attributes:nil ];
	
	// add pushpin to our array
	[self.pushpins addObject:pushpin];
	
	// add pushpin to graphics layer
	[self.graphicsLayer addGraphic:pushpin];
	
	
	// let the graphics layer know it needs to redraw
	[self.graphicsLayer refresh];
	
	// increment the number of points the user has clicked
	self.numPoints++;
	
	// Update label with number of points clicked
	self.statusLabel.text = [NSString stringWithFormat:@"%ld point(s) selected", (long)self.numPoints];
}

#pragma mark -
#pragma mark AGSMapViewLayerDelegate methods

// Method fired when mapView has finished loading
- (void)mapViewDidLoad:(AGSMapView *)mapView {

	// zoom into california
	AGSEnvelope *env = [[AGSEnvelope alloc] initWithXmin:-13045302.192914002
													ymin:4034680.7648891876
													xmax:-13043773.452348258
													ymax:4036878.3294524443
										spatialReference:[AGSSpatialReference spatialReferenceWithWKID:kWebMercator]];

	[self.mapView zoomToEnvelope:env animated:TRUE];

}	

@end
