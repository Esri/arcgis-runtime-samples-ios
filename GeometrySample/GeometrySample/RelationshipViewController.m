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

#import "RelationshipViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface SpatialRelationshipContainer : NSObject 

@property BOOL checked;
@property int spatialRelationship;
@property (nonatomic, strong) NSString *name;

- (id)initWithSpatialRelationship:(int)spatialRelationship 
                          andName:(NSString*)relationshipName;

@end


@implementation SpatialRelationshipContainer

- (id)initWithSpatialRelationship:(int)relationship 
                          andName:(NSString*)relationshipName {
    if (self = [super init]) {
        self.checked = NO;
        self.spatialRelationship = relationship;
        self.name = relationshipName;
    }
    
    return self;
}


@end

@implementation RelationshipViewController

// Do any additional setup after loading the view from its nib.
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
    
    // Create a graphics layer and add it to the map
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
    
    
    // Create a container for each of the spatial relationships
    SpatialRelationshipContainer *within = [[SpatialRelationshipContainer alloc] initWithSpatialRelationship:0 andName:@"Within"];
    SpatialRelationshipContainer *touches = [[SpatialRelationshipContainer alloc] initWithSpatialRelationship:1 andName:@"Touches"];
    SpatialRelationshipContainer *overlaps = [[SpatialRelationshipContainer alloc] initWithSpatialRelationship:2 andName:@"Overlaps"];
    SpatialRelationshipContainer *intersects = [[SpatialRelationshipContainer alloc] initWithSpatialRelationship:3 andName:@"Intersects"];
    SpatialRelationshipContainer *crosses = [[SpatialRelationshipContainer alloc] initWithSpatialRelationship:4 andName:@"Crosses"];
    SpatialRelationshipContainer *contains = [[SpatialRelationshipContainer alloc] initWithSpatialRelationship:5 andName:@"Contains"];
    SpatialRelationshipContainer *disjoint = [[SpatialRelationshipContainer alloc] initWithSpatialRelationship:6 andName:@"Disjoint"];
    
    self.spatialRelationships = [NSMutableArray arrayWithObjects:within,touches,overlaps,intersects,crosses,contains,disjoint, nil];
    
    self.relationshipTable.delegate = self;
    self.relationshipTable.dataSource = self;
    self.relationshipTable.scrollEnabled = NO;
    [self.relationshipTable setBackgroundColor:[UIColor whiteColor]];
    [self.relationshipTable.layer setCornerRadius:5];
    [self.relationshipTable.layer setBorderWidth:1];
    [self.relationshipTable.layer setBorderColor:[UIColor grayColor].CGColor];
    [self.relationshipTable setAlpha:0.8];
    
    AGSSimpleMarkerSymbol *pointSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
    pointSymbol.color = [UIColor blueColor];
    
    AGSSimpleLineSymbol* lineSymbol = [[AGSSimpleLineSymbol alloc] init];
	lineSymbol.color= [UIColor yellowColor];
	lineSymbol.width = 4;
    
    AGSSimpleFillSymbol *innerSymbol = [AGSSimpleFillSymbol simpleFillSymbol];
	innerSymbol.color = [[UIColor redColor] colorWithAlphaComponent:0.40];
    innerSymbol.outline = nil;
    
    
   
    // A composite symbol to symbolize geometries
    AGSCompositeSymbol *compositeSymbol = [AGSCompositeSymbol compositeSymbol];
    [compositeSymbol addSymbol:pointSymbol];
    [compositeSymbol addSymbol:lineSymbol];
    [compositeSymbol addSymbol:innerSymbol];
    
    // A renderer for the graphics layer
    AGSSimpleRenderer *renderer = [AGSSimpleRenderer simpleRendererWithSymbol:compositeSymbol];
    self.graphicsLayer.renderer = renderer;

    self.userInstructions.text = @"Sketch two geometries to see their spatial relationships";
    
}

- (void) mapViewDidLoad:(AGSMapView *)mapView {
    // Create and add a sketch layer to the map
    self.sketchLayer = [AGSSketchGraphicsLayer graphicsLayer];
    self.sketchLayer.geometry = [[AGSMutablePoint alloc] initWithSpatialReference:self.mapView.spatialReference];
    [self.mapView addMapLayer:self.sketchLayer withName:@"Sketch layer"]; 
    self.mapView.touchDelegate = self.sketchLayer;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // The number of sections should be equal to the number of spatial relationships we have
    return [self.spatialRelationships count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *kCustomCellID = @"MyCellID";
	
    // Create a cell
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomCellID];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCustomCellID];
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    // Disable selection
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

	// Get the cell text from the relationship container name
	SpatialRelationshipContainer *relContainer = [self.spatialRelationships objectAtIndex:indexPath.row];
	cell.textLabel.text = relContainer.name;
    
    // If the relationship checked property has been set show a checked box otherwise show an unchecked one
    UIImage *image = relContainer.checked ? [UIImage imageNamed:@"checkbox_full.png"] : [UIImage imageNamed:@"checkbox_empty.png"];
    
    // Match the button's size with the image size
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
	button.frame = frame;	
	
	[button setBackgroundImage:image forState:UIControlStateNormal];

    button.backgroundColor = [UIColor clearColor];
	cell.accessoryView = button;
    cell.accessoryView.userInteractionEnabled = NO;
    
    return cell;
}


#pragma mark -
#pragma mark Toolbar actions

- (IBAction)add {
    // Get the sketch layer's geometry and add a new graphic to the graphics layer
    AGSGeometry *sketchGeometry = [self.sketchLayer.geometry copy];
    AGSGraphic *graphic = [AGSGraphic graphicWithGeometry:sketchGeometry symbol:nil attributes:nil ];

    [self.graphicsLayer addGraphic:graphic];
    
    [self.sketchLayer clear];
    
    // If we exactly two geometries
    if (self.graphicsLayer.graphics.count == 2) {
        AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
        
        // Get the geometries from the graphicslayer's graphics
        AGSGraphic *graphic1 = [self.graphicsLayer.graphics objectAtIndex:0];
        AGSGraphic *graphic2 = [self.graphicsLayer.graphics objectAtIndex:1];
        
        // If any of the spatial relationships occur set that spatial relationship container's checked property
        if ([geometryEngine geometry:graphic1.geometry withinGeometry:graphic2.geometry]) {
            [[self.spatialRelationships objectAtIndex:0] setChecked:YES];
        }
        if ([geometryEngine geometry:graphic1.geometry touchesGeometry:graphic2.geometry]) {
            [[self.spatialRelationships objectAtIndex:1] setChecked:YES];
        }
        if ([geometryEngine geometry:graphic1.geometry overlapsGeometry:graphic2.geometry]) {
            [[self.spatialRelationships objectAtIndex:2] setChecked:YES];
        }
        if ([geometryEngine geometry:graphic1.geometry intersectsGeometry:graphic2.geometry]) {
            [[self.spatialRelationships objectAtIndex:3] setChecked:YES];
        }
        if ([geometryEngine geometry:graphic1.geometry crossesGeometry:graphic2.geometry]) {
            [[self.spatialRelationships objectAtIndex:4] setChecked:YES];
        }
        if ([geometryEngine geometry:graphic1.geometry containsGeometry:graphic2.geometry]) {
            [[self.spatialRelationships objectAtIndex:5] setChecked:YES];
        }
        if ([geometryEngine geometry:graphic1.geometry disjointToGeometry:graphic2.geometry]) {
            [[self.spatialRelationships objectAtIndex:6] setChecked:YES];
        }

        // Reload the table
        [self.relationshipTable reloadData];
        
        self.mapView.touchDelegate = nil;
        self.geometrySelect.enabled = NO;
        self.addButton.enabled = NO;
        
        self.userInstructions.text = @"Tap the reset button to start over";
    }
             

}

- (IBAction)reset {
    self.mapView.touchDelegate = self.sketchLayer;
    self.geometrySelect.enabled = YES;
    self.addButton.enabled = YES;
    [self.graphicsLayer removeAllGraphics];
    [self.sketchLayer clear];
    
    // Reset the checked property for all spatial relationships
    for (int i = 0; i < self.spatialRelationships.count; i++) {
        [[self.spatialRelationships objectAtIndex:i] setChecked:NO];
    }
    
    // Reload the table
    [self.relationshipTable reloadData];
    
    self.userInstructions.text = @"Sketch two overlapping geometries and add them to the map";
}

- (IBAction)selectGeometry:(UISegmentedControl*)geomControl {
    
    // Set the geometry of the sketch layer to match the selected geometry
    switch (geomControl.selectedSegmentIndex) {
        case 0:
            self.sketchLayer.geometry = [[AGSMutablePoint alloc] initWithSpatialReference:self.mapView.spatialReference];
            break;
        case 1:
            self.sketchLayer.geometry = [[AGSMutablePolyline alloc] initWithSpatialReference:self.mapView.spatialReference];
            break;
        case 2:
            self.sketchLayer.geometry = [[AGSMutablePolygon alloc] initWithSpatialReference:self.mapView.spatialReference];
            break;
        default:
            break;
    }
    
    [self.sketchLayer clear];
}

#pragma mark -
#pragma mark Memory management



- (void)viewDidUnload
{
    
    self.userInstructions = nil;
    self.graphicsLayer = nil;
    self.spatialRelationships = nil;
    self.sketchLayer = nil;
    self.mapView = nil;
    self.relationshipTable = nil;
    self.toolbar = nil;
    self.addButton = nil;
    self.resetButton = nil;
    self.geometrySelect = nil;
    

    [super viewDidUnload];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
