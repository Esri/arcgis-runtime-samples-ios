//
//  ViewController.m
//  SimpleMap
//
//  Created by Al Pascual on 10/10/12.
//  Copyright (c) 2012 Esri. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic,strong) IBOutlet AGSMapView *mapView;
@property (nonatomic,strong) AGSTiledMapServiceLayer *tiledLayer;
@property (nonatomic,strong) IBOutlet UIView *floatingView;
@property (nonatomic,strong) AGSTileCacheTask *tileCacheTask;
@property (nonatomic,strong) IBOutlet UILabel *lods;
@property (nonatomic,strong) IBOutlet UILabel *results;
@property (nonatomic,strong) SPUserResizableView *lastResizableView;
@property (nonatomic) CGFloat lastScale;
@property (nonatomic,strong) IBOutlet UISegmentedControl *offlineOnlineControl;

// Overlay
@property (nonatomic,strong) IBOutlet UIView *overlay;
@property (nonatomic,strong) IBOutlet UILabel *statusLabel;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic,strong) IBOutlet UIProgressView *progressBar;
@property (nonatomic,strong) IBOutlet UILabel *percentageValue;

@property (nonatomic,strong) IBOutlet UIButton *processButton;
@property (nonatomic,strong) IBOutlet UIButton *downloadButton;

@property (nonatomic,strong) IBOutlet UIImageView *backgroundGray;
@property (nonatomic,strong) IBOutlet UIImageView *backgroundOverlay;

@property (nonatomic) double lastLod;
@property (nonatomic,strong) id operationToCancel;
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
    
    self.overlay.hidden = YES;
    
    NSURL *tiledUrl = [[NSURL alloc] initWithString:ExportTilesMapService];
    self.tiledLayer = [[AGSTiledMapServiceLayer alloc] initWithURL:tiledUrl];
    
    [self.mapView addMapLayer:self.tiledLayer withName:@"World Street Map"];
    
    AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:239370.783 ymin:5065332.002 xmax:243145.221 ymax:5069219.836 spatialReference:self.mapView.spatialReference];
	[self.mapView zoomToEnvelope:env animated:YES];
    
    // (1) Create a user resizable view with a simple red background content view.
    CGRect gripFrame = CGRectMake(50, 150, 200, 150);
    SPUserResizableView *userResizableView = [[SPUserResizableView alloc] initWithFrame:gripFrame];
    UIView *contentView = [[UIView alloc] initWithFrame:gripFrame];
    [contentView setBackgroundColor:[UIColor blackColor]];
    contentView.alpha = 0.4;
    userResizableView.contentView = contentView;
    userResizableView.delegate = self;
    [userResizableView showEditingHandles];   
    [self.view addSubview:userResizableView];
    self.lastResizableView = userResizableView;

    // Init the tile cache task
    if ( self.tileCacheTask == nil) {
        NSURL *tiledUrl = [[NSURL alloc] initWithString:ExportTilesMapService];
        self.tileCacheTask = [[AGSTileCacheTask alloc] initWithURL:tiledUrl];
    }

    [self hideGrayBox];
    

}


- (void)userResizableViewDidEndEditing:(SPUserResizableView *)userResizableView
{
    AGSEnvelope *testEnvelope = [self.mapView toMapEnvelope:userResizableView.frame];
    NSLog(@"Box Test %@ Extent %@", userResizableView, testEnvelope);
    self.lastResizableView = userResizableView;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeLODs:(id)sender
{
    self.offlineOnlineControl.enabled = YES;
    self.processButton.hidden = NO;
    self.downloadButton.hidden = NO;
    
    AGSMapServiceInfo *mapServiceInfo = self.tiledLayer.mapServiceInfo;    
    AGSLOD * lastLod = [mapServiceInfo.tileInfo.lods objectAtIndex:mapServiceInfo.tileInfo.lods.count-1];
    
    UIStepper *stepper = (UIStepper*)sender;
    if (stepper.value < 0 )
        return;
    if ( stepper.value > lastLod.level ) {
        stepper.value = lastLod.level;
        return;
    }
    
    NSLog(@"stepper value %f", stepper.value);
    self.lastLod = stepper.value;
    
    AGSLOD * lod = [mapServiceInfo.tileInfo.lods objectAtIndex:stepper.value];    
    self.lods.text = [NSString stringWithFormat:@"1:%d", (int)lod.scale];
}
- (IBAction)calculateSize:(id)sender
{
    [self hideGrayBox];
    
    NSArray *arrayLods = [self generateLods];
    NSLog(@"LODs %@", arrayLods);
    
    AGSEnvelope *extent = [self.mapView toMapEnvelope:self.lastResizableView.frame];
    NSLog(@"Box Test %@ Extent %@", self.lastResizableView, extent);
    
    AGSGenerateTileCacheParams *params = [[AGSGenerateTileCacheParams alloc] initWithLevelsOfDetail:arrayLods areaOfInterest:extent];
    params.recompressionFactor = self.progressBar.progress;
    NSLog(@"recompressionFactor %f",params.recompressionFactor);
    
    [self showOverlay];
    self.results.text = @"Processing ...";
    [self.tileCacheTask estimateSizeWithParameters:params status:^(NSString *jobId, AGSTileCacheJobStatus status, NSArray *messages, id result, NSError *error) {
        
        NSLog(@"Processing estimate %@", messages);
        NSLog(@"Estimate %@", [messages description]);
        
        if ( messages.count > 0) {
            NSString * gpDescription =  [[messages objectAtIndex:messages.count-1] description];
            NSLog(@"gpDescription %@", gpDescription);
            gpDescription = [self parseMessagesDescription:gpDescription];
            self.statusLabel.text = gpDescription;
        }
        
        if ( status == AGSTileCacheJobSucceeded) {
            // Hide progress show labels
             NSLog(@"Finished Processing estimate %@", result);
            AGSTileCacheSizeEstimate *estimateResult = result;
            if ( estimateResult != nil)
                self.results.text = [[NSString alloc] initWithFormat:@"File Size %lld / Tile Count %ld ", estimateResult.fileSize, (long)estimateResult.tileCount];
            self.statusLabel.text = @"Done";
            
            [self hideOverlay];
            [self showGrayBox];
        }
        
        if ( error != nil) {
            // Hide the screen and display error
            self.results.text = error.description;
            [self hideOverlay];
            [self showGrayBox];
        }
    }];
    
    
}

- (IBAction)cancelAll:(id)sender {
    
    [self.operationToCancel cancel];
    
    [self hideOverlay];
}

- (IBAction)download:(id)sender
{
    [self hideGrayBox];
    
    NSArray *arrayLods = [self generateLods];
    NSLog(@"LODs %@", arrayLods);
    
    // Get the map coordinate extent from view control
    AGSEnvelope *extent = [self.mapView toMapEnvelope:self.lastResizableView.frame];
    
    AGSGenerateTileCacheParams *params = [[AGSGenerateTileCacheParams alloc] initWithLevelsOfDetail:arrayLods areaOfInterest:extent];
    params.recompressionFactor = self.progressBar.progress;
    
    [self showOverlay];
    
    self.operationToCancel = [self.tileCacheTask generateTileCacheAndDownloadWithParameters:params downloadFolderPath:nil useExisting:YES status:^(AGSAsyncServerJobStatus status, NSDictionary *userInfo) {
        
        NSArray *allMessages =  [userInfo objectForKey:@"messages"];
        
        if ( allMessages.count > 0) {
            NSString *gpDescription = [[allMessages objectAtIndex:allMessages.count-1 ] description];
            self.statusLabel.text = [self parseMessagesDescription:gpDescription];
            
            AGSGPMessage *detailsMessages = [allMessages objectAtIndex:allMessages.count-2 ];
            if ( detailsMessages != nil) {
                
                NSLog(@"Percentage %@", detailsMessages.description);
                
                double dPercentage = [self parsePercentage:detailsMessages.description];
                if (dPercentage > 0 )
                {
                    self.progressBar.hidden = NO;
                    self.percentageValue.hidden = NO;
                    self.percentageValue.text = [[NSString alloc] initWithFormat:@"%d%%", (int)dPercentage  ];
                    [self.progressBar setProgress:dPercentage/100 animated:YES];
                }
                
                self.results.text = detailsMessages.description;
            }
        }
        
        
        NSLog(@"tpk status: %d - %@", status, userInfo);
    } completion:^(AGSLocalTiledLayer *localTiledLayer, NSError *error) {
        if (error){
            NSLog(@"tpk error: %@", error);
            
            self.results.text = [error description];
            [self hideOverlay];
        }
        else{
            [self hideOverlay];
            
            self.results.text = @"Done!";
            [self.mapView reset];
            [self.mapView addMapLayer:localTiledLayer withName:@"offline"];
            [self.mapView zoomToEnvelope:localTiledLayer.fullEnvelope animated:NO];
            
        }
    }];
}

- (IBAction)goOfflineOnline:(id)sender {
    
    UISegmentedControl *offlineOnline = (UISegmentedControl*) sender;
    //Online
    if ( offlineOnline.selectedSegmentIndex == 0 )
    {
        AGSEnvelope *currentEnvelope = self.mapView.visibleAreaEnvelope;
        [self.mapView reset];
        [self.mapView addMapLayer:self.tiledLayer withName:@"World Street Map"];
        [self.mapView zoomToEnvelope:currentEnvelope animated:NO];
        
        [self hideGrayBox];
    }
    // Offline
    else{
        [self showGrayBox];
    }
}


- (NSArray*) generateLods
{
    
    // Get the map coordinate extent from view control
    AGSEnvelope *extent = [self.mapView toMapEnvelope:self.lastResizableView.frame];
    NSLog(@"Box Test %@ Extent %@", self.lastResizableView, extent);
    
    //double extentResolution = self.mapView.resolution;
    double mapWidth = [self.mapView toScreenRect:extent].size.width;
    double extentResolution = (extent.width / mapWidth);
    
    AGSMapServiceInfo *mapServiceInfo = self.tiledLayer.mapServiceInfo;
   
    double startLod = 0;
    for ( int i=0; i < mapServiceInfo.tileInfo.lods.count; i++ ) {
        AGSLOD * tempLod = [mapServiceInfo.tileInfo.lods objectAtIndex:i];
        NSLog(@" Lod resolution %f and target resolution %f", tempLod.resolution, extentResolution);
        if ( tempLod.resolution <= extentResolution) {
            startLod = tempLod.level;
            break;
        }
    }
    
    NSMutableArray *arrayLods = [[NSMutableArray alloc] init];
    for (int i=startLod; i <= self.lastLod; i++) {
        [arrayLods addObject:[NSString stringWithFormat:@"%d", i]];
    }
    
    return arrayLods;
}

- (void) showGrayBox
{
    // Enable the rest
    self.floatingView.hidden = NO;
    self.lastResizableView.hidden = NO;
    self.lastResizableView.hidden = NO;
    
    if ( [[UIScreen mainScreen] bounds].size.height > 500) {
        self.floatingView.frame = CGRectMake(self.floatingView.frame.origin.x, 425, self.floatingView.frame.size.width, self.floatingView.frame.size.height);
    }
}

- (void) hideGrayBox
{
    // Disable the rest
    self.floatingView.hidden = YES;
    self.lastResizableView.hidden = YES;
    self.lastResizableView.hidden = YES;
}

- (void) showOverlay
{
    self.overlay.hidden = NO;
    self.progressBar.hidden = YES;
    self.percentageValue.hidden = YES;
    [self.activity startAnimating];
    self.statusLabel.text = @"Starting...";
    
    
    
}

- (void) hideOverlay
{
    self.overlay.hidden = YES;
    self.progressBar.hidden = YES;
    self.percentageValue.hidden = YES;
    [self.activity stopAnimating];
    
    
    
}

- (double) parsePercentage:(NSString*)percentageString
{
    NSRange range = [percentageString rangeOfString:@"Finished:: "];
    if ( range.length > 0) {
        NSString *substring = [percentageString substringFromIndex:NSMaxRange(range)];
        NSLog(@"Substring %@", substring);
        substring = [substring stringByReplacingOccurrencesOfString:@" percent"
                                             withString:@""];
        
        return [substring doubleValue];
    }
    return 0;
}

- (NSString *) parseMessagesDescription:(NSString*)description
{
    NSRange range = [description rangeOfString:@"description:"];
    if ( range.length > 0 )
    {
        NSString *substring = [description substringFromIndex:NSMaxRange(range)];        
        return substring;
    }
    
    return description;
}

@end
