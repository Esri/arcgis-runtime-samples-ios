
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


#import "PopupSampleViewController.h"


@interface PopupSampleViewController() 

@property (nonatomic, strong) AGSPortalItem *portalItem;
@property (nonatomic, strong) NSString *webMapId;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) AGSPopupsViewController *popupVC;


@end

@implementation PopupSampleViewController 


#pragma mark - View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Release any retained subviews of the main view.
- (void)viewDidUnload
{
    self.portalItem = nil;
    self.mapView = nil;
    self.webMapId = nil;
    self.popupVC = nil;
    self.activityIndicator = nil;
    
    [super viewDidUnload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
      
    self.webMapId = @"9ade9e5c9a2042178ec3128d6d922bbf";
    // create a map with portal item
    AGSPortal *portal = [AGSPortal ArcGISOnlineWithLoginRequired:NO];
    self.portalItem = [AGSPortalItem portalItemWithPortal:portal itemID:self.webMapId];
    [self.portalItem loadWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            // If the portal item failed to load report an error
            NSLog(@"Error while loading webMap: %@",[error localizedDescription]);
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                         message:@"Failed to load the portal item"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [av show];
        }
    }];
    
    self.mapView.map = [AGSMap mapWithItem:self.portalItem];
    self.mapView.callout.delegate = self;
    self.mapView.touchDelegate = self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - AGSMapViewTouchDelegate methods

- (void)geoView:(AGSGeoView *)geoView didTapAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint {
    __weak __typeof(self) weakSelf = self;
    [self.mapView identifyLayersAtScreenPoint:screenPoint tolerance:5 returnPopupsOnly:YES maximumResultsPerLayer:10 completion:^(NSArray<AGSIdentifyLayerResult *> * _Nullable identifyResults, NSError * _Nullable error) {
        if (!error) {
            NSMutableArray *popups = [NSMutableArray array];
            for (AGSIdentifyLayerResult *result in identifyResults) {
                [popups addObjectsFromArray:result.popups];
            }
            [weakSelf showPopups:popups];
        }
    }];
    
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.mapView.callout.customView = self.activityIndicator;
    [self.activityIndicator startAnimating];
    [self.mapView.callout showCalloutAt:mapPoint screenOffset:CGPointZero rotateOffsetWithMap:YES animated:YES];
    self.popupVC = nil;
}

#pragma mark - AGSCallout methods

- (void)didTapAccessoryButtonForCallout:(AGSCallout *)callout {
    [self presentViewController:self.popupVC animated:YES completion:nil];
}

#pragma mark - Handle Identify Result

- (void)showPopups:(NSArray *)popups {
    // If we've found one or more popups
    if (popups.count > 0) {
        
        if(!self.popupVC){
            //Create a popupsContainer view controller with the popups
            self.popupVC = [AGSPopupsViewController popupsViewControllerWithPopups:popups];
            self.popupVC.delegate = self;
        }else{
            [self.popupVC showAdditionalPopups:popups];
        }
        
        // For iPad, display popup view controller in the callout
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {

            self.mapView.callout.customView = self.popupVC.view;
            
            //set the modal presentation options for subsequent popup view transitions
            self.popupVC.modalPresenter =  self.view.window.rootViewController;
            self.popupVC.modalPresentationStyle = UIModalPresentationFormSheet;

            
            // Start the activity indicator in the upper right corner of the
            // popupsContainer view controller while we wait for the query results
            self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            UIBarButtonItem *blankButton = [[UIBarButtonItem alloc] initWithCustomView:(UIView*)self.activityIndicator];
            self.popupVC.customActionButton = blankButton;
            [self.activityIndicator startAnimating];
        }
        else {
            //For iphone, display summary info in the callout
            self.mapView.callout.title = [NSString stringWithFormat:@"%lu Results", (unsigned long)self.popupVC.popups.count];
            self.mapView.callout.accessoryButtonHidden = NO;
            self.mapView.callout.detail = @"loading more...";
            self.mapView.callout.customView = nil;
        }
    }
    else {
        if(self.popupVC){
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
                [self.activityIndicator stopAnimating];
                self.popupVC.customActionButton = self.popupVC.actionButton;
            }
            else {
                self.mapView.callout.detail = @"";
            }
        }
        else {
            [self.activityIndicator stopAnimating];
            self.mapView.callout.customView = nil;
            self.mapView.callout.accessoryButtonHidden = YES;
            self.mapView.callout.title = @"No Results";
            self.mapView.callout.detail = @"";
            
        }
    }
}

#pragma mark - AGSPopupsContainerDelegate methods
- (void)popupsViewControllerDidFinishViewingPopups:(AGSPopupsViewController *)popupsViewController {
    
    // If we are on iPad dismiss the callout
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        self.mapView.callout.hidden = YES;
    else
        //dismiss the modal viewcontroller for iPhone
      [self dismissViewControllerAnimated:YES completion:nil];
    
}


#pragma mark - AGSPopupsContainerDelegate edit methods

- (void)popupsViewController:(AGSPopupsViewController *)popupsViewController readyToEditGeometryWithSketchEditor:(AGSSketchEditor *)sketchEditor forPopup:(AGSPopup *)popup {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not implement editing or deleting features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
}

- (void)popupsViewController:(AGSPopupsViewController *)popupsViewController didFinishEditingForPopup:(AGSPopup *)popup {
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not implement editing or deleting features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
}

- (void)popupsViewController:(AGSPopupsViewController *)popupsViewController didStartEditingForPopup:(AGSPopup *)popup {

    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not allow you to edit or delete features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
}





@end
