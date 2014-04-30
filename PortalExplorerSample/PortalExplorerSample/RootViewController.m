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

#import "RootViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "PortalExplorer.h"
#import "LoginViewController.h"
#import "LoadingView.h"

#define kLoginViewController @"LoginViewController"

//contants for layers

#define ItemId_DefaultMap @"c63e861ae3c945aa9752fcb8d9431e1e"


@interface RootViewController()<AGSMapViewLayerDelegate, AGSWebMapDelegate, PortalExplorerDelegate, LoginViewControllerDelegate>

//map view to open the webmap in
@property (nonatomic, strong) IBOutlet AGSMapView *mapView;

//webmap that needs to be opened. 
@property (nonatomic, strong) AGSWebMap *webMap;

/*Portal Explorer is the object that is used to connect to a portal or organization and access its contents. 
 It has various delegate methods that the root view controller must implement.  
  Make sure to open the PE in a nav controller
  */
@property (nonatomic, strong) PortalExplorer *portalExplorer;

//login view
@property (nonatomic, strong) LoginViewController *loginVC;

//loading view
@property (nonatomic, strong) LoadingView *loadingView;

//popover for ipad
@property (nonatomic, strong) UIPopoverController* popOver;

//opens the default webmap into the mapview
- (void)openDefaultWebMap;

@end

@implementation RootViewController


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// set the delegate for the map view
	self.mapView.layerDelegate = self;
	
	//open default web map so we have something to see when the sample starts up
	[self openDefaultWebMap];
    
    //instantiate the portal explorer and assign the delegate, if not done already
    if(!self.portalExplorer){
        self.portalExplorer = [[PortalExplorer alloc] initWithURL:[NSURL URLWithString: @"http://www.arcgis.com"] credential:nil];
        self.portalExplorer.delegate = self;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    //we're not releasing the portal explorer because a user may have signed in and we don't want to lose that information

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark AGSWebMapDelegate

- (void)webMapDidLoad:(AGSWebMap *)webMap {
	
	//open webmap in mapview
	[self.webMap openIntoMapView:self.mapView];
}

- (void)webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error {
	
    //show the error message in an alert. 
	NSString *err = [NSString stringWithFormat:@"%@",error];	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to load webmap"
													message:err
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

-(void)didFailToLoadLayer:(NSString *)layerTitle url:(NSURL *)url baseLayer:(BOOL)baseLayer withError:(NSError *)error {
    
	//show the error message in an alert. 
	NSString *err = [NSString stringWithFormat:@"%@",error];	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to load layer"
													message:err
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}



#pragma mark PortalExplorerDelegate

- (void)portalExplorer:(PortalExplorer *)portalExplorer didLoadPortal:(AGSPortal *)portal
{
    //if the login view is currently shown, it means that the user is logging in and
    // the portal explorer was updated with the user's credential. 
    //We have to remove the  login view. 
    if(self.loginVC)
    {
        [self.loadingView removeView];
        [self.loginVC dismissViewControllerAnimated:YES completion:nil];
        self.loginVC = nil;
    }
    
    //remove the loading view. 
    if(self.loadingView)
        [self.loadingView removeView];
    
}

- (void)portalExplorer:(PortalExplorer *)portalExplorer didFailToLoadPortalWithError:(NSError *)error
{
    
    //remove the loading view. 
    if(self.loadingView)
        [self.loadingView removeView];
    
    //show the error message if the portal fails to load.
    NSString *err = [NSString stringWithFormat:@"%@",error];	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed to connect to portal"
													message:err
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
    
    
}

- (void)portalExplorer:(PortalExplorer *)portalExplorer didRequestSignInForPortal:(AGSPortal *)portal
{
    //This means a user is trying to log in 
    //show the login view  
    
    if(!self.loginVC){
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
        self.loginVC = [storyboard instantiateViewControllerWithIdentifier:kLoginViewController];
        self.loginVC.delegate = self;
    }
    
    if([[AGSDevice currentDevice] isIPad]){
        
        self.loginVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        self.loginVC.modalPresentationStyle = UIModalPresentationFormSheet;
        [self.popOver.contentViewController presentViewController:self.loginVC animated:YES completion:nil];
        
    }else{
        [self.portalExplorer presentViewController:self.loginVC animated:YES completion:nil];
    }
    
}

- (void)portalExplorer:(PortalExplorer *)portalExplorer didRequestSignOutFromPortal:(AGSPortal *)portal
{
    //This means a user signed out 
    
    //show the loading view while signing out. 
    self.loadingView = [LoadingView loadingViewInView:self.portalExplorer.view withText:@"Logging Out..."]; 
    
    //update the portal explorer with the nil credential as the user is signing out. 
    [self.portalExplorer updatePortalWithCredential:nil];
}

- (void)portalExplorer:(PortalExplorer *)portalExplorer didSelectPortalItem:(AGSPortalItem *)portalItem
{
    //open the webmap with the portal item as specified
	self.webMap = [AGSWebMap webMapWithPortalItem:portalItem];
	self.webMap.delegate = self;
	self.webMap.zoomToDefaultExtentOnOpen = YES;
    
    //dismiss the PE
    if([[AGSDevice currentDevice]isIPad]){
        [self.popOver dismissPopoverAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }

}

- (void)portalExplorerWantsToHide:(PortalExplorer *)portalExplorer{
    //dismiss the PE
    if([[AGSDevice currentDevice]isIPad]){
        [self.popOver dismissPopoverAnimated:YES];
    }else{
       [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark LoginViewControllerDelegate

- (void)userDidProvideCredential:(AGSCredential *)credential
{
    //show the loading view 
    self.loadingView = [LoadingView loadingViewInView:self.loginVC.view withText:@"Logging In..."]; 
    
    //update the portal explorer with the credential provided by the user. 
    [self.portalExplorer updatePortalWithCredential:credential];
    
}

- (void)userDidCancelLogin
{
    //remove the loading view
    [self.loadingView removeView];
    
    //dismiss the login view. 
    [self.portalExplorer dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Helper

//open default webmap
- (void)openDefaultWebMap {
    
    //open the webmap
	self.webMap = [AGSWebMap webMapWithItemId:ItemId_DefaultMap credential:nil];
    
    //set the webmap delegate to self
	self.webMap.delegate = self;
    
    //zoom to default extent
	self.webMap.zoomToDefaultExtentOnOpen = YES;
}

- (IBAction)showPortalExplorer:(id)sender
{
    if([[AGSDevice currentDevice] isIPad]){ //ipad
        
        if(!self.popOver){ //we dont' have a popover view controller, so let's create one
            
            //We must use a nav controller for the portal explorer so that we have ability to navigate back/forth
            UINavigationController *portalExplorerNavController = 
            [[UINavigationController alloc] initWithRootViewController:self.portalExplorer];    
            portalExplorerNavController.navigationBar.barStyle = UIBarStyleDefault;
            
            
            self.popOver= [[UIPopoverController alloc]
                                    initWithContentViewController:portalExplorerNavController] ;
            [self.popOver setPopoverContentSize:CGSizeMake(320, 480)];
        }
        
        if([self.popOver isPopoverVisible]){
            //let's hide the popover because it is already visible
            [self.popOver dismissPopoverAnimated:YES];
        }else{
            //let's show the popover
        	[self.popOver presentPopoverFromBarButtonItem:sender 
                                 permittedArrowDirections:UIPopoverArrowDirectionUp
                                                 animated:YES ];
            
        }
    }else{ //iphone
        
        //We must use a nav controller for the portal explorer so that we have ability to navigate back/forth
        UINavigationController *portalExplorerNavController = 
        [[UINavigationController alloc] initWithRootViewController:self.portalExplorer];    
        portalExplorerNavController.navigationBar.barStyle = UIBarStyleDefault;
        
        //Present modally for iphone
        [self presentViewController:portalExplorerNavController animated:YES completion:nil];
    }
}

@end
