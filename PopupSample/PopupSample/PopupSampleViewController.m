
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

@property (nonatomic, strong) AGSWebMap *webMap;
@property (nonatomic, strong) NSString *webMapId;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) AGSPopupsContainerViewController *popupVC;


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
    self.webMap = nil;
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
    // Create a webmap and open it into the map
    self.webMap = [AGSWebMap webMapWithItemId:self.webMapId credential:nil];
    self.webMap.delegate = self;
    [self.webMap openIntoMapView:self.mapView];
    
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

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint features:(NSDictionary *)features{


    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    AGSPolygon *buffer = [geometryEngine bufferGeometry:mappoint byDistance:(10 *mapView.resolution)];
    BOOL willFetch = [self.webMap fetchPopupsForExtent:buffer.envelope];
    if(!willFetch){
        NSLog(@"Sorry, try again");
    }else{
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.mapView.callout.customView = self.activityIndicator;
        [self.activityIndicator startAnimating];
        [self.mapView.callout showCalloutAt:mappoint screenOffset:CGPointZero animated:YES];
    }
    self.popupVC = nil;

}

#pragma mark - AGSCallout methods

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) 	callout {
    [self presentViewController:self.popupVC animated:YES completion:nil];
}

#pragma mark - AGSWebMapDelegate methods
- (void) didOpenWebMap:(AGSWebMap *)webMap intoMapView:(AGSMapView *)mapView {
    if(![webMap hasPopupsDefined]){
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@""
                                                     message:@"This webmap does not have any popups"
                                                    delegate:self
                                           cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
    }
}

- (void) webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error {
    
    // If the web map failed to load report an error
    NSLog(@"Error while loading webMap: %@",[error localizedDescription]);
    
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                 message:@"Failed to load the webmap"
                                                delegate:self
                                       cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
}




-(void)didFailToLoadLayer:(NSString*)layerTitle url:(NSURL*)url baseLayer:(BOOL)baseLayer withError:(NSError*)error{
    
    NSLog(@"Error while loading layer: %@",[error localizedDescription]);
    
    // If we have an error loading the layer report an error
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error"
                                                 message:[NSString stringWithFormat:@"The layer %@ cannot be displayed",layerTitle]
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
    
    
    
    // skip loading this layer
    [self.webMap continueOpenAndSkipCurrentLayer];
    
}

- (void)webMap:(AGSWebMap *)webMap
didFetchPopups:(NSArray *)popups
     forExtent:(AGSEnvelope *)extent{
    // If we've found one or more popups
    if (popups.count > 0) {
        
        if(!self.popupVC){
            //Create a popupsContainer view controller with the popups
            self.popupVC = [[AGSPopupsContainerViewController alloc] initWithPopups:popups usingNavigationControllerStack:false];
            self.popupVC.style = AGSPopupsContainerStyleBlack;
            self.popupVC.delegate = self;
        }else{
            [self.popupVC showAdditionalPopups:popups];
        }
        
        // For iPad, display popup view controller in the callout
        if ([[AGSDevice currentDevice] isIPad]) {

            self.mapView.callout.customView = self.popupVC.view;
            
            //set the modal presentation options for subsequent popup view transitions
            self.popupVC.modalPresenter =  self.view.window.rootViewController;
            self.popupVC.modalPresentationStyle = UIModalPresentationFormSheet;

            
            // Start the activity indicator in the upper right corner of the
            // popupsContainer view controller while we wait for the query results
            self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            UIBarButtonItem *blankButton = [[UIBarButtonItem alloc] initWithCustomView:(UIView*)self.activityIndicator];
            self.popupVC.actionButton = blankButton;
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
}

- (void) webMap:(AGSWebMap *)webMap didFinishFetchingPopupsForExtent:(AGSEnvelope *)extent{
    if(self.popupVC){
        if ([[AGSDevice currentDevice] isIPad]){
            [self.activityIndicator stopAnimating];
            self.popupVC.actionButton = self.popupVC.defaultActionButton;
        }
        else {
            self.mapView.callout.detail = @"";
        }
        
    }else{
        [self.activityIndicator stopAnimating];
        self.mapView.callout.customView = nil;
        self.mapView.callout.accessoryButtonHidden = YES;
        self.mapView.callout.title = @"No Results";
        self.mapView.callout.detail = @"";

    }
}



#pragma mark - AGSPopupsContainerDelegate methods
- (void)popupsContainerDidFinishViewingPopups:(id<AGSPopupsContainer>)popupsContainer {
    
    //cancel any outstanding requests
    [self.webMap cancelFetchPopups];
    
    // If we are on iPad dismiss the callout
    if ([[AGSDevice currentDevice] isIPad])
        self.mapView.callout.hidden = YES;
    else
        //dismiss the modal viewcontroller for iPhone
      [self dismissViewControllerAnimated:YES completion:nil];
    
}


#pragma mark - AGSPopupsContainerDelegate edit methods

-(void)popupsContainer:(id<AGSPopupsContainer>)popupsContainer
   readyToEditGeometry:(AGSGeometry*)geometry
              forPopup:(AGSPopup*)popup {
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not implement editing or deleting features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
    
    
}

- (void) popupsContainer:(id<AGSPopupsContainer>)popupsContainer
didFinishEditingForPopup:(AGSPopup *)popup {
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not implement editing or deleting features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
}

- (void) popupsContainer:(id< AGSPopupsContainer >)popupsContainer
wantsToDeleteForPopup:(AGSPopup *) popup {
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not allow you to edit or delete features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];

}





@end
