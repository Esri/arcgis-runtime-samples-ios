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

#import "UserGroupsViewController.h"

@interface UserGroupsViewController()

//array to hold the user's groups. 
@property (nonatomic, strong) NSMutableArray *groupsArray;


- (void)getUserGroups;

@end


@implementation UserGroupsViewController

@synthesize groupsArray = _groupsArray;


- (id)initWithPortal:(AGSPortal *)portal
{
    self = [super initWithNibName:@"UserGroupsViewController" bundle:nil];
    if (self) {      
        //assign and instantiate the properties. Portal comes from the base class. 
        super.portal = portal;
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.groupsArray = [NSMutableArray array];     

    //start the process to get the groups. 
    [self getUserGroups];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.groupsArray = nil;
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
}


#pragma mark - Helper methods

- (void) getUserGroups
{    
    //clear the array
    [self.groupsArray removeAllObjects];
    
    //add the objects from the user's groups array to the groupsArray property. 
    [self.groupsArray addObjectsFromArray:super.portal.user.groups];
    
    //reload the tableview
    [self.tableView reloadData];    
}

//overriden method from the base class. 
- (id)contentForRowAtIndex:(NSIndexPath *)indexPath
{
    if (self.groupsArray == nil || [self.groupsArray count] < indexPath.row + 1)
        return nil;
    
    
    return [self.groupsArray objectAtIndex:indexPath.row];
}

//overriden method from the base class. 
- (NSInteger) numberOfRowsInSection:(NSInteger)section
{
    return (self.groupsArray == nil) ? 0 : [self.groupsArray count];
}


@end
