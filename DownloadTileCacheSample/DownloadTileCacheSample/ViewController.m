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

@interface ViewController ()

@property (nonatomic,strong) IBOutlet AGSMapView *mapView;
@property (nonatomic,strong) AGSTiledMapServiceLayer *tiledLayer;
@property (nonatomic,strong) IBOutlet UIView *floatingView;
@property (nonatomic,strong) AGSTileCacheTask *tileCacheTask;
@property (nonatomic,strong) IBOutlet UILabel *scaleLabel;
@property (nonatomic,strong) IBOutlet UILabel *estimateLabel;
@property (nonatomic,strong) IBOutlet UILabel *lodLabel;
@property (nonatomic,strong) SPUserResizableView *lastResizableView;
@property (nonatomic) CGFloat lastScale;
@property (nonatomic,strong) IBOutlet UISegmentedControl *offlineOnlineControl;

// Overlay
@property (nonatomic,strong) IBOutlet UIView *overlay;
@property (nonatomic,strong) IBOutlet UILabel *statusLabel;
@property (nonatomic,strong) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic,strong) IBOutlet UIProgressView *progressBar;
@property (nonatomic,strong) IBOutlet UILabel *percentageValue;

@property (nonatomic,strong) IBOutlet UIButton *estimateButton;
@property (nonatomic,strong) IBOutlet UIButton *downloadButton;

@property (nonatomic,strong) IBOutlet UIImageView *backgroundGray;
@property (nonatomic,strong) IBOutlet UIImageView *backgroundOverlay;

@property (nonatomic) double lastLod;
@property (nonatomic,strong) id operationToCancel;

@property (nonatomic,strong) IBOutlet UILabel *timerLabel;
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
    
    //You can change this to any other service on tiledbasemaps.arcgis.com
    NSString* tileServiceURL = @"http://tiledbasemaps.arcgis.com/arcgis/rest/services/World_Street_Map/MapServer";
    
    NSURL *tiledUrl = [[NSURL alloc] initWithString:tileServiceURL];
    self.tiledLayer = [[AGSTiledMapServiceLayer alloc] initWithURL:tiledUrl];
    
    [self.mapView addMapLayer:self.tiledLayer withName:@"World Street Map"];
    
    //Zoom in to Barcelona
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
        NSURL *tiledUrl = [[NSURL alloc] initWithString:tileServiceURL];
        self.tileCacheTask = [[AGSTileCacheTask alloc] initWithURL:tiledUrl];
    }

    [self hideGrayBox];
    
    self.scaleLabel.numberOfLines = 0;

}

// Gets called after resizing the extent box
- (void)userResizableViewDidEndEditing:(SPUserResizableView *)userResizableView
{
    AGSEnvelope *testEnvelope = [self.mapView toMapEnvelope:userResizableView.frame];
    NSLog(@"Box Test %@ Extent %@", userResizableView, testEnvelope);
    self.lastResizableView = userResizableView;
    
    //self.results.text = [[NSString alloc] initWithFormat:@"XMin:%f XMax:%f YMin:%f YMax:%f", testEnvelope.xmin, testEnvelope.xmax, testEnvelope.ymin, testEnvelope.ymax ];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)changeLODs:(id)sender
{
    self.offlineOnlineControl.enabled = YES;
    self.estimateButton.enabled = YES;
    self.downloadButton.enabled = YES;
    
    AGSMapServiceInfo *mapServiceInfo = self.tiledLayer.mapServiceInfo;    
    AGSLOD * lastLod = [mapServiceInfo.tileInfo.lods objectAtIndex:mapServiceInfo.tileInfo.lods.count-1];
    
    UIStepper *stepper = (UIStepper*)sender;
    if (stepper.value < 0 )
        return;
    if ( stepper.value > lastLod.level ) {
        stepper.value = lastLod.level;
        return;
    }
    
    self.lastLod = stepper.value;
    
    AGSLOD * lod = [mapServiceInfo.tileInfo.lods objectAtIndex:stepper.value];
    self.lodLabel.text = [[NSNumber numberWithInt:stepper.value] stringValue];
    self.scaleLabel.text = [NSString stringWithFormat:@"Scale\n1:%@", [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithInt:lod.scale] numberStyle:NSNumberFormatterDecimalStyle]];
}
- (IBAction)calculateSize:(id)sender
{
    [self hideGrayBox];
    
    NSArray *arrayLods = [self generateLods];
    NSLog(@"LODs %@", arrayLods);
    
    AGSEnvelope *extent = [self.mapView toMapEnvelope:self.lastResizableView.frame];
    NSLog(@"Box Test %@ Extent %@", self.lastResizableView, extent);
    
    
    AGSGenerateTileCacheParams *params = [[AGSGenerateTileCacheParams alloc] initWithLevelsOfDetail:arrayLods areaOfInterest:extent];
    params.recompressionQuality = self.progressBar.progress;
    NSLog(@"recompressionFactor %f",params.recompressionQuality);
    
    [self showOverlay];
    [self.tileCacheTask estimateSizeWithParameters:params status:^(NSString *jobId, AGSTileCacheJobStatus status, NSArray *messages, id result, NSError *error) {
        
        NSLog(@"Processing estimate %@", messages);
        NSLog(@"Estimate %@", [messages description]);
        
        if ( messages.count > 0) {
            NSString * gpDescription =  [[messages objectAtIndex:messages.count-1] description];
            gpDescription = [self parseMessagesDescription:gpDescription];
            self.statusLabel.text = gpDescription;
        }
        
        if ( status == AGSTileCacheJobSucceeded) {
            // Hide progress show labels
             NSLog(@"Finished Processing estimate %@", result);
            AGSTileCacheSizeEstimate *estimateResult = result;
            
            if ( estimateResult != nil){
                NSNumberFormatter* tileCountFormatter = [[NSNumberFormatter alloc]init];
                [tileCountFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                [tileCountFormatter setMaximumFractionDigits:0];
                
                NSString* tileCountString = [tileCountFormatter stringFromNumber:[NSNumber numberWithInt:estimateResult.tileCount]];

                NSByteCountFormatter* byteCountFormatter = [[NSByteCountFormatter alloc]init];
                NSString* byteCountString = [byteCountFormatter stringFromByteCount:estimateResult.fileSize];
                self.estimateLabel.text = [[NSString alloc] initWithFormat:@"%@  / %@ tiles", byteCountString, tileCountString];
            }
            self.statusLabel.text = @"Done";
            
            [self hideOverlay];
            [self showGrayBox];
        }
        
        if ( error != nil) {
            // Hide the screen and display error
            [self hideOverlay];
            [self showGrayBox];
            [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
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

    [self showOverlay];
    self.estimateLabel.text = @"";
    
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
                
                self.estimateLabel.text = detailsMessages.description;
            }
        }
        
        
        NSLog(@"tpk status: %d - %@", status, userInfo);
    } completion:^(AGSLocalTiledLayer *localTiledLayer, NSError *error) {
        if (error){
            [[[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            self.estimateLabel.text = @"";
            [self hideOverlay];
        }
        else{
            [self hideOverlay];
            
            self.estimateLabel.text = [[NSString alloc] initWithFormat:@"Finished downloading tile cache."];
            
            [self.mapView reset];
            [self.mapView addMapLayer:localTiledLayer withName:@"offline"];
            [self.mapView zoomToEnvelope:localTiledLayer.fullEnvelope animated:NO];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cache completed" message:self.estimateLabel.text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
            
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
        self.floatingView.frame = CGRectMake(self.floatingView.frame.origin.x, 400, self.floatingView.frame.size.width, self.floatingView.frame.size.height);
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
    
    if ( [[UIScreen mainScreen] bounds].size.height > 500) {
        self.overlay.frame = CGRectMake(self.overlay.frame.origin.x, 400, self.overlay.frame.size.width, self.overlay.frame.size.height);
    }

    
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
