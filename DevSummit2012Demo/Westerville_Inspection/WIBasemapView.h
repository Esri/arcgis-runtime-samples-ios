/*
 WIBasemapView.h
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

@protocol WIBasemapViewDelegate;

/*
 View that shows a basemaps as defined by a portal item or a local tiled layer.
 */

@interface WIBasemapView : UIImageView <AGSPortalItemDelegate>

@property (nonatomic, unsafe_unretained) id<WIBasemapViewDelegate>    delegate;

- (id)initWithFrame:(CGRect)frame withPortalItem:(AGSPortalItem *)pi;
- (id)initWithFrame:(CGRect)frame withLocalLayer:(AGSLocalTiledLayer*)localLayer;

@end

@protocol WIBasemapViewDelegate <NSObject>

@optional
- (void)basemapViewDidLoad:(WIBasemapView *)basemapView;
- (void)basemapViewDidFailToLoad:(WIBasemapView *)basemapView;

@end
