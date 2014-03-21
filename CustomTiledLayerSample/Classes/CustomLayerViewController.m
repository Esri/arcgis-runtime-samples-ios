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

#import "CustomLayerViewController.h"
#import "OfflineTiledLayer.h"
@implementation CustomLayerViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	NSError* err;
	//Initialze the layer
	OfflineTiledLayer* tiledLyr = [[OfflineTiledLayer alloc] initWithDataFramePath:@"cache_World/Layers" error:&err];

	//If layer was initialized properly, add to the map 
	if(tiledLyr!=nil){
		[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];

	}else{
		//layer encountered an error
		NSLog(@"Error encountered: %@", err);
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end
