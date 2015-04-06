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

#import "LocalTiledLayerViewController.h"
#import <ArcGIS/ArcGIS.h>

@interface LocalTiledLayerViewController()

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSLocalTiledLayer *localTiledLayer;

@end

@implementation LocalTiledLayerViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    //Remove the file extension (if it exists) from the name
    NSString* fileExtension = [self.tilePackage pathExtension];
    if (![fileExtension isEqualToString:@""]) {
        self.tilePackage = [self.tilePackage stringByDeletingPathExtension];
    }
    
	//Initialze the layer
	self.localTiledLayer = [AGSLocalTiledLayer localTiledLayerWithName:self.tilePackage];
    

	//If layer was initialized properly, add to the map 
	if(self.localTiledLayer != nil && !self.localTiledLayer.error){
			[self.mapView addMapLayer:self.localTiledLayer withName:@"Local Tiled Layer"];
	}else{
        [[[UIAlertView alloc]initWithTitle:@"Could not load tile package" message:[self.localTiledLayer.error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}

- (void)viewDidUnload 
{
  	self.mapView = nil;
    self.localTiledLayer = nil;
    self.tilePackage = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end
