
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
#import "PopupHelper.h"


@interface PopupSampleViewController() {
    AGSWebMap *_webMap;
    AGSMapView *_mapView;
    NSString *_webMapId;
    NSMutableArray *_queryableLayers;
    AGSPopupsContainerViewController *_popupVC;
    UIActivityIndicatorView *_activityIndicator;
    PopupHelper* _popupHelper;
}

@end

@implementation PopupSampleViewController 

@synthesize webMapId = _webMapId;
@synthesize webMap = _webMap;
@synthesize mapView = _mapView;
@synthesize queryableLayers = _queryableLayers;
@synthesize activityIndicator = _activityIndicator;
@synthesize popupVC = _popupVC;
@synthesize popupHelper = _popupHelper;

#pragma mark - View lifecycle


// Release any retained subviews of the main view.
- (void)viewDidUnload
{
    self.webMap = nil;
    self.mapView = nil;
    self.webMapId = nil;
    self.queryableLayers = nil;
    self.popupVC = nil;
    self.activityIndicator = nil;
    self.popupHelper = nil;
    
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
    
    
    self.queryableLayers = [NSMutableArray array];

    self.popupHelper = [[PopupHelper alloc] init];
    self.popupHelper.delegate = self;

    
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

- (void)mapView:(AGSMapView *)mapView didClickAtPoint:(CGPoint)screen mapPoint:(AGSPoint *)mappoint graphics:(NSDictionary *)graphics {

    //cancel any outstanding requests
    [self.popupHelper cancelOutstandingRequests];

    [self.popupHelper findPopupsForMapView:mapView withGraphics:graphics atPoint:mappoint andWebMap:self.webMap withQueryableLayers:self.queryableLayers ];
}

#pragma mark - AGSCallout methods

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) 	callout {
    [self presentModalViewController:self.popupVC animated:YES];
}


#pragma mark - PopupHelperDelegate methods
- (void)foundPopups:(NSArray*) popups atMapPonit:(AGSPoint*)mapPoint withMoreToFollow:(BOOL)more {
    
    //Release the last popups vc
    self.popupVC = nil;
    
    // If we've found one or more popups
    if (popups.count > 0) {
        //Create a popupsContainer view controller with the popups
        self.popupVC = [[AGSPopupsContainerViewController alloc] initWithPopups:popups usingNavigationControllerStack:false];
        self.popupVC.style = AGSPopupsContainerStyleBlack;
        self.popupVC.delegate = self;
        
        // For iPad, display popup view controller in the callout
        if ([[AGSDevice currentDevice] isIPad]) {
            self.mapView.callout.customView = self.popupVC.view;
            if(more){
                // Start the activity indicator in the upper right corner of the
                // popupsContainer view controller while we wait for the query results
                self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                UIBarButtonItem *blankButton = [[UIBarButtonItem alloc] initWithCustomView:(UIView*)self.activityIndicator];
                self.popupVC.actionButton = blankButton;
                [self.activityIndicator startAnimating];
            }
        }
        else {
            //For iphone, display summary info in the callout
            self.mapView.callout.title = [NSString stringWithFormat:@"%d Results", popups.count];
            self.mapView.callout.accessoryButtonHidden = NO;
            if(more)
                self.mapView.callout.detail = @"loading more...";
            else
                self.mapView.callout.detail = @"";
        }
        
    }else{
        // If we did not find any popups yet, but we expect some to follow
        // show the activity indicator in the callout while we wait for results
        if(more) {
            self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            self.mapView.callout.customView = self.activityIndicator;
            [self.activityIndicator startAnimating];
        }
        else{
            //If don't have any popups, and we don't expect any more results
            [self.activityIndicator stopAnimating];
            self.mapView.callout.customView = nil;
            self.mapView.callout.accessoryButtonHidden = YES;
            self.mapView.callout.title = @"No Results";
            self.mapView.callout.detail = @"";
        }
           
    }
    [self.mapView.callout showCalloutAt:mapPoint pixelOffset:CGPointZero animated:YES];

    
}

- (void)foundAdditionalPopups:(NSArray*) popups withMoreToFollow:(BOOL)more{
    
    if(popups.count>0){
        if (self.popupVC) {
            [self.popupVC showAdditionalPopups:popups];
        
            // If these are the results of the final query stop the activityIndicator
            if (!more) {
                [self.activityIndicator stopAnimating];
            
                // If we are on iPhone display the number of results returned
                if (![[AGSDevice currentDevice] isIPad]) {
                    self.mapView.callout.customView = nil;
                    NSString *results = self.popupVC.popups.count == 1 ? @"Result" : @"Results";
                    self.mapView.callout.title = [NSString stringWithFormat:@"%d %@", self.popupVC.popups.count, results];
                    self.mapView.callout.detail = @"";
                }
            }
        } else {
        
            self.popupVC = [[AGSPopupsContainerViewController alloc] initWithPopups:popups];
            self.popupVC.delegate = self;
            self.popupVC.style = AGSPopupsContainerStyleBlack;
    
            // If we are on iPad set the popupsContainerViewController to be the callout's customView
            if ([[AGSDevice currentDevice] isIPad]) {
                self.mapView.callout.customView = self.popupVC.view;
            }
    
            // If we have more popups coming, start the indicator on the popupVC
            if (more) {
                if ([[AGSDevice currentDevice] isIPad] ) {
                    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                    UIBarButtonItem *blankButton = [[UIBarButtonItem alloc] initWithCustomView:(UIView*)self.activityIndicator];
                    self.popupVC.actionButton = blankButton;
                    [self.activityIndicator startAnimating];
                }
        
            }
            // Otherwise if we are on iPhone display the number of results returned in the callout
            else if (![[AGSDevice currentDevice] isIPad]) {
                self.mapView.callout.customView = nil;
                NSString *results = self.popupVC.popups.count == 1 ? @"Result" : @"Results";
                self.mapView.callout.title = [NSString stringWithFormat:@"%d %@", self.popupVC.popups.count, results];
                self.mapView.callout.detail = @"";
            }
        }
    }else{
        // If these are the results of the last query stop the activityIndicator
        if (!more) {
            [self.activityIndicator stopAnimating];
                
            // If no query returned results
            if (!self.popupVC) {
                self.mapView.callout.customView = nil;
                self.mapView.callout.accessoryButtonHidden = YES;
                self.mapView.callout.title = @"No Results";
                self.mapView.callout.detail = @"";
            }
            // Otherwise if we are on iPhone display the number of results returned in the callout
            else if (![[AGSDevice currentDevice] isIPad]) {
                self.mapView.callout.customView = nil;
                NSString *results = self.popupVC.popups.count == 1 ? @"Result" : @"Results";
                self.mapView.callout.title = [NSString stringWithFormat:@"%d %@", self.popupVC.popups.count, results];
                self.mapView.callout.detail = @"";
            }
        }

    }
   
}

#pragma mark - AGSPopupsContainerDelegate methods
- (void)popupsContainerDidFinishViewingPopups:(id<AGSPopupsContainer>)popupsContainer {
    
    //cancel any outstanding requests
    [self.popupHelper cancelOutstandingRequests];
    
    // If we are on iPad dismiss the callout
    if ([[AGSDevice currentDevice] isIPad])
        self.mapView.callout.hidden = YES;
    else
        //dismiss the modal viewcontroller for iPhone
        [self.popupVC dismissModalViewControllerAnimated:YES];
    
}

- (void) popupsContainer:		(id< AGSPopupsContainer >) 	popupsContainer
didStartEditingGraphicForPopup:		(AGSPopup *) 	popup {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not allow you to edit or delete features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];
}

- (void) popupsContainer:		(id< AGSPopupsContainer >) 	popupsContainer
wantsToDeleteGraphicForPopup:		(AGSPopup *) 	popup {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Not Implemented"
                                                 message:@"This sample only demonstrates how to display popups. It does not allow you to edit or delete features. Please refer to the Feature Layer Editing Sample instead."
                                                delegate:self
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
    
    [av show];

}


#pragma mark - AGSWebMapDelegate methods

- (void) webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error {
    
    // If the web map failed to load report an error
    NSLog(@"Error while loading webMap: %@",[error localizedDescription]);
    
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                 message:@"Failed to load the webmap" 
                                                delegate:self 
                                       cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
}


-(void) didLoadLayer:(AGSLayer *)layer {
    
    //Compose a list of dynamic and map service layers in the webmap
    //for which we want to find popups
    //Popups for feature layer will always be found regardless of this list
    if([layer isKindOfClass:[AGSDynamicMapServiceLayer class]] || [layer isKindOfClass:[AGSTiledMapServiceLayer class]])
        [self.queryableLayers addObject:layer];

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




@end
