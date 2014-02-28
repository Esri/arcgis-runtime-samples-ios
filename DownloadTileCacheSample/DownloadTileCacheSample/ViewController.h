// Copyright 2013 ESRI
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

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>




@interface ViewController : UIViewController <AGSLayerDelegate>


@property (nonatomic,strong) IBOutlet AGSMapView *mapView;
@property (nonatomic,strong) AGSTiledMapServiceLayer *tiledLayer;
@property (nonatomic,strong) IBOutlet UIView *downloadPanel;
@property (nonatomic,strong) AGSExportTileCacheTask *tileCacheTask;
@property (nonatomic,strong) IBOutlet UILabel *scaleLabel;
@property (nonatomic,strong) IBOutlet UILabel *estimateLabel;
@property (nonatomic,strong) IBOutlet UILabel *lodLabel;


@property (nonatomic,strong) IBOutlet UIButton *estimateButton;
@property (nonatomic,strong) IBOutlet UIButton *downloadButton;
@property (nonatomic,strong) IBOutlet UIStepper*levelStepper;


@property (nonatomic,strong) IBOutlet UILabel *timerLabel;


@end
