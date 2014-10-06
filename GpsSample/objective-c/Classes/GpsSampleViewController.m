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

#import "GpsSampleViewController.h"

@implementation GpsSampleViewController

#pragma mark - UIViewController methods


// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSURL *mapUrl = [NSURL URLWithString:@"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
	
    //Listen to KVO notifications for map gps's autoPanMode property
    [self.mapView.locationDisplay addObserver:self
                       forKeyPath:@"autoPanMode"
                          options:(NSKeyValueObservingOptionNew)
                          context:NULL];
    
    //Listen to KVO notifications for map rotationAngle property
    [self.mapView addObserver:self
                   forKeyPath:@"rotationAngle"
                      options:(NSKeyValueObservingOptionNew)
                      context:NULL];
    
    //to display actual images in iOS 7 for segmented control
    if ([[[UIDevice currentDevice] systemVersion] integerValue] >= 7) {
        NSUInteger index = self.autoPanModeControl.numberOfSegments;
        for (int i = 0; i < index; i++) {
            UIImage *image = [self.autoPanModeControl imageForSegmentAtIndex:i];
            UIImage *newImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [self.autoPanModeControl setImage:newImage forSegmentAtIndex:i];
        }
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

    //if autoPanMode changed
    if ([keyPath isEqual:@"autoPanMode"]){

        //Update the label to reflect which autoPanMode is active
        NSString* mode;
        switch (self.mapView.locationDisplay.autoPanMode) {
            case AGSLocationDisplayAutoPanModeOff:
                mode = @"Off";
                self.label.textColor = [UIColor whiteColor];
                break;
            case AGSLocationDisplayAutoPanModeDefault:
                mode = @"Default";
                self.label.textColor = [UIColor whiteColor];
                break;
            case AGSLocationDisplayAutoPanModeNavigation:
                mode = @"Navigation";
                self.label.textColor = [UIColor whiteColor];
                break;
            case AGSLocationDisplayAutoPanModeCompassNavigation:
                mode = @"Compass Navigation";
                self.label.textColor = [UIColor whiteColor];
                break;
                
            default:
                break;
        }
        self.label.text = [NSString stringWithFormat:@"AutoPan Mode: %@",mode];

        //Un-select the segments when autoPanMode changes to OFF
        //Also, restore north-up map rotation
        if(self.mapView.locationDisplay.autoPanMode == AGSLocationDisplayAutoPanModeOff){
            [self.autoPanModeControl setSelectedSegmentIndex:-1];
        }
        
        //Also, restore north-up map rotation if Auto pan goes OFF or back to Default
        if(self.mapView.locationDisplay.autoPanMode == AGSLocationDisplayAutoPanModeOff || self.mapView.locationDisplay.autoPanMode == AGSLocationDisplayAutoPanModeDefault){
            [self.mapView setRotationAngle:0 animated:YES];
        }
    
    
    } 
    //if rotationAngle changed
    else if([keyPath isEqual:@"rotationAngle"]){
        CGAffineTransform transform = CGAffineTransformMakeRotation(-(self.mapView.rotationAngle*3.14)/180);
        [self.northArrowImage setTransform:transform]; 
    } 
    
    //if mapscale changed
    else if([keyPath isEqual:@"mapScale"]){
        if(self.mapView.mapScale < 5000) {
            [self.mapView zoomToScale:50000 withCenterPoint:nil animated:YES];
            [self.mapView removeObserver:self forKeyPath:@"mapScale"];
        }
    }

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    //Pass the interface orientation on to the map's gps so that
    //it can re-position the gps symbol appropriately in 
    //compass navigation mode
    self.mapView.locationDisplay.interfaceOrientation = interfaceOrientation;
    return YES;
}


- (void)viewDidUnload {
    //Stop the GPS, undo the map rotation (if any)
    if(self.mapView.locationDisplay.dataSourceStarted){
        [self.mapView.locationDisplay stopDataSource];
        self.mapView.rotationAngle = 0;
        [self.autoPanModeControl setSelectedSegmentIndex:-1];
    }
    self.mapView = nil;
    self.autoPanModeControl = nil;
    self.label = nil;
    self.northArrowImage = nil;
}



#pragma mark - Action methods


- (IBAction)autoPanModeChanged:(id)sender {
    //Start the map's gps if it isn't enabled already
    if(!self.mapView.locationDisplay.dataSourceStarted)
        [self.mapView.locationDisplay startDataSource];
    
    //Listen to KVO notifications for map scale property
    [self.mapView addObserver:self
                   forKeyPath:@"mapScale"
                      options:(NSKeyValueObservingOptionNew)
                      context:NULL];
    
    
    //Set the appropriate AutoPan mode
    switch (self.autoPanModeControl.selectedSegmentIndex) {
        case 0:
            self.mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanModeDefault;
            //Set a wander extent equal to 75% of the map's envelope
            //The map will re-center on the location symbol only when
            //the symbol moves out of the wander extent
			self.mapView.locationDisplay.wanderExtentFactor = 0.75;
            break;
        case 1:
            self.mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanModeNavigation;
            //Position the location symbol near the bottom of the map
            //A value of 1 positions it at the top edge, and 0 at bottom edge
			self.mapView.locationDisplay.navigationPointHeightFactor = 0.15;
            break;
        case 2:
            self.mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanModeCompassNavigation;
            //Position the location symbol in the center of the map
			self.mapView.locationDisplay.navigationPointHeightFactor = 0.5;
            break;
            
        default:
            break;
    }
}




@end
