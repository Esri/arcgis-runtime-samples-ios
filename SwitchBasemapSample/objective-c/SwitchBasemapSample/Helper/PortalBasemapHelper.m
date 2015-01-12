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
@property (nonatomic, strong) NSMutableArray *portalItems;
@property (atomic, assign) NSInteger processedThumbnailsCount;
@property (nonatomic, strong) AGSPortalQueryResultSet *lastestResultSet;
@property (nonatomic, strong) NSURL *portalUrl;
@property (nonatomic, strong) AGSCredential *credential;

@end

@implementation PortalBasemapHelper

#pragma mark - Public methods

//method to connect to the given portal url with the provided credential
//portalURL is required but the credential can be nil
- (void)fetchWebmapsFromPortal:(NSURL*)portalURL withCredential:(AGSCredential*)credential {
    self.portalUrl = portalURL;
    self.credential = credential;
    self.portal = [[AGSPortal alloc] initWithURL:portalURL credential:credential];
    [self.portal setDelegate:self];
}

//method to check if there are more results
- (BOOL)hasMoreResults {
    if ([self.lastestResultSet nextQueryParams]) {
        return YES;
    }
    return NO;
}

//method to request for the next set of results
//the results are returned via the delegate
- (void)fetchNextResults {
    if ([self.lastestResultSet nextQueryParams]) {
        [self.portal findItemsWithQueryParams:[self.lastestResultSet nextQueryParams]];
    }
}

#pragma mark - Private methods

//create a query for the basemap gallery group and initiate the query
- (void)getBasemapGroup {
    AGSPortalQueryParams *queryParams = [AGSPortalQueryParams queryParamsWithQuery:self.portal.portalInfo.basemapGalleryGroupQuery];
    [self.portal findGroupsWithQueryParams:queryParams];
}

//use the groupId provided to get the portal items
- (void)getBasemapFromGroupId:(NSString*)groupId {
    AGSPortalQueryParams *queryParams = [AGSPortalQueryParams queryParamsForItemsInGroup:groupId];
    [self.portal findItemsWithQueryParams:queryParams];
}

- (void)startThumbnailsDownload {
    //reset the processed thumbnail count
    self.processedThumbnailsCount = 0;
    
    //enumerate items and assign delegate on each item as self
    //and initiate download if the thumbnail not present
    __weak PortalBasemapHelper *weakSelf = self;
    [self.portalItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AGSPortalItem *portalItem = (AGSPortalItem*)obj;
        [portalItem setDelegate:weakSelf];
        
        if (!portalItem.thumbnail) {
            [portalItem fetchThumbnail];
        }
        else {
            weakSelf.processedThumbnailsCount++;
        }
    }];
}

//keeping a count of the images that have been processed (either successful download or failure)
//and once the count reaches the total number of results, inform the delegate
- (void)incrementCounterAndCheck {
    self.processedThumbnailsCount++;
    if (self.processedThumbnailsCount >= self.portalItems.count) {
        //call the delegate method to refresh the view
        [self.delegate portalBasemapHelperDidFinishFetchingThumbnails:self];
    }
}

//filter out web maps from the portal items obtained
-(NSArray*)filterOutWebmapsFrom:(NSArray*)results {
    NSMutableArray *webmapsArray = [NSMutableArray array];
    for (AGSPortalItem *portalItem in results) {
        if (portalItem.type == AGSPortalItemTypeWebMap) {
            [webmapsArray addObject:portalItem];
        }
    }
    return webmapsArray;
}

#pragma mark - AGSPortalDelegate methods

//failed to connect to the portal
-(void)portal:(AGSPortal *)portal didFailToLoadWithError:(NSError *)error {
    [self.delegate portalBasemapHelper:self didFailToLoadBasemapItemsWithError:error];
}

//connected to portal, now request for the basemap group id
-(void)portalDidLoad:(AGSPortal *)portal {
    [self getBasemapGroup];
}

//failed to get the group details
-(void)portal:(AGSPortal *)portal operation:(NSOperation *)operation didFailToFindGroupsForQueryParams:(AGSPortalQueryParams *)queryParams withError:(NSError *)error {
    [self.delegate portalBasemapHelper:self didFailToLoadBasemapItemsWithError:error];
}

//able to find groups
- (void)portal:(AGSPortal *)portal operation:(NSOperation *)operation didFindGroups:(AGSPortalQueryResultSet *)resultSet {
    if (resultSet.results.count > 0) {
        AGSPortalGroup *group = (AGSPortalGroup*)[resultSet.results objectAtIndex:0];
        [self getBasemapFromGroupId:group.groupId];
    }
    else {
        //create a custom error and call the delegate method
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:@"No groups found" forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"com.esri.SwitchBasemapSample" code:500 userInfo:userInfo];
        [self.delegate portalBasemapHelper:self didFailToLoadBasemapItemsWithError:error];
    }
}

//failed to find items
-(void)portal:(AGSPortal *)portal operation:(NSOperation *)operation didFailToFindItemsForQueryParams:(AGSPortalQueryParams *)queryParams withError:(NSError *)error {
    NSLog(@"Failed to find items : %@", error.localizedDescription);
    [self.delegate portalBasemapHelper:self didFailToLoadBasemapItemsWithError:error];
}

//successfully found items
-(void)portal:(AGSPortal *)portal operation:(NSOperation *)operation didFindItems:(AGSPortalQueryResultSet *)resultSet {
    //update the latestResultSet property
    //we use this property to check if there are more results
    self.lastestResultSet = resultSet;
    
    //filter out web maps from the results
    NSArray *webmaps = [self filterOutWebmapsFrom:resultSet.results];
    
    //if there are already items in the portalItems array then simply append the result (which means request was for next results)
    //else assign the result to the portalItems array
    if (self.portalItems.count > 0) {
        [self.portalItems addObjectsFromArray:webmaps];
    }
    else {
        self.portalItems = [webmaps mutableCopy];
    }
    
    //initiate the thumbnail download
    [self startThumbnailsDownload];
    
    //inform the delegate about the success
    [self.delegate portalBasemapHelper:self didFinishLoadingBasemapItems:self.portalItems];
}

#pragma mark - AGSPortalItemDelegate methods

//able to download the thumbnail
-(void)portalItem:(AGSPortalItem *)portalItem operation:(NSOperation *)op didFetchThumbnail:(UIImage *)thumbnail {
    [self incrementCounterAndCheck];
}


//failed to download the thumbnail
-(void)portalItem:(AGSPortalItem *)portalItem operation:(NSOperation *)op didFailToFetchThumbnailWithError:(NSError *)error {
    [self incrementCounterAndCheck];
}

@end
