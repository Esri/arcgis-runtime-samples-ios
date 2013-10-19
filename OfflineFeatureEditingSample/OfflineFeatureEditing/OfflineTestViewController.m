/*
 COPYRIGHT 2013 ESRI
 
 TRADE SECRETS: ESRI PROPRIETARY AND CONFIDENTIAL
 Unpublished material - all rights reserved under the
 Copyright Laws of the United States and applicable international
 laws, treaties, and conventions.
 
 For additional information, contact:
 Environmental Systems Research Institute, Inc.
 Attn: Contracts and Legal Services Department
 380 New York Street
 Redlands, California, 92373
 USA
 
 email: contracts@esri.com
 */

#import "OfflineTestViewController.h"
#import "AppDelegate.h"
#import "FeatureTemplatePickerViewController.h"
#import "SVProgressHUD.h"
#import "JSBadgeView.h"



@interface OfflineTestViewController () <AGSLayerDelegate, AGSMapViewTouchDelegate, AGSPopupsContainerDelegate, AGSMapViewLayerDelegate, AGSCalloutDelegate, AGSFeatureLayerEditingDelegate, FeatureTemplatePickerDelegate>{
    
    
    AGSGDBTask *_gdbTask;
    AGSTileCacheTask *_tpkTask;
    AGSLocalTiledLayer *_localTiledLayer;

    NSString *_replicaJobId;
    AGSPopupsContainerViewController *_popupsVC;
    AGSSketchGraphicsLayer *_sgl;
    AGSGDBFeature *_addFeature;
    AGSEnvelope *_lastExtent;
    
    JSBadgeView* _badge;
    int _syncButtonIndex;
    
    BOOL _goingOffline;
    BOOL _goingOnline;
    BOOL _offline;
    
    
    NSArray *_connectionMgrs;
    
    UITextView *_statusTextView;
    
    NSURL *_flURL;
    NSURL *_tpkURL;
    
    NSMutableString *_allStatus;
    
    UIPopoverController* _pvc;
    FeatureTemplatePickerViewController* _vc;
}
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIView *badgeView;

@property (nonatomic, strong) AGSGDBGeodatabase *geodatabase;
@property (nonatomic, strong) AGSGDBTask *gdbTask;
@property (nonatomic, strong) id<AGSCancellable> cancellable;
@property (nonatomic, strong) AGSMapView* mapView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *liveActivityIndicator;

//
// iPhone geometry editing ui
@property (strong, nonatomic) IBOutlet UIToolbar *geometryEditToolbar;
- (IBAction)cancelEditingGeometry:(id)sender;
- (IBAction)doneEditingGeometry:(id)sender;
@end

@implementation OfflineTestViewController

- (id)initWithFSURL:(NSURL*)url TPKURL:(NSURL*)tpkurl {
    self = [super initWithNibName:@"OfflineTestViewController" bundle:nil];
    if (self) {
        _flURL = [NSURL URLWithString:@"http://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/Wildfire/FeatureServer/0"];
        
        _tpkURL = [NSURL URLWithString:@"http://sds2-appgrp.esri.com:6080/arcgis/rest/services/RedlandsBasemap2/MapServer"];
        
    }
    return self;
}

- (void)viewDidLoad{
    
    [super viewDidLoad];
    self.mapView = [[AGSMapView alloc]initWithFrame:self.mapContainer.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.mapContainer addSubview:self.mapView];
    
    
    self.mapView.touchDelegate = self;
    self.mapView.layerDelegate = self;
    self.mapView.callout.delegate = self;

        _localTiledLayer =  [AGSLocalTiledLayer localTiledLayerWithName:@"SanFrancisco"];
    [self.mapView addMapLayer:_localTiledLayer];
    self.gdbTask = [[AGSGDBTask alloc]initWithURL:[NSURL URLWithString:@"http://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/Wildfire/FeatureServer"]];
    self.gdbTask.timeoutInterval = 300;
    __weak OfflineTestViewController* weakSelf = self;
    __weak AGSGDBTask* weakTask = self.gdbTask;
    self.gdbTask.loadCompletion = ^(NSError* error){
        for (AGSMapServiceLayerInfo* info in weakTask.featureServiceInfo.layerInfos) {
            
            NSURL* url = [weakTask.URL URLByAppendingPathComponent:[NSString stringWithFormat:@"%d",info.layerId]];
             
            AGSFeatureLayer* fl = [AGSFeatureLayer featureServiceLayerWithURL:url mode:AGSFeatureLayerModeOnDemand];
            fl.delegate = weakSelf;
            fl.editingDelegate = weakSelf;
            fl.expirationInterval = 60;
            fl.autoRefreshOnExpiration = YES;
            [weakSelf.mapView addMapLayer:fl];
            [SVProgressHUD showProgress:-1 status:@"Loading layers"];

        }
    };

    _allStatus = [NSMutableString string];
    
    self.offlineStatusLabel.text = @"Live data" ;//@"online";
    self.statusLabel.text = @"";
    
    CGRect f = self.mapView.frame;
    _statusTextView = [[UITextView alloc]initWithFrame:f];
    _statusTextView.hidden = YES;
    _statusTextView.userInteractionEnabled = YES;
    _statusTextView.autoresizingMask = _mapView.autoresizingMask;
    _statusTextView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:.78];
    _statusTextView.textColor = [UIColor whiteColor];
    _statusTextView.editable = NO;
    
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(statusTextViewGesture:)];
    [_statusTextView addGestureRecognizer:gr];
    [self.view addSubview:_statusTextView];
    
    UISwipeGestureRecognizer *gr2 = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(statusLabelGesture:)];
    gr2.direction = UISwipeGestureRecognizerDirectionUp;
    [_statusLabel addGestureRecognizer:gr2];
    _statusLabel.userInteractionEnabled = YES;
    
    //[self goOnline];
    [self clearStatus];
    
    self.syncButton.enabled = NO;
    
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(featuresLoaded:) name:AGSFeatureLayerDidLoadFeaturesNotification object:nil];

}

- (void)viewDidUnload{
    [self setMapContainer:nil];
    [self setStatusLabel:nil];
    [self setLeftContainer:nil];
    [self setAddFeatureButton:nil];
    [self setSyncButton:nil];
    [self setGoOfflineButton:nil];
    [self setGoOfflineButton:nil];
    [self setOfflineStatusLabel:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
//    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)connectionStatusChanged:(NSNotification*)note{
    [self updateOfflineStatus];
}

#pragma mark gesture recs

-(void)statusTextViewGesture:(UIGestureRecognizer*)gr{
    _statusTextView.hidden = YES;
}

-(void)statusLabelGesture:(UIGestureRecognizer*)gr{
    _statusTextView.hidden = NO;
}

#pragma mark layer delegate

-(void)layerDidLoad:(AGSLayer *)layer{
    if([layer isKindOfClass:[AGSFeatureLayer class]]){
        AGSFeatureLayer* fl = (AGSFeatureLayer*)layer;
        [self logStatus:[NSString stringWithFormat:@"Loaded %@",fl.URL]];
        [SVProgressHUD popActivity];
        [self.mapView zoomToScale:fl.minScale animated:YES];
    }
}

- (void) featuresLoaded:(NSNotification*) notification{
    [self.liveActivityIndicator startAnimating];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self logStatus:@"Refreshed live data"];
        [self.liveActivityIndicator stopAnimating];
    });
}

-(void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error{
    if([layer isKindOfClass:[AGSFeatureLayer class]]){
        AGSFeatureLayer* fl = (AGSFeatureLayer*)layer;
        [self logStatus:[NSString stringWithFormat:@"Failed to load %@. Error:%@",fl.URL, error]];
        [SVProgressHUD popActivity];
        
    }
}


#pragma mark - AGSMapViewTouchDelegate methods
- (void) mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features {
    NSMutableArray *allFeatures = [[NSMutableArray alloc]init];
    
    
    NSEnumerator* keys = [features keyEnumerator];
    for (NSString* key in keys) {
        [allFeatures addObjectsFromArray:[features objectForKey:key]];
    }
        if (allFeatures.count){
            [self showPopupsForFeatures:allFeatures];
        }
        else{
            [self hidePopupsVC];
        }
    
}

-(void)showPopupsForFeatures:(NSArray*)features{
    NSMutableArray *popups = [NSMutableArray arrayWithCapacity:features.count];

    for (id<AGSFeature> feature in features) {
        AGSPopup* popup;
        if([feature isKindOfClass:[AGSGraphic class]]){
            AGSGraphic* graphic = (AGSGraphic*)feature;
            AGSPopupInfo* popupInfo = [AGSPopupInfo popupInfoForFeatureLayer:(AGSFeatureLayer*)graphic.layer];
            popup = [AGSPopup popupWithGraphic:graphic popupInfo:popupInfo];
            
        }else if ([feature isKindOfClass:[AGSGDBFeature class]]){
            AGSGDBFeature* gdbFeature = (AGSGDBFeature*)feature;
            AGSPopupInfo* popupInfo = [AGSPopupInfo popupInfoForGDBFeatureTable:gdbFeature.table];
            popup = [AGSPopup popupWithGDBFeature:gdbFeature popupInfo:popupInfo];
        }
        [popups addObject:popup];
    }
    
        [self showPopupsVCForPopups:popups];
}

-(void)hidePopupsVC{
    if ([[AGSDevice currentDevice] isIPad]) {
        for (UIView *sv in _leftContainer.subviews){
            [sv removeFromSuperview];
        }
        _popupsVC = nil;
        _leftContainer.hidden = YES;
    }
    else {
        [_popupsVC dismissViewControllerAnimated:YES completion:^{
            _popupsVC = nil;
        }];
    }
    
}


-(void)showPopupsVCForPopups:(NSArray*)popups{
    
    [self hidePopupsVC];
    
    if (!_popupsVC) {
        _popupsVC = [[AGSPopupsContainerViewController alloc]initWithPopups:popups usingNavigationControllerStack:NO];
        _popupsVC.delegate = self;
        _popupsVC.style = AGSPopupsContainerStyleBlack;
        _popupsVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;        
    }
    
    if ([[AGSDevice currentDevice] isIPad]) {
        _leftContainer.hidden = NO;
        _popupsVC.modalPresentationStyle = UIModalPresentationFormSheet;
        _popupsVC.view.frame = _leftContainer.bounds;
        [_leftContainer addSubview:_popupsVC.view];
    }
    else {
        _popupsVC.modalPresentationStyle = UIModalPresentationFullScreen;
        _popupsVC.view.frame = self.view.bounds;
        [self presentViewController:_popupsVC animated:YES completion:nil];

    }
}

#pragma mark add feature action

- (IBAction)addFeatureAction:(id)sender {
    
    _vc = [[FeatureTemplatePickerViewController alloc]init];
    _vc.delegate = self;
    [_vc addTemplatesForLayersInMap:self.mapView];
    if ([[AGSDevice currentDevice]isIPad]) {
        _pvc = [[UIPopoverController alloc]initWithContentViewController:_vc];
        [_pvc presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        
    }else{
        [self presentViewController:_vc animated:YES completion:^{
            
        }];
    }
    

}

- (void)featureTemplatePickerViewController:(FeatureTemplatePickerViewController *)featureTemplatePickerViewController didSelectFeatureTemplate:(AGSFeatureTemplate *)template forLayer:(id<AGSGDBFeatureSourceInfo>)layer{
    if ([[AGSDevice currentDevice]isIPad]) {
        [_pvc
         dismissPopoverAnimated:YES];
        if([layer isKindOfClass:[AGSFeatureLayer class]]){
            AGSFeatureLayer* fLayer = (AGSFeatureLayer*)layer;
            AGSGraphic* graphic = [fLayer featureWithTemplate:template];
            [fLayer addGraphic:graphic];
            AGSPopupInfo *pi = [AGSPopupInfo popupInfoForFeatureLayer:fLayer];
            AGSPopup *p = [[AGSPopup alloc]initWithGraphic:graphic popupInfo:pi featureLayer:fLayer];
            [self showPopupsVCForPopups:@[p]];
            [_popupsVC startEditingCurrentPopup];
        }else if([layer isKindOfClass:[AGSGDBFeatureTable class]]){
            AGSGDBFeatureTable* fTable = (AGSGDBFeatureTable*) layer;
            AGSGDBFeature* feature = [fTable featureWithTemplate:template];
            _addFeature = feature;
            AGSPopupInfo *pi = [AGSPopupInfo popupInfoForGDBFeatureTable:fTable];
            AGSPopup *p = [[AGSPopup alloc]initWithGDBFeature:feature popupInfo:pi];
            [self showPopupsVCForPopups:@[p]];
            [_popupsVC startEditingCurrentPopup];
        }

    }else{
        [featureTemplatePickerViewController dismissViewControllerAnimated:YES completion:^{
            if([layer isKindOfClass:[AGSFeatureLayer class]]){
                AGSFeatureLayer* fLayer = (AGSFeatureLayer*)layer;
                AGSGraphic* graphic = [fLayer featureWithTemplate:template];
                [fLayer addGraphic:graphic];
                AGSPopupInfo *pi = [AGSPopupInfo popupInfoForFeatureLayer:fLayer];
                AGSPopup *p = [[AGSPopup alloc]initWithGraphic:graphic popupInfo:pi featureLayer:fLayer];
                [self showPopupsVCForPopups:@[p]];
                [_popupsVC startEditingCurrentPopup];
            }else if([layer isKindOfClass:[AGSGDBFeatureTable class]]){
                AGSGDBFeatureTable* fTable = (AGSGDBFeatureTable*) layer;
                AGSGDBFeature* feature = [fTable featureWithTemplate:template];
                _addFeature = feature;
                AGSPopupInfo *pi = [AGSPopupInfo popupInfoForGDBFeatureTable:fTable];
                AGSPopup *p = [[AGSPopup alloc]initWithGDBFeature:feature popupInfo:pi];
                [self showPopupsVCForPopups:@[p]];
                [_popupsVC startEditingCurrentPopup];
            }

        }];
    }
    
}

- (void) featureTemplatePickerViewControllerWasDismissed:(FeatureTemplatePickerViewController *)featureTemplatePickerViewController{
    if ([[AGSDevice currentDevice]isIPad]) {
        [_pvc
         dismissPopoverAnimated:YES];
    }else{
        [featureTemplatePickerViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)deleteGDBAction:(id)sender {
    if (_offline || _goingOffline){
        [self logStatus:@"cannot delete local data while displaying it"];
        return;
    }
    _geodatabase = nil;
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSArray *files = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:path error:nil];
    for (NSString *file in files){
        BOOL remove = [file hasSuffix:@".geodatabase"] || [file hasSuffix:@".geodatabase-shm"] || [file hasSuffix:@".geodatabase-wal"];
        if (remove){
            [[NSFileManager defaultManager]removeItemAtPath:file error:nil];
            [self logStatus:[NSString stringWithFormat:@"deleting %@",file]];
            
        }
    }
    [self logStatus:[NSString stringWithFormat:@"done."]];
}

#pragma mark popups container view controller delegate

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

    if (!_sgl){
        _sgl = [[AGSSketchGraphicsLayer alloc]initWithGeometry:geometry];
        [_mapView addMapLayer:_sgl];
        _mapView.touchDelegate = _sgl;
    }
    else{
        _sgl.geometry = geometry;
    }
    
    //
    // if we are on iPhone, hide the popupsVC and show editing UI
    if (![[AGSDevice currentDevice] isIPad]) {
        [_popupsVC dismissViewControllerAnimated:YES completion:nil];
        [self toggleGeometryEditUI];
    }
}


-(void)popupsContainerDidFinishViewingPopups:(id<AGSPopupsContainer>)popupsContainer{
    //
    // this clears _currentPopups
    [self hidePopupsVC];
}

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didCancelEditingForPopup:(AGSPopup *)popup {
    [_mapView removeMapLayer:_sgl];
    _sgl = nil;
    _mapView.touchDelegate = self;
}

-(void) popupsContainer:(id<AGSPopupsContainer>)popupsContainer didFinishEditingForPopup:(AGSPopup *)popup {

    [_mapView removeMapLayer:_sgl];
    _sgl = nil;
    _mapView.touchDelegate = self;
    
    // dealing with 'offline' feature
    if (popup.gdbFeature){
        
        if (popup.gdbFeature == _addFeature){
            AGSEditResult *result = [popup.gdbFeatureTable addFeature:popup.gdbFeature];
            if(result.success){
                [self logStatus:[NSString stringWithFormat:@"add succeded (ID:%d)", result.objectId]];
                [_badge removeFromSuperview];
                _badge = [[JSBadgeView alloc]initWithParentView:self.badgeView alignment:JSBadgeViewAlignmentCenterLeft];
                _badge.badgeText = [self numberOfEditsInGeodatabase:popup.gdbFeatureTable.geodatabase];

            }else{
                [self logStatus:[NSString stringWithFormat:@"add failed: %@", result.error.errorDescription]];
            }
            _addFeature = nil;
        }
        else{
            AGSEditResult *result = [popup.gdbFeatureTable updateFeature:popup.gdbFeature];
            if(result.success){
                [self logStatus:[NSString stringWithFormat:@"update succeded (ID:%d)", result.objectId]];
                [_badge removeFromSuperview];
                _badge = [[JSBadgeView alloc]initWithParentView:self.badgeView alignment:JSBadgeViewAlignmentCenterLeft];
                _badge.badgeText = [self numberOfEditsInGeodatabase:popup.gdbFeatureTable.geodatabase];
                
            }else{
                [self logStatus:[NSString stringWithFormat:@"update failed: %@", result.error.errorDescription]];
            }
        }
    }
    else if (popup.graphic){
        if ([popup.featureLayer objectIdForFeature:popup.graphic]<0){
            [popup.featureLayer addFeatures:@[popup.graphic]];
        }
        else{
            [popup.featureLayer updateFeatures:@[popup.graphic]];
        }
    }
    
}

- (NSString*) numberOfEditsInGeodatabase:(AGSGDBGeodatabase*)gdb{
    int total = 0;
    for (AGSGDBFeatureTable* ftable in gdb.featureTables) {
        total += [ftable addedFeatures].count + [ftable deletedFeatures].count + [ftable updatedFeatures].count;
    }
    return [[NSNumber numberWithInt:total] stringValue];
}

-(void) popupsContainer:(id<AGSPopupsContainer>)popupsContainer wantsToDeleteForPopup:(AGSPopup *)popup{
    if([popup.feature isKindOfClass:[AGSGDBFeature class]]){
       AGSEditResult *result = [popup.gdbFeature.table deleteFeature:popup.gdbFeature];
        if(result.success){
            [self logStatus:[NSString stringWithFormat:@"delete succeded (ID:%d)", result.objectId]];
            [_badge removeFromSuperview];
            _badge = [[JSBadgeView alloc]initWithParentView:self.badgeView alignment:JSBadgeViewAlignmentCenterLeft];
            _badge.badgeText = [self numberOfEditsInGeodatabase:popup.gdbFeatureTable.geodatabase];
        }
        else{
            [self logStatus:[NSString stringWithFormat:@"delete failed: %@", result.error.errorDescription]];
        }

    }else{
        AGSFeatureLayer* fLayer = (AGSFeatureLayer*) popup.graphic.layer;
        
        [fLayer deleteFeaturesWithObjectIds:@[[NSNumber numberWithLongLong:[fLayer objectIdForFeature:popup.graphic]]]];
    }
    [self hidePopupsVC];
}

#pragma mark feature layer editing

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFeatureEditsWithResults:(AGSFeatureLayerEditResults *)editResults{
    for (AGSEditResult *res in editResults.addResults){
        if (res.error){
            [self logStatus:[NSString stringWithFormat:@"add failed: %@", res.error]];
        }
        else{
            [self logStatus:[NSString stringWithFormat:@"add succeeded: %d", res.objectId]];
        }
    }
    
    for (AGSEditResult *res in editResults.updateResults){
        if (res.error){
            [self logStatus:[NSString stringWithFormat:@"update failed: %@", res.error]];
        }
        else{
            [self logStatus:[NSString stringWithFormat:@"update succeeded: %d", res.objectId]];
        }
    }
    
    for (AGSEditResult *res in editResults.deleteResults){
        if (res.error){
            [self logStatus:[NSString stringWithFormat:@"delete failed: %@", res.error]];
        }
        else{
            [self logStatus:[NSString stringWithFormat:@"delete succeeded: %d", res.objectId]];
        }
    }
}


#pragma mark going offline

-(void)logStatus:(NSString*)status{
    
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(logStatus:) withObject:status waitUntilDone:NO];
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearStatus) object:nil];
    
    // show basic status
    self.statusLabel.text = [NSString stringWithFormat:@"%@   ", status];
    
    NSString *hideText = @"Tap to hide...";
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    df.dateStyle = NSDateFormatterNoStyle;
    df.timeStyle = NSDateFormatterShortStyle;
    status = [NSString stringWithFormat:@"%@ - %@\n\n", [df stringFromDate:[NSDate date]], status];
    [_allStatus insertString:status atIndex:0];
    if ([[UIDevice currentDevice]userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        _statusTextView.text = [NSString stringWithFormat:@"%@\n\n%@", hideText, _allStatus];
    }
    else{
        _statusTextView.text = [NSString stringWithFormat:@"%@\n\n%@", hideText, _allStatus];
    }
    NSLog(@"%@", status);
    
    // write to log file
    AppDelegate *app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [app logAppStatus:status];
    
    [self performSelector:@selector(clearStatus) withObject:nil afterDelay:2];
}

-(void)clearStatus{
    self.statusLabel.text = @"swipe up to show activity log   ";
}

-(void)updateOfflineStatus{
    
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(updateOfflineStatus) withObject:nil waitUntilDone:NO];
        return;
    }
    
    
    // set status
    if (_goingOffline){
        _offlineStatusLabel.text = @"going offline...";
    }
    else if (_goingOnline){
        _offlineStatusLabel.text = @"going online...";
    }
    else if (_offline){
        _offlineStatusLabel.text = @"Local data"; //@"offline";
        _goOfflineButton.title = @"go live"; //@"go online";
    }
    else if (!_offline){
        _offlineStatusLabel.text = @"Live data"; //@"online";
        _goOfflineButton.title = @"download"; //@"go offline";
        [_badge removeFromSuperview];
    }
    
    _goOfflineButton.enabled = !_goingOffline && !_goingOnline;
    self.syncButton.enabled = _offline;


}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0: //No, just switch to live
            [self goOnline];
            break;
        case 1: //Yes, first sync, then switch to live
            [self syncAction:nil];
            break;
            
        default:
            break;
    }
}

- (IBAction)goOfflineAction:(id)sender {
    
    if (_goingOffline){
        return;
    }
    
    _lastExtent = _mapView.visibleAreaEnvelope;
    
    if (_offline){
        if([self.geodatabase hasLocalEdits]){
            UIAlertView* av = [[UIAlertView alloc]initWithTitle:nil message:@"Do you want to sync local edits with the service?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [av show];
            return;
        }else{
            [self goOnline];
        }
    }
    else{

        [self goOffline];
    }
}

-(void)goOnline{
    
    _goingOnline = YES;
    
    [self logStatus:@"going online"];
    [_mapView reset];
    [_mapView addMapLayer:_localTiledLayer];
    if (_lastExtent){
        [_mapView zoomToEnvelope:_lastExtent animated:NO];
    }
    
    self.gdbTask = [[AGSGDBTask alloc]initWithURL:[NSURL URLWithString:@"http://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/Wildfire/FeatureServer"]];
    self.gdbTask.timeoutInterval = 300;
    __weak OfflineTestViewController* weakSelf = self;
    __weak AGSGDBTask* weakTask = self.gdbTask;
    self.gdbTask.loadCompletion = ^(NSError* error){
        for (AGSMapServiceLayerInfo* info in weakTask.featureServiceInfo.layerInfos) {
            [SVProgressHUD showProgress:-1 status:@"Switching to \n live data"];
            NSURL* url = [weakTask.URL URLByAppendingPathComponent:[NSString stringWithFormat:@"%d",info.layerId]];
            
            AGSFeatureLayer* fl = [AGSFeatureLayer featureServiceLayerWithURL:url mode:AGSFeatureLayerModeOnDemand];
            fl.delegate = weakSelf;
            fl.editingDelegate = weakSelf;
            fl.expirationInterval = 60;
            fl.autoRefreshOnExpiration = YES;

            [weakSelf.mapView addMapLayer:fl];
            [weakSelf logStatus:[NSString stringWithFormat:@"loading: %@", [fl.URL absoluteString]]];
        }
        [weakSelf logStatus:@"now online"];
        [weakSelf updateOfflineStatus];
    };

    _goingOnline = NO;
    _offline = NO;

 }

-(void)featureLayerDidLoadFeatures:(NSNotification*)notification{
    [SVProgressHUD popActivity];
}
-(void)goOffline{
    [[NSNotificationCenter defaultCenter]removeObserver:self];

    [SVProgressHUD showWithStatus:@"Downloading \n features"/*@"Going Offline*/];
    // feature layer
    [self generateGDB];

    [self.mapView reset];
    [self.mapView addMapLayer:_localTiledLayer];

    if (_lastExtent){
        [_mapView zoomToEnvelope:_lastExtent animated:NO];
    }
    
}

-(void)generateGDB{
    _goingOffline = YES;
    __weak OfflineTestViewController *wself = self;
    AGSGDBGenerateParameters *params = [[AGSGDBGenerateParameters alloc]initWithFeatureServiceInfo:self.gdbTask.featureServiceInfo];
    params.extent = self.mapView.visibleArea.envelope;
    params.outSpatialReference = [AGSSpatialReference wgs84SpatialReference];
    NSMutableArray* layers = [[NSMutableArray alloc]init];
    for (AGSMapServiceLayerInfo* layerInfo in self.gdbTask.featureServiceInfo.layerInfos) {
        [layers addObject:[NSNumber numberWithInt: layerInfo.layerId]];
    }
    params.layerIDs = layers;
    [self.gdbTask generateGeodatabaseAndDownloadWithParameters:params downloadFolderPath:nil useExisting:YES status:^(AGSAsyncServerJobStatus status, NSDictionary *userInfo) {
        [wself logStatus:[NSString stringWithFormat:@"going offline status: %@ - %@", [self statusMessageForAsyncStatus:status], userInfo]];
    } completion:^(AGSGDBGeodatabase *geodatabase, NSError *error) {
        if (error){
            _goingOffline = NO;
            _offline = NO;
            [wself logStatus:[NSString stringWithFormat:@"error taking feature layers offline: %@", error]];
            [SVProgressHUD showErrorWithStatus:@"Couldn't go offline"];
        }
        else{
            _goingOffline = NO;
            _offline = YES;
            [self logStatus:@"now offline"];

            wself.geodatabase = geodatabase;
            for (AGSFeatureTable* fTable in geodatabase.featureTables) {
                if ([fTable hasGeometry]) {
                    [wself.mapView addMapLayer:[[AGSFeatureTableLayer alloc]initWithFeatureTable:fTable]];
                }
            }
            [SVProgressHUD showSuccessWithStatus:@"Switching to \n local data"];
        }
        if ([geodatabase hasLocalEdits]) {
            [_badge removeFromSuperview];
            _badge = [[JSBadgeView alloc]initWithParentView:wself.badgeView alignment:JSBadgeViewAlignmentCenterLeft];
            _badge.badgeText = [wself numberOfEditsInGeodatabase:geodatabase];
            
        }
        [wself updateOfflineStatus];
    
        
    }];
}



#pragma mark sync

- (IBAction)syncAction:(id)sender {
    
    if (self.cancellable){
        // if already syncing just return
        return;
    }
    [SVProgressHUD showWithStatus:@"Synchronizing \n changes"];
    [self logStatus:@"Starting sync process..."];
    
    __weak OfflineTestViewController *weakSelf = self;
    AGSGDBSyncParameters* param = [[AGSGDBSyncParameters alloc]initWithGeodatabase:self.geodatabase];
    self.cancellable = [self.gdbTask syncGeodatabase:self.geodatabase params:param status:^(AGSAsyncServerJobStatus status, NSDictionary *userInfo) {
        [self logStatus:[NSString stringWithFormat:@"sync status: %d - %@", status, userInfo]];
    } completion:^(NSError *error) {
        weakSelf.cancellable = nil;
        if (error){
            [weakSelf logStatus:[NSString stringWithFormat:@"error sync'ing: %@", error]];
            [SVProgressHUD showErrorWithStatus:@"Error encountered"];
        }
        else{
            [weakSelf logStatus:[NSString stringWithFormat:@"sync complete"]];
            [SVProgressHUD showSuccessWithStatus:@"Sync complete"];
            [_badge removeFromSuperview];

        }
        
    }];
}


#pragma mark Geometry Editing UI

- (void)toggleGeometryEditUI {
    self.geometryEditToolbar.hidden = !self.geometryEditToolbar.hidden;
}

- (IBAction)cancelEditingGeometry:(id)sender {
    [self doneEditingGeometry:nil];
}

- (IBAction)doneEditingGeometry:(id)sender {
    [_mapView removeMapLayer:_sgl];
    _sgl = nil;
    _mapView.touchDelegate = self;
    [self toggleGeometryEditUI];
    [self presentViewController:_popupsVC animated:YES completion:nil];
}

#pragma mark -

-(NSString*)statusMessageForAsyncStatus:(AGSAsyncServerJobStatus)status
{
    switch (status) {
        case AGSAsyncServerJobStatusNotStarted:
            return @"Not yet started";
            break;
        case AGSAsyncServerJobStatusWaitingForDefaultParameters:
            return @"Waiting for default parameters";
            break;
        case AGSAsyncServerJobStatusPreProcessingJob:
            return @"Preprocessing";
            break;
        case AGSAsyncServerJobStatusStartingJob:
            return @"Starting";
            break;
        case AGSAsyncServerJobStatusPolling:
            return @"In Progress";
            break;
        case AGSAsyncServerJobStatusFetchingResult:
            return @"Downloading Result";
            break;
        case AGSAsyncServerJobStatusInBGWaitingToFinish:
            return @"Backgrounded;waiting to finish";
            break;
        case AGSAsyncServerJobStatusDone:
            return @"Done";
            break;
        case AGSAsyncServerJobStatusCancelled:
            return @"Cancelled";
            break;
        default:
            return @"";
            break;
    }

}
@end







