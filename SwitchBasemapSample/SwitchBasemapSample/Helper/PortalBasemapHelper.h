// Copyright 2014 ESRI
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

@protocol PortalBasemapHelperDelegate;

@interface PortalBasemapHelper : NSObject <AGSPortalDelegate, AGSPortalItemDelegate>

@property (nonatomic, weak) id <PortalBasemapHelperDelegate> delegate;

- (void)connectToPortal:(NSURL*)portalURL withCredential:(AGSCredential*)credential;
- (BOOL)hasMoreResults;
- (void)nextResults;

@end

@protocol PortalBasemapHelperDelegate <NSObject>

- (void)portalBasemapHelper:(PortalBasemapHelper*)portalBasemapHelper didFailToLoadBasemapItemsWithError:(NSError*)error;
- (void)portalBasemapHelper:(PortalBasemapHelper*)portalBasemapHelper didFinishLoadingBasemapItems:(NSArray*)itemsArray;
- (void)portalBasemapHelperDidFinishFetchingThumbnails:(PortalBasemapHelper*)portalBasemapHelper;

@end