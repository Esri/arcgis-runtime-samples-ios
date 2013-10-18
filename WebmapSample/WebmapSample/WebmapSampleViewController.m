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
#import "CODialog.h"

static NSString * const kPublicWebmapId = @"8a567ebac15748d39a747649a2e86cf4";
static NSString * const kPrivateWebmapId = @"9a5e8ffd9eb7438b894becd6c8a85751";


@interface WebmapSampleViewController() {
}

@property (nonatomic, strong) AGSWebMap *webMap;
@property (nonatomic, strong) CODialog* loginDialog;
@property (nonatomic, strong) NSString* webmapId;
@property (nonatomic, strong) NSMutableArray* popups;

@end

@implementation WebmapSampleViewController 


#pragma mark - View lifecycle


// Release any retained subviews of the main view.
- (void)viewDidUnload
{
    self.loginDialog = nil;
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
    UIAlertView* webmapPickerAlertView = [[UIAlertView alloc] initWithTitle:@"Which webmap would you like to open?" message:@"" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [webmapPickerAlertView addButtonWithTitle:@"Public"];
    [webmapPickerAlertView addButtonWithTitle:@"Private"];
    [webmapPickerAlertView show];
    
}

#pragma mark - AGSWebMapDelegagte methods
- (void) webMapDidLoad:(AGSWebMap *)webMap {
    //If we were previously showing the login dialog, let's hide it
    //because the webmap loaded successfully
    if(self.loginDialog)
        [self.loginDialog hideAnimated:YES];
}


- (void) webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error {
    
    NSLog(@"Error while loading webMap: %@",[error localizedDescription]);
    
    // If we have an error loading the webmap due to an invalid or missing credential
    // prompt the user for login information
    if (error.ags_isAuthenticationError) {
        
            if(!self.loginDialog)
                self.loginDialog = [CODialog dialogWithWindow:self.view.window];
            else
                [self.loginDialog resetLayout];
        
            self.loginDialog.title = @"Please sign in to access the webmap";
            self.loginDialog.subtitle =@"Tip: use 'AGSSample' and 'agssample'";
            
            [self.loginDialog addTextFieldWithPlaceholder:@"Username" secure:NO];
            [self.loginDialog addTextFieldWithPlaceholder:@"Password" secure:YES];
            [self.loginDialog addButtonWithTitle:@"Cancel" target:self selector:@selector(cancelSignInWebMap)];
            [self.loginDialog addButtonWithTitle:@"Login" target:self selector:@selector(signInWebMap)];
            [self.loginDialog showOrUpdateAnimated:YES];
            
        
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


- (void) webMap:(AGSWebMap *) 	webMap
   didLoadLayer:(AGSLayer *) 	layer {
    if(self.loginDialog)
        [self.loginDialog hideAnimated:YES];
}


- (void) webMap:(AGSWebMap *) 	webMap
didFailToLoadLayer:(AGSWebMapLayerInfo *) 	layerInfo
baseLayer:(BOOL) 	baseLayer
federated:(BOOL) 	federated
withError:(NSError *) 	error {
    
    NSLog(@"Error while loading layer: %@",[error localizedDescription]);
    
    // If we have an error loading the layer due to an invalid or missing credential
    // prompt the user for login information
    if (error.ags_isAuthenticationError) {
        
        if(!self.loginDialog)
            self.loginDialog = [CODialog dialogWithWindow:self.view.window];
        else
            [self.loginDialog resetLayout];
        
        self.loginDialog.dialogStyle = CODialogStyleDefault;
        self.loginDialog.title = [NSString stringWithFormat:@"This webmap uses a secure layer '%@'. \n Sign in to access the layer", layerInfo.title];
        self.loginDialog.subtitle = @"Tip: use 'sdksample' and 'sample@380'";
        
        [self.loginDialog addTextFieldWithPlaceholder:@"Username" secure:NO];
        [self.loginDialog addTextFieldWithPlaceholder:@"Password" secure:YES];
        [self.loginDialog addButtonWithTitle:@"Cancel" target:self selector:@selector(cancelSignInLayer)];
        [self.loginDialog addButtonWithTitle:@"Login" target:self selector:@selector(signInLayer)];
        [self.loginDialog showOrUpdateAnimated:YES];
        
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
    // hide the progress dialog
    [self.loginDialog hideAnimated:YES];
    
    //show the popups
    AGSPopupsContainerViewController* pvc =
    [[AGSPopupsContainerViewController alloc]initWithPopups:self.popups];
    pvc.delegate = self;
    [self presentViewController:pvc animated:YES completion:nil];
    
}

#pragma mark - Sign in methods

-(void)signInWebMap{
     
    //Get the credential the user entered
    NSString* username = [self.loginDialog textForTextFieldAtIndex:0];
    NSString* password = [self.loginDialog textForTextFieldAtIndex:1];
   AGSCredential *credential = [[AGSCredential alloc] initWithUser:username password:password];

    // Recreate the webmap object; this time with the credentials
    self.webMap = [[AGSWebMap alloc] initWithItemId:self.webmapId credential:credential];
    // set the delegate
    self.webMap.delegate = self;
    // open webmap into mapview
    [self.webMap openIntoMapView:self.mapView];
    
    //Change the login dialog to give feedback to the user
    [self.loginDialog resetLayout];
    self.loginDialog.title = @"Loading";
    self.loginDialog.dialogStyle = CODialogStyleIndeterminate;
    [self.loginDialog showOrUpdateAnimated:YES];
    
}

-(void)cancelSignInWebMap{
    //Tell the user we cant load the private webmap 
    //because we don't have a credential to use
    [self.loginDialog resetLayout];
    self.loginDialog.dialogStyle = CODialogStyleError;
    self.loginDialog.title = @"Failed to load the private webmap";
    self.loginDialog.subtitle = @"No credentials provided";
    [self.loginDialog showOrUpdateAnimated:YES];
    [self.loginDialog hideAnimated:YES afterDelay:3];
}

-(void)signInLayer{
    //Get the credentials the user entered
    NSString* username = [self.loginDialog textForTextFieldAtIndex:0];
    NSString* password = [self.loginDialog textForTextFieldAtIndex:1];
    AGSCredential *credential = [[AGSCredential alloc] initWithUser:username password:password];
    
    // Pass the credential to the webmap so that it can
    // continue to open the layer with the credential
    [self.webMap continueOpenWithCredential:credential];
   
    
    //Change the login dialog to give feedback to the user
    [self.loginDialog resetLayout];
    self.loginDialog.title = @"Loading";
    self.loginDialog.dialogStyle = CODialogStyleIndeterminate;
    [self.loginDialog showOrUpdateAnimated:YES];
    
}

-(void)cancelSignInLayer{
    // hide the login dialog
    [self.loginDialog hideAnimated:YES];

    // skip loading this layer
    [self.webMap continueOpenAndSkipCurrentLayer];
}

#pragma  mark - AGSCalloutDelegte methods
- (void) didClickAccessoryButtonForCallout:(AGSCallout *)callout {
    //fetch popups
    [self.webMap fetchPopupsForExtent:callout.mapLocation.envelope];
    
    //reinitialize the popups array that will hold the results
    self.popups = [[NSMutableArray alloc]init];
    
    //show a progress dialog in case it takes time to fetch popups
    [self.loginDialog resetLayout];
    self.loginDialog.title = @"Loading";
    self.loginDialog.dialogStyle = CODialogStyleIndeterminate;
    [self.loginDialog showOrUpdateAnimated:YES];
}


#pragma mark - AGSPopupsContainerDelegate
- (void) popupsContainerDidFinishViewingPopups:(id<AGSPopupsContainer>)popupsContainer{
    [(AGSPopupsContainerViewController*)popupsContainer dismissViewControllerAnimated:YES completion:nil];
}
#pragma  mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0){
        //user wants to open public webmap
        self.webmapId = kPublicWebmapId;
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

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return  YES;
}



@end
