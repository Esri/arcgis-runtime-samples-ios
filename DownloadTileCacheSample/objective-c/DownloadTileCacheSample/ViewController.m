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
#import "MessageHelper.h"

@interface ViewController ()
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
    self.tiledLayer = [[AGSTiledMapServiceLayer alloc] initWithURL:tiledUrl];
    self.tiledLayer.delegate  = self;
    [self.mapView addMapLayer:self.tiledLayer withName:@"World Street Map"];
    
       
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
        self.levelStepper.maximumValue = self.tiledLayer.tileInfo.lods.count - 1;
        
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
    NSInteger index = [self.tiledLayer.mapServiceInfo.tileInfo.lods indexOfObject:self.tiledLayer.currentLOD];
    self.levelStepper.maximumValue = self.tiledLayer.tileInfo.lods.count - index;
    self.levelStepper.minimumValue = 0;
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
    NSString* currentScale = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:self.tiledLayer.currentLOD.scale] numberStyle:NSNumberFormatterDecimalStyle];
    AGSLOD * maxLOD = [self.tiledLayer.mapServiceInfo.tileInfo.lods objectAtIndex:self.levelStepper.value];
    NSString* maxScale = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:maxLOD.scale] numberStyle:NSNumberFormatterDecimalStyle];
    self.scaleLabel.text = [NSString stringWithFormat:@"1:%@\n\tto\n1:%@",currentScale , maxScale];
}

- (IBAction)estimateAction:(id)sender
{
    
    //Prepare list of levels to download
    NSArray *desiredLevels = [self levelsWithCount:self.levelStepper.value startingAt:self.tiledLayer.currentLOD fromLODs:self.tiledLayer.tileInfo.lods];
    NSLog(@"LODs requested %@", desiredLevels);
    
    //Use current envelope to download
    AGSEnvelope *extent = [self.mapView visibleAreaEnvelope];
    
    //Prepare params with levels and envelope
    AGSExportTileCacheParams *params = [[AGSExportTileCacheParams alloc] initWithLevelsOfDetail:desiredLevels areaOfInterest:extent];

    //kick-off operation to estimate size
    [self.tileCacheTask estimateTileCacheSizeWithParameters:params status:^(AGSResumableTaskJobStatus status, NSDictionary *userInfo) {
        NSLog(@"%@, %@", AGSResumableTaskJobStatusAsString(status) ,userInfo);
    } completion:^(AGSExportTileCacheSizeEstimate *tileCacheSizeEstimate, NSError *error) {
        if ( error != nil) {
            
            //Report error to user
            [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            [SVProgressHUD dismiss];
        }else{
            
            //Display results (# of bytes and tiles), properly formatted, ofcourse
            NSNumberFormatter* tileCountFormatter = [[NSNumberFormatter alloc]init];
            [tileCountFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [tileCountFormatter setMaximumFractionDigits:0];
            NSString* tileCountString = [tileCountFormatter stringFromNumber:[NSNumber numberWithInteger:tileCacheSizeEstimate.tileCount]];
            
            NSByteCountFormatter* byteCountFormatter = [[NSByteCountFormatter alloc]init];
            NSString* byteCountString = [byteCountFormatter stringFromByteCount:tileCacheSizeEstimate.fileSize];
            self.estimateLabel.text = [[NSString alloc] initWithFormat:@"%@ / %@ tiles", byteCountString, tileCountString];
            [SVProgressHUD showSuccessWithStatus:[[NSString alloc] initWithFormat:@"Estimated size:\n%@ bytes / %@ tiles", byteCountString, tileCountString]];
        
        }

    }];
    [SVProgressHUD showWithStatus:@"Estimating\n size" maskType:SVProgressHUDMaskTypeGradient];

}



- (IBAction)downloadAction:(id)sender
{
    
    //Prepare list of levels to download
    NSArray *desiredLevels = [self levelsWithCount:self.levelStepper.value startingAt:self.tiledLayer.currentLOD fromLODs:self.tiledLayer.tileInfo.lods];
    NSLog(@"LODs requested %@", desiredLevels);
    
    //Use current envelope to download
    AGSEnvelope *extent = [self.mapView visibleAreaEnvelope];
    
    //Prepare params using levels and envelope
    AGSExportTileCacheParams *params = [[AGSExportTileCacheParams alloc] initWithLevelsOfDetail:desiredLevels areaOfInterest:extent];

    //Kick-off operation
    [self.tileCacheTask exportTileCacheWithParameters:params downloadFolderPath:nil useExisting:YES status:^(AGSResumableTaskJobStatus status, NSDictionary *userInfo) {
        
        //Print the job status
        NSLog(@"%@, %@", AGSResumableTaskJobStatusAsString(status) ,userInfo);
        NSArray *allMessages =  [userInfo objectForKey:@"messages"];
        
        //Display download progress if we are fetching result
        if (status == AGSResumableTaskJobStatusFetchingResult) {
            NSNumber* totalBytesDownloaded = userInfo[@"AGSDownloadProgressTotalBytesDownloaded"];
            NSNumber* totalBytesExpected = userInfo[@"AGSDownloadProgressTotalBytesExpected"];
            if(totalBytesDownloaded!=nil && totalBytesExpected!=nil){
                double dPercentage = (double)([totalBytesDownloaded doubleValue]/[totalBytesExpected doubleValue]);
                [SVProgressHUD showProgress:dPercentage status:@"Downloading" maskType:SVProgressHUDMaskTypeGradient];
            }
        }else if ( allMessages.count) {
            
            //Else, display latest progress message provided by the service
            [SVProgressHUD showWithStatus:[MessageHelper extractMostRecentMessage:allMessages] maskType:SVProgressHUDMaskTypeGradient];
        }
        
        
    } completion:^(AGSLocalTiledLayer *localTiledLayer, NSError *error) {
        [SVProgressHUD dismiss];
        if (error){
            
            //alert the user
            [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            self.estimateLabel.text = @"";
        }
        else{
            
            //clear out the map, and add the downloaded tile cache to the map
            [self.mapView reset];
            [self.mapView addMapLayer:localTiledLayer withName:@"offline"];

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



- (NSArray*) levelsWithCount:(NSInteger)count startingAt:(AGSLOD*)startLOD fromLODs:(NSArray*)allLODs
{
    
    NSInteger index = [allLODs indexOfObject:startLOD];
    NSRange range = NSMakeRange( index, count);
    NSArray *desiredLODs = [allLODs subarrayWithRange: range];
    NSMutableArray *desiredLevels = [[NSMutableArray alloc] init];
    for (AGSLOD* LOD  in desiredLODs) {
        [desiredLevels addObject:[NSNumber numberWithInteger:LOD.level]];
    }
    
    return desiredLevels;
    

}


@end
