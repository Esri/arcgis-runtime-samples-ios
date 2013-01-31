// Copyright 2010 ESRI
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

//contants for data layers
#define kTiledMapServiceURL @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"



@interface MessageMil2525cSampleViewController : UIViewController <AGSMapViewLayerDelegate> {
	
	//container for map layers
	AGSMapView *_mapView;
}

@property (nonatomic, retain) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSGroupLayer *groupLayer;
@property (nonatomic, strong) AGSMPMessage *message;
@property (nonatomic, strong) AGSMPMessageProcessor *mProcessor;
@property (nonatomic, strong) NSArray *milMessages;

@end

@interface Mil2525Message : NSObject <AGSCoding>
@property (nonatomic, strong) AGSMPMessage *message;
@end

