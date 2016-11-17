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

- (id)initWithToolbar:(UIToolbar*)toolbar
              mapView:(AGSMapView*) mapView
      graphicsOverlay:(AGSGraphicsOverlay*)graphicsOverlay{
	
    self = [super init];
    if (self) {
		
		//hold references to the mapView, graphicsLayer, and sketchLayer
		self.mapView = mapView;
        self.mapView.touchDelegate = self;
        self.sketchEditor = mapView.sketchEditor;
		self.graphicsOverlay = graphicsOverlay;
        
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
        [self.sketchTools setEnabled:(graphicsOverlay.graphics.count>0) forSegmentAtIndex:3];
        
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchEditorGeometryDidChangeNotification object:nil];

        //call this so we can properly initialize the state of undo,redo,clear, and save
        [self respondToGeomChanged:nil];
    }
    return self;
}

- (void)respondToGeomChanged: (NSNotification*) notification {
	//Enable/disable UI elements appropriately
	self.undoTool.enabled = [self.sketchEditor.undoManager canUndo];
	self.redoTool.enabled = [self.sketchEditor.undoManager canRedo];
	self.clearTool.enabled = ![self.sketchEditor.geometry isEmpty] && self.sketchEditor.geometry!=nil;
	self.saveTool.enabled = [self.sketchEditor isSketchValid];
}
- (IBAction) undo {
    if([self.sketchEditor.undoManager canUndo]){ //extra check, just to be sure
		[self.sketchEditor.undoManager undo];
    }
}
- (IBAction) redo {
    if([self.sketchEditor.undoManager canRedo]){ //extra check, just to be sure
		[self.sketchEditor.undoManager redo];
    }
}
- (IBAction) clear {
	[self.sketchEditor clearGeometry];
}
- (IBAction) save {
	//Get the sketch geometry
	AGSGeometry* sketchGeometry = self.sketchEditor.geometry;

	//If this is not a new sketch (i.e we are modifying an existing graphic)
	if(self.activeGraphic!=nil){
		//Modify the existing graphic giving it the new geometry
		self.activeGraphic.geometry = sketchGeometry;
		self.activeGraphic = nil;
		
		//Re-enable the sketch tools
		[self.sketchTools setEnabled:YES forSegmentAtIndex:0];
		[self.sketchTools setEnabled:YES forSegmentAtIndex:1];
		[self.sketchTools setEnabled:YES forSegmentAtIndex:2];
		
	}else {
		//Add a new graphic to the graphics layer
		AGSGraphic* graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:[self symbolForGeometryType:sketchGeometry.geometryType] attributes:nil];
		[self.graphicsOverlay.graphics addObject:graphic];
	}
    
    //enable and select the select tool if there is atleast one graphic to select
    [self.sketchTools setEnabled:(self.graphicsOverlay.graphics.count>0) forSegmentAtIndex:3];
    if (self.graphicsOverlay.graphics.count>0){
        self.sketchTools.selectedSegmentIndex = 3;
        [self.sketchTools setEnabled:YES forSegmentAtIndex:3];
    }
    else{
        [self.sketchTools setEnabled:NO forSegmentAtIndex:3];
    }
 
    // stop sketch editor now
    [self.sketchEditor stop];
}

- (IBAction) toolSelected {
	switch (self.sketchTools.selectedSegmentIndex) {
		case 0://point tool
			//sketch layer should begin tracking touch events to sketch a point
            [self.sketchEditor startWithGeometryType:AGSGeometryTypePoint];
			break;
		
		case 1://polyline tool
			//sketch layer should begin tracking touch events to sketch a polyline
            [self.sketchEditor startWithGeometryType:AGSGeometryTypePolyline];
			break;
		
		case 2://polygon tool
			//sketch layer should begin tracking touch events to sketch a polygon
            [self.sketchEditor startWithGeometryType:AGSGeometryTypePolygon];
			break;
		
		case 3: //select tool
			//We will track touch events to find which graphic to modify
            [self.sketchEditor stop];

			break;
		default:
			break;
	}
	
}

- (void)geoView:(AGSGeoView *)geoView didTapAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint{
    
    __weak __typeof(self) weakSelf = self;
    
    // need to hit test the graphics layer to see if a saved graphics was tapped
    
    [self.mapView identifyGraphicsOverlay:self.graphicsOverlay
                              screenPoint:screenPoint
                                tolerance:12
                         returnPopupsOnly:NO
                           maximumResults:1
                               completion:^(AGSIdentifyGraphicsOverlayResult * _Nonnull identifyResult) {
        
                                   // set activeGraphic
                                   weakSelf.activeGraphic = identifyResult.graphics.firstObject;
                                   if (!weakSelf.activeGraphic){
                                       return;
                                   }
                                   
                                   AGSGeometry *geom = weakSelf.activeGraphic.geometry;
                                   
                                   //Feed the graphic's geometry to the sketch layer so that user can modify it
                                   [weakSelf.sketchEditor startWithGeometry:geom];
                                   
                                   //clear out the graphic's geometry so that it is not displayed under the sketch
                                   weakSelf.activeGraphic.geometry = nil;
                                   
                                   //Disable other tools until we finish modifying a graphic
                                   [weakSelf.sketchTools setEnabled:NO forSegmentAtIndex:0];
                                   [weakSelf.sketchTools setEnabled:NO forSegmentAtIndex:1];
                                   [weakSelf.sketchTools setEnabled:NO forSegmentAtIndex:2];
                                   [weakSelf.sketchTools setEnabled:NO forSegmentAtIndex:3];
                                   
                                   //select appropriate sketch tool
                                   switch (geom.geometryType) {
                                       case AGSGeometryTypePoint:
                                           [weakSelf.sketchTools setSelectedSegmentIndex:0];
                                       case AGSGeometryTypePolyline:
                                           [weakSelf.sketchTools setSelectedSegmentIndex:1];
                                       case AGSGeometryTypePolygon:
                                           [weakSelf.sketchTools setSelectedSegmentIndex:2];
                                       default: ;
                                   }
                                   
                               }];
}

-(AGSSymbol*)symbolForGeometryType:(AGSGeometryType)geometryType{
    
    switch (geometryType) {
        case AGSGeometryTypePoint:
        case AGSGeometryTypeMultipoint:
        {
            AGSSimpleMarkerSymbol* markerSymbol = [[AGSSimpleMarkerSymbol alloc] init];
            markerSymbol.style = AGSSimpleMarkerSymbolStyleSquare;
            markerSymbol.color = [UIColor greenColor];
            markerSymbol.size = 12;
            return markerSymbol;
        }
            
        case AGSGeometryTypePolyline:{
            AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
            lineSymbol.color= [UIColor grayColor];
            lineSymbol.width = 4;
            return lineSymbol;
        }
            
        case AGSGeometryTypePolygon:{
            AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
            lineSymbol.color= [UIColor grayColor];
            lineSymbol.width = 4;
            
            AGSSimpleFillSymbol* fillSymbol = [[AGSSimpleFillSymbol alloc] init];
            fillSymbol.color = [UIColor colorWithRed:1.0 green:1.0 blue:0 alpha:0.5];
            fillSymbol.outline = lineSymbol;
            return fillSymbol;
        }
            
        default:
            return nil;
    }
}

@end


