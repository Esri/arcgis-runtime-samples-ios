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

#import "CustomHybridViewController.h"
#import <ArcGIS/ArcGIS.h>

@interface CustomHybridViewController()

@property (nonatomic, strong) IBOutlet AGSMapView *hybridView;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;

@end

@implementation CustomHybridViewController



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:@"CustomHybridViewController" bundle:nil];
    if (self) {
        self.view.frame = frame;
        self.hybridView.frame = frame;
        self.view.userInteractionEnabled = YES;
        self.view.alpha = .9;
        
        
    }
    return self;
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //initialize the satellite imagery layer
    AGSOpenStreetMapLayer *satelliteImageryLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:[NSURL URLWithString:@"http://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer"]];
    //add the bing map layer to the hybrid map view
    [self.hybridView addMapLayer:satelliteImageryLayer withName:@"Satellite "];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)showHybridMapAtGraphic:(AGSGraphic*)graphic
{
	//Zoom in to the building footprint
    //Resolution 0.597 = Level 18 of the tiled map service
    [self.hybridView zoomToResolution:0.597 withCenterPoint:graphic.geometry.envelope.center animated:YES];
}

#pragma mark - Action Methods

- (IBAction)zoomIn:(id)sender
{
    //zooms in to the next scale 
	[self.hybridView zoomIn:YES];
}

- (IBAction)zoomOut:(id)sender
{
    //zooms out to the next scale 
	[self.hybridView zoomOut:YES];
}


@end
