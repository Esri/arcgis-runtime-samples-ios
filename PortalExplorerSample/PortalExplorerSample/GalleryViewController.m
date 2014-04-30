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

#import "GalleryViewController.h"
#import "GalleryFeaturedGroupsViewController.h"
#import "GalleryFeaturedContentViewController.h"
#import "FilteredItemsViewController.h"
#import "FilteredItemsViewController.h"


#define kFeaturedContentIndex 0
#define kFeaturedGroupsIndex 1
#define kMostPopularIndex 2
#define kHighestRatedIndex 3
#define kMostCommentsIndex 4
#define kMostRecentIndex 5


@interface GalleryViewController()

@property (nonatomic, strong) AGSPortal *portal;
@property (nonatomic, strong) NSMutableArray *listStrings;
@property (nonatomic, strong) NSMutableArray *listImages;
@property (nonatomic, strong) NSMutableDictionary *searchStrings;

- (BOOL)hasFeaturedGroups;
- (BOOL)hasFeaturedContent;
- (void)initializeQueryParams;

@end

@implementation GalleryViewController

- (id)initWithPortal:(AGSPortal *)portal
{
    self = [super initWithNibName:@"GalleryViewController" bundle:nil];
    if (self) {
        //assign the portal property. 
        self.portal = portal;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //create an array of strings to be displayed in the table view. 
    self.listStrings = [NSMutableArray arrayWithObjects:@"Featured Groups",
                                                        @"Featured Content",
                                                        @"Most Popular",
                                                        @"Highest Rated",
                                                        @"Most Comments",
                                                        @"Recent",
                                                        nil];
    
    //create an array of corresponding images to be displayed in the table view. 
    self.listImages = [NSMutableArray arrayWithObjects:[UIImage imageNamed:@"featuredGroups.png"],
                                                       [UIImage imageNamed:@"featuredContent.png"], 
                                                       [UIImage imageNamed:@"mostPopular.png"],
                                                       [UIImage imageNamed:@"highestRated.png"],
                                                       [UIImage imageNamed:@"mostComments.png"],
                                                       [UIImage imageNamed:@"recent.png"],
                                                       nil]; 
    
    //initialize and store all the search strings as query params. 
    self.searchStrings = [NSMutableDictionary dictionary];
    [self initializeQueryParams];
    
    
    //logic to build the table acording to the presence of the featured groups and contents 
    if(!self.hasFeaturedGroups)
    {
        [self.listStrings removeObjectAtIndex:0];
        [self.listImages removeObjectAtIndex:0];
        if(!self.hasFeaturedContent)
        {
            [self.listImages removeObjectAtIndex:0];
             [self.listImages removeObjectAtIndex:0];
        }
    }
    else if(!self.hasFeaturedContent)
    {
        [self.listStrings removeObjectAtIndex:1];
        [self.listImages removeObjectAtIndex:1];
    }     
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.listStrings = nil;
    self.listImages = nil;
    self.searchStrings = nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //Return the number of rows in the section.
    return [self.listStrings count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //initializing the cell. 
    static NSString *CellIdentifier = @"CellIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
    
    //set the cell text and image
	cell.textLabel.text = [self.listStrings objectAtIndex:indexPath.row];
	cell.imageView.image = [self.listImages objectAtIndex:indexPath.row];
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
	//deselect the row
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];    
    
    UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];    
    if([@"Featured Groups" isEqualToString:selectedCell.textLabel.text])
    {
        //show the Featured Groups Controller
        GalleryFeaturedGroupsViewController *featuredGroupsVC = [[GalleryFeaturedGroupsViewController alloc] initWithPortal:self.portal];
        
        //set the title of the view to the appropriate value from the cell. 
        [featuredGroupsVC setTitle:selectedCell.textLabel.text];
        
        //show the view controller
        [self.navigationController pushViewController:featuredGroupsVC animated:YES];
        return;
        
    }
    if([@"Featured Content" isEqualToString:selectedCell.textLabel.text])
    {
        //show the Featured Content Controller
        GalleryFeaturedContentViewController *featuredContentVC = [[GalleryFeaturedContentViewController alloc] initWithPortal:self.portal];
        
        //set the title of the view to the appropriate value from the cell. 
        [featuredContentVC setTitle:selectedCell.textLabel.text];
        
        //show the view controller
        [self.navigationController pushViewController:featuredContentVC animated:YES];
        return;
        
    }
    
    FilteredItemsViewController *filteredItemsVC = [[FilteredItemsViewController alloc] initWithPortal:self.portal queryParams:[self.searchStrings objectForKey:selectedCell.textLabel.text]];  
    
    //set the title of the view to the appropriate value from the cell. 
    [filteredItemsVC setTitle:selectedCell.textLabel.text];
    
     //show the view controller
	[self.navigationController pushViewController:filteredItemsVC animated:YES];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}


#pragma mark - Helper

//method returns bool indicating whether the present organization has any featured groups or not. 
- (BOOL)hasFeaturedGroups
{
    return (self.portal.portalInfo.featuredGroupsQueries && ([self.portal.portalInfo.featuredGroupsQueries count] > 0));
}

//method returns bool indicating whether the present organization has any featured contents or not. 
- (BOOL)hasFeaturedContent
{
    return (self.portal.portalInfo.homepageFeaturedContentGroupQuery != nil);
}

- (void)initializeQueryParams
{
    
    NSString *query = @"type:\"Web Map\" -type:\"Web Mapping Application\"";
    
    //Most Popular
    AGSPortalQueryParams *params = [AGSPortalQueryParams queryParamsWithQuery:query];
    params.sortField = @"numViews";
    params.sortOrder = AGSPortalQuerySortOrderDescending;    
    self.searchStrings = [NSMutableDictionary dictionaryWithObjectsAndKeys:params, @"Most Popular", nil];
    
    //With rating
    params = [AGSPortalQueryParams queryParamsWithQuery:query];
    params.sortField = @"avgRating";
    params.sortOrder = AGSPortalQuerySortOrderDescending;
    [self.searchStrings setObject:params forKey:@"Highest Rated"];
    
    //With number of comments
    params = [AGSPortalQueryParams queryParamsWithQuery:query];
    params.sortField = @"numComments";
    params.sortOrder = AGSPortalQuerySortOrderDescending;
    [self.searchStrings setObject:params forKey:@"Most Comments"];
    
    //With creation date
    params = [AGSPortalQueryParams queryParamsWithQuery:query];
    params.sortField = @"uploaded";
    params.sortOrder = AGSPortalQuerySortOrderDescending;
    [self.searchStrings setObject:params forKey:@"Recent"];
    
}


-(CGSize)contentSizeForViewInPopover
{
    return self.view.bounds.size;
}
@end
