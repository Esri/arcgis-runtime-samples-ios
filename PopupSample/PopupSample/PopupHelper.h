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

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@protocol PoupupHelperDelegate <NSObject>
@optional

- (void)foundPopups:(NSArray*) popups atMapPonit:(AGSPoint*)mapPoint withMoreToFollow:(BOOL)more;
- (void)foundAdditionalPopups:(NSArray*) popups withMoreToFollow:(BOOL)more;

@end


@interface PopupHelper : NSObject <AGSQueryTaskDelegate>

@property (nonatomic, strong) NSMutableArray *outstandingQueries;
@property (nonatomic, strong) NSMutableArray *queryTasks;
@property (nonatomic, weak) id<PoupupHelperDelegate> delegate;


- (void) findPopupsForMapView:(AGSMapView*) mapView withGraphics:(NSDictionary *)graphics atPoint:(AGSPoint*)mappoint  andWebMap:(AGSWebMap*)webmap withQueryableLayers:(NSArray*)queryableLayers  ;

- (void)cancelOutstandingRequests;

@end



@interface AGSTiledMapServiceLayer (PopupHelper)

- (BOOL) subLayer:(AGSMapServiceLayerInfo*)layerInfo isVisibleAtMapScale:(double)mapScale;

@end

@interface AGSDynamicMapServiceLayer (PopupHelper)

- (BOOL) subLayer:(AGSMapServiceLayerInfo*)layerInfo isVisibleAtMapScale:(double)mapScale;

@end

@interface AGSWebMap (PopupHelper)

- (AGSWebMapLayerInfo*) layerInfoForLayer:(AGSLayer*) layer;

@end