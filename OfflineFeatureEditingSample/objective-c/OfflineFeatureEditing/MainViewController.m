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
#import "AppDelegate.h"

#define kTilePackageName @"SanFrancisco"
#define kFeatureServiceURL @"https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer"

@interface MainViewController () <AGSGeoViewTouchDelegate, AGSPopupsViewControllerDelegate, AGSCalloutDelegate, FeatureTemplatePickerDelegate>

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIView *badgeView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *liveActivityIndicator;
@property (weak, nonatomic) IBOutlet UIToolbar *geometryEditToolbar;

@property (nonatomic, strong) AGSGeodatabase *geodatabase;
@property (nonatomic, strong) AGSGeodatabaseSyncTask *gdbTask;
@property (nonatomic, strong) AGSMapView* mapView;
@property (nonatomic, strong) AGSGenerateGeodatabaseJob *generateGDBJob;
@property (nonatomic, strong) AGSSyncGeodatabaseJob *syncJob;
@property (nonatomic, strong) AGSMap* map;

@property (nonatomic, strong) AGSArcGISTiledLayer *localTiledLayer;

@property (nonatomic, strong) NSString *replicaJobId;
@property (nonatomic, strong) AGSPopupsViewController *popupsVC;
@property (nonatomic, strong) AGSSketchEditor *sketchEditor;

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
    //Set up layerViewStateChangedHandler, the replacement for AGSLayerDelegate, using
    //the original layerDidLoad and didFailtoLoad methods.
    __weak __typeof(self) weakSelf = self;
    self.mapView.layerViewStateChangedHandler = ^(AGSLayer *layer, AGSLayerViewState *layerViewState){
        if (layerViewState.status == AGSLayerViewStatusActive) {
            [weakSelf layerDidLoad:layer];
        }
        else if (layerViewState.status == AGSLayerViewStatusError) {
            [weakSelf layer:layer didFailToLoadWithError:layerViewState.error];
        }
    };
    self.mapView.callout.delegate = self;

    //Add the basemap layer from a tile package
    AGSTileCache *tileCache = [AGSTileCache tileCacheWithName:kTilePackageName];
    self.localTiledLayer = [AGSArcGISTiledLayer ArcGISTiledLayerWithTileCache:tileCache];
    AGSBasemap *basemap = [AGSBasemap basemapWithBaseLayer:self.localTiledLayer];
    
    //create the map with the basemap and set it on the map view
    self.map = [AGSMap mapWithBasemap:basemap];
    self.mapView.map = self.map;

    
    //load the map, calling loadWithCompletion; the completion handler replaces, in part,
    //the AGSMapViewDelegate.  Call the original mapViewDidLoad methods when the map loads.
    [self.map loadWithCompletion:^(NSError * _Nullable error) {
        [weakSelf mapViewDidLoad:self.mapView];
    }];
    
    self.gdbTask = [[AGSGeodatabaseSyncTask alloc]initWithURL:[NSURL URLWithString:kFeatureServiceURL]];

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

//This is now called from the map's load completion block.
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

//These methods are now called from the layerViewStateChangedHandler.
-(void)layerDidLoad:(AGSLayer *)layer{
    if(self.mapView.mapScale > layer.minScale && layer.minScale > 0) {
        AGSViewpoint *currentVP = [self.mapView currentViewpointWithType:AGSViewpointTypeCenterAndScale];
        AGSViewpoint *vp = [AGSViewpoint viewpointWithCenter:(AGSPoint *)currentVP.targetGeometry scale:layer.minScale];
        [self.mapView setViewpoint:vp];
    }
    [SVProgressHUD popActivity];
}


-(void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error{
    NSString *errmsg;
    
    if([layer isKindOfClass:[AGSFeatureLayer class]]){
        AGSFeatureLayer* ftLayer = (AGSFeatureLayer*)layer;
        errmsg = [NSString stringWithFormat:@"Failed to load %@. Error:%@",ftLayer.name, error];
        
        // activity shown when loading online layer, dismiss this
        [SVProgressHUD popActivity];
    }
    else if([layer isKindOfClass:[AGSArcGISTiledLayer class]]){
        errmsg = [NSString stringWithFormat:@"Failed to load local tiled layer. Error:%@", error];
    }
    
    [self logStatus:errmsg];
}


#pragma mark - AGSMapViewTouchDelegate methods
-(void)geoView:(AGSGeoView *)geoView didTapAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {
    
    //Show popups for features that were tapped on
    __weak __typeof(self) weakSelf = self;
    [self.mapView identifyLayersAtScreenPoint:screenPoint tolerance:10 returnPopupsOnly:NO completion:^(NSArray<AGSIdentifyLayerResult *> * _Nullable identifyResults, NSError * _Nullable error) {
        NSMutableArray *features = [NSMutableArray array];
        for (AGSIdentifyLayerResult *result in identifyResults) {
            [features addObjectsFromArray:result.geoElements];
        }
        if (features.count > 0) {
            [weakSelf showPopupsForFeatures:features];
        }
        else {
            [weakSelf hidePopupsVC];
        }
    }];
}

#pragma mark - Showing popups
-(void)showPopupsForFeatures:(NSArray*)features{
    NSMutableArray *popups = [NSMutableArray arrayWithCapacity:features.count];

    for (id<AGSGeoElement> geoElement in features) {
        AGSPopup* popup = [AGSPopup popupWithGeoElement:geoElement];
        [popups addObject:popup];
    }
    
    [self showPopupsVCForPopups:popups];
}

-(void)hidePopupsVC{
    if ([self isIPad]) {
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
    self.popupsVC = [[AGSPopupsViewController alloc]initWithPopups:popups containerStyle:AGSPopupsViewControllerContainerStyleNavigationBar];
    self.popupsVC.delegate = self;
    self.popupsVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //On ipad, display the popups vc a form sheet on the left
    if ([self isIPad]) {
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
    if ([self isIPad]) {
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
    
    if (self.syncJob.status == AGSJobStatusStarted){
        // if already syncing just return
        return;
    }
    
    if (!self.geodatabase.hasLocalEdits) {
        //we have no local edits, show status and return
        [SVProgressHUD showErrorWithStatus:@"No local edits"];
        return;
    }
    
    [SVProgressHUD showWithStatus:@"Synchronizing \n changes"];
    [self logStatus:@"Starting sync process..."];
    
    NSMutableArray *syncLayerOptions = [NSMutableArray array];
    for (AGSIDInfo *layerInfo in self.gdbTask.featureServiceInfo.layerInfos) {
        [syncLayerOptions addObject:[AGSSyncLayerOption syncLayerOptionWithLayerID:layerInfo.ID
                                                                     syncDirection:AGSSyncDirectionBidirectional]];
    }
    
    //Create default sync params based on the geodatabase
    //You can modify the param to change sync options (sync direction, included layers, etc)
    AGSSyncGeodatabaseParameters* param = [AGSSyncGeodatabaseParameters syncGeodatabaseParameters];
    param.layerOptions = syncLayerOptions;
    
    __weak __typeof(self) weakSelf = self;
    self.syncJob = [self.gdbTask syncJobWithParameters:param geodatabase:self.geodatabase];

    //set current job so BackgroundHelper can function
    ((AppDelegate *)[UIApplication sharedApplication].delegate).currentJob = self.syncJob;
    [self.syncJob startWithStatusHandler:^(AGSJobStatus status) {
        [weakSelf logStatus:[NSString stringWithFormat:@"sync status: %@", [weakSelf jobStatusAsString:status]]];
    } completion:^(NSArray<AGSSyncLayerResult *> *result, NSError *error) {
        //clear current job
        ((AppDelegate *)[UIApplication sharedApplication].delegate).currentJob = nil;

        if (error){
            [self logStatus:[NSString stringWithFormat:@"error sync'ing: %@", error.localizedDescription]];
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

    __weak __typeof(self) weakSelf = self;
    [self.gdbTask loadWithCompletion:^(NSError *error) {
        self.goingLive = NO;
        self.viewingLocal = NO;

        if (error) {
            [weakSelf logStatus:[NSString stringWithFormat:@"error loading geodatabase sync task: %@", error]];
            [SVProgressHUD showErrorWithStatus:@"Couldn't load geodatabase sync task"];
        }
        else {
            //Remove all local layers from map
            [self.map.operationalLayers removeAllObjects];
            
            //Add live feature layers
            for (AGSIDInfo* info in weakSelf.gdbTask.featureServiceInfo.layerInfos) {
                [SVProgressHUD showProgress:-1 status:@"Loading \n live data"];
                NSURL* url = [weakSelf.gdbTask.URL URLByAppendingPathComponent:[NSString stringWithFormat:@"%lu",(unsigned long)info.ID]];
                
                AGSServiceFeatureTable *ft = [[AGSServiceFeatureTable alloc] initWithURL:url];
                ft.credential = weakSelf.gdbTask.credential;
                
                AGSFeatureLayer *fl = [AGSFeatureLayer featureLayerWithFeatureTable:ft];
                fl.name = info.name;
                [weakSelf.map.operationalLayers addObject:fl];
                [weakSelf logStatus:[NSString stringWithFormat:@"loading: %@", [ft.URL absoluteString]]];
            }
            [weakSelf logStatus:@"now in live mode"];
            [weakSelf updateStatus];
        }
        
    }];
    
}
-(void)switchToLocalData{
    
    self.goingLocal = YES;
    
    //Clear out the template picker so that we create it again when needed using templates in the local data
    self.featureTemplatePickerVC = nil;

    AGSGenerateGeodatabaseParameters *params = [AGSGenerateGeodatabaseParameters generateGeodatabaseParameters];
    
    //NOTE: You should typically set this to a smaller envelope covering an area of interest
    //Setting to visible area extent here because sample data covers limited area in San Francisco
    params.extent = self.mapView.visibleArea.extent;
    params.outSpatialReference = self.mapView.spatialReference;
    NSMutableArray *layerOptions = [NSMutableArray array];
    for (AGSIDInfo *layerInfo in self.gdbTask.featureServiceInfo.layerInfos) {
        [layerOptions addObject:[AGSGenerateLayerOption generateLayerOptionWithLayerID:layerInfo.ID]];
    }
    params.layerOptions = layerOptions;
    params.returnAttachments = YES;
    
    self.newlyDownloaded = NO;
    [SVProgressHUD showWithStatus:@"Preparing to \n download"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filename = [NSString stringWithFormat:@"%@.geodatabase", [NSDate date]];
    NSURL *fileURL = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:filename] isDirectory:NO];
    self.generateGDBJob = [self.gdbTask generateJobWithParameters:params downloadFileURL:fileURL];
    
    //start generating the geodatabase
    __weak __typeof(self) weakSelf = self;
    //set current job so BackgroundHelper can function
    ((AppDelegate *)[UIApplication sharedApplication].delegate).currentJob = self.generateGDBJob;
    [self.generateGDBJob startWithStatusHandler:^(AGSJobStatus status) {
        //If we are fetching result, display download progress
        if(status == AGSJobStatusStarted){
            self.newlyDownloaded = YES;
        }
        else{
            //don't want to log status for "AGSJobStatusStarted" state because
            //status block gets called many times a second when downloading.
            //we only log status for other states here
            [self logStatus:[NSString stringWithFormat:@"Status: %@", [weakSelf jobStatusAsString:status]]];
        }
        [SVProgressHUD showWithStatus:[weakSelf jobStatusAsString:status]];
    } completion:^(AGSGeodatabase *result, NSError * error) {
        //clear current job
        ((AppDelegate *)[UIApplication sharedApplication].delegate).currentJob = nil;

        if (error){
            //handle the error
            weakSelf.goingLocal = NO;
            weakSelf.viewingLocal = NO;
            [weakSelf logStatus:[NSString stringWithFormat:@"error taking feature layers offline: %@", error]];
            [SVProgressHUD showErrorWithStatus:@"Couldn't download features"];
        }
        else{
            //take app into offline mode
            weakSelf.goingLocal = NO;
            weakSelf.viewingLocal = YES;
            [weakSelf logStatus:@"now viewing local data"];
            [BackgroundHelper postLocalNotificationIfAppNotActive:@"Features downloaded."];
            
            //remove the live feature layers
            [weakSelf.map.operationalLayers removeAllObjects];
            
            //add layers from local geodatabase
            weakSelf.geodatabase = result;
            [weakSelf.geodatabase loadWithCompletion:^(NSError * _Nullable error) {
                AGSLoadObjects(weakSelf.geodatabase.geodatabaseFeatureTables, ^(BOOL finishedWithNoErrors) {
                    for (AGSFeatureTable* fTable in weakSelf.geodatabase.geodatabaseFeatureTables) {
                        if (fTable.hasGeometry) {
                            [weakSelf.map.operationalLayers addObject:[AGSFeatureLayer featureLayerWithFeatureTable:fTable]];
                        }
                    }
                    
                    if (weakSelf.newlyDownloaded) {
                        [SVProgressHUD showSuccessWithStatus:@"Finished \n downloading"];
                    }else{
                        [SVProgressHUD dismiss];
                        [weakSelf showEditsInGeodatabaseAsBadge:weakSelf.geodatabase];
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
                });
            }];
        }
        [weakSelf updateStatus];
        
        
    }];
    
    
}

#pragma mark - FeatureTemplatePickerViewControllerDelegate methods

- (void)featureTemplatePickerViewController:(FeatureTemplatePickerViewController *)featureTemplatePickerViewController didSelectFeatureTemplate:(AGSFeatureTemplate *)template forTable:(AGSArcGISFeatureTable *)table{
    
    //if iPad
    if ([self isIPad]) {
        //Dismiss popover
        [self.pvc dismissPopoverAnimated:YES];
        self.pvc = nil;
        
        //Create new feature with temaplate
        AGSFeature* feature = [table createFeatureWithTemplate:template];
        
        //Create popup for new feature, commence edit mode
        AGSPopup *p = [[AGSPopup alloc] initWithGeoElement:feature];
        [self showPopupsVCForPopups:@[p]];
        [self.popupsVC startEditingCurrentPopup];

    }else{
        //if iPhone, dismiss modal view controller
        [featureTemplatePickerViewController dismissViewControllerAnimated:YES completion:^{
            
            //Create new feature with temaplate
            AGSFeature* feature = [table createFeatureWithTemplate:template];

            //Create popup for new feature, commence edit mode
            AGSPopup *p = [[AGSPopup alloc] initWithGeoElement:feature];
            [self showPopupsVCForPopups:@[p]];
            [self.popupsVC startEditingCurrentPopup];

        }];
    }
    
}

- (void) featureTemplatePickerViewControllerWasDismissed:(FeatureTemplatePickerViewController *)featureTemplatePickerViewController{
    if ([self isIPad]) {
        [self.pvc dismissPopoverAnimated:YES];
        self.pvc = nil;
    }else{
        [featureTemplatePickerViewController dismissViewControllerAnimated:YES completion:nil];
    }
}



#pragma mark AGSPopupsViewControllerDelegate methods

-(AGSSketchEditor *)popupsViewController:(AGSPopupsViewController *)popupsViewController sketchEditorForPopup:(AGSPopup *)popup {
    if (!self.sketchEditor) {
        self.sketchEditor = [AGSSketchEditor sketchEditor];
    }
    
    if (popup.geoElement.geometry) {
        [self.sketchEditor startWithGeometry:popup.geoElement.geometry];
        [self.mapView setViewpointGeometry:popup.geoElement.geometry.extent completion:nil];
    }
    else if ([popup.geoElement isKindOfClass:[AGSFeature class]] &&
             [((AGSFeature *)popup.geoElement).featureTable isKindOfClass:[AGSArcGISFeatureTable class]]) {
        AGSArcGISFeatureTable *fTable = (AGSArcGISFeatureTable *)((AGSFeature *)popup.geoElement).featureTable;
        [self.sketchEditor startWithGeometryType:fTable.geometryType];
    }
    else {
        [self.sketchEditor startWithGeometryType:AGSGeometryTypePolygon];
    }

    self.mapView.sketchEditor = self.sketchEditor;
    
    return self.sketchEditor;
}

-(void)popupsViewController:(AGSPopupsViewController *)popupsViewController readyToEditGeometryWithSketchEditor:(AGSSketchEditor *)sketchEditor forPopup:(AGSPopup *)popup {
    
    // if we are on iPhone, hide the popupsVC and show editing UI
    if (![self isIPad]) {
        [self.popupsVC dismissViewControllerAnimated:YES completion:nil];
        self.mapView.sketchEditor = self.sketchEditor;
        [self toggleGeometryEditUI];
    }
}

-(void)popupsViewControllerDidFinishViewingPopups:(AGSPopupsViewController *)popupsViewController {
    //
    // this clears self.currentPopups
    [self hidePopupsVC];
}

-(void)popupsViewController:(AGSPopupsViewController *)popupsViewController didCancelEditingForPopup:(AGSPopup *)popup {
    [self disableSketchEditor];
    [self hidePopupsVC];
}

-(void)popupsViewController:(AGSPopupsViewController *)popupsViewController didFinishEditingForPopup:(AGSPopup *)popup {
    
    // Disable sketch layer
    [self disableSketchEditor];
    
    // popup vc has already committed edits to the local geodatabase at this point
    
    //if we are in local data mode, show edits as badge over the sync button
    //and wait for the user to explicitly sync changes back up to the service
    if(self.viewingLocal) {
        [self showEditsInGeodatabaseAsBadge:self.geodatabase];
        [self logStatus:@"feature saved in local geodatabase"];
        [self hidePopupsVC];
    }else{
        //we are in live data mode, apply edits to the service immediately; this will also apply attachment edits
        self.loadingView = [LoadingView loadingViewInView:self.popupsVC.view withText:@"Applying edit to server..."];
        AGSFeature *feature = (AGSFeature *)popup.geoElement;
        AGSServiceFeatureTable *fst = (AGSServiceFeatureTable *)feature.featureTable;
        [fst applyEditsWithCompletion:^(NSArray<AGSFeatureEditResult *> * result, NSError *error) {
            [self.loadingView removeView];
            if(error){
                UIAlertView* av = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Could not apply edit to server." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
                NSLog(@"Error while applying edit : %@",[error localizedDescription]);
            }else{
                for (AGSFeatureEditResult* featureEditResult in result) {
                    if (featureEditResult.completedWithErrors) {
                        NSLog(@"Edit to feature(objectID = %lld) rejected by server because : %@",featureEditResult.objectID, [featureEditResult.error localizedDescription]);
                        for (AGSEditResult *editResult in featureEditResult.attachmentResults) {
                            NSLog(@"Edit to attachment(OBJECTID = %lld) rejected by server because : %@",editResult.objectID, [editResult.error localizedDescription]);
                        }
                    }
                    //attachments are handled in `applyEditsWithCompetion`, so no need to handle them separately.
                }
                
                //Dismiss the popups VC. All edits have been applied.
                [self hidePopupsVC];
            }
            
        }];
    }
    
}

-(void)popupsViewController:(AGSPopupsViewController *)popupsViewController didDeleteForPopup:(AGSPopup *)popup {
    // popup vc has already committed edits to the local geodatabase at this point
    
    //if we are in local data mode, show edits as badge over the sync button
    //and wait for the user to explicitly sync changes back up to the service
    if(self.viewingLocal) {
        [self showEditsInGeodatabaseAsBadge:self.geodatabase];
        [self logStatus:@"feature deleted in local geodatabase"];
        [self hidePopupsVC];
    }else{
        //we are in live data mode, apply edits to the service immediately
        self.loadingView = [LoadingView loadingViewInView:self.popupsVC.view withText:@"Applying edit to server..."];
        AGSFeature *feature = (AGSFeature *)popup.geoElement;
        AGSServiceFeatureTable *fst = (AGSServiceFeatureTable *)feature.featureTable;
        [fst applyEditsWithCompletion:^(NSArray<AGSFeatureEditResult *> * result, NSError *error) {
            [self.loadingView removeView];
            if(error){
                UIAlertView* av = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Could not apply edit to server." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
                [self logStatus:[NSString stringWithFormat:@"Error while applying edit : %@",[error localizedDescription]]];
            }else{
                for (AGSFeatureEditResult* featureEditResult in result) {
                    if (featureEditResult.completedWithErrors) {
                        [self logStatus:[NSString stringWithFormat:@"Deleting feature(OBJECTID = %lld) rejected by server because : %@",featureEditResult.objectID, [featureEditResult.error localizedDescription]]];
                    }
                }

                [self logStatus:@"feature deleted in server"];
                
                [self hidePopupsVC];

            }
            
        }];
    }

}



#pragma mark - Convenience methods

- (void)numberOfEditsInGeodatabase:(AGSGeodatabase*)gdb completion:(void (^)(NSNumber *count))completion {
    __block NSInteger total = 0;
    
    dispatch_group_t group = dispatch_group_create();
    
    for (AGSArcGISFeatureTable* ftable in gdb.geodatabaseFeatureTables) {
        if (ftable.loadStatus == AGSLoadStatusLoaded) {
            dispatch_group_enter(group);
            [ftable addedFeaturesCountWithCompletion:^(NSInteger count, NSError *error) {
                total += count;
                dispatch_group_leave(group);
            }];
            
            dispatch_group_enter(group);
            [ftable updatedFeaturesCountWithCompletion:^(NSInteger count, NSError *error) {
                total += count;
                dispatch_group_leave(group);
            }];
            
            dispatch_group_enter(group);
            [ftable deletedFeaturesCountWithCompletion:^(NSInteger count, NSError *error) {
                total += count;
                dispatch_group_leave(group);
            }];
        }
    }

    if (completion){
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            completion([NSNumber numberWithInteger:total]);
        });
    }
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

-(NSString*)jobStatusAsString:(AGSJobStatus)status {
    NSString *jobStatusString;
    if (status == AGSJobStatusNotStarted) {
        jobStatusString = @"Not Started...";
    }
    else if (status == AGSJobStatusStarted) {
        jobStatusString = @"Started...";
    }
    else if (status == AGSJobStatusPaused) {
        jobStatusString = @"Paused...";
    }
    else if (status == AGSJobStatusSucceeded) {
        jobStatusString = @"Succeeded...";
    }
    else if (status == AGSJobStatusFailed) {
        jobStatusString = @"Failed...";
    }
    
    return jobStatusString;
}

- (void) showEditsInGeodatabaseAsBadge:(AGSGeodatabase*)geodatabase{
    [self.badge removeFromSuperview];
    [self numberOfEditsInGeodatabase:geodatabase completion:^(NSNumber *count) {
        NSLog(@"number of edits = %@", count);
    }];

    if ([geodatabase hasLocalEdits]) {
        self.badge = [[JSBadgeView alloc]initWithParentView:self.badgeView alignment:JSBadgeViewAlignmentCenterRight];
        
        __weak __typeof(self) weakSelf = self;
        [self numberOfEditsInGeodatabase:geodatabase completion:^(NSNumber *count) {
            weakSelf.badge.badgeText = [count stringValue];
        }];
    }
}

-(BOOL)isIPad {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}

-(void)disableSketchEditor {
    self.mapView.sketchEditor = nil;
}

#pragma mark Sketch toolbar UI

- (void)toggleGeometryEditUI {
    self.geometryEditToolbar.hidden = !self.geometryEditToolbar.hidden;
}

- (IBAction)cancelEditingGeometry:(id)sender {
    [self doneEditingGeometry:nil];
    [self.sketchEditor clearGeometry];
}

- (IBAction)doneEditingGeometry:(id)sender {
    [self disableSketchEditor];
    [self toggleGeometryEditUI];
    [self presentViewController:self.popupsVC animated:YES completion:nil];
}

#pragma mark -


@end







