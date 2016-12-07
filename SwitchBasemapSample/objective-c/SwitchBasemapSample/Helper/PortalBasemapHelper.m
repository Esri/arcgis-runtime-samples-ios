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

#import "PortalBasemapHelper.h"
#import "AppConstants.h"

@interface PortalBasemapHelper ()

@property (nonatomic, strong) AGSPortal *portal;
@property (nonatomic, strong) NSMutableArray *basemaps;
@property (atomic, assign) NSInteger processedThumbnailsCount;
@property (nonatomic, strong) NSURL *portalUrl;
@property (nonatomic, strong) AGSCredential *credential;

@end

@implementation PortalBasemapHelper

#pragma mark - Public methods

//method to connect to the given portal url with the provided credential
//portalURL is required but the credential can be nil
- (void)fetchBasemapsFromPortal:(NSURL*)portalURL withCredential:(AGSCredential*)credential
                     completion:(void (^)(NSArray<AGSBasemap *> *basemaps, NSError *error))completion {
    self.portalUrl = portalURL;
    self.credential = credential;
    self.portal = [[AGSPortal alloc] initWithURL:portalURL loginRequired:NO];
    self.portal.credential = credential;
    
    [self.portal fetchBasemapsWithCompletion:^(NSArray<AGSBasemap *> * _Nullable basemaps, NSError * _Nullable error) {
        if (completion) {
            completion(basemaps, error);
        }
    }];
}

@end
