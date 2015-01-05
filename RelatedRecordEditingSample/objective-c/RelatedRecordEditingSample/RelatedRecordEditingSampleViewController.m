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

#import "RelatedRecordEditingSampleViewController.h"

#import <ArcGIS/ArcGIS.h>
#import "NotesViewController.h"
#import "LoadingView.h"

//this is the url for the basemap. 
#define kBaseMapServiceURL @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"

//url for the incidents layer
#define kIncidentsLayerURL @"http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/SanFrancisco/311Incidents/FeatureServer/0"


#pragma mark - Class Extension

@interface RelatedRecordEditingSampleViewController() 

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSFeatureLayer *incidentsLayer;
@property (nonatomic, strong) AGSPopupsContainerViewController* popupVC;
@property (nonatomic, strong) UIBarButtonItem* customActionButton;
@property (nonatomic, strong) LoadingView* loadingView;

@end

#pragma mark - Implementation

@implementation RelatedRecordEditingSampleViewController

#pragma mark -  UIView methods

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad {
    
    //creating a tiled service with the base map url
    NSURL *mapUrl = [NSURL URLWithString:kBaseMapServiceURL];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
    
    //add the tiled layer to the map view
	[self.mapView addMapLayer:tiledLyr withName:@"Tiled Layer"];
    
    //Zooming to an initial envelope with the specified spatial reference of the map.
    //this is the San Francisco extent. 
	AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-13639984
                                                ymin:4537387
                                                xmax:-13606734
                                                ymax:4558866 
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:YES];
    
    //Set up the map view
    self.mapView.callout.delegate = self;
	
    //setup the incidents layer as a feature layer and add it to the map
    self.incidentsLayer = [AGSFeatureLayer featureServiceLayerWithURL:[NSURL URLWithString:kIncidentsLayerURL] mode:AGSFeatureLayerModeOnDemand]; 
    self.incidentsLayer.outFields = [NSArray arrayWithObject:@"*"];
    self.incidentsLayer.calloutDelegate = self.incidentsLayer;
    
    [self.mapView addMapLayer:self.incidentsLayer withName:@"Incidents"];
    
    //setting the custom action button which will be later used to display related notes of an incident
    self.customActionButton  = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"pencil.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(displayIncidentNotes)];
	
    [super viewDidLoad];
}



#pragma mark - AGSCalloutDelegate methods


- (void) didClickAccessoryButtonForCallout:		(AGSCallout *) 	callout {

    AGSGraphic* graphic = (AGSGraphic*)callout.representedObject;
    self.incidentsLayer = (AGSFeatureLayer*) graphic.layer;
    
    //Show popup for the graphic because the user tapped on the callout accessory button
    //this is a client side popup based on the graphic that was selected. 
    AGSPopupInfo *info = [AGSPopupInfo popupInfoForGraphic:graphic];
    self.popupVC = [[AGSPopupsContainerViewController alloc] initWithPopupInfo:info graphic:graphic usingNavigationControllerStack:NO];
    self.popupVC.delegate = self;    
    self.popupVC.actionButton = self.customActionButton; //set the custom action button. 
    self.popupVC.modalTransitionStyle =  UIModalTransitionStyleFlipHorizontal;
    
    //If iPad, use a modal presentation style
    if([[AGSDevice currentDevice] isIPad])
        self.popupVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:self.popupVC animated:YES completion:nil];

}



#pragma mark -  AGSPopupsContainerDelegate methods

- (void)popupsContainerDidFinishViewingPopups:(id) popupsContainer {
    //dismiss the popups view controller
    [self dismissViewControllerAnimated:YES completion:nil];
    self.popupVC = nil;
}

#pragma mark - Helper

- (void) warnUserOfErrorWithMessage:(NSString*) message {
    //Display an alert to the user  
    [[[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
}

- (void)displayIncidentNotes
{
    //get the current popup. 
    AGSPopup *currentPopup = self.popupVC.currentPopup;  
    
    BOOL exists;
    //obtain the OID of the current popup graphic
    NSNumber *incidentOID = [NSNumber numberWithLong:[currentPopup.graphic attributeAsIntegerForKey:@"objectid" exists:&exists]];
    
    //instantiate the notes view to show the related notes
    NotesViewController *controller = [[NotesViewController alloc] initWithIncidentOID:incidentOID incidentLayer:self.incidentsLayer];    
    controller.delegate = self;    
    [self.popupVC presentViewController:controller animated:YES completion:nil];
}

#pragma mark - NotesViewControllerDelegate

- (void)didFinishWithNotes 
{
    //dismiss the notes view.
    [self dismissViewControllerAnimated:YES completion:nil];

}



#pragma mark -

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    self.customActionButton = nil;
}


@end
