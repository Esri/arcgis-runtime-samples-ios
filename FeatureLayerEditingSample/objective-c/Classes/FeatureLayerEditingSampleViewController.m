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

#import "FeatureLayerEditingSampleViewController.h"
#define kFeatureTemplatePickerViewController @"FeatureTemplatePickerViewController"


@implementation FeatureLayerEditingSampleViewController
@synthesize mapView = _mapView;
@synthesize activeFeatureLayer = _featureLayer;
@synthesize webmap = _webmap;
@synthesize popupVC = _popupVC;
@synthesize featureTemplatePickerViewController = _featureTemplatePickerViewController;
@synthesize sketchLayer = _sketchLayer;
@synthesize bannerView = _bannerView;
@synthesize alertView = _alertView;
@synthesize loadingView = _loadingView;
@synthesize sketchCompleteButton = _sketchCompleteButton;
@synthesize pickTemplateButton = _pickTemplateButton;

#pragma mark - Handlers for Navigation Bar buttons


// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return NO;
}

-(void)presentFeatureTemplatePicker{
    //Only for iPad, set presentation style to Form sheet 
    //We don't want it to cover the entire screen
    if([[AGSDevice currentDevice] isIPad])
        self.featureTemplatePickerViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    //Animate vertically on both iPhone & iPad
    self.featureTemplatePickerViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    //Present
    [self presentViewController:self.featureTemplatePickerViewController animated:YES completion:nil];
}

-(void)sketchComplete{
    self.navigationItem.rightBarButtonItem = self.pickTemplateButton;
    [self presentViewController:self.popupVC animated:YES completion:nil];
    self.mapView.touchDelegate = self;
    self.bannerView.hidden = YES;
    self.mapView.allowCallout = YES;

}


#pragma mark -  UIView methods

- (void)viewDidLoad {
    
    //initialize the navigation bar buttons
	self.pickTemplateButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(presentFeatureTemplatePicker)];
    self.sketchCompleteButton = [[UIBarButtonItem alloc]initWithTitle:@"Sketch Done" style:UIBarButtonItemStylePlain target:self action:@selector(sketchComplete)];
    
    //Display the pickTemplateButton initially so that user can start collecting a new feature
    self.navigationItem.rightBarButtonItem = self.pickTemplateButton;
    
    //Initialize the feature template picker so that we can show it later when needed
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    self.featureTemplatePickerViewController = [storyboard instantiateViewControllerWithIdentifier:kFeatureTemplatePickerViewController];
    self.featureTemplatePickerViewController.delegate = self;


    //Set up the map view
	self.mapView.layerDelegate = self;
	self.mapView.touchDelegate = self;
    self.mapView.callout.delegate = self;
    self.mapView.showMagnifierOnTapAndHold = YES;
	
    self.webmap = [AGSWebMap webMapWithItemId:@"b31153c71c6c429a8b24c1751a50d3ad" credential:nil];
    //designate a delegate to be notified as web map is opened
    self.webmap.delegate = self;
    [self.webmap openIntoMapView:self.mapView];
	
    [super viewDidLoad];
}


#pragma mark - AGSWebMapDelegate methods


- (void) webMap:(AGSWebMap *) 	webMap
   didLoadLayer:(AGSLayer *) 	layer  {
    
    //The last feature layer we encounter we will use for editing features
    //If the web map contains more than one feature layer, the sample may need to be modified to handle that
    if([layer isKindOfClass:[AGSFeatureLayer class]]){
        AGSFeatureLayer* featureLayer = (AGSFeatureLayer*)layer;
        
        //set the feature layer as its calloutDelegate 
        //this will then automatically set the callout's title to a value
        //from the display field of the feature service
        featureLayer.calloutDelegate = featureLayer;
        
        //Get all the fields
        featureLayer.outFields = [NSArray arrayWithObject:@"*"];

        //This view controller should be notified when features are edited
        featureLayer.editingDelegate = self;
        
        //Add templates from this layer to the Feature Template Picker
        [self.featureTemplatePickerViewController addTemplatesFromLayer:featureLayer];
    }
}

- (void)didOpenWebMap:(AGSWebMap *) webMap intoMapView:(AGSMapView *) mapView {
    //Once all the layers in the web map are loaded
    //we will add a dormant sketch layer on top. We will activate the sketch layer when the time is right.
    self.sketchLayer = [[AGSSketchGraphicsLayer alloc] init];
    [self.mapView addMapLayer:self.sketchLayer withName:@"Sketch Layer"];
    //register self for receiving notifications from the sketch layer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchGraphicsLayerGeometryDidChangeNotification object:nil];
}

- (void) webMap:(AGSWebMap *) 	webMap
didFailToLoadLayer:(AGSWebMapLayerInfo *) 	layerInfo
      baseLayer:(BOOL) 	baseLayer
      federated:(BOOL) 	federated
      withError:(NSError *) 	error  {
    NSLog(@"Failed to load layer : %@", layerInfo.title);
    NSLog(@"Sample may not work as expected");

    //continue anyway
    [self.webmap continueOpenAndSkipCurrentLayer];
}



#pragma mark -
#pragma mark AGSSketchGraphicsLayer notifications
- (void)respondToGeomChanged: (NSNotification*) notification {
    //Check if the sketch geometry is valid to decide whether to enable
    //the sketchCompleteButton
    if([self.sketchLayer.geometry isValid] && ![self.sketchLayer.geometry isEmpty])
        self.sketchCompleteButton.enabled   = YES;

}


#pragma mark - FeatureTemplatePickerDelegate methods

-(void)featureTemplatePickerViewControllerWasDismissed: (FeatureTemplatePickerViewController*) featureTemplatePickerViewController{
       [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)featureTemplatePickerViewController:(FeatureTemplatePickerViewController*) featureTemplatePickerViewController didSelectFeatureTemplate:(AGSFeatureTemplate*)template forFeatureLayer:(AGSFeatureLayer*)featureLayer{
    
    //set the active feature layer to the one we are going to edit
    self.activeFeatureLayer = featureLayer;
    
    //create a new feature based on the template
    _newFeature = [self.activeFeatureLayer featureWithTemplate:template];
    
    //Add the new feature to the feature layer's graphic collection
    //This is important because then the popup view controller will be able to 
    //find the feature layer associated with the graphic and inspect the field metadata
    //such as domains, subtypes, data type, length, etc
    //Also note, if the user cancels before saving the new feature to the server, 
    //we will manually need to remove this
    //feature from the feature layer (see implementation for popupsContainer:didCancelEditingGraphicForPopup: below)
    [self.activeFeatureLayer addGraphic:_newFeature];
    
    //Iniitalize a popup view controller
    self.popupVC = [[AGSPopupsContainerViewController alloc] initWithWebMap:self.webmap forFeature:_newFeature usingNavigationControllerStack:NO];
    self.popupVC.delegate = self;
    
    //Only for iPad, set presentation style to Form sheet 
    //We don't want it to cover the entire screen
    if([[AGSDevice currentDevice] isIPad])
        self.popupVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    //Animate by flipping horizontally
    self.popupVC.modalTransitionStyle =  UIModalTransitionStyleFlipHorizontal;
    
    //First, dismiss the Feature Template Picker
       [self dismissViewControllerAnimated:NO completion:nil];
    
    //Next, Present the popup view controller
    [self presentViewController:self.popupVC animated:YES completion:^{
        //and put it in edit mode to start capturing feature details
        [self.popupVC startEditingCurrentPopup];
    }];
    
    
}

#pragma mark - AGSCalloutDelegate methods

- (void) didClickAccessoryButtonForCallout:		(AGSCallout *) 	callout {
    
    AGSGraphic* graphic = (AGSGraphic*)callout.representedObject;
    self.activeFeatureLayer = (AGSFeatureLayer*) graphic.layer;
    //Show popup for the graphic because the user tapped on the callout accessory button
    self.popupVC = [[AGSPopupsContainerViewController alloc] initWithWebMap:self.webmap forFeature:graphic usingNavigationControllerStack:NO];
    self.popupVC.delegate = self;
    self.popupVC.modalTransitionStyle =  UIModalTransitionStyleFlipHorizontal;
    //If iPad, use a modal presentation style
    if([[AGSDevice currentDevice] isIPad])
        self.popupVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:self.popupVC animated:YES completion:nil];

}



#pragma mark -  AGSPopupsContainerDelegate methods

- (AGSGeometry *)popupsContainer:(id) popupsContainer wantsNewMutableGeometryForPopup:(AGSPopup *) popup {
    //Return an empty mutable geometry of the type that our feature layer uses
    return AGSMutableGeometryFromType( ((AGSFeatureLayer*)popup.graphic.layer).geometryType, self.mapView.spatialReference);
}

- (void)popupsContainer:(id) popupsContainer readyToEditGeometry:(AGSGeometry *) geometry forPopup:(AGSPopup *) popup{
    //Dismiss the popup view controller
    [self dismissViewControllerAnimated:YES completion:nil];
    
    //Prepare the current view controller for sketch mode
    self.bannerView.hidden = NO;
    self.mapView.touchDelegate = self.sketchLayer; //activate the sketch layer
    self.mapView.callout.hidden = YES;

    //Dont show callout when the sketch layer is active.
    //The user is sketching and even if he taps on a feature,
    //we don't want to display the callout and interfere with the sketching workflow
    self.mapView.allowCallout = NO;
    
    //Assign the sketch layer the geometry that is being passed to us for 
    //the active popup's graphic. This is the starting point of the sketch
    self.sketchLayer.geometry = geometry;
    
    
    //zoom to the existing feature's geometry
    AGSEnvelope* env = nil;
    AGSGeometryType geoType = AGSGeometryTypeForGeometry(self.sketchLayer.geometry);
    if(geoType == AGSGeometryTypePolygon){
        env = ((AGSPolygon*)self.sketchLayer.geometry).envelope;
    }else if(geoType == AGSGeometryTypePolyline){
        env = ((AGSPolyline*)self.sketchLayer.geometry).envelope ;
    }
    
    if(env!=nil){
        AGSMutableEnvelope* mutableEnv  = [env mutableCopy];
        [mutableEnv expandByFactor:1.4];
        [self.mapView zoomToEnvelope:mutableEnv animated:YES];
    }
    
    //replace the button in the navigation bar to allow a user to 
    //indicate that the sketch is done
	self.navigationItem.rightBarButtonItem = self.sketchCompleteButton;
    self.sketchCompleteButton.enabled = NO;
}

- (void)popupsContainer:(id<AGSPopupsContainer>) popupsContainer wantsToDeleteForPopup:(AGSPopup *) popup {
    //Call method on feature layer to delete the feature
    NSNumber* number = [NSNumber numberWithInteger: [self.activeFeatureLayer objectIdForFeature:popup.graphic]];
    NSArray* oids = [NSArray arrayWithObject: number ];
    [self.activeFeatureLayer deleteFeaturesWithObjectIds:oids ];
    self.loadingView = [LoadingView loadingViewInView:self.popupVC.view withText:@"Deleting feature..."];

}

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer didFinishEditingForPopup:(AGSPopup*)popup{
	// simplify the geometry, this will take care of self intersecting polygons and 
	popup.graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine]simplifyGeometry:popup.graphic.geometry];
    //normalize the geometry, this will take care of geometries that extend beyone the dateline 
    //(ifwraparound was enabled on the map)
	popup.graphic.geometry = [[AGSGeometryEngine defaultGeometryEngine]normalizeCentralMeridianOfGeometry:popup.graphic.geometry];
	
    
	long long oid = [self.activeFeatureLayer objectIdForFeature:popup.graphic];
	
	if (oid > 0){
		//feature has a valid objectid, this means it exists on the server
        //and we simply update the exisiting feature
		[self.activeFeatureLayer updateFeatures:[NSArray arrayWithObject:popup.graphic]];
	} else {
		//objectid does not exist, this means we need to add it as a new feature
		[self.activeFeatureLayer addFeatures:[NSArray arrayWithObject:popup.graphic]];
	}
    
    //Tell the user edits are being saved int the background
    self.loadingView = [LoadingView loadingViewInView:self.popupVC.view withText:@"Saving feature details..."];

    //we will wait to post attachments till when the updates succeed
}

- (void)popupsContainerDidFinishViewingPopups:(id) popupsContainer {
    //dismiss the popups view controller
    [self dismissViewControllerAnimated:YES completion:nil];
    self.popupVC = nil;
}

- (void)popupsContainer:(id) popupsContainer didCancelEditingForPopup:(AGSPopup *) popup {
    //dismiss the popups view controller
    [self dismissViewControllerAnimated:YES completion:nil];

    //if we had begun adding a new feature, remove it from the layer because the user hit cancel.
    if(_newFeature!=nil){
        [self.activeFeatureLayer removeGraphic:_newFeature];
        _newFeature = nil;
    }
    
    //reset any sketch related changes we made to our main view controller
    [self.sketchLayer clear];
    self.mapView.touchDelegate = self;
    self.mapView.callout.delegate = self;
    self.bannerView.hidden = YES;
    self.popupVC = nil;
}

#pragma mark - 
- (void) warnUserOfErrorWithMessage:(NSString*) message {
    //Display an alert to the user  
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [self.alertView show];
    
    //Restart editing the popup so that the user can attempt to save again
    [self.popupVC startEditingCurrentPopup];
}

#pragma mark - AGSFeatureLayerEditingDelegate methods

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFeatureEditsWithResults:(AGSFeatureLayerEditResults *)editResults{
    
    //Remove the activity indicator
    [self.loadingView removeView];
    
    //We will assume we have to update the attachments unless
    //1) We were adding a feature and it failed
    //2) We were updating a feature and it failed
    //3) We were deleting a feature
    BOOL _updateAttachments = YES;
    
    if([editResults.addResults count]>0){
        //we were adding a new feature
        AGSEditResult* result = (AGSEditResult*)[editResults.addResults objectAtIndex:0];
        if(!result.success){
            //Add operation failed. We will not update attachments
            _updateAttachments = NO;
            //Inform user
            [self warnUserOfErrorWithMessage:@"Could not add feature. Please try again"];
        }
        
    }else if([editResults.updateResults count]>0){
        //we were updating a feature
        AGSEditResult* result = (AGSEditResult*)[editResults.updateResults objectAtIndex:0];
        if(!result.success){
            //Update operation failed. We will not update attachments
            _updateAttachments = NO;
            //Inform user
            [self warnUserOfErrorWithMessage:@"Could not update feature. Please try again"];
        }
    }else if([editResults.deleteResults count]>0){
        //we were deleting a feature
        _updateAttachments = NO;
        AGSEditResult* result = (AGSEditResult*)[editResults.deleteResults objectAtIndex:0];
        if(!result.success){
            //Delete operation failed. Inform user
            [self warnUserOfErrorWithMessage:@"Could not delete feature. Please try again"];
        }else{
            //Delete operation succeeded
            //Dismiss the popup view controller and hide the callout which may have been shown for
            //the deleted feature.
            self.mapView.callout.hidden = YES;
            [self dismissViewControllerAnimated:YES completion:nil];
            self.popupVC = nil;
        }

    }
    
    //if edits pertaining to the feature were successful...
    if (_updateAttachments){
        
        [self.sketchLayer clear];

        //...we post edits to the attachments 
		AGSAttachmentManager *attMgr = [featureLayer attachmentManagerForFeature:self.popupVC.currentPopup.graphic];
		attMgr.delegate = self;
        
        if([attMgr hasLocalEdits]){
			[attMgr postLocalEditsToServer];
            self.loadingView = [LoadingView loadingViewInView:self.popupVC.view withText:@"Saving feature attachments..."];
        }
        
        
        
        
	}

    
}

-(void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFailFeatureEditsWithError:(NSError *)error{
    NSLog(@"Could not commit edits because: %@", [error localizedDescription]);

    [self.loadingView removeView];
    [self warnUserOfErrorWithMessage:@"Could not save edits. Please try again"];
}



#pragma mark -
#pragma mark AGSAttachmentManagerDelegate

-(void)attachmentManager:(AGSAttachmentManager *)attachmentManager didPostLocalEditsToServer:(NSArray *)attachmentsPosted{
    
    [self.loadingView removeView];
    
    //loop through all attachments looking for failures
    BOOL _anyFailure = NO;
    for (AGSAttachment* attachment in attachmentsPosted) {
        if(attachment.networkError!=nil || attachment.editResultError!=nil){
            _anyFailure = YES;
            NSString* reason = nil;
            if(attachment.networkError!=nil)
                reason = [attachment.networkError localizedDescription];
            else if(attachment.editResultError !=nil)
                reason = attachment.editResultError.errorDescription;
            NSLog(@"Attachment '%@' could not be synced with server because %@",attachment.attachmentInfo.name,reason);
        }
    }
    
    if(_anyFailure){
        [self warnUserOfErrorWithMessage:@"Some attachment edits could not be synced with the server. Please try again"];
    }
}



#pragma mark -
/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    
}


@end
