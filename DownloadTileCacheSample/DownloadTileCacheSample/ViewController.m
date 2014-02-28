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
    [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:Nil cancelButtonTitle:nil otherButtonTitles:nil, nil] show];
}

- (void)layerDidLoad:(AGSLayer *)layer{
    if (layer == self.tiledLayer) {
        self.scaleStepper.value = 0;
        self.scaleStepper.minimumValue = 0;
        self.scaleStepper.maximumValue = self.tiledLayer.tileInfo.lods.count;
        [self.mapView addObserver:self forKeyPath:@"mapScale" options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    self.estimateLabel.text = @"";
    self.scaleLabel.text = @"";
    self.lodLabel.text = @"";
    self.estimateButton.enabled = NO;
    self.downloadButton.enabled = NO;

    
    NSInteger index = [self.tiledLayer.mapServiceInfo.tileInfo.lods indexOfObject:self.tiledLayer.currentLOD];
    self.scaleStepper.maximumValue = self.tiledLayer.tileInfo.lods.count - index;
    self.scaleStepper.minimumValue = 0;
    self.scaleStepper.value = 0;
}

- (AGSLOD*) bestFitLODForEnvelope:(AGSEnvelope*)env{
    CGRect screenRect = [self.mapView toScreenRect:env];
    double impliedResolution = env.width /    screenRect.size.width;
    
    AGSMapServiceInfo *mapServiceInfo = self.tiledLayer.mapServiceInfo;
    
    for ( int i=0; i < mapServiceInfo.tileInfo.lods.count; i++ ) {
        AGSLOD * tempLod = [mapServiceInfo.tileInfo.lods objectAtIndex:i];
        if(impliedResolution > tempLod.resolution)
            return tempLod;
    }
    return [mapServiceInfo.tileInfo.lods lastObject];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeLevels:(id)sender
{
    self.estimateButton.enabled = YES;
    self.downloadButton.enabled = YES;
    self.scaleStepper.minimumValue = 1;
    
    AGSLOD * lod = [self.tiledLayer.mapServiceInfo.tileInfo.lods objectAtIndex:self.scaleStepper.value];
    self.lodLabel.text = [[NSNumber numberWithInt:self.scaleStepper.value] stringValue];
    self.scaleLabel.text = [NSString stringWithFormat:@"1:%@\n  to\n1:%@", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:self.tiledLayer.currentLOD.scale] numberStyle:NSNumberFormatterDecimalStyle],[NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:lod.scale] numberStyle:NSNumberFormatterDecimalStyle]];
}

- (IBAction)estimateAction:(id)sender
{
    
    NSArray *arrayLods = [self generateLods];
    NSLog(@"LODs %@", arrayLods);
    
    AGSEnvelope *extent = [self.mapView visibleAreaEnvelope];
    
    
    AGSExportTileCacheParams *params = [[AGSExportTileCacheParams alloc] initWithLevelsOfDetail:arrayLods areaOfInterest:extent];

    [SVProgressHUD showWithStatus:@"Estimating\n size" maskType:SVProgressHUDMaskTypeGradient];
    [self.tileCacheTask estimateTileCacheSizeWithParameters:params status:^(AGSResumableTaskJobStatus status, NSDictionary *userInfo) {
        NSLog(@"%@, %@", AGSResumableTaskJobStatusAsString(status) ,userInfo);
    } completion:^(AGSExportTileCacheSizeEstimate *tileCacheSizeEstimate, NSError *error) {
        if ( error != nil) {
            [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            [SVProgressHUD dismiss];
        }else{
            NSNumberFormatter* tileCountFormatter = [[NSNumberFormatter alloc]init];
            [tileCountFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
            [tileCountFormatter setMaximumFractionDigits:0];
            
            NSString* tileCountString = [tileCountFormatter stringFromNumber:[NSNumber numberWithInteger:tileCacheSizeEstimate.tileCount]];
            
            NSByteCountFormatter* byteCountFormatter = [[NSByteCountFormatter alloc]init];
            NSString* byteCountString = [byteCountFormatter stringFromByteCount:tileCacheSizeEstimate.fileSize];
            self.estimateLabel.text = [[NSString alloc] initWithFormat:@"%@  / %@ tiles", byteCountString, tileCountString];
            [SVProgressHUD showSuccessWithStatus:[[NSString alloc] initWithFormat:@"%@  / %@ tiles", byteCountString, tileCountString]];
        
        }

    }];
    
}



- (IBAction)downloadAction:(id)sender
{
    
    NSArray *arrayLods = [self generateLods];
    NSLog(@"LODs to be requested for the cache : %@", arrayLods);
    
    // Get the map coordinate extent from view control
    AGSEnvelope *extent = [self.mapView visibleAreaEnvelope];
    
    AGSExportTileCacheParams *params = [[AGSExportTileCacheParams alloc] initWithLevelsOfDetail:arrayLods areaOfInterest:extent];

    self.estimateLabel.text = @"";
    [SVProgressHUD showWithStatus:@"Preparing\n to download" maskType:SVProgressHUDMaskTypeGradient];
    
    self.operationToCancel = [self.tileCacheTask exportTileCacheWithParameters:params downloadFolderPath:nil useExisting:YES status:^(AGSResumableTaskJobStatus status, NSDictionary *userInfo) {
          NSLog(@"%@, %@", AGSResumableTaskJobStatusAsString(status) ,userInfo);
        NSArray *allMessages =  [userInfo objectForKey:@"messages"];
        
        if (status == AGSResumableTaskJobStatusFetchingResult) {
            NSNumber* totalBytesDownloaded = userInfo[@"AGSDownloadProgressTotalBytesDownloaded"];
            NSNumber* totalBytesExpected = userInfo[@"AGSDownloadProgressTotalBytesExpected"];
            if(totalBytesDownloaded!=nil && totalBytesExpected!=nil){
                double dPercentage = (double)([totalBytesDownloaded doubleValue]/[totalBytesExpected doubleValue]);
                [SVProgressHUD showProgress:dPercentage status:@"Downloading" maskType:SVProgressHUDMaskTypeGradient];
            }
        }else if ( allMessages.count) {
            [SVProgressHUD showWithStatus:[MessageHelper extractMostRecentMessage:allMessages] maskType:SVProgressHUDMaskTypeGradient];
        }
        
        
    } completion:^(AGSLocalTiledLayer *localTiledLayer, NSError *error) {
        [SVProgressHUD dismiss];
        if (error){
            [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            self.estimateLabel.text = @"";
        }
        else{
            [self.mapView reset];
            [self.mapView addMapLayer:localTiledLayer withName:@"offline"];
            [self.mapView zoomToEnvelope:localTiledLayer.fullEnvelope animated:NO];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download complete" message:@"The tile cache has been added to the map." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            
            [[self.floatingView subviews]
             makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
            [BackgroundHelper postLocalNotificationIfAppNotActive:@"Tile cache downloaded."];
        }
    }];
}



- (NSArray*) generateLods
{
    
    AGSLOD* displayedLOD  = self.tiledLayer.currentLOD;
    NSInteger index = [self.tiledLayer.mapServiceInfo.tileInfo.lods indexOfObject:displayedLOD];
    NSRange range = NSMakeRange( index, self.scaleStepper.value );
    NSArray *lods = [self.tiledLayer.mapServiceInfo.tileInfo.lods subarrayWithRange: range];
    NSMutableArray *arrayLods = [[NSMutableArray alloc] init];
    for (AGSLOD* lod  in lods) {
        [arrayLods addObject:[NSNumber numberWithInteger:lod.level]];
    }
    
    return arrayLods;
    

}


@end
