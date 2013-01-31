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

@protocol DisplayPoupupHelperDelegate <NSObject>
@optional

- (void)foundPopups:(NSArray*) popups atMapPonit:(AGSPoint*)mapPoint withMoreToFollow:(BOOL)more;
- (void)foundAdditionalPopups:(NSArray*) popups withMoreToFollow:(BOOL)more;

@end


@interface DisplayPopupHelper : NSObject <AGSMapViewCalloutDelegate, AGSMapViewTouchDelegate, UIAlertViewDelegate, AGSPopupsContainerDelegate, AGSQueryTaskDelegate>

+ (DisplayPopupHelper *)sharedHelper;

@property (nonatomic,assign) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) AGSWebMap *webMap;
@property (nonatomic, retain) AGSPopupsContainerViewController *popupVC;
@property (nonatomic, assign) AGSMapView *mapView;
@property (nonatomic, retain) NSMutableArray *outstandingQueries;
@property (nonatomic, assign) id<DisplayPoupupHelperDelegate> delegate;


- (void) displayPopupsForMapView:(AGSMapView*) mapView atPoint:(AGSPoint*)mappoint withGraphics:(NSDictionary *)graphics inWebMap:(AGSWebMap*)webmap withMapLayers:(NSDictionary*)mapLayers queryableLayers:(NSArray*)queryableLayers  ;

- (void) presentPopupUsingViewController:(UIViewController*)viewController ;


@end



@interface AGSTiledMapServiceLayer (DisplayPopupHelper)

- (BOOL) subLayer:(AGSMapServiceLayerInfo*)layerInfo isVisibleAtMapScale:(double)mapScale;

@end

@interface AGSDynamicMapServiceLayer (DisplayPopupHelper)

- (BOOL) subLayer:(AGSMapServiceLayerInfo*)layerInfo isVisibleAtMapScale:(double)mapScale;

@end