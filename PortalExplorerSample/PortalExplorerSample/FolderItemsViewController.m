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

#import "FolderItemsViewController.h"

@interface FolderItemsViewController() <AGSPortalUserDelegate>

//query parameters used to obtain the items from a folder. 
@property (nonatomic, strong) AGSPortalQueryParams *queryParams;

//array to hold the items. 
@property (nonatomic, strong) NSMutableArray *itemsArray;

//operation that retrieves the items. 
@property (nonatomic, strong) NSOperation *folderItemsOp;

//the id of the folder to retrieve the items from. 
@property (nonatomic, strong) NSString *folderID;

//method to retrieve the folder items. 
- (void)getFolderItems;

@end

@implementation FolderItemsViewController

@synthesize queryParams = _queryParams;
@synthesize itemsArray = _itemsArray;
@synthesize folderItemsOp = _folderItemsOp;
@synthesize doneLoading = _doneLoading;
@synthesize folderID = _folderID;

- (void)dealloc {
    [self.folderItemsOp cancel];
    super.portal = nil;
}


- (id)initWithPortal:(AGSPortal *)portal folderID:(NSString *)folderID
{
    self = [super initWithNibName:@"FolderItemsViewController" bundle:nil];
    if (self) {  
        //assign the portal
        super.portal = portal;
        self.folderID = folderID;
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
    
    //Make this view controller the delegate for all portal operations
    //performed by it
    super.portal.user.delegate = self;

    self.itemsArray = [NSMutableArray array];
    
    //fill searchResponseArray with one NULL (we have one section)
    self.searchResponseArray = [NSMutableArray arrayWithObjects:[NSNull null], nil];

    //start the process to get folder items
    [self getFolderItems];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self.folderItemsOp cancel];
    self.folderItemsOp = nil;
    self.itemsArray = nil;
    super.portal = nil;
    self.queryParams = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark -
#pragma mark AGSPortalUserDelegate

-(void)portalUser:(AGSPortalUser*)portalUser operation:(NSOperation*)op didFetchContent:(NSArray*)items folders:(NSArray*)folders inFolder:(NSString*)folderId;
{
    //add the returned items to the items array. 
    for (AGSPortalItem* item in items)
    {
        if (item.type == AGSPortalItemTypeWebMap)
        {
            [self.itemsArray addObject:item];
        }
    }
    
    //we're done loading, set the flag
    super.doneLoading = YES;
    
    //reload the data to show the newly loaded list of items
	[self.tableView reloadData];
}

-(void)portalUser:(AGSPortalUser*)portalUser operation:(NSOperation*)op didFailToFetchContentInFolder:(NSString*)folderId withError:(NSError*)error;
{
    //error loading, set the flag
    super.doneLoading = YES;
    
    //reload the tableview
	[self.tableView reloadData];
}

#pragma mark - Helper Methods

- (void) getFolderItems
{
    //empty the items array. 
    [self.itemsArray removeAllObjects];    
    
    //fetch the items from the folder of the user with the specified folder id. 
    [super.portal.user fetchContentInFolder:self.folderID];
}

//overridden method from the base class
- (id) contentForRowAtIndex:(NSIndexPath *) indexPath
{
    if ([self.itemsArray count] < indexPath.row + 1)
        return nil;
    
    return [self.itemsArray objectAtIndex:indexPath.row];
}

//overridden method from the base class
- (NSInteger) numberOfRowsInSection:(NSInteger)section
{
    return (self.itemsArray == nil) ? 0 : [self.itemsArray count];
}


@end
