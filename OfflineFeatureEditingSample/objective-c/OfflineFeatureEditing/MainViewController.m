// Copyright 2013 ESRI
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

#import "MainViewController.h"
#import "AppDelegate.h"
#import "FeatureTemplatePickerViewController.h"
#import "SVProgressHUD.h"
#import "JSBadgeView.h"
#import "UIAlertView+NSCookbook.h"
#import "LoadingView.h"
#import "BackgroundHelper.h"

#define kTilePackageName @"SanFrancisco"
#define kFeatureServiceURL @"http://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer"

@interface MainViewController () <AGSLayerDelegate, AGSMapViewTouchDelegate, AGSPopupsContainerDelegate, AGSMapViewLayerDelegate, AGSCalloutDelegate, FeatureTemplatePickerDelegate>

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIView *badgeView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *liveActivityIndicator;
@property (weak, nonatomic) IBOutlet UIToolbar *geometryEditToolbar;

@property (nonatomic, strong) AGSGDBGeodatabase *geodatabase;
@property (nonatomic, strong) AGSGDBSyncTask *gdbTask;
@property (nonatomic, strong) id<AGSCancellable> cancellable;
@property (nonatomic, strong) AGSMapView* mapView;

@property (nonatomic, strong) AGSLocalTiledLayer *localTiledLayer;

@property (nonatomic, strong) NSString *replicaJobId;
@property (nonatomic, strong) AGSPopupsContainerViewController *popupsVC;
@property (nonatomic, strong) AGSSketchGraphicsLayer *sgl;

@property (nonatomic, strong) JSBadgeView* badge;
@property (nonatomic, strong) LoadingView* loadingView;

@property (nonatomic, assign) BOOL goingLocal;
@property (nonatomic, assign) BOOL goingLive;
@property (nonatomic, assign) BOOL viewingLocal;


@property (nonatomic, strong) UITextView *logsTextView;

@property (nonatomic, strong) NSMutableString *allStatus;

@property (nonatomic, strong) UIPopoverController* pvc;
@property (nonatomic, strong) FeatureTemplatePickerViewController* featureTemplatePickerVC;

@property (nonatomic, assign) BOOL newlyDownloaded;

- (IBAction)cancelEditingGeometry:(id)sender;
- (IBAction)doneEditingGeometry:(id)sender;

@end

@implementation MainViewController


- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    //Add a map view to the UI
    self.mapView = [[AGSMapView alloc]initWithFrame:self.mapContainer.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.mapContainer addSubview:self.mapView];
    self.mapView.touchDelegate = self;
    self.mapView.layerDelegate = self;
    self.mapView.callout.delegate = self;

    //Add the basemap layer from a tile package
    self.localTiledLayer =  [AGSLocalTiledLayer localTiledLayerWithName:kTilePackageName];
    
    //Add layer delegate to catch errors in case the local tiled layer is replaced and problems arise
    self.localTiledLayer.delegate = self;
    
    [self.mapView addMapLayer:self.localTiledLayer];
    


    self.allStatus = [NSMutableString string];
    
    
    //Add a view that will display logs
    self.logsTextView = [[UITextView alloc]initWithFrame:self.view.bounds];
    self.logsTextView.hidden = YES;
    self.logsTextView.userInteractionEnabled = YES;
    self.logsTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.logsTextView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:.78];
    self.logsTextView.textColor = [UIColor whiteColor];
    self.logsTextView.editable = NO;
    [self.view addSubview:self.logsTextView];

    //Add a swipe gesture recognizer that will show this view
    UISwipeGestureRecognizer *gr2 = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(showLogsGesture:)];
    gr2.direction = UISwipeGestureRecognizerDirectionUp;
    [self.logsLabel addGestureRecognizer:gr2];

    //Add a tap gesture recognizer that will hide this view
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideLogsGesture:)];
    [self.logsTextView addGestureRecognizer:gr];
    


}

- (void)viewDidUnload{
    [self setMapContainer:nil];
    [self setLogsLabel:nil];
    [self setLeftContainer:nil];
    [self setAddFeatureButton:nil];
    [self setSyncButton:nil];
    [self setGoOfflineButton:nil];
    [self setGoOfflineButton:nil];
    [self setOfflineStatusLabel:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    if(!self.pvc.popoverVisible){
        self.pvc =  nil;
        self.featureTemplatePickerVC = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

#pragma mark AGSMapViewLayerDelegate methods
-(void) mapViewDidLoad:(AGSMapView *)mapView {

    //Load live layers
    [self switchToLiveData];

}

#pragma mark Gesture Recognizers

-(void)hideLogsGesture:(UIGestureRecognizer*)gr{
    self.logsTextView.hidden = YES;
}

-(void)showLogsGesture:(UIGestureRecognizer*)gr{
    self.logsTextView.hidden = NO;
}

#pragma mark AGSLayerDelegate methods

-(void)layerDidLoad:(AGSLayer *)layer{
    if([layer isKindOfClass:[AGSFeatureTableLayer class]]){
        AGSFeatureTableLayer* ftLayer = (AGSFeatureTableLayer*)layer;
        if(self.mapView.mapScale>ftLayer.minScale)
            [self.mapView zoomToScale:ftLayer.minScale animated:YES];
        [SVProgressHUD popActivity];
    }
}


-(void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error{
    NSString *errmsg;
    
    if([layer isKindOfClass:[AGSFeatureTableLayer class]]){
        AGSFeatureTableLayer* ftLayer = (AGSFeatureTableLayer*)layer;
        errmsg = [NSString stringWithFormat:@"Failed to load %@. Error:%@",ftLayer.name, error];
        
        // activity shown when loading online layer, dismiss this
        [SVProgressHUD popActivity];
    }
    else if([layer isKindOfClass:[AGSLocalTiledLayer class]]){
        errmsg = [NSString stringWithFormat:@"Failed to load local tiled layer. Error:%@", error];
    }
    
    [self logStatus:errmsg];
}


#pragma mark - AGSMapViewTouchDelegate methods
- (void) mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features {
    
    //Show popups for features that were tapped on
    NSMutableArray *tappedFeatures = [[NSMutableArray alloc]init];
    NSEnumerator* keys = [features keyEnumerator];
    for (NSString* key in keys) {
        [tappedFeatures addObjectsFromArray:[features objectForKey:key]];
    }
        if (tappedFeatures.count){
            [self showPopupsForFeatures:tappedFeatures];
        }
        else{
            [self hidePopupsVC];
        }
    
}

#pragma mark - Showing popups
-(void)showPopupsForFeatures:(NSArray*)features{
    NSMutableArray *popups = [NSMutableArray arrayWithCapacity:features.count];

    for (id<AGSFeature> feature in features) {
        AGSPopup* popup;
        AGSGDBFeature* gdbFeature = (AGSGDBFeature*)feature;
        AGSPopupInfo* popupInfo = [AGSPopupInfo popupInfoForGDBFeatureTable:gdbFeature.table];
        popup = [AGSPopup popupWithGDBFeature:gdbFeature popupInfo:popupInfo];
        [popups addObject:popup];
    }
    
    [self showPopupsVCForPopups:popups];
}

-(void)hidePopupsVC{
    if ([[AGSDevice currentDevice] isIPad]) {
        for (UIView *sv in self.leftContainer.subviews){
            [sv removeFromSuperview];
        }
        self.popupsVC = nil;
        self.leftContainer.hidden = YES;
    }
    else {
        [self.popupsVC dismissViewControllerAnimated:YES completion:^{
            self.popupsVC = nil;
        }];
    }
    
}


-(void)showPopupsVCForPopups:(NSArray*)popups{
    
    [self hidePopupsVC];
    
    //Create the view controller for the popups
        self.popupsVC = [[AGSPopupsContainerViewController alloc]initWithPopups:popups usingNavigationControllerStack:NO];
        self.popupsVC.delegate = self;
        self.popupsVC.style = AGSPopupsContainerStyleBlack;
        self.popupsVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;        
    
    //On ipad, display the popups vc a form sheet on the left
    if ([[AGSDevice currentDevice] isIPad]) {
        self.leftContainer.hidden = NO;
        self.popupsVC.modalPresentationStyle = UIModalPresentationFormSheet;
        self.popupsVC.modalPresenter = self;
        self.popupsVC.view.frame = self.leftContainer.bounds;
        [self.leftContainer addSubview:self.popupsVC.view];
    }
    //On iphone, display the vc in full screen
    else {
        self.popupsVC.modalPresentationStyle = UIModalPresentationFullScreen;
        self.popupsVC.view.frame = self.view.bounds;
        [self presentViewController:self.popupsVC animated:YES completion:nil];

    }
}

#pragma mark Action methods

- (IBAction)addFeatureAction:(id)sender {
    
    //Initialize the template picker view controller
    if(!self.featureTemplatePickerVC){
        self.featureTemplatePickerVC = [[FeatureTemplatePickerViewController alloc]init];
        self.featureTemplatePickerVC.delegate = self;
        [self.featureTemplatePickerVC addTemplatesForLayersInMap:self.mapView];
    }
    
    //On iPad, display the template picker vc in a popover
    if ([[AGSDevice currentDevice]isIPad]) {
        self.pvc = [[UIPopoverController alloc]initWithContentViewController:self.featureTemplatePickerVC];
        [self.pvc presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        
    //On iPhone, display the vc full screen
    }else{
        [self presentViewController:self.featureTemplatePickerVC animated:YES completion:nil];
    }
    

}

- (IBAction)deleteGDBAction:(id)sender {
    if (self.viewingLocal || self.goingLocal){
        [self logStatus:@"cannot delete local data while displaying it"];
        return;
    }
    self.geodatabase = nil;
    
    //Remove all files with .geodatabase, .geodatabase-shm, and .geodatabase-wal file extensions
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSArray *files = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:path error:nil];
    for (NSString *file in files){
        BOOL remove = [file hasSuffix:@".geodatabase"] || [file hasSuffix:@".geodatabase-shm"] || [file hasSuffix:@".geodatabase-wal"];
        if (remove){
            NSError* error;
            [[NSFileManager defaultManager]removeItemAtPath:[path stringByAppendingPathComponent:file] error:&error];
            [self logStatus:[NSString stringWithFormat:@"deleting %@",file]];
            
        }
    }
    [self logStatus:[NSString stringWithFormat:@"deleted all local data"]];
}

- (IBAction)syncAction:(id)sender {
    
    if (self.cancellable){
        // if already syncing just return
        return;
    }
    [SVProgressHUD showWithStatus:@"Synchronizing \n changes"];
    [self logStatus:@"Starting sync process..."];
    
    //Create default sync params based on the geodatabase
    //You can modify the param to change sync options (sync direction, included layers, etc)
    AGSGDBSyncParameters* param = [[AGSGDBSyncParameters alloc]initWithGeodatabase:self.geodatabase];

    //kick off the sync operation
    self.cancellable = [self.gdbTask syncGeodatabase:self.geodatabase params:param status:^(AGSResumableTaskJobStatus status, NSDictionary *userInfo) {
        [self logStatus:[NSString stringWithFormat:@"sync status: %@", [self statusMessageForAsyncStatus:status]]];
    } completion:^(AGSGDBEditErrors* editErrors, NSError *syncError) {
        self.cancellable = nil;
        if (syncError){
            [self logStatus:[NSString stringWithFormat:@"error sync'ing: %@", syncError]];
            [SVProgressHUD showErrorWithStatus:@"Error encountered"];
        }
        else{
 
// TODO: Handle sync edit errors
            
            [self logStatus:[NSString stringWithFormat:@"sync complete"]];
            [SVProgressHUD showSuccessWithStatus:@"Sync complete"];
            [BackgroundHelper postLocalNotificationIfAppNotActive:@"sync complete"];
            
            //Remove the local edits badge from the sync button
            [self showEditsInGeodatabaseAsBadge:nil];
            
        }
        
    }];
}

- (IBAction)switchModeAction:(id)sender {
    
    if (self.goingLocal){
        return;
    }
    
    if (self.viewingLocal){
        if([self.geodatabase hasLocalEdits]){
            UIAlertView* av = [[UIAlertView alloc]initWithTitle:@"Local data contains edits" message:@"Do you want to sync them with the service?" delegate:nil cancelButtonTitle:@"Later" otherButtonTitles:@"Yes", nil];
            [av showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
                switch (buttonIndex) {
                    case 0: //No, just switch to live
                        [self switchToLiveData];
                        break;
                    case 1: //Yes, sync instead
                        [self syncAction:nil];
                        break;
                    default:
                        break;
                }
            }];
            return;
        }else{
            [self switchToLiveData];
        }
    }
    else{
        
        [self switchToLocalData];
    }
}
#pragma mark - Online/Offline methods



-(void)switchToLiveData{
    
    self.goingLive = YES;
    [self logStatus:@"loading live data"];

    //Clear out the template picker so that we create it again when needed using templates in the live data
    self.featureTemplatePickerVC = nil;


    self.gdbTask = [[AGSGDBSyncTask alloc]initWithURL:[NSURL URLWithString:kFeatureServiceURL]];
    __weak MainViewController* weakSelf = self;
    self.gdbTask.loadCompletion = ^(NSError* error){
        
        //Remove all local feature layers
        for (AGSLayer* lyr in weakSelf.mapView.mapLayers) {
            if ([lyr isKindOfClass:[AGSFeatureTableLayer class]]) {
                [weakSelf.mapView removeMapLayer:lyr];
            }
        }
        
        //Add live feature layers
        for (AGSMapServiceLayerInfo* info in weakSelf.gdbTask.featureServiceInfo.layerInfos) {
            [SVProgressHUD showProgress:-1 status:@"Loading \n live data"];
            NSURL* url = [weakSelf.gdbTask.URL URLByAppendingPathComponent:[NSString stringWithFormat:@"%lu",(unsigned long)info.layerId]];
            
            AGSGDBFeatureServiceTable* fst = [[AGSGDBFeatureServiceTable alloc]initWithServiceURL:url credential:weakSelf.gdbTask.credential spatialReference:weakSelf.mapView.spatialReference];
            AGSFeatureTableLayer* ftLayer = [[AGSFeatureTableLayer alloc]initWithFeatureTable:fst];
            ftLayer.delegate = weakSelf;
            
            
            
            [weakSelf.mapView addMapLayer:ftLayer];
            [weakSelf logStatus:[NSString stringWithFormat:@"loading: %@", [fst.serviceURL absoluteString]]];
        }
        [weakSelf logStatus:@"now in live mode"];
        [weakSelf updateStatus];
    };
    
    self.goingLive = NO;
    self.viewingLocal = NO;
    
}
-(void)switchToLocalData{
    
    self.goingLocal = YES;
    
    //Clear out the template picker so that we create it again when needed using templates in the local data
    self.featureTemplatePickerVC = nil;

    
    AGSGDBGenerateParameters *params = [[AGSGDBGenerateParameters alloc]initWithFeatureServiceInfo:self.gdbTask.featureServiceInfo];
    
    //NOTE: You should typically set this to a smaller envelope covering an area of interest
    //Setting to maxEnvelope here because sample data covers limited area in San Francisco
    params.extent = self.mapView.maxEnvelope;
    params.outSpatialReference = self.mapView.spatialReference;
    NSMutableArray* layers = [[NSMutableArray alloc]init];
    for (AGSMapServiceLayerInfo* layerInfo in self.gdbTask.featureServiceInfo.layerInfos) {
        [layers addObject:[NSNumber numberWithInt: (int)layerInfo.layerId]];
    }
    params.layerIDs = layers;
    self.newlyDownloaded = NO;
    [SVProgressHUD showWithStatus:@"Preparing to \n download"];
    [self.gdbTask generateGeodatabaseWithParameters:params downloadFolderPath:nil useExisting:YES status:^(AGSResumableTaskJobStatus status, NSDictionary *userInfo) {
        
        //If we are fetching result, display download progress
        if(status == AGSResumableTaskJobStatusFetchingResult){
            self.newlyDownloaded = YES;
            NSNumber* totalBytesDownloaded = userInfo[@"AGSDownloadProgressTotalBytesDownloaded"];
            NSNumber* totalBytesExpected = userInfo[@"AGSDownloadProgressTotalBytesExpected"];
            if(totalBytesDownloaded!=nil && totalBytesExpected!=nil){
                double dPercentage = (double)([totalBytesDownloaded doubleValue]/[totalBytesExpected doubleValue]);
                [SVProgressHUD showProgress:dPercentage status:@"Downloading \n features"];
            }
        }else{
            //don't want to log status for "fetching result" state because
            //status block gets called many times a second when downloading.
            //we only log status for other states here
            [self logStatus:[NSString stringWithFormat:@"Status: %@", [self statusMessageForAsyncStatus:status]]];
        }
    } completion:^(AGSGDBGeodatabase *geodatabase, NSError *error) {
        if (error){
            //handle the error
            self.goingLocal = NO;
            self.viewingLocal = NO;
            [self logStatus:[NSString stringWithFormat:@"error taking feature layers offline: %@", error]];
            [SVProgressHUD showErrorWithStatus:@"Couldn't download features"];
        }
        else{
            //take app into offline mode
            self.goingLocal = NO;
            self.viewingLocal = YES;
            [self logStatus:@"now viewing local data"];
            [BackgroundHelper postLocalNotificationIfAppNotActive:@"Features downloaded."];
            
            //remove the live feature layers
            for (AGSLayer* lyr in self.mapView.mapLayers) {
                if([lyr isKindOfClass:[AGSFeatureTableLayer class]])
                    [self.mapView removeMapLayer:lyr];
            }
            
            //add layers from local geodatabase
            self.geodatabase = geodatabase;
            for (AGSFeatureTable* fTable in geodatabase.featureTables) {
                if ([fTable hasGeometry]) {
                    [self.mapView addMapLayer:[[AGSFeatureTableLayer alloc]initWithFeatureTable:fTable]];
                }
            }
            
            if (self.newlyDownloaded) {
                [SVProgressHUD showSuccessWithStatus:@"Finished \n downloading"];
            }else{
                [SVProgressHUD dismiss];
                [self showEditsInGeodatabaseAsBadge:geodatabase];
                UIAlertView* av = [[UIAlertView alloc]initWithTitle:@"Found local data" message:@" It may contain edits or may be out of date. Do you want synchronize it with the service?" delegate:nil cancelButtonTitle:@"Later" otherButtonTitles:@"Yes", nil];
                [av showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
                    switch (buttonIndex) {
                        case 0: //do nothing
                            break;
                        case 1: //Yes, sync
                            [self syncAction:nil];
                            break;
                        default:
                            break;
                    }
                }];
                
            }
        }
        [self updateStatus];
        
        
    }];
    
    
}

#pragma mark - FeatureTemplatePickerViewControllerDelegate methods

- (void)featureTemplatePickerViewController:(FeatureTemplatePickerViewController *)featureTemplatePickerViewController didSelectFeatureTemplate:(AGSFeatureTemplate *)template forLayer:(id<AGSGDBFeatureSourceInfo>)layer{
    
    //if iPad
    if ([[AGSDevice currentDevice]isIPad]) {
        //Dismiss popover
        [self.pvc dismissPopoverAnimated:YES];
        self.pvc = nil;
        
        //Create new feature with temaplate
        AGSGDBFeatureTable* fTable = (AGSGDBFeatureTable*) layer;
        AGSGDBFeature* feature = [fTable featureWithTemplate:template];
        
        //Create popup for new feature, commence edit mode
        AGSPopupInfo *pi = [AGSPopupInfo popupInfoForGDBFeatureTable:fTable];
        AGSPopup *p = [[AGSPopup alloc]initWithGDBFeature:feature popupInfo:pi];
        [self showPopupsVCForPopups:@[p]];
        [self.popupsVC startEditingCurrentPopup];

    }else{
        //if iPhone, dismiss modal view controller
        [featureTemplatePickerViewController dismissViewControllerAnimated:YES completion:^{
            
            //Create new feature with temaplate
            AGSGDBFeatureTable* fTable = (AGSGDBFeatureTable*) layer;
            AGSGDBFeature* feature = [fTable featureWithTemplate:template];

            //Create popup for new feature, commence edit mode
            AGSPopupInfo *pi = [AGSPopupInfo popupInfoForGDBFeatureTable:fTable];
            AGSPopup *p = [[AGSPopup alloc]initWithGDBFeature:feature popupInfo:pi];
            [self showPopupsVCForPopups:@[p]];
            [self.popupsVC startEditingCurrentPopup];

        }];
    }
    
}

- (void) featureTemplatePickerViewControllerWasDismissed:(FeatureTemplatePickerViewController *)featureTemplatePickerViewController{
    if ([[AGSDevice currentDevice]isIPad]) {
        [self.pvc dismissPopoverAnimated:YES];
        self.pvc = nil;
    }else{
        [featureTemplatePickerViewController dismissViewControllerAnimated:YES completion:nil];
    }
}



#pragma mark AGSPopupsContainerDelegate methods

-(AGSGeometry *)popupsContainer:(id<AGSPopupsContainer>)popupsContainer wantsNewMutableGeometryForPopup:(AGSPopup *)popup{
    switch (popup.gdbFeatureSourceInfo.geometryType) {
        case AGSGeometryTypePoint:
            return [[AGSMutablePoint alloc]initWithSpatialReference:self.mapView.spatialReference];
            break;
        case AGSGeometryTypePolygon:
            return [[AGSMutablePolygon alloc]initWithSpatialReference:self.mapView.spatialReference];
            break;
        case AGSGeometryTypePolyline:
            return [[AGSMutablePolyline alloc]initWithSpatialReference:self.mapView.spatialReference];
            break;
        default:
            return [[AGSMutablePoint alloc]initWithSpatialReference:self.mapView.spatialReference];
            break;
    }
}

-(void) popupsContainer:(id<AGSPopupsContainer>)popupsContainer readyToEditGeometry:(AGSGeometry *)geometry forPopup:(AGSPopup *)popup {

    if (!self.sgl){
        self.sgl = [[AGSSketchGraphicsLayer alloc]initWithGeometry:geometry];
        [self.mapView addMapLayer:self.sgl];
        self.mapView.touchDelegate = self.sgl;
    }
    else{
        self.sgl.geometry = geometry;
    }
    
    // if we are on iPhone, hide the popupsVC and show editing UI
    if (![[AGSDevice currentDevice] isIPad]) {
        [self.popupsVC dismissViewControllerAnimated:YES completion:nil];
        [self toggleGeometryEditUI];
    }
}


-(void)popupsContainerDidFinishViewingPopups:(id<AGSPopupsContainer>)popupsContainer{
    //
    // this clears self.currentPopups
    [self hidePopupsVC];
}

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didCancelEditingForPopup:(AGSPopup *)popup {
    [self.mapView removeMapLayer:self.sgl];
    self.sgl = nil;
    self.mapView.touchDelegate = self;
    [self hidePopupsVC];
}

-(void) popupsContainer:(id<AGSPopupsContainer>)popupsContainer didFinishEditingForPopup:(AGSPopup *)popup {

    // Remove sketch layer
    [self.mapView removeMapLayer:self.sgl];
    self.sgl = nil;
    self.mapView.touchDelegate = self;

    
    // popup vc has already committed edits to the local geodatabase at this point
    
    //if we are in local data mode, show edits as badge over the sync button
    //and wait for the user to explicitly sync changes back up to the service
    if(self.viewingLocal) {
        [self showEditsInGeodatabaseAsBadge:popup.gdbFeatureTable.geodatabase];
        [self logStatus:@"feature saved in local geodatabase"];
        [self hidePopupsVC];
    }else{
        //we are in live data mode, apply edits to the service immediately
        self.loadingView = [LoadingView loadingViewInView:self.popupsVC.view withText:@"Applying edit to server..."];
        AGSGDBFeatureServiceTable* fst = (AGSGDBFeatureServiceTable*) popup.gdbFeature.table;
        [fst applyFeatureEditsWithCompletion:^(NSArray *featureEditErrors, NSError *error) {
            [self.loadingView removeView];
            if(error){
                UIAlertView* av = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Could not apply edit to server." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
                NSLog(@"Error while applying edit : %@",[error localizedDescription]);
            }else{
                for (AGSGDBFeatureEditError* featureEditError in featureEditErrors) {
                    NSLog(@"Edit to feature(OBJECTID = %lld) rejected by server because : %@",featureEditError.objectID, [featureEditError localizedDescription]);
                }
                
                
                //If the dataset support attachments, apply attachment edits.
                if([fst hasAttachments]){
                    self.loadingView = [LoadingView loadingViewInView:self.popupsVC.view withText:@"Applying attachment edits to server..."];
                    
                    [fst applyAttachmentEditsWithCompletion:^(NSArray *attachmentEditErrors, NSError *error) {
                    
                        [self.loadingView removeView];
                    
                        if(error){
                            UIAlertView* av = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Could not apply edit to server." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                            [av show];
                            NSLog(@"Error while applying attachment edit : %@",[error localizedDescription]);
                        
                        }else{
                        
                            for (AGSGDBFeatureEditError* attachmentEditError in attachmentEditErrors) {
                                NSLog(@"Edit to attachment(OBJECTID = %lld) rejected by server because : %@",attachmentEditError.attachmentID, [attachmentEditError localizedDescription]);
                            }
                        
                        //Dismiss the popups VC. All edits have been applied.
                            [self hidePopupsVC];
                        }
                    }];
                }
            }
            
        }];
    }
    
}

-(void) popupsContainer:(id<AGSPopupsContainer>)popupsContainer didDeleteForPopup:(AGSPopup *)popup {
    // popup vc has already committed edits to the local geodatabase at this point
    
    //if we are in local data mode, show edits as badge over the sync button
    //and wait for the user to explicitly sync changes back up to the service
    if(self.viewingLocal) {
        [self showEditsInGeodatabaseAsBadge:popup.gdbFeatureTable.geodatabase];
        [self logStatus:@"feature deleted in local geodatabase"];
        [self hidePopupsVC];
    }else{
        //we are in live data mode, apply edits to the service immediately
        self.loadingView = [LoadingView loadingViewInView:self.popupsVC.view withText:@"Applying edit to server..."];
        AGSGDBFeatureServiceTable* fst = (AGSGDBFeatureServiceTable*) popup.gdbFeature.table;
        [fst applyFeatureEditsWithCompletion:^(NSArray *featureEditErrors, NSError *error) {
            [self.loadingView removeView];
            if(error){
                UIAlertView* av = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Could not apply edit to server." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
                [self logStatus:[NSString stringWithFormat:@"Error while applying edit : %@",[error localizedDescription]]];
            }else{
                for (AGSGDBFeatureEditError* featureEditError in featureEditErrors) {
                    [self logStatus:[NSString stringWithFormat:@"Deleting feature(OBJECTID = %lld) rejected by server because : %@",featureEditError.objectID, [featureEditError localizedDescription]]];
                }

                [self logStatus:@"feature deleted in server"];
                
                [self hidePopupsVC];

            }
            
        }];
    }

}



#pragma mark - Convenience methods

- (NSNumber*) numberOfEditsInGeodatabase:(AGSGDBGeodatabase*)gdb{
    int total = 0;
    for (AGSGDBFeatureTable* ftable in gdb.featureTables) {
        total += ftable.addedFeaturesCount+ftable.deletedFeaturesCount+ftable.updatedFeaturesCount;
    }
    return [NSNumber numberWithInt:total] ;
}

-(void)logStatus:(NSString*)status{
    
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(logStatus:) withObject:status waitUntilDone:NO];
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearStatus) object:nil];
    
    // show basic status
    self.logsLabel.text = status;
    
    NSString *hideText = @"\nTap to hide...";
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    df.dateStyle = NSDateFormatterNoStyle;
    df.timeStyle = NSDateFormatterShortStyle;
    status = [NSString stringWithFormat:@"%@ - %@\n\n", [df stringFromDate:[NSDate date]], status];
    [self.allStatus insertString:status atIndex:0];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        self.logsTextView.text = [NSString stringWithFormat:@"%@\n\n%@", hideText, self.allStatus];
    }
    else{
        self.logsTextView.text = [NSString stringWithFormat:@"%@\n\n%@", hideText, self.allStatus];
    }
    NSLog(@"%@", status);
    
    // write to log file
    AppDelegate *app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [app logAppStatus:status];
    
    [self performSelector:@selector(clearStatus) withObject:nil afterDelay:2];
}

-(void)clearStatus{
    self.logsLabel.text = @"swipe up to show activity log   ";
}

-(void)updateStatus{
    
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(updateStatus) withObject:nil waitUntilDone:NO];
        return;
    }
    
    
    // set status
    if (self.goingLocal){
        self.offlineStatusLabel.text = @"switching to local data...";
    }
    else if (self.goingLive){
        self.offlineStatusLabel.text = @"switching to live data...";
    }
    else if (self.viewingLocal){
        self.offlineStatusLabel.text = @"Local data";
        self.goOfflineButton.title = @"switch to live";
    }
    else if (!self.viewingLocal){
        self.offlineStatusLabel.text = @"Live data";
        self.goOfflineButton.title = @"download";
        [self showEditsInGeodatabaseAsBadge:nil];
    }
    
    self.goOfflineButton.enabled = !self.goingLocal && !self.goingLive;
    self.syncButton.enabled = self.viewingLocal;


}

-(NSString*)statusMessageForAsyncStatus:(AGSResumableTaskJobStatus)status
{
    return AGSResumableTaskJobStatusAsString(status);
}

- (void) showEditsInGeodatabaseAsBadge:(AGSGDBGeodatabase*)geodatabase{
    [self.badge removeFromSuperview];
    if ([geodatabase hasLocalEdits]) {
        self.badge = [[JSBadgeView alloc]initWithParentView:self.badgeView alignment:JSBadgeViewAlignmentCenterRight];
        self.badge.badgeText = [[self numberOfEditsInGeodatabase:geodatabase] stringValue];
        
    }
}



#pragma mark Sketch toolbar UI

- (void)toggleGeometryEditUI {
    self.geometryEditToolbar.hidden = !self.geometryEditToolbar.hidden;
}

- (IBAction)cancelEditingGeometry:(id)sender {
    [self doneEditingGeometry:nil];
}

- (IBAction)doneEditingGeometry:(id)sender {
    [self.mapView removeMapLayer:self.sgl];
    self.sgl = nil;
    self.mapView.touchDelegate = self;
    [self toggleGeometryEditUI];
    [self presentViewController:self.popupsVC animated:YES completion:nil];
}

#pragma mark -


@end







