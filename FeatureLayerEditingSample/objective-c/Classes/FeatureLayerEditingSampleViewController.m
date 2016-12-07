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
@synthesize sketchEditor = _sketchEditor;
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
    if([self isIPad])
        self.featureTemplatePickerViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    //Animate vertically on both iPhone & iPad
    self.featureTemplatePickerViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    //Present
    [self presentViewController:self.featureTemplatePickerViewController animated:YES completion:nil];
}

-(void)sketchComplete{
    self.navigationItem.rightBarButtonItem = self.pickTemplateButton;
    [self presentViewController:self.popupVC animated:YES completion:nil];
    self.mapView.sketchEditor = nil;
    self.bannerView.hidden = YES;

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
	self.mapView.touchDelegate = self;
    self.mapView.callout.delegate = self;
    self.mapView.interactionOptions.magnifierEnabled = YES;
	
    AGSPortal *portal = [AGSPortal ArcGISOnlineWithLoginRequired:NO];
    AGSPortalItem *item = [AGSPortalItem portalItemWithPortal:portal itemID:@"b31153c71c6c429a8b24c1751a50d3ad"];
    self.webmap = [AGSMap mapWithItem:item];
    //designate a delegate to be notified as web map is opened
    self.mapView.map = self.webmap;
    
    __weak __typeof(self) weakSelf = self;
    self.mapView.layerViewStateChangedHandler = ^(AGSLayer *layer, AGSLayerViewState *layerViewState){
        if (layerViewState.status == AGSLayerViewStatusActive) {
            [weakSelf layerDidLoad:layer];
        }
        else if (layerViewState.status == AGSLayerViewStatusError) {
            [weakSelf layer:layer didFailToLoadWithError:layerViewState.error];
        }
    };
    
    [self.webmap loadWithCompletion:^(NSError * _Nullable error) {
        [self mapDidLoad];
    }];
    
    [super viewDidLoad];
}

#pragma mark - geoView touch delegate methods

-(void)geoView:(AGSGeoView *)geoView didTapAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {
    //Show popups for features that were tapped on
    if (self.mapView.callout.hidden) {
        self.popup = nil;
        __weak __typeof(self) weakSelf = self;
        [self.mapView identifyLayersAtScreenPoint:screenPoint
                                        tolerance:10
                                 returnPopupsOnly:YES
                           maximumResultsPerLayer:1
                                       completion:^(NSArray<AGSIdentifyLayerResult *> * _Nullable identifyResults, NSError * _Nullable error) {
            NSMutableArray *popups = [NSMutableArray array];
            for (AGSIdentifyLayerResult *result in identifyResults) {
                [popups addObjectsFromArray:result.popups];
                for (AGSIdentifyLayerResult *sublayerResults in result.sublayerResults) {
                    [popups addObjectsFromArray:sublayerResults.popups];
                }
            }
                                           
                                           
            if (popups.count > 0) {
                self.popup = popups[0];
                
                weakSelf.mapView.callout.title = self.popup.title;
                [weakSelf.mapView.callout showCalloutAt:mapPoint screenOffset:CGPointZero rotateOffsetWithMap:NO animated:YES];
            }
        }];
    }
    else {  //hide the callout
        [self.mapView.callout dismiss];
    }
}

#pragma mark - layer/map handler methods

-(void)layerDidLoad:(AGSLayer *)layer{
    
    //The last feature layer we encounter we will use for editing features
    //If the web map contains more than one feature layer, the sample may need to be modified to handle that
    if([layer isKindOfClass:[AGSFeatureLayer class]]){
        self.activeFeatureLayer = (AGSFeatureLayer*)layer;
        
        //Add templates from this layer to the Feature Template Picker
        [self.featureTemplatePickerViewController addTemplatesFromLayer:self.activeFeatureLayer];
    }
}

- (void)mapDidLoad {
    //register self for receiving notifications from the sketch layer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToGeomChanged:) name:AGSSketchEditorGeometryDidChangeNotification object:nil];
}

-(void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error{
    NSLog(@"Failed to load layer : %@", layer.name);
    NSLog(@"Sample may not work as expected");
}



#pragma mark -
#pragma mark AGSSketchEditorGeometryDidChangeNotification notifications
- (void)respondToGeomChanged: (NSNotification*) notification {
    //Check if the sketch geometry is valid to decide whether to enable
    //the sketchCompleteButton
    if(self.sketchEditor.sketchValid && ![self.sketchEditor.geometry isEmpty])
        self.sketchCompleteButton.enabled   = YES;

}


#pragma mark - FeatureTemplatePickerDelegate methods

-(void)featureTemplatePickerViewControllerWasDismissed: (FeatureTemplatePickerViewController*) featureTemplatePickerViewController{
       [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)featureTemplatePickerViewController:(FeatureTemplatePickerViewController *)featureTemplatePickerViewController didSelectFeatureTemplate:(AGSFeatureTemplate *)template forTable:(AGSArcGISFeatureTable *)table{
    
    //create a new feature based on the template
    _newFeature = [table createFeatureWithTemplate:template];
    
    AGSPopup *popup = [AGSPopup popupWithGeoElement:_newFeature popupDefinition:table.featureLayer.popupDefinition];
    
    //Iniitalize a popup view controller
    self.popupVC = [AGSPopupsViewController popupsViewControllerWithPopups:@[popup] containerStyle:AGSPopupsViewControllerContainerStyleNavigationBar];
    self.popupVC.delegate = self;
    
    //Only for iPad, set presentation style to Form sheet 
    //We don't want it to cover the entire screen
    if([self isIPad])
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

- (void)didTapAccessoryButtonForCallout:(AGSCallout *)callout {
    
    self.popupVC = [AGSPopupsViewController popupsViewControllerWithPopups:@[self.popup] containerStyle:AGSPopupsViewControllerContainerStyleNavigationBar];
    self.popupVC.delegate = self;
    self.popupVC.modalTransitionStyle =  UIModalTransitionStyleFlipHorizontal;
    //If iPad, use a modal presentation style
    if([self isIPad])
        self.popupVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:self.popupVC animated:YES completion:nil];

}



#pragma mark -  AGSPopupsViewControllerDelegate methods

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
    
    [self dismissViewControllerAnimated:YES completion:nil];
    self.mapView.sketchEditor = self.sketchEditor; //activate the sketch layer
    self.bannerView.hidden = NO;
    self.mapView.callout.hidden = YES;
    
    //zoom to the existing feature's geometry
    AGSEnvelope* env = popup.geoElement.geometry.extent;
    AGSEnvelopeBuilder *builder = [env toBuilder];
    [builder expandByFactor:1.4];
    env = [builder toGeometry];
    
    [self.mapView setViewpointGeometry:env completion:nil];

    self.navigationItem.rightBarButtonItem = self.sketchCompleteButton;
    self.sketchCompleteButton.enabled = NO;
}

-(BOOL)popupsViewController:(AGSPopupsViewController *)popupsViewController wantsToDeleteForPopup:(AGSPopup *)popup {
    return YES;
}

-(void)popupsViewController:(AGSPopupsViewController *)popupsViewController didDeleteForPopup:(AGSPopup *)popup {
    AGSFeature *feature = (AGSFeature *)popup.geoElement;
    AGSServiceFeatureTable *fst = (AGSServiceFeatureTable *)feature.featureTable;
    [fst applyEditsWithCompletion:^(NSArray<AGSFeatureEditResult *> * result, NSError *error) {
        [self.loadingView removeView];
        if(error){
            UIAlertView* av = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Could not apply edit to server." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [av show];
            NSLog(@"%@", [NSString stringWithFormat:@"Error while applying edit : %@",[error localizedDescription]]);
        }else{
            for (AGSFeatureEditResult* featureEditResult in result) {
                if (featureEditResult.completedWithErrors) {
                    NSLog(@"%@", [NSString stringWithFormat:@"Deleting feature(OBJECTID = %lld) rejected by server because : %@",featureEditResult.objectID, [featureEditResult.error localizedDescription]]);
                }
            }
            
            NSLog(@"feature deleted in server");
            self.mapView.sketchEditor = nil;
            self.mapView.callout.hidden = YES;
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    self.loadingView = [LoadingView loadingViewInView:self.popupVC.view withText:@"Deleting feature..."];
}

-(void)popupsViewController:(AGSPopupsViewController *)popupsViewController didFinishEditingForPopup:(AGSPopup *)popup {
	// simplify the geometry, this will take care of self intersecting polygons and
	popup.geoElement.geometry = [AGSGeometryEngine simplifyGeometry:popup.geoElement.geometry];
    //normalize the geometry, this will take care of geometries that extend beyone the dateline 
    //(ifwraparound was enabled on the map)
	popup.geoElement.geometry = [AGSGeometryEngine normalizeCentralMeridianOfGeometry:popup.geoElement.geometry];
	
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
            }
            
            //Dismiss the popups VC. All edits have been applied.
            self.mapView.sketchEditor = nil;
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        
    }];
    
    //Tell the user edits are being saved in the background
    self.loadingView = [LoadingView loadingViewInView:self.popupVC.view withText:@"Saving feature details..."];

    //attachments were handled in `applyEditsWithCompetion`, above, so no need to handle them separately.
}

-(void)popupsViewControllerDidFinishViewingPopups:(AGSPopupsViewController *)popupsViewController {
    //dismiss the popups view controller
    self.mapView.sketchEditor = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    self.popupVC = nil;
}

-(void)popupsViewController:(AGSPopupsViewController *)popupsViewController didCancelEditingForPopup:(AGSPopup *)popup {
    //dismiss the popups view controller
    self.mapView.sketchEditor = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
    
    //reset any sketch related changes we made to our main view controller
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

//These methods and delegate have been removed; the same functionality now resides in the
//AGSServiceFeatureTable:applyEditsWithCompletion: method which gets called from the
//AGSPopupsViewControllerDelegate delgate method: popupsViewController:didFinishEditingForPopup:



#pragma mark -
#pragma mark AGSAttachmentManagerDelegate

//This methods and delegate have been removed; the same functionality now resides in the
//AGSServiceFeatureTable:applyEditsWithCompletion: method which gets called from the
//AGSPopupsViewControllerDelegate delgate method: popupsViewController:didFinishEditingForPopup:



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

-(BOOL)isIPad {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}

@end
