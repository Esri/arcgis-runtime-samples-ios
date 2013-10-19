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
@synthesize activeGraphic=_activeGraphic;

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (id)initWithToolbar:(UIToolbar*)toolbar sketchLayer:(AGSSketchGraphicsLayer*)sketchLayer mapView:(AGSMapView*) mapView graphicsLayer:(AGSGraphicsLayer*)graphicsLayer{
	
    self = [super init];
    if (self) {
		
		//hold references to the mapView, graphicsLayer, and sketchLayer
		_sketchLayer = sketchLayer;
		_mapView = mapView;
		_graphicsLayer = graphicsLayer;

		//Get references to the UI elements in the toolbar
		//Each UI element was assigned a "tag" in the nib file to make it easy to find them
		_sketchTools = (UISegmentedControl* )[toolbar viewWithTag:55];
        
        //disable the select tool if no graphics available
        [_sketchTools setEnabled:(graphicsLayer.graphicsCount>0) forSegmentAtIndex:3];
        
		_undoTool = (UIButton*) [toolbar viewWithTag:56];
		_redoTool = (UIButton*) [toolbar viewWithTag:57];
		_saveTool = (UIButton*) [toolbar viewWithTag:58];
		_clearTool = (UIButton*) [toolbar viewWithTag:59];
		
		//Set target-actions for the UI elements in the toolbar
		[_sketchTools addTarget:self action:@selector(toolSelected) forControlEvents:UIControlEventValueChanged];
		[_undoTool addTarget:self action:@selector(undo) forControlEvents:UIControlEventTouchUpInside];
		[_redoTool addTarget:self action:@selector(redo) forControlEvents:UIControlEventTouchUpInside];
		[_saveTool addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
		[_clearTool addTarget:self action:@selector(clear) forControlEvents:UIControlEventTouchUpInside];
		
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
	_undoTool.enabled = [_sketchLayer.undoManager canUndo];
	_redoTool.enabled = [_sketchLayer.undoManager canRedo];
	_clearTool.enabled = ![_sketchLayer.geometry isEmpty] && _sketchLayer.geometry!=nil;
	_saveTool.enabled = [_sketchLayer.geometry isValid];
}
- (IBAction) undo {
	if([_sketchLayer.undoManager canUndo]) //extra check, just to be sure
		[_sketchLayer.undoManager undo];
}
- (IBAction) redo {
	if([_sketchLayer.undoManager canRedo]) //extra check, just to be sure
		[_sketchLayer.undoManager redo];
}
- (IBAction) clear {
	[_sketchLayer clear];
}
- (IBAction) save {
	//Get the sketch geometry
	AGSGeometry* sketchGeometry = [_sketchLayer.geometry copy];

	//If this is not a new sketch (i.e we are modifying an existing graphic)
	if(self.activeGraphic!=nil){
		//Modify the existing graphic giving it the new geometry
		self.activeGraphic.geometry = sketchGeometry;
		self.activeGraphic = nil;
		
		//Re-enable the sketch tools
		[_sketchTools setEnabled:YES forSegmentAtIndex:0];
		[_sketchTools setEnabled:YES forSegmentAtIndex:1];
		[_sketchTools setEnabled:YES forSegmentAtIndex:2];
        [_sketchTools setEnabled:YES forSegmentAtIndex:3];
		
	}else {
		//Add a new graphic to the graphics layer
		AGSGraphic* graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:nil attributes:nil ];
		[_graphicsLayer addGraphic:graphic];
        
        //enable the select tool if there is atleast one graphic to select
        [_sketchTools setEnabled:(_graphicsLayer.graphicsCount>0) forSegmentAtIndex:3];

	}
	
	[_sketchLayer clear];
	[_sketchLayer.undoManager removeAllActions];
}

- (IBAction) toolSelected {
	switch (_sketchTools.selectedSegmentIndex) {
		case 0://point tool
			//sketch layer should begin tracking touch events to sketch a point
			_mapView.touchDelegate = _sketchLayer;  
			_sketchLayer.geometry = [[AGSMutablePoint alloc] initWithX:NAN y:NAN spatialReference:_mapView.spatialReference];
            [[_sketchLayer undoManager]removeAllActions];
			break;
		
		case 1://polyline tool
			//sketch layer should begin tracking touch events to sketch a polyline
			_mapView.touchDelegate = _sketchLayer; 
			_sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:_mapView.spatialReference];
            [[_sketchLayer undoManager]removeAllActions];
			break;
		
		case 2://polygon tool
			//sketch layer should begin tracking touch events to sketch a polygon
			_mapView.touchDelegate = _sketchLayer; 
			_sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:_mapView.spatialReference];
            [[_sketchLayer undoManager]removeAllActions];
			break;
		
		case 3: //select tool
			//nothing to sketch
			_sketchLayer.geometry = nil; 
			
			//We will track touch events to find which graphic to modify
			_mapView.touchDelegate = self; 
			

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
		_sketchLayer.geometry = geom;
        [[_sketchLayer undoManager]removeAllActions];

		//sketch layer should begin tracking touch events to modify the sketch
		_mapView.touchDelegate = _sketchLayer;
		
        //Disable other tools until we finish modifying a graphic
        [_sketchTools setEnabled:NO forSegmentAtIndex:0];
        [_sketchTools setEnabled:NO forSegmentAtIndex:1];
        [_sketchTools setEnabled:NO forSegmentAtIndex:2];
        [_sketchTools setEnabled:NO forSegmentAtIndex:3];
        
        
		//Activate the appropriate sketch tool
		if([geom isKindOfClass:[AGSPoint class]]){
			[_sketchTools setSelectedSegmentIndex:0];
		}else if ([geom isKindOfClass:[AGSPolyline class]]) {
			[_sketchTools setSelectedSegmentIndex:1];
		}else if ([geom isKindOfClass:[AGSPolygon class]]) {
			[_sketchTools setSelectedSegmentIndex:2];
		}


        

	}
}


@end
