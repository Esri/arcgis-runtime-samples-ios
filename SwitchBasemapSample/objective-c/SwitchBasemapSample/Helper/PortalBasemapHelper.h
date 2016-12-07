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

@interface PortalBasemapHelper : NSObject

//instantiates a portal object and requests for basemaps
- (void)fetchBasemapsFromPortal:(NSURL*)portalURL withCredential:(AGSCredential*)credential completion:(void (^)(NSArray<AGSBasemap *> *basemaps, NSError *error))completion;


@end

//The PortalBasemapHelperDelegate protocol has been removed; the same functionality is now
// accomplished using completion blocks.
