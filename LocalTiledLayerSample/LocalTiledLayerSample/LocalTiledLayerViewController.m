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
@property (nonatomic, strong) NSString *tilePackage;

@end

@implementation LocalTiledLayerViewController

@synthesize mapView=_mapView;
@synthesize localTiledLayer=_localTiledLayer;
@synthesize tilePackage = _tilePackage;

- (id)initWithTilePackage:(NSString *)tilePackage
{
    if(self = [super initWithNibName:@"LocalTiledLayerViewController" bundle:nil])
    {
        //initializes the string with the name of the tile package. 
        self.tilePackage = tilePackage;
    }
    return self;
}

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    
	//Initialze the layer
	self.localTiledLayer = [AGSLocalTiledLayer localTiledLayerWithName:self.tilePackage];

	//If layer was initialized properly, add to the map 
	if(self.localTiledLayer != nil){
			[self.mapView addMapLayer:self.localTiledLayer withName:@"Local Tiled Layer"];
	}
    
    [super viewDidLoad];
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
