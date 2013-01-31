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

@synthesize hybridView = _hybridView;



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithNibName:@"CustomHybridViewController" bundle:nil];
    if (self) {
        self.view.frame = frame;
        self.hybridView.frame = frame;
        self.view.userInteractionEnabled = YES;
        self.view.alpha = .9;
        
        //initialize the bing map layer
        AGSBingMapLayer* bingLayer = [[AGSBingMapLayer alloc] initWithAppID:@"ApW8SZU7fZGUZ9eoEfyp6nJZdrcVM7s2TMWqtDx7PWEh74OZBN1lHVaAiZf-fUwZ" style:AGSBingMapLayerStyleAerialWithLabels]; //Do not forget to replace this app id with your own app id. 
        
        //add the bing map layer to the hybrid map view
        [self.hybridView addMapLayer:bingLayer withName:@"Bing"];     
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
    // Do any additional setup after loading the view from its nib.
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
	
    //getting the scale of the hybrid map view
	double scale = self.hybridView.mapScale;
    
    //this is the scale that we are interested in for a particular point
	double targetScale = 10000;
    
    //zooms to the appropriate scale. 
	[self.hybridView zoomWithFactor:targetScale/scale atAnchorPoint:CGPointZero animated:NO];
    
    //center the hybrid
	[self.hybridView centerAtPoint:graphic.geometry.envelope.center animated:YES];
	
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
