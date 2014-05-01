// Copyright 2014 ESRI
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

#import "SwitchBasemapViewController.h"
#import "AppConstants.h"

@interface SwitchBasemapViewController ()

@property (strong, nonatomic) IBOutlet AGSMapView *mapView;
@property (strong, nonatomic) AGSWebMap *webMap;
@property (strong, nonatomic) AGSWebMap *selectedWebMap;
@property (strong, nonatomic) AGSPortal *portal;

@end

@implementation SwitchBasemapViewController


// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //add the default web map
    [self addWebMapWithItemId:kWebMapItemId];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//method to initialize and load the web map
-(void)addWebMapWithItemId:(NSString*)itemId {
    self.webMap = [AGSWebMap webMapWithItemId:itemId credential:nil];
    [self.webMap setDelegate:self];
}

//once the user selects a different web map on the list or collection
//load that web map using the credential provided
-(void)switchBasemapWithItemId:(NSString*)itemId credential:(AGSCredential*)credential {
    self.selectedWebMap = [AGSWebMap webMapWithItemId:itemId credential:credential];
    [self.selectedWebMap setDelegate:self];
}

#pragma mark - AGSWebMapDelegate methods

//failed to load the web map
-(void)webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

//able to load the web map
-(void)webMapDidLoad:(AGSWebMap *)webMap {
    //if the web map is the default one then simply show the web map
    if (webMap == self.webMap) {
        [webMap openIntoMapView:self.mapView];
    }
    //else if the web map is a newly selected web map, then switch the base map
    //for the default web map
    else if (webMap == self.selectedWebMap) {
        [self.webMap switchBaseMapOnMapView:self.selectedWebMap.baseMap];
    }
}

#pragma mark - BasemapsCollectionViewControllerDelegate methods

//user selected a new web map from the collection
-(void)basemapsCollectionViewController:(BasemapsCollectionViewController *)controller didSelectMapWithItemId:(NSString *)itemId credential:(AGSCredential*)credential {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self switchBasemapWithItemId:itemId credential:credential];
}

//user tapped cancel button
-(void)basemapsCollectionViewControllerDidCancel:(BasemapsCollectionViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - BasemapsListViewControllerDelegate methods

//user selected a new web map from the list
-(void)basemapsListViewController:(BasemapsListViewController *)controller didSelectMapWithItemId:(NSString *)itemId credential:(AGSCredential *)credential{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self switchBasemapWithItemId:itemId credential:credential];
}

//user tapped cancel button
-(void)basemapsListViewControllerDidCancel:(BasemapsListViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - segues 

//segue could either be for the list or for the collection
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kOptionsSegueIdentifier]) {
        BasemapsCollectionViewController *controller = [segue destinationViewController];
        controller.delegate = self;
        
        if ([[AGSDevice currentDevice] isIPad]) {
            [controller setModalPresentationStyle:UIModalPresentationFormSheet];
        }
    }
    else if ([segue.identifier isEqualToString:kOptionsTableSegueIdentifier]) {
        BasemapsListViewController *controller = [segue destinationViewController];
        controller.delegate = self;
        
        if ([[AGSDevice currentDevice] isIPad]) {
            [controller setModalPresentationStyle:UIModalPresentationFormSheet];
        }
    }
}

@end
