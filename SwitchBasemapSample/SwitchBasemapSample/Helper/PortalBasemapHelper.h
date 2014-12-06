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

//instantiates a portal object and requests for basemaps
- (void)fetchWebmapsFromPortal:(NSURL*)portalURL withCredential:(AGSCredential*)credential;

//checks if there are more basemaps that can be fetched
- (BOOL)hasMoreResults;

//gets the next set of results
- (void)fetchNextResults;

@end

@protocol PortalBasemapHelperDelegate <NSObject>

//called if there was some error while getting the basemaps
- (void)portalBasemapHelper:(PortalBasemapHelper*)portalBasemapHelper didFailToLoadBasemapItemsWithError:(NSError*)error;

//called when the basemaps get loaded successfully
- (void)portalBasemapHelper:(PortalBasemapHelper*)portalBasemapHelper didFinishLoadingBasemapItems:(NSArray*)itemsArray;

//as soon as we get the portal items for the basemap
//we initiate the download of thumbnail on those items
//and keep a combined count on the failures and success
//when the count reaches the number of items this delegate
//is fired to let the controller know about the conclusion
- (void)portalBasemapHelperDidFinishFetchingThumbnails:(PortalBasemapHelper*)portalBasemapHelper;

@end