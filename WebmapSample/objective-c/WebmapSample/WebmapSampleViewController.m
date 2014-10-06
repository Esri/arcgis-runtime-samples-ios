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


#import "WebmapSampleViewController.h"
#import "SVProgressHUD.h"

#define CHOOSE_WEBMAP_TAG 0
#define SIGN_IN_WEBMAP_TAG 1
#define SIGN_IN_LAYER_TAG 2

static NSString * const kPublicWebmapId = @"8a567ebac15748d39a747649a2e86cf4";
static NSString * const kPrivateWebmapId = @"9a5e8ffd9eb7438b894becd6c8a85751";


@interface WebmapSampleViewController()

@property (nonatomic, strong) AGSWebMap *webMap;
@property (nonatomic, strong) NSString* webmapId;
@property (nonatomic, strong) NSMutableArray* popups;

@end

@implementation WebmapSampleViewController 


#pragma mark - View lifecycle


// Release any retained subviews of the main view.
- (void)viewDidUnload
{
    self.webMap = nil;
    self.mapView = nil;
    self.webmapId = nil;
    [super viewDidUnload];
}
// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Do any additional setup after loading the view
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.mapView.callout.delegate = self;
    //Ask the user which webmap to load : Public or Private?
    UIAlertView* webmapPickerAlertView = [[UIAlertView alloc] initWithTitle:@"Which web map would you like to open?" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [webmapPickerAlertView addButtonWithTitle:@"Public"];
    [webmapPickerAlertView addButtonWithTitle:@"Private"];
    //Set tag so we know which action this alertview is being shown for
    [webmapPickerAlertView setTag:CHOOSE_WEBMAP_TAG];
    [webmapPickerAlertView show];
    
}

#pragma mark - AGSWebMapDelegagte methods
- (void) webMapDidLoad:(AGSWebMap *)webMap {

    [SVProgressHUD dismiss];
}


- (void) webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error {
    
    NSLog(@"Error while loading webMap: %@",[error localizedDescription]);
    
    // If we have an error loading the webmap due to an invalid or missing credential
    // prompt the user for login information
    if (error.ags_isAuthenticationError) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Please sign in to access the web map" message:@"Tip: use 'AGSSample' and 'agssample'" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
        [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        //Set tag so we know which action this alertview is being shown for
        [alertView setTag:SIGN_IN_WEBMAP_TAG];
        [alertView show];
        
    }
    // For any other error alert the user
    else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                     message:@"Failed to load the webmap" 
                                                    delegate:nil 
                                           cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [av show];
    }
}

- (void)webMap:(AGSWebMap *)webMap didLoadLayer:(AGSLayer *)layer {
    [SVProgressHUD dismiss];
}


- (void) webMap:(AGSWebMap *) webMap didFailToLoadLayer:(AGSWebMapLayerInfo *)layerInfo baseLayer:(BOOL)baseLayer federated:(BOOL)federated withError:(NSError *)error
{
    NSLog(@"Error while loading layer: %@",[error localizedDescription]);
    
    // If we have an error loading the layer due to an invalid or missing credential
    // prompt the user for login information
    if (error.ags_isAuthenticationError) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"This webmap uses a secure layer '%@'. \n Sign in to access the layer", layerInfo.title]
                                                            message:@"Tip: use 'sdksample' and 'sample@380'"
                                                           delegate:self cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Login", nil];
        [alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        //Set tag so we know which action this alertview is being shown for
        [alertView setTag:SIGN_IN_LAYER_TAG];
        [alertView show];
    }
    // For any other error alert the user
    else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Error" 
                                            message:[NSString stringWithFormat:@"The layer %@ cannot be displayed",layerInfo.title]
                                            delegate:self
                                           cancelButtonTitle:@"OK" 
                                           otherButtonTitles:nil];
        [av show];
        
        // and skip loading this layer
        [self.webMap continueOpenAndSkipCurrentLayer];
        
    }        
}


- (NSString*) bingAppIdForWebMap:(AGSWebMap *)webMap {
    //this delegate method is called when the webmap contains a Bing Maps basemap layer
    //you should return a valid Bing Maps ID so that the basemap can be displayed.
    return @"<your-bingid-goes-here>";
}


- (void) webMap:(AGSWebMap *)webMap didFetchPopups:(NSArray *)popups forExtent:(AGSEnvelope *)extent {
    //hold on to the results
    for (AGSPopup* popup in popups) {
        //disable editing because this sample does not implement any editing functionality.
        //only permit viewing of popups
        popup.allowEdit = NO;
        popup.allowEditGeometry = NO;
        popup.allowDelete = NO;
        [self.popups addObject:popup];
    }
}

- (void) webMap:(AGSWebMap *)webMap didFinishFetchingPopupsForExtent:(AGSEnvelope *)extent {
    
    //show the popups
    AGSPopupsContainerViewController* pvc =
    [[AGSPopupsContainerViewController alloc]initWithPopups:self.popups];
    pvc.delegate = self;
    [self presentViewController:pvc animated:YES completion:nil];
    
}

#pragma mark - Sign in methods

-(void)signInWebMap:(UIAlertView*)alertView {
     
    //Get the credential the user entered
    NSString* username = [[alertView textFieldAtIndex:0] text];
    NSString* password = [[alertView textFieldAtIndex:1] text];
   AGSCredential *credential = [[AGSCredential alloc] initWithUser:username password:password];

    // Recreate the webmap object; this time with the credentials
    self.webMap = [[AGSWebMap alloc] initWithItemId:self.webmapId credential:credential];
    // set the delegate
    self.webMap.delegate = self;
    // open webmap into mapview
    [self.webMap openIntoMapView:self.mapView];
    
    [SVProgressHUD showWithStatus:@"Loading"];
    
}

-(void)cancelSignInWebMap{
    //Tell the user we cant load the private webmap 
    //because we don't have a credential to use
    [[[UIAlertView alloc] initWithTitle:@"Failed to load the private webmap" message:@"No credentials provided" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

-(void)signInLayer:(UIAlertView*)alertView {
    //Get the credentials the user entered
    NSString* username = [[alertView textFieldAtIndex:0] text];
    NSString* password = [[alertView textFieldAtIndex:1] text];
    AGSCredential *credential = [[AGSCredential alloc] initWithUser:username password:password];
    
    // Pass the credential to the webmap so that it can
    // continue to open the layer with the credential
    [self.webMap continueOpenWithCredential:credential];
   
    [SVProgressHUD showWithStatus:@"Loading"];
    
}

-(void)cancelSignInLayer{
    // skip loading this layer
    [self.webMap continueOpenAndSkipCurrentLayer];
}

#pragma  mark - AGSCalloutDelegte methods
- (void) didClickAccessoryButtonForCallout:(AGSCallout *)callout {
    //fetch popups
    [self.webMap fetchPopupsForExtent:callout.mapLocation.envelope];
    
    //reinitialize the popups array that will hold the results
    self.popups = [[NSMutableArray alloc]init];
}


#pragma mark - AGSPopupsContainerDelegate
- (void) popupsContainerDidFinishViewingPopups:(id<AGSPopupsContainer>)popupsContainer{
    [(AGSPopupsContainerViewController*)popupsContainer dismissViewControllerAnimated:YES completion:nil];
}


#pragma  mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // If the user was asked to pick a web map
    if (alertView.tag == CHOOSE_WEBMAP_TAG) {
        if(buttonIndex == 0){
            //user wants to open public webmap
            self.webmapId = kPublicWebmapId;
            [SVProgressHUD showWithStatus:@"Loading"];
        }else{
            //user want to open private webmap
            self.webmapId = kPrivateWebmapId;
        }
        
        // The private webmap needs to be accessed with these credentials -
        // Username: AGSSample
        // Password: agssample  (note, lowercase)
        
        // Create a webmap using the ID
        self.webMap = [AGSWebMap webMapWithItemId:self.webmapId credential:nil];
        
        // Set self as the webmap's delegate so that we get notified
        // if the web map opens successfully or if errors are encounterer
        self.webMap.delegate = self;
        
        // Open the webmap
        [self.webMap openIntoMapView:self.mapView];

    }
    // If the user was asked to sign in to access a secured web map
    else if (alertView.tag == SIGN_IN_WEBMAP_TAG) {
        switch (buttonIndex) {
            case 0: //cancel button tapped
                [self cancelSignInWebMap];
                break;
            case 1: //login button tapped
                [self signInWebMap:alertView];
            default:
                break;
        }
    }
    // If the user was asked to sign in to access a secured layer within the web map
    else if (alertView.tag == SIGN_IN_LAYER_TAG) {
        switch (buttonIndex) {
            case 0:     //cancel button tapped
                [self cancelSignInLayer];
                break;
            case 1:     //login button tapped
                [self signInLayer:alertView];
            default:
                break;
        }
    }
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return  YES;
}



@end
