/*
 WIBasemapsView.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */


#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>
#import "WIBasemapView.h"

@class WIBasemaps;
@protocol WIBasemapsViewDelegate; 

/*
 View that shows a collection of basemap views (WIBasemapView) on the screen
 in a grid
 */

@interface WIBasemapsView : UIView <WIBasemapViewDelegate>

@property (nonatomic, unsafe_unretained) id<WIBasemapsViewDelegate>    delegate;

- (id)initWithFrame:(CGRect)frame withBasemaps:(WIBasemaps *)basemaps;

@end

@protocol WIBasemapsViewDelegate <NSObject>

- (void)basemapsViewDidLoad:(WIBasemapsView *)basemapView;
- (void)basemapView:(WIBasemapsView *)basemapView wantsToChangeToBasemap:(AGSPortalItem *)pi;
- (void)basemapView:(WIBasemapsView *)basemapView wantsToChangeToLocalTiledLayer:(AGSLocalTiledLayer *)localTiledLayer;

@end
