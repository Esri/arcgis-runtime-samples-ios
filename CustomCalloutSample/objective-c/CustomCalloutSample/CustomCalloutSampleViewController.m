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

#import "CustomCalloutSampleViewController.h"
#import "CustomWebViewController.h"
#import "CustomHybridViewController.h"

#define kCustomHybridViewControllerIdentifier @"CustomHybridViewController"
#define kCustomWebViewControllerIdentifier @"CustomWebViewController"

//this enum is used to determine the type of graphic created
typedef enum {
    EmbeddedMapView = 0,    
    EmbeddedWebView,
    CustomInfoView,
    SimpleView
} GraphicType;


@interface CustomCalloutSampleViewController()

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) AGSGraphicsOverlay *graphicsOverlay;

//this is the view controller that handles the loading and operations of the Bing Aerial view in a callout. 
@property (nonatomic, strong) CustomHybridViewController *hybridViewController;

//this is the view controller that handles the loading and operations of the Traffic Camera feed in a callout. 
@property (nonatomic, strong) CustomWebViewController *cameraViewController;

//this method creates the sample graphics. 
- (void)createSampleGraphics;

@end

@implementation CustomCalloutSampleViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle


// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    //Add the basemap.
    self.mapView.map = [AGSMap mapWithBasemap:[AGSBasemap lightGrayCanvasVector]];
	
    //Zooming to an initial envelope with the specified spatial reference of the map.
	AGSSpatialReference *sr = [AGSSpatialReference spatialReferenceWithWKID:102100];
	AGSEnvelope *env = [AGSEnvelope envelopeWithXMin:-9555813.309582941 yMin:4606200.425377472 xMax:-9543583.38505733 yMax:4623780.94188304 spatialReference:sr];
    [self.mapView setViewpointGeometry:env completion:nil];
    
    // set the touch delegate of the mapView so that we know when a tap happens
    self.mapView.touchDelegate = self;
    
    //set the callout delegate so we know when the accessory button is tapped
    self.mapView.callout.delegate = self;
    
    //add graphics layer for the graphics
    self.graphicsOverlay = [AGSGraphicsOverlay graphicsOverlay];
    
    //add the sample graphics
    [self createSampleGraphics];
    
    //add the graphics layer to the map
    [self.mapView.graphicsOverlays addObject:self.graphicsOverlay];
    
    //reference to the storyboard
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    
    //initialize the hybrid map view with street map
    CGRect frame = CGRectMake(0, 0, 125, 125);
    self.hybridViewController = [storyboard instantiateViewControllerWithIdentifier:kCustomHybridViewControllerIdentifier];
    [self.hybridViewController.view setFrame:frame];
    [self.hybridViewController.view setClipsToBounds:YES];
    
    //initialize the traffic camera view
    frame = CGRectMake(0, 0, 125, 125);
	self.cameraViewController = [storyboard instantiateViewControllerWithIdentifier:kCustomWebViewControllerIdentifier];
	[self.cameraViewController.view setFrame:frame];
    [self.cameraViewController.view setClipsToBounds:YES];
    
    [super viewDidLoad];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark AGSGeoViewTouchDelegate

-(void)geoView:(AGSGeoView *)geoView didTapAtScreenPoint:(CGPoint)screenPoint mapPoint:(AGSPoint *)mapPoint{
    
    __weak __typeof(self) weakSelf = self;
    
    // We have to identify which graphic was tapped so we can show a callout.
    // Callouts do not automatically show as they did in 10.2.x
    
    [self.mapView identifyGraphicsOverlay:self.graphicsOverlay screenPoint:screenPoint tolerance:12 returnPopupsOnly:NO maximumResults:1 completion:^(AGSIdentifyGraphicsOverlayResult * _Nonnull identifyResult) {
       
        AGSGraphic *graphic = identifyResult.graphics.firstObject;
        if (graphic){
            // show callout for identified graphic
            [weakSelf showCalloutForGraphic:graphic tapLocation:mapPoint];
        }
        else{
            // nothing tapped - dismiss callout
            [weakSelf.mapView.callout dismiss];
        }
    }];
    
}

-(void)showCalloutForGraphic:(AGSGraphic*)graphic tapLocation:(AGSPoint*)tapLocation{
    
    //extract the type of graphics to check.
    NSNumber *typeNumber = (NSNumber*)[graphic.attributes valueForKey:@"type"];
    GraphicType graphicType = typeNumber.intValue;
    
    switch (graphicType) {
            //graphic's callout is an embedded map view
        case EmbeddedMapView:{
            NSLog(@"%@", @"Tapped on Building");
            
            //call the helper method to update the hybrid map view according to the graphic
            [self.hybridViewController showHybridMapAtGraphic:graphic];
            
            //assign the hybrid map view to the callout view of the main map view
            self.mapView.callout.customView = self.hybridViewController.view;
            
            [self.mapView.callout showCalloutForGraphic:graphic tapLocation:tapLocation animated:YES];
            
            break;
        }
            //graphic's callout is an embedded map view
        case EmbeddedWebView:{
            NSLog(@"%@", @"Tapped on Camera");
            
            //get the url for the image feed from the camera
            NSString *imageURL = [graphic.attributes valueForKey:@"url"];
            
            //create the url object
            NSURL *imageURLObject = [NSURL URLWithString:imageURL];
            
            //load the web view with the url. The web view will refresh the feed automatically every 2 seconds.
            [self.cameraViewController loadUrlWithRepeatInterval:imageURLObject withRepeatInterval:10];
            
            //assign the camera view as the custom view of the callout for this graphic.
            self.mapView.callout.customView = self.cameraViewController.view;
            
            [self.mapView.callout showCalloutForGraphic:graphic tapLocation:tapLocation animated:YES];
            
            break;
        }
            //graphic's callout is a view with title, detail, custom accessory button and an image.
        case CustomInfoView:{
            NSLog(@"%@", @"Tapped on McDonalds");
            
            //clear the custom view.
            self.mapView.callout.customView = nil;
            
            //get the attribute values for the graphic
            self.mapView.callout.title = [graphic.attributes valueForKey:@"name"];
            self.mapView.callout.detail = [graphic.attributes valueForKey:@"address"];
            
            //sets the left image of the callout.
            self.mapView.callout.image = [UIImage imageNamed:@"McDonalds.png"];
            
            //creates the custom button image for the accessory view of the callout
            self.mapView.callout.accessoryButtonType = UIButtonTypeCustom;
            self.mapView.callout.accessoryButtonImage = [UIImage imageNamed:@"Phone.png"];
            self.mapView.callout.accessoryButtonHidden = NO;
            
            [self.mapView.callout showCalloutForGraphic:graphic tapLocation:tapLocation animated:YES];
            
            break;
        }
            //graphic's callout is a simple view with just the title and detail
        case SimpleView:{
            NSLog(@"%@", @"Tapped on Monument");
            
            //clear the custom view.
            self.mapView.callout.customView = nil;
            
            //get the attribute values for the graphic
            self.mapView.callout.title = [graphic.attributes valueForKey:@"name"];
            self.mapView.callout.detail = [graphic.attributes valueForKey:@"address"];
            
            //hide the accessory view and also the left image view.
            self.mapView.callout.accessoryButtonHidden = YES;
            self.mapView.callout.image = nil;
            
            [self.mapView.callout showCalloutForGraphic:graphic tapLocation:tapLocation animated:YES];
            
            break;
        }
        default:
            break;
    }
}

#pragma mark AGSCalloutDelegate

- (void)didTapAccessoryButtonForCallout:(AGSCallout *)callout{
    
    if (![callout.representedObject isKindOfClass:[AGSGraphic class]]){
        // we are expecting a graphic in this sample
        return;
    }
    
    AGSGraphic* graphic = (AGSGraphic*)callout.representedObject;
    //extract the type of graphics to check.
    NSNumber *typeNumber = (NSNumber*)[graphic.attributes valueForKey:@"type"];
    GraphicType graphicType = typeNumber.intValue;
    
    switch (graphicType) {
            //only this graphic's callout has an accessory view.
        case CustomInfoView:{
            NSLog(@"%@", @"Tapped accessory button on McDonalds callout");
            
            //get the phone number and create the proper string.
            NSString *phoneNumber = [@"tel://" stringByAppendingString:[graphic.attributes valueForKey:@"phone"]];
            
            //call the number.
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
            
            break;
        }
        default:
            break;
            
    }
}

#pragma mark - Helper Methods

//creating sample graphics. 
- (void)createSampleGraphics
{
    AGSGraphic *graphic;    
    AGSPoint *graphicPoint;    
    NSMutableDictionary *graphicAttributes;    
    AGSPictureMarkerSymbol *graphicSymbol;
    
    //Graphic for demonstrating Bing's aerial view
    graphicPoint = [AGSPoint pointWithX:-9546541.78950715 y:4615710.12174574 spatialReference:[AGSSpatialReference webMercator]];
    graphicAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(EmbeddedMapView), @"type", nil];
    graphicSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"Building.png"]];
    graphic = [AGSGraphic graphicWithGeometry:graphicPoint symbol:graphicSymbol attributes:graphicAttributes ];    
    [self.graphicsOverlay.graphics addObject:graphic];
    
    //Graphic for demonstrating embedded Web view (traffic camera feed)
    graphicPoint = [AGSPoint pointWithX:-9552294.6205 y:4618447.7069 spatialReference:[AGSSpatialReference webMercator]];
    graphicAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(EmbeddedWebView), @"type", @"http://www.trimarc.org/images/snapshots/CCTV060.jpg", @"url", nil];    
    graphicSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"TrafficCamera.png"]];
    graphic = [AGSGraphic graphicWithGeometry:graphicPoint symbol:graphicSymbol attributes:graphicAttributes ];    
    [self.graphicsOverlay.graphics addObject:graphic];
    
    //Graphic for demonstrating custom callout with buttons
    graphicPoint = [AGSPoint pointWithX:-9550988.22392791 y:4614761.34217867 spatialReference:[AGSSpatialReference webMercator]];
    graphicAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         @(CustomInfoView), @"type", 
                         @"MacDonald's", @"name", 
                         @"2720 West Broadway, Louisville, KY 40211-1320", @"address", 
                         @"5027787110", @"phone", 
                         @"www.mcdonalds.com", @"url",
                         nil];    
    graphicSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"McDonalds.png"]];
    graphic = [AGSGraphic graphicWithGeometry:graphicPoint symbol:graphicSymbol attributes:graphicAttributes ];    
    [self.graphicsOverlay.graphics addObject:graphic];
    
    //Graphic for demonstrating simple callout
    graphicPoint = [AGSPoint pointWithX:-9547261.91529309 y:4615891.15535562 spatialReference:[AGSSpatialReference webMercator]];
    graphicAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         @(SimpleView), @"type", 
                         @"Frazier Museum", @"name", 
                         @"829 West Main Street, Louisville, KY 40202", @"address",
                         nil];    
    graphicSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"Museum.png"]];
    graphic = [AGSGraphic graphicWithGeometry:graphicPoint symbol:graphicSymbol attributes:graphicAttributes ];    
    [self.graphicsOverlay.graphics addObject:graphic];
    
}       



@end
