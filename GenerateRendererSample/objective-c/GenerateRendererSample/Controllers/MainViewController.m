/*
 Copyright 2014 Esri
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MainViewController.h"
#import "LegendViewController.h"
#import "OptionsViewController.h"
#import "AppConstants.h"
#import "SVProgressHUD.h"

@interface MainViewController () <AGSMapViewLayerDelegate, AGSLayerDelegate, LegendViewControllerDelegate, AGSCalloutDelegate>

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *legendContainerView;

@property (nonatomic, strong) AGSFeatureLayer *featureLayer;

@property (nonatomic, strong) LegendViewController *legendViewController;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //hide the legend view until the dynamic layer loads
    self.legendContainerView.hidden = true;
    
    //assign self as the map view delegates
    [self.mapView setLayerDelegate:self];
    [self.mapView.callout setDelegate:self];
    
    //zoom into the California
    AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin: -14029650.509177 ymin: 3560436.632155 xmax: -12627306.217347 ymax: 5430229.021262 spatialReference:[AGSSpatialReference webMercatorSpatialReference]];
    [self.mapView zoomToEnvelope:envelope animated:NO];
    
    //loading World_Topo_Map as basemap
    AGSTiledMapServiceLayer *tiledLayer = [[AGSTiledMapServiceLayer alloc] initWithURL:[[NSURL alloc] initWithString:BASEMAP_URL]];
    [self.mapView addMapLayer:tiledLayer];
    
    //initialize the feature layer and assign the delegate
    self.featureLayer = [[AGSFeatureLayer alloc] initWithURL:[[NSURL alloc] initWithString:FEATURE_SERVICE_URL] mode:AGSFeatureLayerModeSnapshot];
    self.featureLayer.delegate = self;
    //using definition expression to get counties(features) for just California
    self.featureLayer.definitionExpression = @"state_name = 'California'";
    self.featureLayer.outFields = @[@"*"];
    [self.mapView addMapLayer:self.featureLayer];
    
    //notification for features did load for a feature layer
    //will hide the progress hud once the features load
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissProgressHUD) name:AGSFeatureLayerDidLoadFeaturesNotification object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //show progress hud until the features load
    [SVProgressHUD showWithStatus:@"Loading Features"];
}

-(void)dismissProgressHUD {
    //dismiss the progress hud
    [SVProgressHUD dismiss];
    //un hide the legend view controller
    self.legendContainerView.hidden = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - AGSMapViewDelegate methods

-(void)mapViewDidLoad:(AGSMapView *)mapView {
}

#pragma mark - AGSLayerDelegate methods

-(void)layerDidLoad:(AGSLayer *)layer {
    //once the feature layer gets loaded
    //assign the layer's fields to the legend view controller
    self.legendViewController.classificationFields = self.featureLayer.fields;
}

-(void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error {
    //display the error to the user via alertview
    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

#pragma mark - AGSCalloutDelegate methods

-(BOOL)callout:(AGSCallout *)callout willShowForFeature:(id<AGSFeature>)feature layer:(AGSLayer<AGSHitTestable> *)layer mapPoint:(AGSPoint *)mapPoint {
    //use the current selected classification field as title
    //and its value as the detail text
    if (self.legendViewController) {
        NSString *fieldName = [self.legendViewController selectedFieldName];
        NSString *fieldValue = [feature attributeAsStringForKey:fieldName];
        callout.title = fieldName;
        callout.detail = fieldValue;
        return YES;
    }
    return NO;
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"LegendEmbedSegue"]) {
        self.legendViewController = (LegendViewController*)segue.destinationViewController;
        //assign self as the delegate for legendViewController
        self.legendViewController.delegate = self;
    }
}

#pragma mark - LegendViewController delegate

-(void)legendViewController:(LegendViewController *)legendViewController didGenerateRenderer:(AGSRenderer *)renderer {
    //assign the new renderer to the feature layer
    self.featureLayer.renderer = renderer;
}

-(void)legendViewController:(LegendViewController *)legendViewController failedToGenerateRendererWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

@end
