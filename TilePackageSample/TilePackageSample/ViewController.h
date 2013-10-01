//
//  ViewController.h
//  SimpleMap
//
//  Created by Al Pascual on 10/10/12.
//  Copyright (c) 2012 Esri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

#import "SPUserResizableView.h"

#define ExportTilesMapService @"http://63.241.159.63:6080/arcgis/rest/services/World_Street_Map/MapServer"

@interface ViewController : UIViewController <SPUserResizableViewDelegate>

- (NSArray*) generateLods;
- (void) showGrayBox;
- (void) hideGrayBox;
- (void) showOverlay;
- (void) hideOverlay;
- (double) parsePercentage:(NSString*)percentageString;
- (NSString *) parseMessagesDescription:(NSString*)description;

@end
