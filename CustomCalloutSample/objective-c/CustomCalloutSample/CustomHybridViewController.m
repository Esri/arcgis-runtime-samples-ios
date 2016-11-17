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
    
    //set satellite imagery plus labels map on the map view
    self.hybridView.map = [AGSMap mapWithBasemap:[AGSBasemap imageryWithLabelsBasemap]];
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
    //Scale 2256.994353 = Level 18 of the tiled map service
    [self.hybridView setViewpointCenter:graphic.geometry.extent.center scale:2256.994353 completion:nil];
}

#pragma mark - Action Methods

- (IBAction)zoomIn:(id)sender
{
    //zooms in to the next scale
    [self.hybridView setViewpointScale:(self.hybridView.mapScale / 2.0) completion:nil];
}

- (IBAction)zoomOut:(id)sender
{
    //zooms out to the next scale
    [self.hybridView setViewpointScale:(self.hybridView.mapScale * 2.0) completion:nil];
}


@end
