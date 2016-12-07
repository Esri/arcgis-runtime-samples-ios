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

@property (nonatomic, strong) NSArray *basemaps;
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
    if (!self.basemaps) {
        [self loadBasemaps];
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
    }
    //prepare for the connection to portal
    NSURL *portalUrl = [NSURL URLWithString:kPortalUrl];
    //if required create a credential
    //self.credential = [[AGSCredential alloc] initWithUser:kUserName password:kPassword];
    self.credential = nil;
    __weak __typeof(self) weakSelf = self;
    [self.portalBasemapHelper fetchBasemapsFromPortal:portalUrl withCredential:self.credential completion:^(NSArray<AGSBasemap *> *basemaps, NSError *error) {
        [SVProgressHUD dismiss];
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        } else {
            weakSelf.basemaps = basemaps;
        }
        [weakSelf.tableView reloadData];
    }];
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
    return self.basemaps.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reusableString = @"TableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusableString];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] init];
    }
    
    AGSBasemap *basemap = [self.basemaps objectAtIndex:indexPath.item];
    cell.tag = indexPath.row + 1000;  // add 1000 to prevent conflicts with other tag operations
    
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:1];
    [imageView setImage:basemap.item.thumbnail.image];
    if (!basemap.item.thumbnail.image) {
        //if we don't have an image yet, load it
        [basemap.item.thumbnail loadWithCompletion:^(NSError * _Nullable error) {
            //make sure this is loaded and we're still on the correct cell
            if (!error && cell.tag == indexPath.row + 1000) {
                [imageView setImage:basemap.item.thumbnail.image];
            }
        }];
    }
    
    UILabel *label = (UILabel*)[cell viewWithTag:2];
    [label setText:basemap.item.title];
    UILabel *descriptionLabel = (UILabel*)[cell viewWithTag:3];
    [descriptionLabel setText:basemap.item.snippet];
    
    //disable highlighting of selected cell
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}

#pragma mark - Table view delegate methods

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AGSBasemap *basemap  = (AGSBasemap*)[self.basemaps objectAtIndex:indexPath.item];
    [self.delegate basemapPickerController:self didSelectBasemap:basemap];
}

#pragma mark - actions

-(IBAction)cancel:(id)sender {
    [self.delegate basemapPickerControllerDidCancel:self];
}

@end
