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

#import "FilteredItemsViewController.h"


@interface FilteredItemsViewController()<AGSPortalDelegate>

@property (nonatomic, strong) AGSPortalQueryParams *queryParams;
@property (nonatomic, strong) NSMutableArray *itemsArray;
@property (nonatomic, strong) NSOperation *filteredItemsOp;


- (void)getFilteredItems;

@end

@implementation FilteredItemsViewController

@synthesize queryParams = _queryParams;
@synthesize itemsArray = _itemsArray;
@synthesize filteredItemsOp = _filteredItemsOp;



- (void)dealloc {
    [self.filteredItemsOp cancel];
}



- (id)initWithPortal:(AGSPortal *)portal queryParams:(AGSPortalQueryParams *)queryParams
{
    self = [super initWithNibName:@"FilteredItemsViewController" bundle:nil];
    if (self) {  
        //assign the properties
        super.portal = portal;
        self.queryParams = queryParams;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
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
    [self getFilteredItems];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self.filteredItemsOp cancel];
    self.filteredItemsOp = nil;
    self.itemsArray = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}



#pragma mark - AGSPortalDelegate

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFindItems:(AGSPortalQueryResultSet*)resultSet;
{
    //set the next query object
    [self.searchResponseArray replaceObjectAtIndex:0 withObject:resultSet];
    
    //get the list of items
    NSArray *items = resultSet.results;
    
    //for each content item, add to the items array
    for (AGSPortalItem* item in items)
    {
        if (item.type == AGSPortalItemTypeWebMap)
        {
            [self.itemsArray addObject:item];
        }
    }
    
    //set done loading flag
    super.doneLoading = YES;
    
    //reload the data to pick up the new resuls
	[self.tableView reloadData];
    
    // nil out to release data
    self.filteredItemsOp = nil;
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFailToFindItemsForQueryParams:(AGSPortalQueryParams*)queryParams withError:(NSError*)error;
{
    super.doneLoading = YES;
    [self.tableView reloadData];
    self.filteredItemsOp = nil;
}

#pragma mark - Helper methods

- (void)getFilteredItems
{    
    //empty the items array. 
    [self.itemsArray removeAllObjects];

    //initiate the op to get the items with the filter params. 
    self.filteredItemsOp = [super.portal findItemsWithQueryParams:self.queryParams];
    
    super.doneLoading = NO;
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
