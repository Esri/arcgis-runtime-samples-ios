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

#import "UserContentViewController.h"

#define kNumberOfSections 2


@interface UserContentViewController() <AGSPortalUserDelegate, IconDownloaderDelegate>

//array to hold the user content. 
@property (nonatomic, strong) NSMutableArray *itemsArray;

//array to hold the root level folders. 
@property (nonatomic, strong) NSMutableArray *foldersArray;

//operation to get the content and folders. 
@property (nonatomic, strong) NSOperation *contentsOp;

//method to get the content
- (void)getUserContents;

@end

@implementation UserContentViewController


@synthesize itemsArray = _itemsArray;
@synthesize foldersArray = _foldersArray;
@synthesize contentsOp = _contentsOp;
@synthesize doneLoading = _doneLoading;


- (void)dealloc {
    [self.contentsOp cancel];
}


- (id)initWithPortal:(AGSPortal *)portal
{
    self = [super initWithNibName:@"UserContentViewController" bundle:nil];
    if (self) {   
        
        //assign the portal. portal comes from the base class. 
        super.portal = portal;
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
    super.portal.user.delegate = self;
    
    //instantiate the items and folders array. 
    self.itemsArray = [NSMutableArray array];
    self.foldersArray = [NSMutableArray array];
    //start the process to get featured content
    [self getUserContents];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self.contentsOp cancel];
    self.contentsOp = nil;
    self.itemsArray = nil;
    self.foldersArray = nil;

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
    //get the array of items. 
    for (AGSPortalItem* item in items)
    {
        if (item.type == AGSPortalItemTypeWebMap)
        {
            [self.itemsArray addObject:item];
        }
    }
    
    //get array of folders:
    self.foldersArray = [NSMutableArray arrayWithArray:folders];
    
    //we're done loading, set the flag
    super.doneLoading = YES;
    
    //reload the data to show the newly loaded list of items and  folders
	[self.tableView reloadData];
    
    //set the contents op to nil.
    [self.contentsOp cancel];
    self.contentsOp = nil;
}

-(void)portalUser:(AGSPortalUser*)portalUser operation:(NSOperation*)op didFailToFetchContentInFolder:(NSString*)folderId withError:(NSError*)error;
{
    //failed to load. set the flag. 
    super.doneLoading = YES;
    
    //cancel the op
    [self.contentsOp cancel];
    self.contentsOp = nil;
    
    //reload the tableview. 
    [self.tableView reloadData];
}

#pragma mark - Helper methods


- (void)getUserContents
{    
    
    //clear the array
    [self.itemsArray removeAllObjects];
    
    //fetch the user content
    self.contentsOp = [super.portal.user fetchContent];
    
    //set the done loading flag. 
    super.doneLoading = NO;
    
}

//overridden method from the base class. 
- (id)contentForRowAtIndex:(NSIndexPath *) indexPath
{
    if ((indexPath.section == 0 && (self.itemsArray == nil || [self.itemsArray count] < indexPath.row + 1)) ||
        (indexPath.section == 1 && (self.foldersArray == nil || [self.foldersArray count] < indexPath.row + 1)))
        return nil;
    
    //if items section. 
    if (indexPath.section == 0)
        return [self.itemsArray objectAtIndex:indexPath.row];
    
    //if folders section.
    if (indexPath.section == 1)
        return [self.foldersArray objectAtIndex:indexPath.row];
    
    return @"";
}

//overridden method from the base class. 
- (NSInteger) numberOfRowsInSection:(NSInteger)section
{
    //if items section.
    if (section == 0)
        return [self.itemsArray count];
    
    //if folders section.
    if (section == 1)
        return [self.foldersArray count];
    
    return 0;    
}

//returns number of sections
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kNumberOfSections;
}

//overridden method from the base class. 
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    //if items section.
    if (section == 0)
        return NSLocalizedString(@"Maps", nil);
    
    //if folders section.
    if (section == 1)
        return NSLocalizedString(@"Folders", nil);
    
    return @"";    
}

@end
