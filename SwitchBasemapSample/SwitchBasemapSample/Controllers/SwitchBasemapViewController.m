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
@property (strong, nonatomic) AGSWebMap *webMap;
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

//once the user selects a different basemap on the list or collection
//switch the basemap
-(void)switchBasemapWithBasemap:(AGSWebMapBaseMap*)selectedBasemap {
    [self.webMap switchBaseMapOnMapView:selectedBasemap];
}

#pragma mark - AGSWebMapDelegate methods

//failed to load the web map
-(void)webMap:(AGSWebMap *)webMap didFailToLoadWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

//able to load the web map
-(void)webMapDidLoad:(AGSWebMap *)webMap {
    //show the web map
    [webMap openIntoMapView:self.mapView];
}

#pragma mark - BasemapPickerDelegate methods

//user selected a new base map from the collection
-(void)basemapPickerController:(UIViewController *)controller didSelectBasemap:(AGSWebMapBaseMap *)basemap {
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
