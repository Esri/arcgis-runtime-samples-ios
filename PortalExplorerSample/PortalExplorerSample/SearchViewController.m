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

#import "SearchViewController.h"
#import "IconDownloader.h"
#import "LoadingTableViewCell.h"
#import "ItemTableViewCell.h"
#import "GroupTableViewCell.h"
#import "IconDownloader.h"

//how much to inset the cell buton

#define kCustomSectionCount 2


@interface SearchViewController() <AGSPortalDelegate, UISearchBarDelegate, IconDownloaderDelegate>

@property (nonatomic,strong) IBOutlet UISearchBar *searchBar;

//for items
@property (nonatomic, strong) NSMutableArray *itemsArray;
@property (nonatomic, strong) NSOperation *itemsQueryOp;
@property (nonatomic, readwrite) BOOL itemsDoneLoading;

//for groups
@property (nonatomic, strong) NSMutableArray *groupsArray;
@property (nonatomic, strong) NSOperation *groupsQueryOp;
@property (nonatomic, readwrite) BOOL groupsDoneLoading;

- (void)searchForItemsWithQueryParams:(AGSPortalQueryParams *)queryParams;
- (void)searchForGroupsWithQueryParams:(AGSPortalQueryParams *)queryParams;


@end

@implementation SearchViewController


- (void)dealloc {
    
    [self.itemsQueryOp cancel];
    
    [self.groupsQueryOp cancel];
    
}


- (id)initWithPortal:(AGSPortal *)portal
{
    self = [super initWithNibName:@"SearchViewController" bundle:nil];
    if (self) {        
        super.portal = portal;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //the portal is shared by many view controllers
    //setting the delegate to be self when this view controller is made visible
    super.portal.delegate = self;
    
    self.itemsArray = [NSMutableArray array];
    self.groupsArray = [NSMutableArray array];
    
    self.itemsDoneLoading = YES;
    self.groupsDoneLoading = YES;
    
    //fill searchResponseArray with one NULL (we have one section)
    self.searchResponseArray = [NSMutableArray arrayWithObjects:[NSNull null], [NSNull null], nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.searchBar = nil;
    
    self.itemsArray = nil;
    [self.itemsQueryOp cancel];
    self.itemsQueryOp = nil;
    
    self.groupsArray = nil;
    [self.groupsQueryOp cancel];
    self.groupsQueryOp = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return kCustomSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        return @"Items";
    }
    return @"Groups";
}



#pragma mark - UISearchBarDelegate

// called when keyboard search button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    //create the query params for the items. 
	AGSPortalQueryParams *itemsQueryParams = [AGSPortalQueryParams queryParamsWithQuery:[NSString stringWithFormat:@"%@",searchBar.text]]; 
    [self searchForItemsWithQueryParams:itemsQueryParams];
    
    //create the query params for the groups. 
    AGSPortalQueryParams *groupsQueryParams = [AGSPortalQueryParams queryParamsWithQuery:[NSString stringWithFormat:@"%@",searchBar.text]];  
    [self searchForGroupsWithQueryParams:groupsQueryParams];
    
    //reload the tableview
    [self.tableView reloadData];
	
	[searchBar resignFirstResponder];
    
}

// called when cancel button pressed
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self.searchBar resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AGSPortalDelegate

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFindItems:(AGSPortalQueryResultSet*)resultSet;
{
    //set the next query object
    [self.searchResponseArray replaceObjectAtIndex:0 withObject:resultSet];
    
    //get the list of items
    NSArray *items = resultSet.results;
    
    //for each content item, create a map settings object and store it in the item array
    for (AGSPortalItem* item in items)
    {
        if (item.type == AGSPortalItemTypeWebMap)
        {
            [self.itemsArray addObject:item];
        }
    }
    
    //set done loading flag
    self.itemsDoneLoading = YES;
    
    //reload the data to pick up the new resuls
	[self.tableView reloadData];
    
    // nil out to release data
    self.itemsQueryOp = nil;
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFailToFindItemsForQueryParams:(AGSPortalQueryParams*)queryParams withError:(NSError*)error;
{
    self.itemsDoneLoading = YES;
    //fill searchResponseArray with one NULL (we have one section)
    [self.searchResponseArray replaceObjectAtIndex:0 withObject:[NSNull null]];
    [self.tableView reloadData];
    self.itemsQueryOp = nil;
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFindGroups:(AGSPortalQueryResultSet*)resultSet
{    
    //set the next query object
    [self.searchResponseArray replaceObjectAtIndex:1 withObject:resultSet];
    
    if (resultSet.totalResults > 0)
    {                
        //add the group(s) to our item array (there should be only 1)
        [self.groupsArray addObjectsFromArray:resultSet.results];
    }
    
    //set done loading flag
    self.groupsDoneLoading = YES;
    
    //reload the data to pick up the new resuls
	[self.tableView reloadData];
    
    // nil out to release data
    self.groupsQueryOp = nil;
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFailToFindGroupsForQueryParams:(AGSPortalQueryParams*)queryParams withError:(NSError*)error
{    
    self.groupsDoneLoading = YES;
    //fill searchResponseArray with one NULL (we have one section)
    [self.searchResponseArray replaceObjectAtIndex:1 withObject:[NSNull null]];
    [self.tableView reloadData];
    self.groupsQueryOp = nil;
}

#pragma mark - Helper

- (void)searchForItemsWithQueryParams:(AGSPortalQueryParams *)queryParams
{    
    //empty the items array and cancel the ops
    [self.itemsArray removeAllObjects];    
    [self.itemsQueryOp cancel];
    self.itemsQueryOp = nil;
    
    //initiate the query request
    self.itemsQueryOp = [super.portal findItemsWithQueryParams:queryParams];
    
    self.itemsDoneLoading = NO;
    
    //fill searchResponseArray with one NULL (we have one section)
    [self.searchResponseArray replaceObjectAtIndex:0 withObject:[NSNull null]]; 
}


- (void)searchForGroupsWithQueryParams:(AGSPortalQueryParams *)queryParams
{    
    //empty the groups array and cancel the ops
    [self.groupsArray removeAllObjects];    
    [self.groupsQueryOp cancel];
    self.groupsQueryOp = nil;
    
    //initiate the query request
    self.groupsQueryOp = [super.portal findGroupsWithQueryParams:queryParams];
    
    self.groupsDoneLoading = NO;
    
    //fill searchResponseArray with one NULL (we have one section)
    [self.searchResponseArray replaceObjectAtIndex:1 withObject:[NSNull null]]; 
    
}


- (id)contentForRowAtIndex:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            super.doneLoading = self.itemsDoneLoading;
            if ([self.itemsArray count] < indexPath.row + 1)
                break;
            
            return [self.itemsArray objectAtIndex:indexPath.row];
        }
        case 1:
        {
            super.doneLoading = self.groupsDoneLoading;
            if ([self.groupsArray count] < indexPath.row + 1)
                break;
            
            return [self.groupsArray objectAtIndex:indexPath.row];
        }
            
        default:
            break;
    }
    
    return nil;
}


- (void)loadMoreResults:(NSInteger)section
{
    //load more results for the items section
    if(section == 0)
    {
        self.itemsDoneLoading = NO;
        AGSPortalQueryResultSet *resultSet = [self.searchResponseArray objectAtIndex:section];    
        super.portal.delegate = self;
        self.itemsQueryOp = [super.portal findItemsWithQueryParams:resultSet.nextQueryParams];
        
    }
    
    //load more results for the groups section
    else
    {
        self.groupsDoneLoading = NO;
        AGSPortalQueryResultSet *resultSet = [self.searchResponseArray objectAtIndex:section];    
        super.portal.delegate = self;
        self.groupsQueryOp = [super.portal findGroupsWithQueryParams:resultSet.nextQueryParams];
    }
}

- (NSInteger) numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
    {
        return (self.itemsArray == nil) ? 0 : [self.itemsArray count];
    }
    else
    {
        return (self.groupsArray == nil) ? 0 : [self.groupsArray count];
    }

    
}




@end
