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


#import "SketchToolbar.h"


@implementation SketchToolbar

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (id)initWithToolbar:(UIToolbar*)toolbar sketchLayer:(AGSSketchGraphicsLayer*)sketchLayer mapView:(AGSMapView*) mapView graphicsLayer:(AGSGraphicsLayer*)graphicsLayer{
	
    self = [super init];
    if (self) {
		
		//hold references to the mapView, graphicsLayer, and sketchLayer
		self.sketchLayer = sketchLayer;
		self.mapView = mapView;
		self.graphicsLayer = graphicsLayer;

		//Get references to the UI elements in the toolbar
		//Each UI element was assigned a "tag" in the nib file to make it easy to find them
		self.sketchTools = (UISegmentedControl* )[toolbar viewWithTag:55];
        
        //to display actual images in iOS 7 for segmented control
        if ([[[UIDevice currentDevice] systemVersion] integerValue] >= 7) {
            NSUInteger index = self.sketchTools.numberOfSegments;
            for (int i = 0; i < index; i++) {
                UIImage *image = [self.sketchTools imageForSegmentAtIndex:i];
                UIImage *newImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
                [self.sketchTools setImage:newImage forSegmentAtIndex:i];
            }
        }
        
        //disable the select tool if no graphics available
        [self.sketchTools setEnabled:(graphicsLayer.graphicsCount>0) forSegmentAtIndex:3];
        
		self.undoTool = (UIButton*) [toolbar viewWithTag:56];
		self.redoTool = (UIButton*) [toolbar viewWithTag:57];
		self.saveTool = (UIButton*) [toolbar viewWithTag:58];
		self.clearTool = (UIButton*) [toolbar viewWithTag:59];
		
		//Set target-actions for the UI elements in the toolbar
		[self.sketchTools addTarget:self action:@selector(toolSelected) forControlEvents:UIControlEventValueChanged];
		[self.undoTool addTarget:self action:@selector(undo) forControlEvents:UIControlEventTouchUpInside];
		[self.redoTool addTarget:self action:@selector(redo) forControlEvents:UIControlEventTouchUpInside];
		[self.saveTool addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
		[self.clearTool addTarget:self action:@selector(clear) forControlEvents:UIControlEventTouchUpInside];
		
		//Register for "Geometry Changed" notifications 
		//We want to enable/disable UI elements when sketch geometry is modified
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:nil];

        //call this so we can properly initialize the state of undo,redo,clear, and save
        [self respondToGeomChanged:nil];
    }
    return self;
}

- (void)respondToGeomChanged: (NSNotification*) notification {
	//Enable/disable UI elements appropriately
	self.undoTool.enabled = [self.sketchLayer.undoManager canUndo];
	self.redoTool.enabled = [self.sketchLayer.undoManager canRedo];
	self.clearTool.enabled = ![self.sketchLayer.geometry isEmpty] && self.sketchLayer.geometry!=nil;
	self.saveTool.enabled = [self.sketchLayer.geometry isValid];
}
- (IBAction) undo {
	if([self.sketchLayer.undoManager canUndo]) //extra check, just to be sure
		[self.sketchLayer.undoManager undo];
}
- (IBAction) redo {
	if([self.sketchLayer.undoManager canRedo]) //extra check, just to be sure
		[self.sketchLayer.undoManager redo];
}
- (IBAction) clear {
	[self.sketchLayer clear];
}
- (IBAction) save {
	//Get the sketch geometry
	AGSGeometry* sketchGeometry = [self.sketchLayer.geometry copy];

	//If this is not a new sketch (i.e we are modifying an existing graphic)
	if(self.activeGraphic!=nil){
		//Modify the existing graphic giving it the new geometry
		self.activeGraphic.geometry = sketchGeometry;
		self.activeGraphic = nil;
		
		//Re-enable the sketch tools
		[self.sketchTools setEnabled:YES forSegmentAtIndex:0];
		[self.sketchTools setEnabled:YES forSegmentAtIndex:1];
		[self.sketchTools setEnabled:YES forSegmentAtIndex:2];
        [self.sketchTools setEnabled:YES forSegmentAtIndex:3];
		
	}else {
		//Add a new graphic to the graphics layer
		AGSGraphic* graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:nil attributes:nil ];
		[self.graphicsLayer addGraphic:graphic];
        
        //enable the select tool if there is atleast one graphic to select
        [self.sketchTools setEnabled:(self.graphicsLayer.graphicsCount>0) forSegmentAtIndex:3];

	}
	
	[self.sketchLayer clear];
	[self.sketchLayer.undoManager removeAllActions];
}

- (IBAction) toolSelected {
	switch (self.sketchTools.selectedSegmentIndex) {
		case 0://point tool
			//sketch layer should begin tracking touch events to sketch a point
			self.mapView.touchDelegate = self.sketchLayer;  
			self.sketchLayer.geometry = [[AGSMutablePoint alloc] initWithX:NAN y:NAN spatialReference:self.mapView.spatialReference];
            [[self.sketchLayer undoManager]removeAllActions];
			break;
		
		case 1://polyline tool
			//sketch layer should begin tracking touch events to sketch a polyline
			self.mapView.touchDelegate = self.sketchLayer; 
			self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];
            [[self.sketchLayer undoManager]removeAllActions];
			break;
		
		case 2://polygon tool
			//sketch layer should begin tracking touch events to sketch a polygon
			self.mapView.touchDelegate = self.sketchLayer; 
			self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
            [[self.sketchLayer undoManager]removeAllActions];
			break;
		
		case 3: //select tool
			//nothing to sketch
			self.sketchLayer.geometry = nil; 
			
			//We will track touch events to find which graphic to modify
			self.mapView.touchDelegate = self; 
			

			break;
		default:
			break;
	}
	
}

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{
	//find which graphic to modify
	NSEnumerator *enumerator = [features objectEnumerator];
	NSArray* graphicArray = (NSArray*) [enumerator nextObject];
	if(graphicArray!=nil && [graphicArray count]>0){
		//Get the graphic's geometry to the sketch layer so that it can be modified
		self.activeGraphic = (AGSGraphic*)[graphicArray objectAtIndex:0];
		AGSGeometry* geom = [self.activeGraphic.geometry mutableCopy];
        
        //clear out the graphic's geometry so that it is not displayed under the sketch
        self.activeGraphic.geometry = nil;
        
        //Feed the graphic's geometry to the sketch layer so that user can modify it
		self.sketchLayer.geometry = geom;
        [[self.sketchLayer undoManager]removeAllActions];

		//sketch layer should begin tracking touch events to modify the sketch
		self.mapView.touchDelegate = self.sketchLayer;
		
        //Disable other tools until we finish modifying a graphic
        [self.sketchTools setEnabled:NO forSegmentAtIndex:0];
        [self.sketchTools setEnabled:NO forSegmentAtIndex:1];
        [self.sketchTools setEnabled:NO forSegmentAtIndex:2];
        [self.sketchTools setEnabled:NO forSegmentAtIndex:3];
        
        
		//Activate the appropriate sketch tool
		if([geom isKindOfClass:[AGSPoint class]]){
			[self.sketchTools setSelectedSegmentIndex:0];
		}else if ([geom isKindOfClass:[AGSPolyline class]]) {
			[self.sketchTools setSelectedSegmentIndex:1];
		}else if ([geom isKindOfClass:[AGSPolygon class]]) {
			[self.sketchTools setSelectedSegmentIndex:2];
		}
	}
}


@end
