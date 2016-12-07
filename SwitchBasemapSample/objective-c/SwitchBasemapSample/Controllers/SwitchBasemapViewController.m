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
#import "BasemapsCollectionViewController.h"
#import "BasemapsListViewController.h"

@interface SwitchBasemapViewController ()

@property (strong, nonatomic) IBOutlet AGSMapView *mapView;
@property (strong, nonatomic) AGSMap *webMap;
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
    AGSPortal *portal = [AGSPortal ArcGISOnlineWithLoginRequired:NO];
    self.webMap = [AGSMap mapWithItem:[AGSPortalItem portalItemWithPortal:portal itemID:itemId]];
    self.mapView.map = self.webMap;

    __weak __typeof(self) weakSelf = self;
    [self.webMap loadWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            [weakSelf webMap:self.webMap didFailToLoadWithError:error];
        }
    }];
}

//once the user selects a different basemap on the list or collection
//switch the basemap
-(void)switchBasemapWithBasemap:(AGSBasemap*)selectedBasemap {
    self.webMap.basemap = selectedBasemap;
}

//The AGSWebMapDelegate is no longer needed, now that we're using completion blocks

//failed to load the web map
-(void)webMap:(AGSMap *)webMap didFailToLoadWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

#pragma mark - BasemapPickerDelegate methods

//user selected a new base map from the collection
-(void)basemapPickerController:(UIViewController *)controller didSelectBasemap:(AGSBasemap *)basemap {
    [self switchBasemapWithBasemap:basemap];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//user tapped cancel button
-(void)basemapPickerControllerDidCancel:(UIViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - segues 

//segue could either be for the list or for the collection
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kOptionsSegueIdentifier]) {
        BasemapsCollectionViewController *controller = [segue destinationViewController];
        controller.delegate = self;
        
        if ([self isIPad]) {
            [controller setModalPresentationStyle:UIModalPresentationFormSheet];
        }
    }
    else if ([segue.identifier isEqualToString:kOptionsTableSegueIdentifier]) {
        BasemapsListViewController *controller = [segue destinationViewController];
        controller.delegate = self;
        
        if ([self isIPad]) {
            [controller setModalPresentationStyle:UIModalPresentationFormSheet];
        }
    }
}

#pragma mark - internal

-(BOOL)isIPad {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}

@end
