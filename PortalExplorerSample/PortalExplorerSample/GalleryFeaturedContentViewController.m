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

#import "GalleryFeaturedContentViewController.h"

@interface GalleryFeaturedContentViewController()<AGSPortalDelegate>

@property (nonatomic, strong) NSMutableArray *itemsArray;
@property (nonatomic, strong) NSOperation *relatedItemsOp;
@property (nonatomic, strong) NSOperation *featuredContentOp;

- (void)getFeaturedContent;
- (void)getRelatedItemsForGroup:(AGSPortalGroup*)portalGroup;

@end

@implementation GalleryFeaturedContentViewController

- (void)dealloc {
    [self.relatedItemsOp cancel];
    [self.featuredContentOp cancel];
}

- (id)initWithPortal:(AGSPortal *)portal 
{
    self = [super initWithNibName:@"GalleryFeaturedContentViewController" bundle:nil];
    if (self) {       
        //assign the properties
        super.portal = portal;
    }
    return self;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    //the portal is shared by many view controllers
    //setting the delegate to be self when this view controller is made visible
    super.portal.delegate = self;

    self.itemsArray = [NSMutableArray array];
    
  
    //fill searchResponseArray with one NULL (we have one section)
    self.searchResponseArray = [NSMutableArray arrayWithObjects:[NSNull null], nil];

    
    //start the process to get featured content
    [self getFeaturedContent];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self.relatedItemsOp cancel];
    self.relatedItemsOp = nil;
    [self.featuredContentOp cancel];
    self.featuredContentOp = nil;
    self.itemsArray = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark -
#pragma mark AGSPortalDelegate

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFindGroups:(AGSPortalQueryResultSet*)resultSet
{
    
    if (resultSet.totalResults > 0)
    {                
        //get the items for the group. 
        AGSPortalGroup *group = (AGSPortalGroup *)[resultSet.results objectAtIndex:0];
        [self getRelatedItemsForGroup:group];
    }
    else
    {
        super.doneLoading = YES;
    }
    
    //cancel the operation
    [self.featuredContentOp cancel];
    self.featuredContentOp = nil;
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFailToFindGroupsForQueryParams:(AGSPortalQueryParams*)queryParams withError:(NSError*)error
{
    // nil out op so all data is released
    self.featuredContentOp = nil;
    super.doneLoading = YES;
    [self.tableView reloadData];
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFindItems:(AGSPortalQueryResultSet*)resultSet;
{
    //set the next query object
    [self.searchResponseArray replaceObjectAtIndex:0 withObject:resultSet];
    
    //get the list of items
    NSArray *items = resultSet.results;
    
    //for each content item, add to the items array. 
    for (AGSPortalItem* item in items)
    {
        if (item.type == AGSPortalItemTypeWebMap)
        {
            [self.itemsArray addObject:item];
        }
    }
    
    //set done loading flag
    super.doneLoading = YES;
    
    //reload the data to pick up the new results
	[self.tableView reloadData];
    
    // nil out to release data
    self.relatedItemsOp = nil;
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFailToFindItemsForQueryParams:(AGSPortalQueryParams*)queryParams withError:(NSError*)error;
{
    super.doneLoading = YES;
    [self.tableView reloadData];
    self.relatedItemsOp = nil;
}

#pragma mark - Helper methods


- (void)getFeaturedContent
{    
    //remove all objects
    [self.itemsArray removeAllObjects];
    
    //create the query params to retieve the groups. 
    AGSPortalQueryParams *params = [AGSPortalQueryParams queryParamsWithQuery:super.portal.portalInfo.featuredItemsGroupQuery];
    self.featuredContentOp = [super.portal findGroupsWithQueryParams:params];
    
    //set this to NO to show proper indicators. 
    super.doneLoading = NO;
}


- (void) getRelatedItemsForGroup:(AGSPortalGroup*)portalGroup
{        
    //create the query params to retieve the content for each group.
    AGSPortalQueryParams *params = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap inGroup:portalGroup.groupId];
    params.sortOrder = AGSPortalQuerySortOrderDescending;
    params.sortField = @"uploaded";    
    self.relatedItemsOp = [super.portal findItemsWithQueryParams:params];
    
    //fill searchResponseArray with one NULL (we have one section)
    self.searchResponseArray = [NSMutableArray arrayWithObjects:[NSNull null], nil];
}


// Base class implementation, subclasses need to override this
- (void)loadMoreResults:(NSInteger)section
{
    super.doneLoading = NO;
    
    //we have only one section...
    AGSPortalQueryResultSet *resultSet = [self.searchResponseArray objectAtIndex:section];    
    super.portal.delegate = self;
    [super.portal findItemsWithQueryParams:resultSet.nextQueryParams];
}

- (id)contentForRowAtIndex:(NSIndexPath *)indexPath
{
    if ([self.itemsArray count] < indexPath.row + 1)
        return nil;
    
    return [self.itemsArray objectAtIndex:indexPath.row];
}


- (NSInteger) numberOfRowsInSection:(NSInteger)section
{
    return (self.itemsArray == nil) ? 0 : [self.itemsArray count];
}

@end
