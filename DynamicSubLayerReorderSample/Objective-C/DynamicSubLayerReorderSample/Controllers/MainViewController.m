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

#define BASEMAP_URL @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
#define DYNAMIC_LAYER_URL @"http://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer"

@interface MainViewController () <AGSLayerDelegate>

@property (nonatomic, weak) IBOutlet AGSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *listContainerView;

@property (nonatomic, strong) AGSDynamicMapServiceLayer *dynamicMapServiceLayer;
@property (nonatomic, strong) LayersListViewController *layersListViewController;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //add the basemap layer
    NSURL *tiledLayerURL = [[NSURL alloc] initWithString:BASEMAP_URL];
    AGSTiledMapServiceLayer *tiledLayer = [[AGSTiledMapServiceLayer alloc] initWithURL:tiledLayerURL];
    [self.mapView addMapLayer:tiledLayer];
    
    //add the dynamic layer
    NSURL *dynamicLayerURL = [[NSURL alloc] initWithString:DYNAMIC_LAYER_URL];
    self.dynamicMapServiceLayer = [[AGSDynamicMapServiceLayer alloc] initWithURL:dynamicLayerURL];
    self.dynamicMapServiceLayer.delegate = self;
    [self.mapView addMapLayer:self.dynamicMapServiceLayer];
    
    //zoom into the California
    AGSEnvelope *envelope = [AGSEnvelope envelopeWithXmin: -14029650.509177 ymin: 3560436.632155 xmax: -12627306.217347 ymax: 5430229.021262 spatialReference:[AGSSpatialReference webMercatorSpatialReference]];
    [self.mapView zoomToEnvelope:envelope animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - AGSLayerDelegate

-(void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error {
    //notify the user of the error using the alert view
    [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
}

-(void)layerDidLoad:(AGSLayer *)layer {
    if (layer == self.dynamicMapServiceLayer) {
        //un hide the container view
        self.listContainerView.hidden = NO;
        //pass the dynamicLayerInfos array to the list view
        self.layersListViewController.layerInfos = [self.dynamicMapServiceLayer.mapServiceInfo.layerInfos mutableCopy];
    }
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //save the reference to the LayersListViewController
    //when its embeded in the container view
    //and assign self as the delegate
    if ([segue.identifier isEqualToString:@"ListEmbedSegue"]) {
        self.layersListViewController = segue.destinationViewController;
        self.layersListViewController.delegate = self;
    }
}

#pragma mark - LayersListDelegate

-(void)layersListViewController:(LayersListViewController *)layersListViewController didUpdateLayerInfos:(NSArray *)dynamicLayerInfos {
    //assign the new array of AGSDynamicLayerInfo on the dynamicMapServiceLayer
    //and refresh to update the changes
    self.dynamicMapServiceLayer.dynamicLayerInfos = dynamicLayerInfos;
    [self.dynamicMapServiceLayer refresh];
}

@end
