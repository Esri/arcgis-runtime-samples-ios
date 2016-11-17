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

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@interface SketchToolbar : NSObject <AGSGeoViewTouchDelegate>

@property (nonatomic,strong) AGSSketchEditor* sketchEditor;
@property (nonatomic,strong) AGSMapView* mapView;
@property (nonatomic,strong) AGSGraphicsOverlay* graphicsOverlay;

@property (nonatomic,strong) UISegmentedControl* sketchTools;
@property (nonatomic,strong) UIButton* undoTool;
@property (nonatomic,strong) UIButton* redoTool;
@property (nonatomic,strong) UIButton* saveTool;
@property (nonatomic,strong) UIButton* clearTool;

@property (nonatomic,strong) AGSGraphic* activeGraphic;
@property (nonatomic,strong) AGSGeometry* activeGraphicOriginalGeometry;

- (id)initWithToolbar:(UIToolbar*)toolbar
              mapView:(AGSMapView*) mapView
        graphicsOverlay:(AGSGraphicsOverlay*)graphicsOverlay;

@end
