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

#import "GalleryFeaturedGroupsViewController.h"
#import "GroupTableViewCell.h"

#define kGroupTableViewCellIdentifier @"GroupTableViewCell"

@interface GalleryFeaturedGroupsViewController() <AGSPortalDelegate, IconDownloaderDelegate>

@property (nonatomic, strong) NSMutableArray *featuredGroupsQueriesArray;
@property (nonatomic, strong) NSMutableArray *groupsArray;
@property (nonatomic, strong) NSMutableArray *operationArray;

- (void)getFeaturedGroups;
 
@end


@implementation GalleryFeaturedGroupsViewController


- (void)dealloc {
    [self.operationArray makeObjectsPerformSelector:@selector(cancel)];
    [self.operationArray removeAllObjects];
}

- (id)initWithPortal:(AGSPortal *)portal
{
    self = [super initWithNibName:@"GalleryFeaturedGroupsViewController" bundle:nil];
    if (self) {    
        //assign all the properties
        super.portal = portal;
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    //the portal is shared by many view controllers
    //setting the delegate to be self when this view controller is made visible
    super.portal.delegate = self;

    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.groupsArray = [NSMutableArray array];
    self.operationArray = [NSMutableArray array];
    
    //queries to obtain the featured groups. 
    self.featuredGroupsQueriesArray = [NSMutableArray arrayWithArray:super.portal.portalInfo.featuredGroupsQueries];
    
    //set the next query object. Used for understanding which section we are dealing with and to help in paging. 
    self.searchResponseArray = [NSMutableArray arrayWithObjects:[NSNull null], nil];
    
    //start the process to get featured content
    [self getFeaturedGroups];
}

- (void)viewDidUnload
{

    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self.operationArray makeObjectsPerformSelector:@selector(cancel)];
    [self.operationArray removeAllObjects];
    self.operationArray = nil;    
    self.groupsArray = nil;
    self.featuredGroupsQueriesArray = nil;
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}


#pragma mark - AGSPortalDelegate

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFindGroups:(AGSPortalQueryResultSet*)resultSet
{    
    //store the result for initiating the next query if more items are there. 
    [self.searchResponseArray replaceObjectAtIndex:0 withObject:resultSet];
    
    if (resultSet.totalResults > 0)
    {                
        //add the group(s) to our groups array
        [self.groupsArray addObjectsFromArray:resultSet.results];
    }

    //remove the operation from the op array. 
    [self.operationArray removeObject:op];
    
    //if the 
    if ([self.operationArray count] <= 0)
    {
        super.doneLoading = YES;
        [self.tableView reloadData];
    }
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFailToFindGroupsForQueryParams:(AGSPortalQueryParams*)queryParams withError:(NSError*)error
{    
    //remove the op from the array. 
    [self.operationArray removeObject:op];    
    if ([self.operationArray count] <= 0)
    {
        super.doneLoading = YES;
        [self.tableView reloadData];
    }
}


#pragma mark - Helper methods

- (void) getFeaturedGroups
{    
    //spawn an operation to get each group, based on the elements in the groupArray
    for (NSString *featureGroupsQuery in super.portal.portalInfo.featuredGroupsQueries) {
        
        //create the query params to retrieve the groups 
        AGSPortalQueryParams *params = [AGSPortalQueryParams queryParamsWithQuery:featureGroupsQuery];
        
        //initiate the operation
        NSOperation *op = [super.portal findGroupsWithQueryParams:params];
        
        //add the operation to the array. 
        [self.operationArray addObject:op];
        
        //set this to NO to show the necessary indicators in the table view. 
        super.doneLoading = NO;
    }

}

// Base class implementation, subclasses need to override this
- (void)loadMoreResults:(NSInteger)section
{
    //set this to NO to show the necessary indicators in the table view. 
    super.doneLoading = NO;
    
    //we have only one section...
    AGSPortalQueryResultSet *resultSet = [self.searchResponseArray objectAtIndex:section];    
    super.portal.delegate = self;
    [super.portal findItemsWithQueryParams:resultSet.nextQueryParams];
}


- (id)contentForRowAtIndex:(NSIndexPath *)indexPath
{
    if (self.groupsArray == nil || [self.groupsArray count] < indexPath.row + 1)
        return nil;    
    
    return [self.groupsArray objectAtIndex:indexPath.row];
}

- (NSInteger) numberOfRowsInSection:(NSInteger)section
{
    return (self.groupsArray == nil) ? 0 : [self.groupsArray count];
}


@end
