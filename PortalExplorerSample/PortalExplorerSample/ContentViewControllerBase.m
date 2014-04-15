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

#import "ContentViewControllerBase.h"
#import "LoadingTableViewCell.h"
#import "GroupTableViewCell.h"
#import "FolderTableViewCell.h"
#import "ItemTableViewCell.h"
#import "FilteredItemsViewController.h"
#import "FolderItemsViewController.h"
#import "PortalExplorer.h"
#import <ArcGIS/ArcGIS.h>

#define kGroupTableViewCellIdentifier @"GroupTableViewCell"
#define kItemTableViewCellIdentifier @"ItemTableViewCell"
#define kFolderTableViewCellIdentifier @"FolderTableViewCell"
#define kLoadingCellIdentifier @"LoadingTableViewCell"
#define kDefaultCellIdentifier @"Cell"
#define kButtonCellIdentifier @"ButtonTableViewCell"

//how much to inset the cell buton
#define kButtonInset 10.0

#define kButtonTag 99

#define kCustomRowCount 1
#define kRowHeight 64

#define kThumbnailTag 1
#define kTitleTag 2
#define kDescriptionTag 3
#define kCreatedTag 3

#define kAppIconHeight 128


@implementation ContentViewControllerBase

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.currentIconDownloads = [NSMutableDictionary dictionary];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.currentIconDownloads = nil;
    self.searchResponseArray = nil;
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // terminate all pending download connections
    NSArray *allDownloads = [self.currentIconDownloads allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    [self.currentIconDownloads removeAllObjects];
}

#pragma mark - Table view data source


//subclasses can override if they have more than one section
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kRowHeight;
}

// Customize the number of rows in the table view.
// subclasses must override this
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger count = [self numberOfRowsInSection:section];
	
	// if we're still loading data, return enough rows to fill the screen
    //Note if doneLoading is YES, then there is no data at all
    if (count == 0)
	{
        count = kCustomRowCount;
    }
    
    //get the search response, if any, for this section
    AGSPortalQueryResultSet *resultSet = [self.searchResponseArray objectAtIndex:section];
    if (((id)resultSet) != [NSNull null])
    {
        //if we have a search response, check and see if we have any more left to get
        //If we're done loading, this cell will become the 'more results' button;
        //If we're not done loading, this cell will be the 'Loading' cell
        if (resultSet.totalResults > 0 && resultSet.queryParams.startIndex + [resultSet.results count] <= resultSet.totalResults)
        {
            //we have items left to get, add a 'More Results' button
            count++;
        }
    }
    
    return count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //get the content from the subclassed 'getContentForRowAtIndex'
    id content = [self contentForRowAtIndex:indexPath];
    
    //get the row count for the given section
    NSInteger rowCountForSection = [self numberOfRowsInSection:indexPath.section];
    
    //if we have no content, then the cell will either be the 'Loading' cell OR
    //the "More Results" button cell OR
    //(and this is the last choice) a "No results" cell
    if (content == nil) {
        
        //we're not done loading and we're either the first row
        //or beyond the last cell of data, so dispaly the 'loading' cell
        if (!self.doneLoading && (indexPath.row == 0 || indexPath.row == rowCountForSection))
        {
            //based on the kind of content, create the appropriate cell
            LoadingTableViewCell *cell = (LoadingTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:kLoadingCellIdentifier];
            
            if (cell == nil) {
                cell = [[LoadingTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kLoadingCellIdentifier];
            }
            
            return cell;
        }
        
        //we're done loading and we're not the first cell and we are beyond
        //the last cell of data, so display the 'More Results' button.
        if (self.doneLoading && indexPath.row != 0 && indexPath.row == rowCountForSection)
        {
            //we're done loading, not the first row, and if indexPath.row == rowCountForSection
            //that means we are trying to fill a row beyond the end of the item data, which
            //can only mean that we have a search response....so...
            //
            //get the search response, if any, for this section
            AGSPortalQueryResultSet *resultSet = [self.searchResponseArray objectAtIndex:indexPath.section];
            if (((id)resultSet) != [NSNull null])
            {
                //if we have a search response, check and see
                //if we have any more left to get
                if (resultSet.totalResults > 0 && resultSet.queryParams.startIndex + [resultSet.results count] <= resultSet.totalResults)
                {
                    //we have items left to get, add a 'More Results' button
                    
                    //Add the login button to the table view cell
                    UIButton* button = nil;
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kButtonCellIdentifier];
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kButtonCellIdentifier];
                        
                        //we need to add the button...  Create it and set it's properties
                        NSInteger buttonInset = kButtonInset;
                        
                        //frame
                        CGRect frame = CGRectInset(cell.contentView.bounds, buttonInset, buttonInset);
                        button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                        button.frame = frame;
                        button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                        
                        //in case the parent view draws with a custom color or gradient, use a transparent color
                        button.backgroundColor = [UIColor clearColor];
                        
                        UIImage *buttonBackgroundBlue = [UIImage imageNamed:@"blueButton.png"];
                        UIImage *newImageBlue = [buttonBackgroundBlue stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
                        
                        //Set up the button text and color
                        [button setBackgroundImage:newImageBlue forState:UIControlStateNormal];
                        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];                     
                        NSInteger fontSize = 18;
                        button.titleLabel.font = [button.titleLabel.font fontWithSize:fontSize];
                        [button setTitle:@"More Results" forState:UIControlStateNormal];
                        
                        //add tag so we can find it again. add the section to it to identify later. 
                        button.tag = indexPath.section + kButtonTag;
                        
                        //set the target for what happens when the button is clicked
                        [button addTarget:self action:@selector(moreResultsButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
                        
                        //resizing flags
                        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                        
                        //add the button to the cell
                        [cell.contentView addSubview:button];
                    }
                    else {
                        //get the button from the cell by finding the UIButton
                        //this way we can use the tab to store the section...
                        for (UIView *view in cell.contentView.subviews) {
                            if ([view isKindOfClass:[UIButton class]])
                            {
                                button = (UIButton *)view;
                                button.tag = indexPath.section + kButtonTag;
                                break;
                            }
                        }
                        
                    }    
                    
                    return cell;
                }
                else {
                    NSAssert(0, @"We should never get here; this means we made space for the 'More Results' button, but did not have any more results");
                }                
            }            
        }
        
        //default cell
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDefaultCellIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                           reuseIdentifier:kDefaultCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.detailTextLabel.text = @"NoContentAvailable";
        }
        
        return cell;
        
    } 

    UITableViewCell *cell = nil;
    
    //cell for the portal group class
    if ([content isKindOfClass:[AGSPortalGroup class]])
    {
        AGSPortalGroup *portalGroup = (AGSPortalGroup *)content;
        
        //based on the kind of content, create the appropriate cell
        GroupTableViewCell *groupTableViewCell = [self.tableView dequeueReusableCellWithIdentifier:kGroupTableViewCellIdentifier];
        
        if (groupTableViewCell == nil) {
            groupTableViewCell = [[GroupTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kGroupTableViewCellIdentifier];
        }       
        
        UIImage *image = nil;
        
        //if the portal group has a thumbnail, assign that to the image
        if (portalGroup.thumbnail)
        {
            image = portalGroup.thumbnail;
        }else if (portalGroup.thumbnailFileName != nil && ![portalGroup.thumbnailFileName isEqual: @""])
        {
           //obtain the thumbnail to fill the place holder
           [self startIconDownload:portalGroup forIndexPath:indexPath withSize:groupTableViewCell.thumbnailImageView.bounds.size];
            image = [UIImage imageNamed:@"Placeholder.png"];
               
        }else{
            image = [UIImage imageNamed:@"PlaceholderGroup.png"];
        }
        
        
        
        
        //load thumbnail view
        groupTableViewCell.thumbnailImageView.image = image;
        
        //set the title
        groupTableViewCell.titleLabel.text = portalGroup.title;
        
        //set the description
        groupTableViewCell.descriptionLabel.text = portalGroup.snippet;    
        
        //set the accessory type. 
        groupTableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;  
        
        cell = groupTableViewCell;
    }
    
    //cell for the portal item class
    if ([content isKindOfClass:[AGSPortalItem class]])
    {
        
        AGSPortalItem *portalItem = (AGSPortalItem *)content;
        
        //based on the kind of content, create the appropriate cell
        ItemTableViewCell *itemTableViewCell = [self.tableView dequeueReusableCellWithIdentifier:kItemTableViewCellIdentifier];
        
        if (itemTableViewCell == nil) {
            itemTableViewCell = [[ItemTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kItemTableViewCellIdentifier];
        }       
        
        UIImage *image = nil;
        
        //if the portal item has a thumbnail, assign that to the image
        if (portalItem.thumbnail)
        {
            image = portalItem.thumbnail;
        }else if (portalItem.thumbnailFileName != nil && ![portalItem.thumbnailFileName isEqual: @""])
        {
            //obtain the thumbnail to fill the place holder
            [self startIconDownload:portalItem forIndexPath:indexPath withSize:itemTableViewCell.thumbnailImageView.bounds.size];
            
            // use a placeholder image
            image = [UIImage imageNamed:@"Placeholder.png"];          
                
        }else{
            image = [UIImage imageNamed:@"PlaceholderMap.png"]; 
        }
         
        
        
        
        //load thumbnail view
        itemTableViewCell.thumbnailImageView.image = image;
        
        //set the title
        itemTableViewCell.titleLabel.text = portalItem.title;
        
        //set the description
        itemTableViewCell.descriptionLabel.text = portalItem.snippet;    
        
        //set the accessory type. 
        itemTableViewCell.accessoryType = UITableViewCellAccessoryNone;  
        
        cell = itemTableViewCell;
    }
    
    //cell for the portal folder class
    if ([content isKindOfClass:[AGSPortalFolder class]])
    {
        AGSPortalFolder *portalFolder = (AGSPortalFolder *)content;
        
        //based on the kind of content, create the appropriate cell
        FolderTableViewCell *folderTableViewCell = [self.tableView dequeueReusableCellWithIdentifier:kFolderTableViewCellIdentifier];
        
        if (folderTableViewCell == nil) {
            folderTableViewCell = [[FolderTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kFolderTableViewCellIdentifier];
        }               
        
        //load thumbnail view
        folderTableViewCell.thumbnailImageView.image = [UIImage imageNamed:@"Folder.png"];;
        
        //set the title
        folderTableViewCell.titleLabel.text = portalFolder.title;
        
        //set the description as the created date
        if (portalFolder.created)
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterLongStyle];
            NSString *sCreatedDateText = [dateFormatter stringFromDate:portalFolder.created];
            folderTableViewCell.descriptionLabel.text = [NSString stringWithFormat:@"Created: %@", sCreatedDateText];
        }
        else
            folderTableViewCell.descriptionLabel.text = @"";    
        
        //set the accessory type. 
        folderTableViewCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;  
        
        cell = folderTableViewCell;
    }

    return cell;
        
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    //deselect the row
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    //get content from subclassed getContentForRowAtIndex
    id content = [self contentForRowAtIndex:indexPath];
    
    if ([content isKindOfClass:[AGSPortalItem class]])
    {
        AGSPortalItem* portalItem = (AGSPortalItem *)content;
                
        //get the topmost view controller (portal explorer)
        //then check and make sure it response to 'openMap'
        NSArray *vcs = self.navigationController.viewControllers;
        UIViewController *viewController = [vcs objectAtIndex:0];
        
        //if the view controller is nil. means we are showing the search results,
        //and the navigation controller is now being pointed to by parentNavController
        if (![viewController isKindOfClass:[PortalExplorer class]]) {
            NSArray *vcs = self.parentViewController.navigationController.viewControllers;
            viewController = [vcs objectAtIndex:0];
        }  
    
        //open map if view controller responds to that message
        if ([viewController respondsToSelector:@selector(openMap:)]) {
            [viewController performSelector:@selector(openMap:) withObject:portalItem];
        }

    }
    
    if ([content isKindOfClass:[AGSPortalGroup class]])
    {
        //if it's a group, display the list of maps associated with that group
        AGSPortalGroup* portalGroup = (AGSPortalGroup *)content;
        AGSPortalQueryParams *queryParams = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap inGroup:portalGroup.groupId];
        
        FilteredItemsViewController *filteredItemsVC = [[FilteredItemsViewController alloc] initWithPortal:self.portal queryParams:queryParams];
        [filteredItemsVC setTitle:portalGroup.title];
        [self.navigationController pushViewController:filteredItemsVC animated:YES];
    }
    
    if ([content isKindOfClass:[AGSPortalFolder class]])
    {
        //if it's a folder, display the list of maps associated with that folder
        AGSPortalFolder *portalFolder = (AGSPortalFolder *)content;
        
        FolderItemsViewController *folderItemsVC = [[FolderItemsViewController alloc] initWithPortal:self.portal folderID:portalFolder.folderId];
        [folderItemsVC setTitle:portalFolder.title];
        [self.navigationController pushViewController:folderItemsVC animated:YES];
    }    
    
}

#pragma mark - IconDownloaderDelegate

// called by ImageDownloader when an icon is ready to be displayed
- (void)iconDownloader:(IconDownloader *)iconDownloader didDownloadIcon:(UIImage *)icon ofContentType:(id)contentType atIndexPath:(NSIndexPath *)indexPath
{
    //assign the icon to the corresponding cell. 
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if([cell isKindOfClass:[GroupTableViewCell class]])
    {
        GroupTableViewCell *groupTableViewCell = (GroupTableViewCell *)cell;
        groupTableViewCell.thumbnailImageView.image = icon;
    }
    
    if([cell isKindOfClass:[ItemTableViewCell class]])
    {
        ItemTableViewCell *itemTableViewCell = (ItemTableViewCell *)cell;
        itemTableViewCell.thumbnailImageView.image = icon;
    }
    
    [self.tableView reloadData];
}

- (void)iconDownloader:(IconDownloader *)iconDownloader didFailToDownloadIconAtIndexPath:(NSIndexPath *)indexPath error:(NSError *)error
{
    //assign the icon to the corresponding cell. 
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if([cell isKindOfClass:[GroupTableViewCell class]])
    {
        GroupTableViewCell *groupTableViewCell = (GroupTableViewCell *)cell;
        groupTableViewCell.thumbnailImageView.image = [UIImage imageNamed:@"PlaceholderGroup.png"];
    }
    
    if([cell isKindOfClass:[ItemTableViewCell class]])
    {
        ItemTableViewCell *itemTableViewCell = (ItemTableViewCell *)cell;
        itemTableViewCell.thumbnailImageView.image = [UIImage imageNamed:@"PlaceholderMap.png"];
    }
    
    [self.tableView reloadData]; 
}


#pragma mark - overriding methods

//for subclasses to override. 
- (id)contentForRowAtIndex:(NSIndexPath *)indexPath
{
    return nil;
}

//downloads the icon
- (void)startIconDownload:(id)contentType forIndexPath:(NSIndexPath *)indexPath withSize:(CGSize)size
{
    IconDownloader *iconDownloader = [self.currentIconDownloads objectForKey:indexPath];
    if (iconDownloader == nil) 
    {
        iconDownloader = [IconDownloader iconDownloaderWithContentType:contentType indexPath:indexPath iconSize:size];
        iconDownloader.delegate = self;
        [self.currentIconDownloads setObject:iconDownloader forKey:indexPath];
        [iconDownloader startIconDownload];  
    }
}

- (void)moreResultsButtonClicked:(id)sender
{
    [self loadMoreResults:(((UIButton *)sender).tag - kButtonTag)];
    [self.tableView reloadData];
}

// Base class implementation, subclasses need to override this
- (void)loadMoreResults:(NSInteger)section
{
    self.doneLoading = YES;
}

// Base class implementation, subclasses need to override this
- (NSInteger) numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

-(CGSize)contentSizeForViewInPopover
{
    return self.view.bounds.size;
}
@end
