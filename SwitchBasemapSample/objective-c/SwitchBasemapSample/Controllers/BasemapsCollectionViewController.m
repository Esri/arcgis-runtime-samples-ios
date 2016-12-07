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

#import "BasemapsCollectionViewController.h"
#import "AppConstants.h"
#import "SVProgressHUD.h"


@interface BasemapsCollectionViewController ()

@property (nonatomic, strong) NSArray *basemaps;
@property (nonatomic, strong) AGSPortal *portal;
@property (nonatomic, strong) PortalBasemapHelper *portalBasemapHelper;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) AGSCredential *credential;

@end

@implementation BasemapsCollectionViewController

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
    // Do any additional setup after loading the view.
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
    
    //prepare for connection to the portal
    NSURL *portalUrl = [NSURL URLWithString:kPortalUrl];
    //if required create a credential
    //self.credential = [[AGSCredential alloc] initWithUser:kUserName password:kPassword];
    self.credential = nil;
    __weak __typeof(self) weakSelf = self;
    [self.portalBasemapHelper fetchBasemapsFromPortal:portalUrl withCredential:self.credential completion:^(NSArray<AGSBasemap *> *basemaps, NSError *error) {
        [SVProgressHUD dismiss];
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        }
        else {
            //populate the basemaps array and reload data
            weakSelf.basemaps = basemaps;
            [weakSelf.collectionView reloadData];
        }
    }];
}

#pragma mark - dataSource methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    //an extra item cell in case there are more results
    return self.basemaps.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    //item cell for the regular data
    NSString *reusableString = @"Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reusableString forIndexPath:indexPath];
    
    AGSBasemap *basemap = [self.basemaps objectAtIndex:indexPath.item];
    cell.tag = indexPath.row + 1000;  // add 1000 to prevent conflicts with other tag operations
    
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:1];
    [imageView setImage:basemap.item.thumbnail.image];
    if (!basemap.item.thumbnail.image) {
        //if we don't have an image yet, load it
        [basemap.item.thumbnail loadWithCompletion:^(NSError * _Nullable error) {
            //make sure this is loaded and we're still on the correct row
            if (!error && cell.tag == indexPath.row + 1000) {
                [imageView setImage:basemap.item.thumbnail.image];
            }
        }];
    }
    
    UILabel *label = (UILabel*)[cell viewWithTag:2];
    [label setText:basemap.item.title];
    
    //add shadow to the cell
    [cell.layer setShadowOpacity:1];
    [cell.layer setShadowColor:[UIColor lightGrayColor].CGColor];
    [cell.layer setShadowRadius:2];
    [cell.layer setShadowOffset:CGSizeMake(2, 2)];
    [cell setClipsToBounds:NO];
    
    return cell;
}

#pragma mark - delegate methods

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    AGSBasemap *basemap = (AGSBasemap*)[self.basemaps objectAtIndex:indexPath.item];
    if (basemap) {
        [self.delegate basemapPickerController:self didSelectBasemap:basemap];
    }
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    //for iPad showing 3 item cells each row
    if ([self isIPad]) {
        double width = (self.collectionView.frame.size.width - 40)/3.0;
        return CGSizeMake(width, width);
    }
    //for iPhone showing 2 item cells each row for landscape
    //and 3 item cells for portrait
    else {
        double width;
        if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeLeft || [[UIDevice currentDevice] orientation] == UIInterfaceOrientationLandscapeRight) {
            width = (self.collectionView.frame.size.width - 40)/3.0;
        }
        else {
            width = (self.collectionView.frame.size.width - 30)/2.0;
        }
        return CGSizeMake(width, width);
    }
}

#pragma mark - actions

-(IBAction)cancel:(id)sender {
    [self.delegate basemapPickerControllerDidCancel:self];
}

//reload the data to adjust the layout based on orientation
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.collectionView reloadData];
}

#pragma mark - internal

-(BOOL)isIPad {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}

@end
