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

#import "PortalExplorer.h"
#import <ArcGIS/ArcGIS.h>
#import "OrganizationDetailsViewController.h"
#import "GalleryViewController.h"
#import "SearchViewController.h"
#import "UserGroupsViewController.h"
#import "UserContentViewController.h"


//table view layout info
#define kOrganizationSection 0
#define kGroupsAndContentsSection 1
#define kLoginSection 2
#define kSectionCount 3
#define kOrganizationRowSize 80
#define kGroupsAndContentsSectionRowsCountWithCredential 3
#define kTitleFontSize 16
#define kImageViewTag 100
#define kTitleTag 101
#define kSignInButtonTag 99

//how much to inset the sign in buton
static float kButtonInset = 2.0;

@interface PortalExplorer()<AGSPortalDelegate, AGSPortalInfoDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

//tableView to display portal info
@property (nonatomic, strong) IBOutlet UITableView *tableView;

//portal that is currently being explored
@property (nonatomic, strong) AGSPortal *portal;

//URL of the portal that is currently being explored
@property (nonatomic, strong) NSURL* portalURL;

//previous portal if current one does not load
@property (nonatomic, strong) AGSPortal *backupPortal;

//Credential that should be used to explore the portal
@property (nonatomic, strong) AGSCredential* credential;

- (void)openMap:(AGSPortalItem *)webmap;
- (void)signInButtonClicked:(id)sender;
- (void)doneButtonClicked:(id)sender;
- (void)searchButtonClicked:(id)sender;

@end

@implementation PortalExplorer

- (void)dealloc {    
    self.delegate = nil;
}

- (id)initWithURL:(NSURL *)portalURL credential:(AGSCredential *)credential
{
    self = [super initWithNibName:@"PortalExplorer" bundle:nil];
    if (self) {     
        self.portalURL = portalURL;
        self.credential = credential;
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
    
    //init specified portal if we haven't already
    if(!self.portal){
        //Get the app delegate and turn on the activity indicator
        [AGSApplication ags_showNetworkActivityIndicator:YES];
        self.portal = [[AGSPortal alloc] initWithURL:self.portalURL credential:self.credential];  
    }
    
    
    //assign the portal delegate to self.
    //we do this everytime this view controller loads because the portal is 
    //shared by many view controllers each of which sets themselves as the delegate
    //
    //This ensures that this view controller becomes the delegate when visible again
    self.portal.delegate = self; 
    
  

    //create and asign a done button as the left bar button. 
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(doneButtonClicked:)];
	self.navigationItem.leftBarButtonItem = doneButton;
    
    //create and assign a search portal button as the right bar button. 
    UIBarButtonItem *searchButton = 
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch 
                                                  target:self 
                                                  action:@selector(searchButtonClicked:)];
	self.navigationItem.rightBarButtonItem = searchButton;
    
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.tableView = nil;
    
    //eventhough we are releasing the portal,
    //we have the URL and the credential to recreate it
    self.portal = nil;  
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItem = nil;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    //there are three sections: 1)About the Organization, 2) Contents and Groups, 3) Sign In
    return kSectionCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.section == kOrganizationSection)
    {
        return kOrganizationRowSize;
    }
    else
    {
        return self.tableView.rowHeight;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    //both the organization and sign in sections have 1 row. groups and contents section row count would depend on the credential. 
    NSInteger nRowCount = 1;    
    if (section == kGroupsAndContentsSection)
    {
        if (self.portal.credential)
        {
            nRowCount = kGroupsAndContentsSectionRowsCountWithCredential;
        }
    }    
    return nRowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //static cell identifiers. 
    static NSString *organizationCellIdentifier = @"OrganizationCell";
    static NSString *groupsAndContentsCellIdentifier = @"GroupsAndContentsCell";
    static NSString *signInButtonCellIdentifier = @"SignInButtonCell";
    
    UITableViewCell *cell = nil; 
    
    //for the organization cell. 
    if (indexPath.section == kOrganizationSection)
    {
        //Organization row
        cell = [tableView dequeueReusableCellWithIdentifier:organizationCellIdentifier];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:organizationCellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            //add organization thumbnail view
            UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(8, 8, 64, 64)];
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            imageView.tag = kImageViewTag;
            if ([imageView.layer respondsToSelector:@selector(setShadowColor:)])
            {
                imageView.layer.shadowColor = [UIColor blackColor].CGColor;
                imageView.layer.shadowOpacity = 0.8;
                imageView.layer.shadowRadius = 5;
                imageView.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);        
            }            
            [[cell contentView] addSubview:imageView];
            
            //add organization title
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(84, 8, 188, 64)];
            [titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
            [titleLabel setNumberOfLines:0];
            [titleLabel setFont:[UIFont boldSystemFontOfSize:kTitleFontSize]];
            titleLabel.tag = kTitleTag;
            titleLabel.textColor = [UIColor blackColor];
            titleLabel.backgroundColor = [UIColor clearColor];            
            [[cell contentView] addSubview:titleLabel];
            
            //set the accessory type
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        //set the thumbnail image if it exists in the portal info otherwise set it to the default one. 
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:kImageViewTag]; 
        if(self.portal.portalInfo.organizationThumbnail)
        {
            imageView.image = self.portal.portalInfo.organizationThumbnail;
        }        
        else if(self.portal.portalInfo.portalThumbnail)
        {
            imageView.image = self.portal.portalInfo.portalThumbnail;
        }
        else
        {
            imageView.image = [UIImage imageNamed:@"defaultOrganization.png"];
        }
        
        //set the title        
        UILabel *label = (UILabel *)[cell viewWithTag:kTitleTag];               
        label.text = self.portal.portalInfo.organizationId ? self.portal.portalInfo.organizationName : self.portal.portalInfo.portalName;  
        
    }

    //for the groups and contents section.
    else if (indexPath.section == kGroupsAndContentsSection)
    {
        //set up the cell
        cell = [tableView dequeueReusableCellWithIdentifier:groupsAndContentsCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:groupsAndContentsCellIdentifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        //if the credential exists, it should contain three cells
        if(self.portal.credential)
        {
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"My Groups";
                    cell.imageView.image = [UIImage imageNamed:@"myGroups.png"];
                    break;
                case 1:
                    cell.textLabel.text = @"My Maps";
                    cell.imageView.image = [UIImage imageNamed:@"myContent.png"];
                    break;
                case 2:
                    cell.textLabel.text = @"Gallery";
                    cell.imageView.image = [UIImage imageNamed:@"gallery.png"];
                    break;
                    
                default:
                    break;
            }

        }
        
        //otherwise just the gallery cell
        else
        {
            cell.textLabel.text = @"Gallery";
            cell.imageView.image = [UIImage imageNamed:@"gallery.png"];
        }
        
        //set the acessory type
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    else
    {
        UIButton* button;
        
        //sign in button
        cell = [tableView dequeueReusableCellWithIdentifier:signInButtonCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:signInButtonCellIdentifier];
            
            //create the button and set it's properties            
            CGRect frame = CGRectInset(cell.contentView.bounds, kButtonInset, kButtonInset);
            button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            button.frame = frame;
            button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            
            // in case the parent view draws with a custom color or gradient, use a transparent color
            button.backgroundColor = [UIColor clearColor];
            
            //set the font
            button.titleLabel.font = [button.titleLabel.font fontWithSize:18];
            
            //add tag so we can find it again
            button.tag = kSignInButtonTag;
            
            //set the target for what happens when the button is clicked
            [button addTarget:self action:@selector(signInButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
            
            //resizing flags
            button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            
            //add the button to the cell
            [cell.contentView addSubview:button];
        }
        else {
            //get button from cell via tag
            button = (UIButton *)[cell viewWithTag:kSignInButtonTag];
        }
        
        //get the appropriate images
		UIImage *buttonBackgroundSignedOut = [UIImage imageNamed:@"whiteButton.png"];
		UIImage *buttonBackgroundSignedIn = [UIImage imageNamed:@"blueButton.png"];
        
        UIImage *newImageSignedOut = [buttonBackgroundSignedOut stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
        UIImage *newImageSignedIn = [buttonBackgroundSignedIn stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
        
        //Set up the button text and color appropriately based on
        //whether the user is signed in or not
        NSString* text;
        UIImage* backgroundImage;
        if (self.portal.credential)
        {
            text = [NSString stringWithFormat:@"Account: %@", self.portal.credential.username];
            backgroundImage = newImageSignedIn;
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        else {
            text = @"Sign In";
            backgroundImage = newImageSignedOut;            
            [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
        
        //set the title and background image. 
        [button setTitle:text forState:UIControlStateNormal];	
        [button setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //deselect the row
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];   
    
    UIViewController* nextViewController = nil;
    
    //show the ogranization details. 
    if (indexPath.section == kOrganizationSection)
    {
        OrganizationDetailsViewController *organizationDetailsVC = [[OrganizationDetailsViewController alloc] initWithPortalInfo:self.portal.portalInfo];
        [organizationDetailsVC setTitle:@"Organization"];
        nextViewController = organizationDetailsVC;
    }
    
    else if (indexPath.section == kGroupsAndContentsSection)
    {
        //if the credential exists, it should contain three cells
        if(self.portal.credential)
        {
            //show the ogranization details. 
            switch (indexPath.row) {
                case 0:
                {
                    //open user's groups controller
                    UserGroupsViewController *userGroupsVC = [[UserGroupsViewController alloc] initWithPortal:self.portal];
                    [userGroupsVC setTitle:@"User Groups"];
                    nextViewController = userGroupsVC;
                    break;
                }
                case 1:
                {
                    //open user's maps controller
                    UserContentViewController *userContentsVC = [[UserContentViewController alloc] initWithPortal:self.portal];
                    [userContentsVC setTitle:@"User Content"];
                    nextViewController = userContentsVC;
                    break;
                }
                case 2:
                {
                    //open gallery controller
                    GalleryViewController *mapGalleryVC = [[GalleryViewController alloc] initWithPortal:self.portal];
                    [mapGalleryVC setTitle:@"Gallery"];
                    nextViewController = mapGalleryVC;
                    break;
                }
                default:
                    break;
            }
        }
        
        //otherwise just the gallery cell
        else
        {
            //open gallery controller
            GalleryViewController *mapGalleryVC = [[GalleryViewController alloc] initWithPortal:self.portal];
            [mapGalleryVC setTitle:@"Gallery"];
            nextViewController = mapGalleryVC;

        }
    }
    
    else
    {
        //login button which is handled separately. 
    }
    
    // Navigation logic may go here. Push another view controller.
    [self.navigationController pushViewController:nextViewController animated:YES];
}

#pragma mark - AGSPortalDelegate

- (void)portalDidLoad:(AGSPortal *)portal {
    
    //clear out the backup, we won't need it any more because the new portal loaded successfully
    self.backupPortal = nil;
    
    //Get the app delegate and turn on the activity indicator
    [AGSApplication ags_showNetworkActivityIndicator:NO];
    
    //reload the tableview
    [self.tableView reloadData];
    
    //retrieve the thumbnails of the organization
    if (self.portal.portalInfo.organizationThumbnailFileName) {        
        [self.portal.portalInfo fetchOrganizationThumbnail];
        self.portal.portalInfo.delegate = self;
        
        //Get the app delegate and turn on the activity indicator
        [AGSApplication ags_showNetworkActivityIndicator:YES];
    }     
    else if(self.portal.portalInfo.portalThumbnailFileName)
    {
        [self.portal.portalInfo fetchPortalThumbnail];
        self.portal.portalInfo.delegate = self;
        
        //Get the app delegate and turn on the activity indicator
        [AGSApplication ags_showNetworkActivityIndicator:YES];
    }
    
    //inform the PE delegate that the portal has been successfully loaded. 
    if([self.delegate respondsToSelector:@selector(portalExplorer:didLoadPortal:)])
    {
        [self.delegate portalExplorer:self didLoadPortal:self.portal];
    }
    
}

- (void)portal:(AGSPortal *)portal didFailToLoadWithError:(NSError *)error {
    
    //Get the app delegate and turn off the activity indicator
    [AGSApplication ags_showNetworkActivityIndicator:NO];
    
    //confronting the untrusted host error and trying again. 
    if ([error code] == NSURLErrorServerCertificateUntrusted) {
		
        //add host to trusted hosts
        [[NSURLConnection ags_trustedHosts] addObject:[self.portal.URL host]];
        
        //retry
        [self.portal resubmitWithURL:self.portal.URL credential:self.portal.credential];
        
        //Get the app delegate and turn on the activity indicator
        [AGSApplication ags_showNetworkActivityIndicator:YES];
    }
    
    //for all other errors, call the appropriate delegate method 
    else {
        
        if([self.delegate respondsToSelector:@selector(portalExplorer:didFailToLoadPortalWithError:)])
        {
            [self.delegate portalExplorer:self didFailToLoadPortalWithError:error];
        }
        
        //and restore the backup portal so that the portal explorer continues to work as before
        self.portal = self.backupPortal;
        self.credential = self.backupPortal.credential;
        self.backupPortal = nil;
    }
}

#pragma mark - AGSPortalInfoDelegate

-(void)portalInfo:(AGSPortalInfo*)portalInfo operation:(NSOperation*)op didFetchOrganizationThumbnail:(UIImage*)thumbnail
{        
    //Get the app delegate and turn off the activity indicator
    [AGSApplication ags_showNetworkActivityIndicator:NO];
    
    //assign the image to the corresponding image view. 
    UITableViewCell *organizationCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kOrganizationSection]];    
    UIImageView *orgThumbnailImageView = (UIImageView *)[organizationCell viewWithTag:kImageViewTag];
    orgThumbnailImageView.image = thumbnail;
}

-(void)portalInfo:(AGSPortalInfo*)portalInfo operation:(NSOperation*)op didFailToFetchOrganizationThumbnailWithError:(NSError*)error
{
    //Get the app delegate and turn off the activity indicator
    [AGSApplication ags_showNetworkActivityIndicator:NO];
}

-(void)portalInfo:(AGSPortalInfo*)portalInfo operation:(NSOperation*)op didFetchPortalThumbnail:(UIImage*)thumbnail
{        
    //Get the app delegate and turn off the activity indicator
    [AGSApplication ags_showNetworkActivityIndicator:NO];
    
    //assign the image to the corresponding image view. 
    UITableViewCell *organizationCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:kOrganizationSection]];    
    UIImageView *orgThumbnailImageView = (UIImageView *)[organizationCell viewWithTag:kImageViewTag];
    orgThumbnailImageView.image = thumbnail;
}

-(void)portalInfo:(AGSPortalInfo*)portalInfo operation:(NSOperation*)op didFailToFetchPortalThumbnailWithError:(NSError *)error
{
    //Get the app delegate and turn off the activity indicator
    [AGSApplication ags_showNetworkActivityIndicator:NO];
}




#pragma mark - Helper

- (void)signInButtonClicked:(id)sender
{    
    //if the portal already has the credential, then user wants to sign out. 
    if(self.portal.credential)
    {
        [[[UIAlertView alloc] initWithTitle:@"Sign out" 
                                     message:@"Would you like to sign out of the portal?" 
                                    delegate:self cancelButtonTitle:@"Cancel" 
                           otherButtonTitles:@"Sign out", nil] 
         show];       
       
    }
    
    //else user wants to sign in. call the appropriate delegate method to inform the same. 
    else
    {
        if([self.delegate respondsToSelector:@selector(portalExplorer:didRequestSignInForPortal:)])
        {
            [self.delegate portalExplorer:self didRequestSignInForPortal:self.portal];
        }
    }    
}

- (void)doneButtonClicked:(id)sender
{
    if([self.delegate respondsToSelector:@selector(portalExplorerWantsToHide:)])
    {
        [self.delegate portalExplorerWantsToHide:self];
    }
}

- (void)searchButtonClicked:(id)sender
{
    //instantiate the search VC and show it in a nav controller
    SearchViewController *searchVC = [[SearchViewController alloc] initWithPortal:self.portal];
    [searchVC setTitle:@"Search"];
    [self.navigationController pushViewController:searchVC animated:YES];
}

- (void)updatePortalWithCredential:(AGSCredential *)credential
{

    //keep a reference to the current portal incase we need to revert back to it in the event of an error
    self.backupPortal = self.portal;
    self.credential = credential;
    
    //connect again, this time using a credential
    self.portal = [[AGSPortal alloc] initWithURL:self.portalURL credential:self.credential];
    self.portal.delegate = self;
    //Get the app delegate and turn on the activity indicator
    [AGSApplication ags_showNetworkActivityIndicator:YES];
}

- (void)openMap:(AGSPortalItem *)portalItem
{
    //call the appropriate delegate method to inform that the portal item has been selected and needs to be opened. 
    if([self.delegate respondsToSelector:@selector(portalExplorer:didSelectPortalItem:)])
    {
        [self.delegate portalExplorer:self didSelectPortalItem:portalItem];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        //user is signed out. 
        if([self.delegate respondsToSelector:@selector(portalExplorer:didRequestSignOutFromPortal:)])
        {
            [self.delegate portalExplorer:self didRequestSignOutFromPortal:self.portal];
        }
    }
}

-(CGSize)contentSizeForViewInPopover
{
    return self.view.bounds.size;
}


@end
