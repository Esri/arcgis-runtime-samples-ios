// Copyright 2013 ESRI
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

#import "ViewController.h"
#import "BackgroundHelper.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"

@interface ViewController ()
@property(nonatomic, strong) AGSEstimateTileCacheSizeJob *estimateTileCacheSizeJob;
@property(nonatomic, strong) AGSExportTileCacheJob *exportTileCacheJob;
@end

@implementation ViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //You can change this to any other service on tiledbasemaps.arcgis.com if you have an ArcGIS for Organizations subscription
    NSString* tileServiceURL = @"http://sampleserver6.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer";
    
    //Add basemap layer to the map
    //Set delegate to be notified of success or failure while loading
    NSURL *tiledUrl = [[NSURL alloc] initWithString:tileServiceURL];
    self.tiledLayer = [[AGSArcGISTiledLayer alloc] initWithURL:tiledUrl];
    
    __weak __typeof(self) weakSelf = self;
    [self.tiledLayer loadWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            [weakSelf layer:weakSelf.tiledLayer didFailToLoadWithError:error];
        }
        else {
            [weakSelf layerDidLoad:weakSelf.tiledLayer];
        }
    }];
    self.mapView.map = [AGSMap mapWithBasemap:[AGSBasemap basemapWithBaseLayer:self.tiledLayer]];
    
       
    // Init the tile cache task
    if ( self.tileCacheTask == nil) {
        NSURL *tiledUrl = [[NSURL alloc] initWithString:tileServiceURL];
        self.tileCacheTask = [[AGSExportTileCacheTask alloc] initWithURL:tiledUrl];
    }

    self.scaleLabel.numberOfLines = 0;
}



- (void)layer:(AGSLayer *)layer didFailToLoadWithError:(NSError *)error{
    //Alert user of error
    [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:Nil cancelButtonTitle:nil otherButtonTitles:nil, nil] show];
}

- (void)layerDidLoad:(AGSLayer *)layer{
    if (layer == self.tiledLayer) {
        //Initialize UIStepper based on number of scale levels in the tiled layer
        self.levelStepper.value = 0;
        self.levelStepper.minimumValue = 0;
        self.levelStepper.maximumValue = self.tiledLayer.tileInfo.levelsOfDetail.count - 1;
        
        //Register observer for mapScale property so we can reset the stepper and other UI when map is zoomed in/out
        [self.mapView addObserver:self forKeyPath:@"mapScale" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    //Clear out any estimate or previously chosen levels by the user
    //They are no longer relevant as the map's scale has changed
    //Disable buttons to force the user to specify levels again
    self.estimateLabel.text = @"";
    self.scaleLabel.text = @"";
    self.lodLabel.text = @"";
    self.estimateButton.enabled = NO;
    self.downloadButton.enabled = NO;

    //Re-initialize the stepper with possible values based on current map scale
    NSInteger index = [self.tiledLayer.tileInfo.levelsOfDetail indexOfObject:[self currentLOD]];
    self.levelStepper.maximumValue = self.tiledLayer.tileInfo.levelsOfDetail.count - index;
    self.levelStepper.minimumValue = 1;
    self.levelStepper.value = 0;
}


- (IBAction)changeLevels:(id)sender
{
    //Enable buttons because the user has specified how many levels to download
    self.estimateButton.enabled = YES;
    self.downloadButton.enabled = YES;
    self.levelStepper.minimumValue = 1;

    //Display the levels
    self.lodLabel.text = [[NSNumber numberWithInt:self.levelStepper.value] stringValue];

    //Display the scale range that will be downloaded based on specified levels
    AGSLevelOfDetail *currentLOD = [self currentLOD];
    NSInteger currentLODIndex = [self.tiledLayer.tileInfo.levelsOfDetail indexOfObject:currentLOD];
    NSString* currentScale = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:[self currentLOD].scale] numberStyle:NSNumberFormatterDecimalStyle];
    AGSLevelOfDetail * maxLOD = [self.tiledLayer.mapServiceInfo.tileInfo.levelsOfDetail objectAtIndex:self.levelStepper.value + (currentLODIndex - 1)];
    NSString* maxScale = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:maxLOD.scale] numberStyle:NSNumberFormatterDecimalStyle];
    self.scaleLabel.text = [NSString stringWithFormat:@"1:%@\n\tto\n1:%@",currentScale , maxScale];
}

- (IBAction)estimateAction:(id)sender
{
    
    //Prepare list of levels to download
    NSArray *desiredLevels = [self levelsWithCount:self.levelStepper.value startingAt:[self currentLOD] fromLODs:self.tiledLayer.tileInfo.levelsOfDetail];
    NSLog(@"LODs requested %@", desiredLevels);
    
    //Use current envelope to download
    AGSEnvelope *extent = self.mapView.visibleArea.extent;
    
    //Prepare params with levels and envelope
    AGSExportTileCacheParameters *params = [AGSExportTileCacheParameters tileCacheParameters];
    params.areaOfInterest = extent;
    params.levelIDs = desiredLevels;
    
    //kick-off operation to estimate size
    __weak __typeof(self) weakSelf = self;
    self.estimateTileCacheSizeJob = [self.tileCacheTask estimateTileCacheSizeJobWithParameters:params];
    
    //set current job so BackgroundHelper can function
    ((AppDelegate *)[UIApplication sharedApplication].delegate).currentJob = self.estimateTileCacheSizeJob;
    
    [self.estimateTileCacheSizeJob startWithStatusHandler:^(AGSJobStatus status) {
        [SVProgressHUD showWithStatus:[weakSelf stringForJobStatus:status] maskType:SVProgressHUDMaskTypeGradient];
    } completion:^(AGSEstimateTileCacheSizeResult * _Nullable result, NSError * _Nullable error) {
        //dismiss progress indicator
        [SVProgressHUD dismiss];
        
        //clear current job
        ((AppDelegate *)[UIApplication sharedApplication].delegate).currentJob = nil;
        
        if (error) {
            //Report error to user
            [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
        else {
            //Display results (# of bytes and tiles), properly formatted, ofcourse
            NSNumberFormatter* tileCountFormatter = [[NSNumberFormatter alloc]init];
            [tileCountFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [tileCountFormatter setMaximumFractionDigits:0];
            NSString* tileCountString = [tileCountFormatter stringFromNumber:[NSNumber numberWithInteger:result.tileCount]];
            
            NSByteCountFormatter* byteCountFormatter = [[NSByteCountFormatter alloc]init];
            NSString* byteCountString = [byteCountFormatter stringFromByteCount:result.fileSize];
            weakSelf.estimateLabel.text = [[NSString alloc] initWithFormat:@"%@ / %@ tiles", byteCountString, tileCountString];
            [SVProgressHUD showSuccessWithStatus:[[NSString alloc] initWithFormat:@"Estimated size:\n%@ bytes / %@ tiles", byteCountString, tileCountString]];
        }
    }];
    [SVProgressHUD showWithStatus:@"Estimating\n size" maskType:SVProgressHUDMaskTypeGradient];

}



- (IBAction)downloadAction:(id)sender
{
    
    //Prepare list of levels to download
    NSArray *desiredLevels = [self levelsWithCount:self.levelStepper.value startingAt:[self currentLOD] fromLODs:self.tiledLayer.tileInfo.levelsOfDetail];
    NSLog(@"LODs requested %@", desiredLevels);
    
    //Use current envelope to download
    AGSEnvelope *extent = self.mapView.visibleArea.extent;
    
    //Prepare params using levels and envelope
    AGSExportTileCacheParameters *params = [AGSExportTileCacheParameters tileCacheParameters];
    params.areaOfInterest = extent;
    params.levelIDs = desiredLevels;

    //Kick-off operation
    __weak __typeof(self) weakSelf = self;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *tpkPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"MyTileCache.tpk"];
    self.exportTileCacheJob = [self.tileCacheTask exportTileCacheJobWithParameters:params downloadFileURL:[NSURL fileURLWithPath:tpkPath]];
    
    //set current job so BackgroundHelper can function
    ((AppDelegate *)[UIApplication sharedApplication].delegate).currentJob = self.exportTileCacheJob;
    
    [self.exportTileCacheJob startWithStatusHandler:^(AGSJobStatus status) {
        //Else, display latest progress message provided by the service
        [SVProgressHUD showWithStatus:[weakSelf stringForJobStatus:status] maskType:SVProgressHUDMaskTypeGradient];
    } completion:^(AGSTileCache * _Nullable result, NSError * _Nullable error) {
        //dismiss progress indicator
        [SVProgressHUD dismiss];
        
        //clear current job
        ((AppDelegate *)[UIApplication sharedApplication].delegate).currentJob = nil;
        
        if (error) {
            //alert the user
            [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            weakSelf.estimateLabel.text = @"";
        }
        else {

            //clear out the map, and add the downloaded tile cache to the map
            AGSArcGISTiledLayer *localTiledLayer = [AGSArcGISTiledLayer ArcGISTiledLayerWithTileCache:result];
            weakSelf.mapView.map = [AGSMap mapWithBasemap:[AGSBasemap basemapWithBaseLayer:localTiledLayer]];
            
            //Tell the user we're done
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download complete" message:@"The tile cache has been added to the map." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            
            //Remove the option to download again.
            [[self.downloadPanel subviews]
             makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
            [BackgroundHelper postLocalNotificationIfAppNotActive:@"Tile cache downloaded."];
        }
    }];
    [SVProgressHUD showWithStatus:@"Preparing\n to download" maskType:SVProgressHUDMaskTypeGradient];
    
}



- (NSArray*) levelsWithCount:(NSInteger)count startingAt:(AGSLevelOfDetail*)startLOD fromLODs:(NSArray*)allLODs
{
    
    NSInteger index = [allLODs indexOfObject:startLOD];
    NSRange range = NSMakeRange( index, count);
    NSArray *desiredLODs = [allLODs subarrayWithRange: range];
    NSMutableArray *desiredLevels = [[NSMutableArray alloc] init];
    for (AGSLevelOfDetail *LOD in desiredLODs) {
        [desiredLevels addObject:[NSNumber numberWithInteger:LOD.level]];
    }
    
    return desiredLevels;
    

}

- (NSString*)stringForJobStatus:(AGSJobStatus)status {
    switch (status) {
        case AGSJobStatusNotStarted:
            return @"Not Started";
            break;
        case AGSJobStatusStarted:
            return @"Started";
            break;
        case AGSJobStatusPaused:
            return @"Paused";
            break;
        case AGSJobStatusSucceeded:
            return @"Succeeded";
            break;
        case AGSJobStatusFailed:
            return @"Failed";
            break;
        default:
            break;
    }
}

-(AGSLevelOfDetail*)currentLOD {
    for (int i = 0; i < self.tiledLayer.tileInfo.levelsOfDetail.count; i++) {
        AGSLevelOfDetail *lod = [self.tiledLayer.tileInfo.levelsOfDetail objectAtIndex:i];
        if (self.mapView.mapScale > lod.scale) {
            if (i > 0) {
                return [self.tiledLayer.tileInfo.levelsOfDetail objectAtIndex:i-1];
            }
            return lod;
        }
    }
    return nil;
}

@end
