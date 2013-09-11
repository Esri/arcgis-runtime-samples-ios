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

#import "MeasureViewController.h"
#import "UnitSelectorViewController.h"

@interface MeasureViewController () {
    AGSMapView *_mapView;
    UIToolbar  *_toolbar;
    UISegmentedControl *_measureMethod;
    UIBarButtonItem *_undoButton;
    UIBarButtonItem *_redoButton;
    UIBarButtonItem *_resetButton;
    AGSGraphicsLayer *_graphicsLayer;
    AGSSketchGraphicsLayer *_sketchLayer;
    UILabel *_userInstructions;
    UIButton *_selectUnitButton;
    
    
    double _distance;
    double _area;
    AGSSRUnit _distanceUnit;
    AGSAreaUnits _areaUnit;
}

- (void)updateDistance:(AGSSRUnit)unit ;
- (void)updateArea:(AGSAreaUnits)unit ;


@end

@implementation MeasureViewController

@synthesize userInstructions = _userInstructions;
@synthesize resetButton = _resetButton;
@synthesize redoButton = _redoButton;
@synthesize undoButton = _undoButton;
@synthesize measureMethod = _measureMethod;
@synthesize mapView =_mapView;
@synthesize toolbar = _toolbar;
@synthesize sketchLayer = _sketchLayer;
@synthesize selectUnitButton = _selectUnitButton;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.showMagnifierOnTapAndHold = YES;
    [self.mapView enableWrapAround];
    self.mapView.layerDelegate = self;
    
    // Load a tiled map service 
	NSURL *mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
 
    
    self.userInstructions.text = @"Sketch on the map to measure distance or area";
    
    // Register for geometry changed notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:nil];
    
    self.selectUnitButton.backgroundColor = [UIColor clearColor];

    // Set the default measures and units
    _distance = 0;
    _area = 0;
    _distanceUnit = AGSSRUnitSurveyMile;
    _areaUnit = AGSAreaUnitsAcres;

}

- (void) mapViewDidLoad:(AGSMapView *)mapView {
    // Create and add a sketch layer to the map
    self.sketchLayer = [AGSSketchGraphicsLayer graphicsLayer];
    self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];
    [self.mapView addMapLayer:self.sketchLayer withName:@"Sketch layer"]; 
    self.mapView.touchDelegate = self.sketchLayer;
}


- (void)respondToGeomChanged:(NSNotification*)notification {
    
    // Enable/Disable redo, undo, and add buttons
    self.undoButton.enabled = [self.sketchLayer.undoManager  canUndo];
    self.redoButton.enabled = [self.sketchLayer.undoManager canRedo];
    self.resetButton.enabled = ![self.sketchLayer.geometry isEmpty] && self.sketchLayer.geometry !=nil;

    //return if we don't have a valid geometry yet
    //polyline must have atleast 2 vertices, polygon must have atleast 3
    AGSGeometry *sketchGeometry = self.sketchLayer.geometry;
    if (![sketchGeometry isValid]) {
        return;
    }
    
    // Update the distance and area whenever the geometry changes
    if ([sketchGeometry isKindOfClass:[AGSMutablePolyline class]]) {
        [self updateDistance:_distanceUnit];
    }
    else if ([sketchGeometry isKindOfClass:[AGSMutablePolygon class]]){
        [self updateArea:_areaUnit];
    }
}


- (void)updateDistance:(AGSSRUnit)unit {
    
    // Get the sketch layer's geometry
    AGSGeometry *sketchGeometry = self.sketchLayer.geometry;
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];

    // Get the geodesic distance of the current line
    _distance = [geometryEngine geodesicLengthOfGeometry:sketchGeometry inUnit:_distanceUnit];
    
    // Display the current unit
    NSString *distanceUnitString = nil;
    switch (_distanceUnit) {
        case AGSSRUnitSurveyMile:
            distanceUnitString = @"Miles";
            break;
        case AGSSRUnitSurveyYard:
            distanceUnitString = @"Yards";
            break;
        case AGSSRUnitSurveyFoot:
            distanceUnitString = @"Feet";
            break;
        case AGSSRUnitKilometer:
            distanceUnitString = @"Kilometers";
            break;
        case AGSSRUnitMeter:
            distanceUnitString = @"Meters";
            break;
        default:
            break;
    }

    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumFractionDigits:0];
    
    self.userInstructions.text = [NSString stringWithFormat:@"%@", [formatter stringFromNumber:[NSNumber numberWithDouble:_distance]]];
    [self.selectUnitButton setTitle:distanceUnitString forState:UIControlStateNormal];
    

}

- (void)updateArea:(AGSAreaUnits)unit {
    
    // Get the sketch layer's geometry
    AGSGeometry *sketchGeometry = self.sketchLayer.geometry;
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    
    // Get the area of the current polygon
    _area = [geometryEngine shapePreservingAreaOfGeometry:sketchGeometry inUnit:_areaUnit];
    
    // Display the current unit
    NSString *areaUnitString = nil;
    switch (_areaUnit) {
        case AGSAreaUnitsSquareMiles:
            areaUnitString = @"Square Miles";
            break;
        case AGSAreaUnitsAcres:
            areaUnitString = @"Acres";
            break;
        case AGSAreaUnitsSquareYards:
            areaUnitString = @"Square Yards";
            break;
        case AGSAreaUnitsSquareKilometers:
            areaUnitString = @"Square Kilometers";
            break;
        case AGSAreaUnitsSquareMeters:
            areaUnitString = @"Square Meters";
        default:
            break;
    }

    NSNumberFormatter* formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [formatter setMaximumFractionDigits:0];
    
    self.userInstructions.text = [NSString stringWithFormat:@"%@", [formatter stringFromNumber:[NSNumber numberWithDouble:_area]]];
    [self.selectUnitButton setTitle:areaUnitString forState:UIControlStateNormal];
    
}

- (IBAction)measure:(UISegmentedControl*)measureMethod {
    
    // Set the geometry of the sketch layer to match the selected geometry
    if (measureMethod.selectedSegmentIndex == 0) {
        self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];
    }
    else {
        self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
    }
}

// Delegate method called by UnitSelectorViewController to update the distance unit
- (void)didSelectAreaUnit:(AGSAreaUnits)unit {
    _areaUnit = unit;
    [self updateArea:unit];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Delegate method called by UnitSelectorViewController to update the area units
- (void)didSelectDistanceUnit:(AGSSRUnit)unit {
    _distanceUnit = unit;
    [self updateDistance:unit];
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Called when the button under user instructions is tapped
- (IBAction)selectUnit {
    // Create a UnitSelectorViewController
    UnitSelectorViewController *inputVC = [[UnitSelectorViewController alloc] initWithNibName:@"UnitSelectorViewController" bundle:nil];
    // Set the delegate to self
    inputVC.delegate = self;
    
    // Tell the view controller wheather we want distance units or area units
    if (self.measureMethod.selectedSegmentIndex == 0) {
        inputVC.useAreaUnits = NO;
    }
    else {
        inputVC.useAreaUnits = YES;
    }
    
    // Make the contoller the correct size and style
    inputVC.modalPresentationStyle = UIModalPresentationFormSheet;
    inputVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:inputVC animated:YES completion:nil];
    inputVC.view.superview.bounds = CGRectMake(-150, 0, 300, 220);
}

- (IBAction)reset {
    self.userInstructions.text = @"Sketch on the map to measure distance or area";
    [self.sketchLayer clear];
}

// The undo action gets called when the undo button is pressed 
- (IBAction) undo {
	if([self.sketchLayer.undoManager canUndo]) //extra check, just to be sure
		[self.sketchLayer.undoManager undo];
}

// The redo action gets called when the redo button is pressed
- (IBAction)redo {
    if ([self.sketchLayer.undoManager canRedo])
        [self.sketchLayer.undoManager redo];
    
}


#pragma mark -
#pragma mark Memory management


- (void)viewDidUnload
{
    
    self.resetButton = nil;
    self.redoButton = nil;
    self.undoButton = nil;
    self.measureMethod = nil;
    self.mapView = nil;
    self.toolbar = nil;
    self.sketchLayer = nil;
    self.userInstructions = nil;
    self.selectUnitButton = nil;

    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
