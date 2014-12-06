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

@property (nonatomic, strong) NSArray *portalItems;
@property (nonatomic, strong) AGSPortal *portal;
@property (nonatomic, strong) PortalBasemapHelper *portalBasemapHelper;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) AGSCredential *credential;
@property (nonatomic, assign) BOOL thumbnailLoaded;
@property (nonatomic, strong) AGSWebMap *selectedWebMap;
@property (nonatomic, strong) NSMutableDictionary *basemapDictionary;

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
    
    //initialize the basedictionary if nil
    if (!self.basemapDictionary) {
        self.basemapDictionary = [NSMutableDictionary dictionary];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    //viewDidLoad called everytime you trigger the segue
    //so in order to avoid reloading data everytime add a condition
    if (!self.portalItems) {
        self.thumbnailLoaded = NO;
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
        [self.portalBasemapHelper setDelegate:self];
    }
    
    //prepare for connection to the portal
    NSURL *portalUrl = [NSURL URLWithString:kPortalUrl];
    //if required create a credential
    //self.credential = [[AGSCredential alloc] initWithUser:kUserName password:kPassword];
    self.credential = nil;
    [self.portalBasemapHelper fetchWebmapsFromPortal:portalUrl withCredential:self.credential];
}

#pragma mark - dataSource methods

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    //an extra item cell in case there are more results
    if ([self.portalBasemapHelper hasMoreResults]) {
        return self.portalItems.count+1;
    }
    return self.portalItems.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    //item cell for the next results
    if ([self.portalBasemapHelper hasMoreResults] && indexPath.item == self.portalItems.count) {
        NSString *reusableString = @"LoadCell";
        
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reusableString forIndexPath:indexPath];
        
        return cell;
    }
    //item cell for the regular data
    else {
        NSString *reusableString = @"Cell";
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reusableString forIndexPath:indexPath];
        
        AGSPortalItem *item = [self.portalItems objectAtIndex:indexPath.item];
        
        if (self.thumbnailLoaded) {
            UIImageView *imageView = (UIImageView*)[cell viewWithTag:1];
            [imageView setImage:item.thumbnail];
        }
        
        UILabel *label = (UILabel*)[cell viewWithTag:2];
        [label setText:item.title];
        
        //add shadow to the cell
        [cell.layer setShadowOpacity:1];
        [cell.layer setShadowColor:[UIColor lightGrayColor].CGColor];
        [cell.layer setShadowRadius:2];
        [cell.layer setShadowOffset:CGSizeMake(2, 2)];
        [cell setClipsToBounds:NO];
        
        return cell;
    }
}

#pragma mark - delegate methods

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!([self.portalBasemapHelper hasMoreResults] && indexPath.item == self.portalItems.count)) {
        AGSPortalItem *item = (AGSPortalItem*)[self.portalItems objectAtIndex:indexPath.item];
        AGSWebMapBaseMap *basemap = [self cachedBasemapForItemId:item.itemId];
        if (basemap) {
            [self.delegate basemapPickerController:self didSelectBasemap:basemap];
        }
        else {
            self.selectedWebMap = [[AGSWebMap alloc] initWithPortalItem:item];
            [self.selectedWebMap setDelegate:self];
        }
    }
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    //for iPad showing 3 item cells each row
    if ([[AGSDevice currentDevice] isIPad]) {
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

#pragma mark - Web map delegate methods

-(void)webMapDidLoad:(AGSWebMap *)webMap {
    //cache the base map
    [self.basemapDictionary setValue:webMap.baseMap forKeyPath:webMap.portalItem.itemId];
    [self.delegate basemapPickerController:self didSelectBasemap:self.selectedWebMap.baseMap];
}

#pragma mark - actions

-(IBAction)cancel:(id)sender {
    [self.delegate basemapPickerControllerDidCancel:self];
}

//load the next set of results
-(IBAction)loadMoreResults:(id)sender {
    [self.portalBasemapHelper fetchNextResults];
}

#pragma mark - PortalBasemapHelperDelegate methods

-(void)portalBasemapHelper:(PortalBasemapHelper *)portalBasemapHelper didFailToLoadBasemapItemsWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
    [SVProgressHUD dismiss];
}

- (void)portalBasemapHelper:(PortalBasemapHelper *)portalBasemapHelper didFinishLoadingBasemapItems:(NSArray *)itemsArray {
    //populate the portalitems array and reload data
    self.portalItems = itemsArray;
    [self.collectionView reloadData];
    [SVProgressHUD dismiss];
}

-(void)portalBasemapHelperDidFinishFetchingThumbnails:(PortalBasemapHelper *)portalBasemapHelper {
    self.thumbnailLoaded = YES;
    //once all the images are downloaded, reload the view
    [self.collectionView reloadData];
}

//reload the data to adjust the layout based on orientation
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.collectionView reloadData];
}

#pragma mark - local/cached basemap methods

-(AGSWebMapBaseMap*)cachedBasemapForItemId:(NSString*)itemId {
    AGSWebMapBaseMap *basemap = [self.basemapDictionary objectForKey:itemId];
    return basemap;
}

@end
