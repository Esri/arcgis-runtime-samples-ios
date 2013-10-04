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

#import "SPUserResizableView.h"
#import "Timer.h"

#define ExportTilesMapService @"http://63.241.159.63:6080/arcgis/rest/services/World_Street_Map/MapServer"
//#define ExportTilesMapService @"http://pathik1:6080/arcgis/rest/services/usa/MapServer"
//#define ExportTilesMapService @"http://10.211.21.79:6080/arcgis/rest/services/ESRI_StreetMap_World_2D/MapServer"
//#define ExportTilesMapService @"http://geoshock:6090/arcgis/rest/services/usa/MapServer/"

@interface ViewController : UIViewController <SPUserResizableViewDelegate>

- (NSArray*) generateLods;
- (void) showGrayBox;
- (void) hideGrayBox;
- (void) showOverlay;
- (void) hideOverlay;
- (double) parsePercentage:(NSString*)percentageString;
- (NSString *) parseMessagesDescription:(NSString*)description;

@end
