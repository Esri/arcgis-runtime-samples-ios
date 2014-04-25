// Copyright 2014 ESRI
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

#import "BasemapsListViewController.h"
#import "SVProgressHUD.h"
#import "AppConstants.h"

@interface BasemapsListViewController ()

@property (nonatomic, strong) NSArray *portalItems;
@property (nonatomic, strong) PortalBasemapHelper *portalBasemapHelper;
@property (nonatomic, weak) IBOutlet UIButton *loadButton;
@property (nonatomic, weak) IBOutlet UIView *footerView;
@property (nonatomic, strong) AGSCredential *credential;

@end

@implementation BasemapsListViewController

//in order to keep a single instance of the view controller
//creating a sharedInstance variable and will assign it the
//view controller once created
static id sharedInstance = nil;

//once the view controller is instantiated through the storyboard
//the following method is called for initialization
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        //storing the instance created as the sharedInstance inside a dispatch_once
        //block, in order to assign only the first time
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = self;
        });
    }
    return self;
}

//the following method is called everytime an object is instantiated using the initwithcoder method
//and we are using this method to return the sharedInstance (if exists) instead of the newly instantiated object
-(id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
    if (sharedInstance) {
        return sharedInstance;
    }
    return self;
}

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated {
    //viewDidLoad called everytime you trigger the segue
    //so in order to avoid reloading data everytime add a condition
    if (!self.portalItems) {
        [self loadBasemaps];
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadBasemaps {
    //show the progress hud
    [SVProgressHUD showWithStatus:@"Loading"];
    
    //instantiate the portalBasemapHelper if nil
    if (!self.portalBasemapHelper) {
        self.portalBasemapHelper = [[PortalBasemapHelper alloc] init];
        [self.portalBasemapHelper setDelegate:self];
    }
    //prepare for the connection to portal
    NSURL *portalUrl = [NSURL URLWithString:kPortalUrl];
    //if required create a credential
    //self.credential = [[AGSCredential alloc] initWithUser:kUserName password:kPassword];
    self.credential = nil;
    [self.portalBasemapHelper connectToPortal:portalUrl withCredential:self.credential];
}

//hide footer in case no more results
- (void)hideFooter {
    [self.footerView setHidden:YES];
}

//show footer if there are more results
- (void)showFooter {
    [self.footerView setHidden:NO];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.portalItems.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableString = @"TableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableString];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
    }
    
    AGSPortalItem *item = [self.portalItems objectAtIndex:indexPath.item];
    
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:1];
    [imageView setImage:item.thumbnail];
    
    UILabel *label = (UILabel*)[cell viewWithTag:2];
    [label setText:item.title];
    UILabel *descriptionLabel = (UILabel*)[cell viewWithTag:3];
    [descriptionLabel setText:item.snippet];
    
    return cell;
}

#pragma mark - Table view delegate methods

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AGSPortalItem *item = (AGSPortalItem*)[self.portalItems objectAtIndex:indexPath.item];
    [self.delegate basemapsListViewController:self didSelectMapWithItemId:item.itemId credential:self.credential];
}

#pragma mark - PortalBasemapHelperDelegate methods

-(void)portalBasemapHelper:(PortalBasemapHelper *)portalBasemapHelper didFailToLoadBasemapItemsWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    [SVProgressHUD dismiss];
}

-(void)portalBasemapHelper:(PortalBasemapHelper *)portalBasemapHelper didFinishLoadingBasemapItems:(NSArray *)itemsArray {
    //populate the portalItems array and reload data
    self.portalItems = itemsArray;
    [self.tableView reloadData];
    
    //check if there are more results and hide/show the footer view accordingly
    if ([portalBasemapHelper hasMoreResults]) {
        [self showFooter];
    }
    else {
        [self hideFooter];
    }
    
    [SVProgressHUD dismiss];
}

-(void)portalBasemapHelperDidFinishFetchingThumbnails:(PortalBasemapHelper *)portalBasemapHelper {
    //once all the thumbnails are downloaded, reload data
    [self.tableView reloadData];
}

#pragma mark - actions

-(IBAction)cancel:(id)sender {
    [self.delegate basemapsListViewControllerDidCancel:self];
}

//load more results
-(IBAction)loadMoreResults:(id)sender {
    [self.portalBasemapHelper nextResults];
}

@end
