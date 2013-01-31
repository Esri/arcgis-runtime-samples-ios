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

#import "ClipboardViewController.h"
#import "Reachability.h"
#import "InspectionFormViewController.h"
#import <QuartzCore/QuartzCore.h>

#define kShowSyncLabelOnTop YES
#define kCurlAnimationDuration .55
#define kDownloadTimerLength 1
#define kSyncTimerLength 4
#define kPaperClipWidth 40

//Will only be used if a URL doesn't exist in the Settings
#define kFeatureLayerUrl @"http://mobilesampleserver.arcgisonline.com/ArcGIS/rest/services/DemoData/TeapotDomeTanks/FeatureServer/0"
#define kFeatureLayerName @"FeatureLayer"

//Will only be used if a URL doesn't exist in the Settings
#define kInspectionsLayerUrl @"http://mobilesampleserver.arcgisonline.com/ArcGIS/rest/services/DemoData/ProductionTicket/FeatureServer/0"
#define kInspectionsLayerName @"Inspections Layer"

#define kNumberOfOperationalLayers 2


//Private Methods
@interface ClipboardViewController () 

-(void)wifiChanged:(NSNotification *)n;
-(void)updateWifiAvailability;


-(void)initializeMapWithOfflineCache;
-(void)initializeMapWithOperationalLayers;

-(void)inspectButtonPressed:(id)sender;
-(void)filterPopupInfo:(AGSPopupInfo *)popupInfo;
-(void)timerFinished;
-(void)finalizeDownload;

-(void)hideSyncButtonAfterTimerFinished;

-(void)finishAnimateOutInspectionForm;
-(void)removeInspectionForm;

-(AGSPoint *)getLocationPointForGeometry:(AGSGeometry *)geometry;

-(void)setCurrentSyncIndexAndUpdateForStatus:(BOOL)status;
-(void)syncNextInspection;
-(void)finalizeSynchronizations;

@end

//here so compiler doesn't complain about method call to UIView. Disclaimer: 
//Using this in an app destined for the App Store will probably get you rejected
//since this is classified as private API
@interface UIView ()

+(void)setAnimationPosition:(CGPoint)point;

@end


@implementation ClipboardViewController

@synthesize mapView=_mapView;
@synthesize clipboard = _clipboard;
@synthesize clip = _clip;
@synthesize downloadDataView = _downloadDataView;
@synthesize startInspectionView = _startInspectionView;
@synthesize downloadImageView = _downloadImageView;
@synthesize startInspectionImageView = _startInpsectionImageView;
@synthesize connectivityImageView = _connectivityImageView;
@synthesize downloadCheckImageView = _downloadCheckImageView;
@synthesize syncCheckImageView = _syncCheckImageView;
@synthesize featuresLayer = _featuresLayer;
@synthesize inspectionLayer = _inspectionLayer;
@synthesize inspectionLayerUrl = _inspectionLayerUrl;
@synthesize featureLayerUrl = _featureLayerUrl;
@synthesize inspectionsToSync = _inspectionsToSync;
@synthesize currentFeatureToInspectPopup = _currentFeatureToInspectPopup;
@synthesize currentInspectionPopup = _currentInspectionPopup;
@synthesize activityIndicator = _activityIndicator;
@synthesize syncButton = _syncButton;
@synthesize wifiReachability = _wifiReachability;
@synthesize inspectionVC = _inspectionVC;
@synthesize syncDataView = _syncDataView;
@synthesize syncDataImageView = _syncDataImageView;
@synthesize syncDataLabel = _syncDataLabel;
@synthesize syncStatuses = _syncStatuses;

#pragma mark -
#pragma mark View Stuff

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Load images here. Better to do it in viewDidLoad than from nib to give appearance of
    //app loading faster
    self.clip.image = [UIImage imageNamed:@"clip.png"];
    self.downloadImageView.image = [UIImage imageNamed:@"green_post_it.png"];
    self.startInspectionImageView.image = [UIImage imageNamed:@"yellow_post_it.png"];
    self.clipboard.image = [UIImage imageNamed:@"clipboard_shadow.png"];
    
    
    self.mapView.backgroundColor = [UIColor whiteColor];
    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    /*Configure and check for reachability */
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(wifiChanged:) name: kReachabilityChangedNotification object: nil];
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
	[self.wifiReachability startNotifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerLoaded:) name:AGSLayerDidLoadNotification object:nil];
    
    [self updateWifiAvailability];
    
    //grab layer URLs from Settings.  Note: If user changes URLs once app is loaded,
    //those layer changes will have no effect. User needs to kill app, change layers,
    //then update
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.inspectionLayerUrl = [defaults stringForKey:@"inspectionLayerUrl"];
    self.featureLayerUrl = [defaults stringForKey:@"featureToInspectLayerUrl"];
    
    //one of the layers wasn't set in Settings, use default set programatically
    if (self.inspectionLayerUrl == nil || [self.inspectionLayerUrl length] == 0 || 
        self.featureLayerUrl == nil || [self.featureLayerUrl length] == 0) 
    {
        self.inspectionLayerUrl = kInspectionsLayerUrl;
        self.featureLayerUrl = kFeatureLayerUrl;
    }

    //Configure exploded cache layer
    [self initializeMapWithOfflineCache];
    
    self.mapView.layer.cornerRadius = 4;
}

#pragma mark -
#pragma mark Lazy Loads
-(UIImageView *)connectivityImageView
{
    if(_connectivityImageView == nil)
    {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"offline_tape.png"]];
        iv.frame = CGRectMake(560, 842, 197, 143);
        self.connectivityImageView = iv;
    }
    
    return _connectivityImageView;
}

-(UIActivityIndicatorView *)activityIndicator
{
    if(_activityIndicator == nil)
    {
        float sideLength = 30;
        CGRect downloadFrame = self.downloadDataView.frame;
        
        UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        ai.frame = CGRectMake(downloadFrame.size.width/2 - sideLength, downloadFrame.size.height/2, 40, 40);
        self.activityIndicator = ai;
    }
    
    return _activityIndicator;
}

-(UIButton *)syncButton
{
    if(_syncButton == nil)
    {
        self.syncButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.syncButton.frame = CGRectMake(20, 30, 240, 25);
        [self.syncButton addTarget:self action:@selector(syncFeatures:) forControlEvents:UIControlEventTouchUpInside];
        [self.syncButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.syncButton.titleLabel.font = [UIFont fontWithName:@"Courier" size:18.0];
        
        [self.view insertSubview:_syncButton aboveSubview:self.clipboard];
        self.syncButton.hidden = YES;
    }
    return _syncButton;
}

-(NSMutableArray *)inspectionsToSync
{
    if(_inspectionsToSync == nil)
    {
        NSMutableArray *ma = [[NSMutableArray alloc] initWithCapacity:3];
        self.inspectionsToSync = ma;
    }
    
    return _inspectionsToSync;
}

//sync statuses is a dictionary of indices (into the inspections sync array) to a boolean
//on whether or not the synchronization to the server was successful
-(NSMutableDictionary *)syncStatuses
{
    if (_syncStatuses == nil) {
        self.syncStatuses = [NSMutableDictionary dictionaryWithCapacity:4];
    }
    
    return _syncStatuses;
}

#pragma mark -
#pragma mark Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    //App only works in portrait. If app is destined for the app store, you might consider
    //making the app work in all orientations as suggested by Apple's iPad Human Interface Guidelines(HIG).
    return (interfaceOrientation == UIInterfaceOrientationPortrait  ||
            interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark -
-(void)layerLoaded:(NSNotification *)n
{
    _numLayersLoaded++;
    
    if (_numLayersLoaded == kNumberOfOperationalLayers) {
        
        _downloadedData = YES;
        
        if (_timerFired) {
            [self finalizeDownload];
        }
    }
}

#pragma mark -
#pragma mark Button Actions
-(IBAction)downloadData:(id)sender
{
    if (!_hasWifiConnection) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                            message:@"Please establish an internet connection before attempting to download data" 
                                                           delegate:nil cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    else if (!_downloadedData) {
        
        [self.downloadDataView addSubview:self.activityIndicator];
        [self.activityIndicator startAnimating];
        
        [self initializeMapWithOperationalLayers];
        
        _timerFired = NO;
        [NSTimer scheduledTimerWithTimeInterval:kDownloadTimerLength 
                                         target:self 
                                       selector:@selector(timerFinished) 
                                       userInfo:nil 
                                        repeats:NO];
    }
}

-(IBAction)startInspections:(id)sender
{
    if (!_downloadedData) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" 
                                                        message:@"Please download inspection data before beginning inspections" 
                                                       delegate:nil cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        
        //curl map back so user can start
        [self curlMapButtonPressed:nil];
    }
}

-(IBAction)syncFeatures:(id)sender
{
    if (!_hasWifiConnection) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                            message:@"Please establish an internet connection before attempting to synchronize features" 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
    }
    else {
        if (self.inspectionsToSync.count > 0) {
            self.syncStatuses = nil;
            _inspectionIndex = 0;
            [self syncNextInspection];
        }
        //make note disappear
        else
        {
            self.syncDataView.hidden = YES;
        }

    }
}

-(void)inspectButtonPressed:(id)sender
{
    AGSGraphic *inspectionFeature = nil;
    if (self.inspectionLayer.templates.count > 0) {
        inspectionFeature = [self.inspectionLayer featureWithTemplate:[self.inspectionLayer.templates objectAtIndex:0]];
    }
    else
    {
        inspectionFeature = [self.inspectionLayer featureWithType:[self.inspectionLayer.types objectAtIndex:0]];
    }
    
    inspectionFeature.geometry = [self getLocationPointForGeometry:self.currentFeatureToInspectPopup.graphic.geometry];
    
    //add graphic to layer so edit properties can be set appropriately
    [self.inspectionLayer addGraphic:inspectionFeature];
    
    AGSPopupInfo *popupInfo = [AGSPopupInfo popupInfoForGraphic:inspectionFeature];
    
    
    self.currentInspectionPopup = nil;
    self.currentInspectionPopup = [AGSPopup popupWithGraphic:inspectionFeature popupInfo:popupInfo];

    //don't want edit geometry capability
    self.currentInspectionPopup.allowEditGeometry = NO;
    
    InspectionFormViewController *iVC = [[InspectionFormViewController alloc] initWithInspectionPopup:self.currentInspectionPopup 
                                                                             andFeatureToInspectPopup:self.currentFeatureToInspectPopup];
    iVC.delegate = self;
    self.inspectionVC = iVC;
    
    CGRect inspectionFormRect = self.inspectionVC.view.frame;
    inspectionFormRect.origin = CGPointMake(self.mapView.superview.frame.origin.x - kPaperClipWidth, self.mapView.superview.frame.origin.y); 
    self.inspectionVC.view.frame = inspectionFormRect;
    
    //Add the inspection form. Then remove the clip and place it over the inspection form. 
    //This will need to be reversed when removing the inspection form
    [self.view addSubview:self.inspectionVC.view];
    [self.clip removeFromSuperview];
    [self.view addSubview:self.clip];
        
    self.mapView.superview.transform = CGAffineTransformMakeRotation(-.04); 
}

-(IBAction)curlMapButtonPressed:(id)sender
{
    UIView *viewToCurlUnCurl = self.mapView.superview;
    viewToCurlUnCurl.clipsToBounds = NO;
    
    CATransition *transition = [CATransition animation];
    [transition setDelegate:self];
    [transition setDuration:kCurlAnimationDuration];
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    if (!_curled) {
        transition.type = @"pageCurl";
        transition.fillMode = kCAFillModeForwards;
        transition.endProgress = 0.87;        
    }
    else {
        transition.type = @"pageUnCurl";
        transition.fillMode = kCAFillModeBackwards;
        transition.startProgress = 0.13;
    }
    
    [transition setRemovedOnCompletion:NO];
    [viewToCurlUnCurl.layer addAnimation:transition forKey:@"pageCurlAnimation"];
    viewToCurlUnCurl.hidden = !_curled;
    _curled = !_curled;
}

#pragma mark -
#pragma mark AGSMapViewCalloutDelegate
- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForGraphic:(AGSGraphic *)graphic
{
    self.mapView.callout.accessoryButtonHidden = (graphic.layer == self.inspectionLayer);
    
    return YES;
}


#pragma mark -
#pragma mark AGSCalloutDelegate
- (void)didClickAccessoryButtonForCallout:(AGSCallout *)callout
{
    AGSGraphic* graphic = (AGSGraphic*)callout.representedObject;
	AGSPopupInfo *popupInfo = [AGSPopupInfo popupInfoForGraphic:graphic];
	if (!popupInfo){
		return;
	}
    
    [self filterPopupInfo:popupInfo];
    popupInfo.title = [graphic attributeAsStringForKey:@"name"];
    
	// create a popup from the popupInfo and a feature
	self.currentFeatureToInspectPopup = [[AGSPopup alloc]initWithGraphic:graphic popupInfo:popupInfo];
    self.currentFeatureToInspectPopup.allowEdit = NO;
    self.currentFeatureToInspectPopup.allowDelete = NO;
    self.currentFeatureToInspectPopup.allowEditGeometry = NO;
	    
    self.mapView.callout.hidden = YES;
    [self inspectButtonPressed:nil];
}

#pragma mark -
#pragma mark InspectionFormDelegate

-(void)inspectionFormDidCancel:(InspectionFormViewController *)inspectionVC
{
    [self.inspectionLayer removeGraphic:self.currentInspectionPopup.graphic];
    
    [self.clip removeFromSuperview];
    [self.view insertSubview:self.clip aboveSubview:self.clipboard];
        
    [self removeInspectionForm];
}

//just finished an inspection. Mark initial feature as inspected, add inspection to a list to sync later, 
//and update UI to reflect new changes
-(void)inspectionFormDidFinishWithNewInspection:(AGSPopup *)newInspectionPopup
{
    if (newInspectionPopup){
        
        //keep a record of all popups to sync
        [self.inspectionsToSync addObject:newInspectionPopup];
        
        if (kShowSyncLabelOnTop) {
            [self.syncButton setTitle:[NSString stringWithFormat:@"%d inspection%@ to sync", self.inspectionsToSync.count, (self.inspectionsToSync.count == 1) ? @"" : @"s"] forState:UIControlStateNormal];
            self.syncButton.hidden = NO;
        }
        
    }
    
    [self.clip removeFromSuperview];
    [self.view insertSubview:self.clip aboveSubview:self.clipboard];
    
    //put map back to unrotated form
    self.mapView.superview.transform = CGAffineTransformIdentity;
    
    //Animate the inspection form to a point on the screen where the feature actually is
    CGPoint sp = [self.mapView toScreenPoint:(AGSPoint *)self.currentInspectionPopup.graphic.geometry];
    CGPoint actualScreenPoint = [self.mapView convertPoint:sp toView:self.view];
        
    [UIView beginAnimations:@"test" context:nil];
    [UIView setAnimationDidStopSelector:@selector(finishAnimateOutInspectionForm)];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationPosition:actualScreenPoint];
    [UIView setAnimationTransition:103 forView:self.inspectionVC.view cache:YES];
    [UIView commitAnimations];
    self.inspectionVC.view.hidden = YES;
    
    //show sync post-it
    self.syncDataView.hidden = NO;
    //lazy load image
    if (self.syncDataImageView.image == nil) {
        self.syncDataImageView.image = [UIImage imageNamed:@"blue_post_it.png"];
    }
    self.syncDataLabel.text = [NSString stringWithFormat:@"Synchronize my %d inspection%@", self.inspectionsToSync.count, (self.inspectionsToSync.count == 1) ? @"" : @"s"];
}

#pragma mark AGSFeatureLayerEditingDelegate

//Called when we have successfully posted a set of features. Once an inspection has finished posting, we then
//need to post the attachments for the particular feature (if there are any) 
- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFeatureEditsWithResults:(AGSFeatureLayerEditResults *)editResults {
	
    BOOL needsToDownloadAttachment = NO;
    BOOL success = YES;
    
	if ([editResults.addResults count] > 0) {
		
		for (int i=0;i<[editResults.addResults count];i++) {
			AGSEditResult *editResult = [editResults.addResults objectAtIndex:i];
			if (!editResult.success) {
				success = NO;
			}
		}
		
        if(success)
        {
            //See if there are attachments to post
            AGSPopup *currentInspection = [self.inspectionsToSync objectAtIndex:_inspectionIndex];
            
            AGSAttachmentManager *am = [self.inspectionLayer attachmentManagerForFeature:currentInspection.graphic];
            needsToDownloadAttachment = [am hasLocalEdits];
            if (needsToDownloadAttachment) {
                am.delegate = self;
                [am postLocalEditsToServer];
            }
            //no attachments, increment and continue
            else {
                [self setCurrentSyncIndexAndUpdateForStatus:YES];
            }
        }
        //fail on add feature
        else {
            [self setCurrentSyncIndexAndUpdateForStatus:NO];
        }

	}
    //only sync next one if we don't have any attachments to sync
    if (!needsToDownloadAttachment) {
        [self syncNextInspection];
    }
}

//Failed to post a feature
- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFailFeatureEditsWithError:(NSError *)error {
    //fail!
    [self setCurrentSyncIndexAndUpdateForStatus:NO];
    [self syncNextInspection];
}

#pragma mark AGSAttachmentManagerDelegate

//Called when we have sucessfully posted an attachment
- (void)attachmentManager:(AGSAttachmentManager *)attachmentManager didPostLocalEditsToServer:(NSArray *)attachmentsPosted {
    
	NSLog(@"Attachments posted successfully...");
    
    [self setCurrentSyncIndexAndUpdateForStatus:YES];
    [self syncNextInspection];
}



#pragma mark -
#pragma mark Internal Methods

-(void)updateWifiAvailability
{
    NetworkStatus netStatus = [self.wifiReachability currentReachabilityStatus];
    if (netStatus == ReachableViaWiFi){
        [self.connectivityImageView removeFromSuperview];
        self.connectivityImageView = nil;
        
        _hasWifiConnection = YES;
    }
    else {
        if (!self.connectivityImageView.superview) {
            UIView *viewToShowConnectivityOnTop = (kShowSyncLabelOnTop) ? self.mapView.superview : self.clipboard;
            [self.view insertSubview:self.connectivityImageView aboveSubview:viewToShowConnectivityOnTop];
        }
        _hasWifiConnection = NO;
    }
}

-(void)wifiChanged:(NSNotification *)n
{
    [self updateWifiAvailability];
}

-(void)initializeMapWithOfflineCache
{
    self.mapView.layerDelegate = self;
    self.mapView.touchDelegate = self;
    self.mapView.calloutDelegate = self;
    self.mapView.callout.delegate = self;
    
    
    //Load the Imagery.tpk tile package
    AGSLocalTiledLayer *tiledLyr = [AGSLocalTiledLayer localTiledLayerWithName:@"Imagery"];
    
	[self.mapView addMapLayer:tiledLyr withName:@"Basemap Layer"];

    
    
	AGSEnvelope *teapotDomeEnv = [AGSEnvelope envelopeWithXmin:-11821994.711433 
                                                          ymin:5354125.129688 
                                                          xmax:-11821615.846141 
                                                          ymax:5354617.599419 
                                              spatialReference:[AGSSpatialReference webMercatorSpatialReference]];
    
	[self.mapView zoomToEnvelope:teapotDomeEnv animated:YES];
}

-(void)initializeMapWithOperationalLayers
{    
    _numLayersLoaded = 0;
    
    NSURL* url = [NSURL URLWithString: self.featureLayerUrl]; 	 
    self.featuresLayer = [AGSFeatureLayer featureServiceLayerWithURL: url mode: AGSFeatureLayerModeSnapshot];
    self.featuresLayer.infoTemplateDelegate = self.featuresLayer;
    self.featuresLayer.outFields = [NSArray arrayWithObject:@"*"];
    [self.mapView addMapLayer:self.featuresLayer withName:kFeatureLayerName];
    
    NSURL* inpsectionUrl = [NSURL URLWithString: self.inspectionLayerUrl]; 	 
    self.inspectionLayer = [AGSFeatureLayer featureServiceLayerWithURL:inpsectionUrl mode: AGSFeatureLayerModeSnapshot];
    self.inspectionLayer.infoTemplateDelegate = self.inspectionLayer;
    self.inspectionLayer.outFields = [NSArray arrayWithObject:@"*"];
    [self.mapView addMapLayer:self.inspectionLayer withName:kInspectionsLayerName]; 
}

//Ensure some fields can't be seen in popup
-(void)filterPopupInfo:(AGSPopupInfo *)popupInfo
{
    NSArray *fieldInfos = popupInfo.fieldInfos;
    NSArray *fieldNamesToFilter = [NSArray arrayWithObjects:@"objectid", @"globalid", @"website", nil];
    
    for (AGSPopupFieldInfo *fi in fieldInfos) {
        if ([fieldNamesToFilter containsObject:fi.fieldName]) {
            fi.visible = NO;
        }
    }
}

-(void)timerFinished
{
    _timerFired = YES;
    if (_downloadedData) {
        [self finalizeDownload];
    }
}

-(void)hideSyncButtonAfterTimerFinished
{
    self.syncButton.hidden = YES;
}

-(void)finalizeDownload
{
    [self.activityIndicator stopAnimating];
    [self.activityIndicator removeFromSuperview];
    
    self.downloadCheckImageView.image = [UIImage imageNamed:@"green_check_mark.png"];
}

//Depending on what we are inspecting, pick a reasonable point to be the inspection geometry
-(AGSPoint *)getLocationPointForGeometry:(AGSGeometry *)geometry
{
    if (!geometry) {
        return nil;
    }
    
    if ([geometry isKindOfClass:[AGSPoint class]]){
        return (AGSPoint*)geometry;
    }
    else if ([geometry isKindOfClass:[AGSPolyline class]] ||
             [geometry isKindOfClass:[AGSPolygon class]]){
        return geometry.envelope.center;
    }
    else if ([geometry isKindOfClass:[AGSMultipoint class]] &&
             ((AGSMultipoint *)geometry).numPoints > 0){
        return [((AGSMultipoint*)geometry) pointAtIndex:0];
    }
    
    return nil;
}

#pragma mark -
#pragma mark Internal Inspection Form Animation Methods
-(void)removeInspectionForm
{
    [self.inspectionVC.view removeFromSuperview];
    self.inspectionVC = nil;
    
    //put map back to unrotated form
    self.mapView.superview.transform = CGAffineTransformIdentity;
}


-(void)finishAnimateOutInspectionForm
{
    self.inspectionVC = nil;
    self.currentInspectionPopup = nil;
    self.currentFeatureToInspectPopup = nil;
    [self removeInspectionForm];
}

#pragma mark -
#pragma mark Internal Synchronization Methods

-(void)setCurrentSyncIndexAndUpdateForStatus:(BOOL)status
{
    [self.syncStatuses setObject:[NSNumber numberWithBool:status] forKey:[NSNumber numberWithInt:_inspectionIndex++]];
}


-(void)syncNextInspection
{
    if (!self.inspectionsToSync)
        return;
    
    if (_inspectionIndex == self.inspectionsToSync.count) {
        [self finalizeSynchronizations];
    }
    else {
        
        _isSyncing = YES;
        
        self.inspectionLayer.editingDelegate = self;
        
        AGSPopup *currentInspection = [self.inspectionsToSync objectAtIndex:_inspectionIndex];
        
        currentInspection.graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine]simplifyGeometry:currentInspection.graphic.geometry];
        currentInspection.graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine]normalizeCentralMeridianOfGeometry:currentInspection.graphic.geometry];
        
        int oid = [self.inspectionLayer objectIdForFeature:currentInspection.graphic];
        
        //updating should probably never happen...
        if (oid > 0){
            // post updates
            [self.inspectionLayer updateFeatures:[NSArray arrayWithObject:currentInspection.graphic]];
        }
        else {
            // add feature
            [self.inspectionLayer addFeatures:[NSArray arrayWithObject:currentInspection.graphic]];
        }
    }
}

//Finalize. Make sure everything synced. If it didn't, update inspections array, update status message, etc.
-(void)finalizeSynchronizations
{
    _isSyncing = NO;
    
    NSMutableArray *unsuccessfulEdits = [NSMutableArray arrayWithCapacity:self.inspectionsToSync.count];
    
    for(int i = 0; i< self.inspectionsToSync.count; i++)
    {
        BOOL success = [[self.syncStatuses objectForKey:[NSNumber numberWithInt:i]] boolValue];
        //fail!
        if(!success)
        {
            [unsuccessfulEdits addObject:[self.inspectionsToSync objectAtIndex:i]];
        }
    }
   
    if (unsuccessfulEdits.count == 0) {
        
        self.syncCheckImageView.image = [UIImage imageNamed:@"green_check_mark.png"];
        self.syncCheckImageView.hidden = NO;
        
        self.inspectionsToSync = nil;
        
        if(kShowSyncLabelOnTop)
        {
            
            [self.syncButton setTitle:@"Sync Complete" forState:UIControlStateNormal];
            
            //set off a timer to kill message in a few seconds
            [NSTimer scheduledTimerWithTimeInterval:kSyncTimerLength 
                                             target:self 
                                           selector:@selector(hideSyncButtonAfterTimerFinished) 
                                           userInfo:nil 
                                            repeats:NO];
        }
        
    }
    else {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                        message:@"Some features unable to synchronize" 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
        [alert show];
        
        self.inspectionsToSync = unsuccessfulEdits;
        
        if (kShowSyncLabelOnTop) {
            [self.syncButton setTitle:[NSString stringWithFormat:@"%d inspection%@ to sync", self.inspectionsToSync.count, (self.inspectionsToSync.count == 1) ? @"" : @"s"] forState:UIControlStateNormal];
        }
        
        self.syncDataLabel.text = [NSString stringWithFormat:@"Synchronize my %d inspection%@", self.inspectionsToSync.count, (self.inspectionsToSync.count == 1) ? @"" : @"s"];
    }             
}

#pragma mark -
#pragma mark Apple Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.downloadDataView = nil;
    self.startInspectionView = nil;
    self.mapView = nil;
    self.clip = nil;
    self.clipboard = nil;
    self.downloadImageView = nil;
    self.startInspectionImageView = nil;
    self.activityIndicator = nil;
    self.syncButton = nil;
    self.connectivityImageView = nil;
    self.downloadCheckImageView = nil;
    self.syncDataView = nil;
    self.syncDataImageView = nil;
    self.syncDataLabel = nil;
}




@end
