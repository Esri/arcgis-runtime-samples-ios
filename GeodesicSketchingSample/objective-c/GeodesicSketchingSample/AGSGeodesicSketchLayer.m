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


#import "AGSGeodesicSketchLayer.h"

@implementation AGSGeodesicSketchLayer

// Override init method to initialize our geometry engine
// you may want to override initWithGeometry: as well
- (id)init {
    if (self = [super init]) {
        self.geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    }
    return self;
}

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Override the method to get the desired functionality
-(void)insertVertex:(AGSPoint*)point inPart:(NSInteger)partIndex atIndex:(NSInteger)coordinateIndex{
    
    // If we can no longer undo, then the next vertex inserted
    // will create a single point not a polyline so don't densify
    BOOL firstPointPlaced = [self.undoManager canUndo];
    
    // Call AGSSketchGraphicsLayer's insertVertex:inPart:atIndex: to get the existing functionality
    [super insertVertex:point inPart:partIndex atIndex:coordinateIndex];
    
    
    
    // Densify the geometry to get geodesic lines drawn rather than just straight lines                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
    if ([self.geometry isKindOfClass:[AGSPolyline class]] && firstPointPlaced) {
        AGSPolyline* densified = (AGSPolyline*)[self.geometryEngine geodesicDensifyGeometry:self.geometry withMaxSegmentLength:50 inUnit:AGSSRUnitSurveyMile];
        
        [self applyGeometry:densified];
    }
    
}



@end
