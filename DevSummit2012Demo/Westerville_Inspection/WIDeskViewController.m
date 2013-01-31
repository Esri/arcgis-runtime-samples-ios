/*
 WIViewController.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIConstants.h"
#import "WIAppDelegate.h"
#import "WIDeskViewController.h"
#import "WICustomCalloutView.h"

#import "WISignatureView.h"
#import "WIPinchableContainerView.h"
#import "WIContactsManager.h"
#import "WIContactsView.h"
#import "WIContactGraphic.h"
#import "WIRouteStopsView.h"
#import "WIInspectionsView.h"
#import "WIFeatureView.h"
#import "WIInspectionView.h"
#import "WISimpleCSVParser.h"
#import "WIPinnedView.h"
#import "WIBasemapsView.h"
#import "WIListTableView.h"
#import "WIDefaultListTableViewCell.h"
#import "WIArrowCalloutView.h"
#import "WIWaitingView.h"

#import "AGSGeometry+Additions.h"

#import "WIStringSymbol.h"

#import "WIBasemaps.h"

#import "WIRoute.h"
#import "WIRouteSolver.h"

#import "Reachability.h"

#import "WIInspection.h"
#import "WIInspections.h"

#import <QuartzCore/QuartzCore.h>


@interface WIDeskViewController ()
{
    BOOL    _observingReachability;
    BOOL    _hasWifiConnection;
    BOOL    _showingBasemaps;
    BOOL    _basemapsLoaded;
    BOOL    _editingInspection;
    BOOL    _changingBasemap;
    
    CGRect  _origPinchFrame;
    CGRect  _animatedPinchFrame;
}

/*** User Experience, UI ***/
//Map Related
@property (nonatomic, strong) WIPinnedView             *mapPinnedView;
@property (nonatomic, strong) AGSMapView                *mapView;
@property (nonatomic, strong) UIView                    *toggleBasemapsSwipeView;
@property (nonatomic, strong) UIImageView               *offlineTapeView;

//Extra Map Layers
@property (nonatomic, strong) AGSGraphicsLayer          *contactsLayer;
@property (nonatomic, strong) AGSGraphicsLayer          *stopsLayer;
@property (nonatomic, strong) AGSGraphicsLayer          *routeLayer;
@property (nonatomic, strong) NSMutableDictionary       *offlineFeatureLayers;

//Side Panel Views
@property (nonatomic, strong) WIPinnedView             *pinchPinnedView;
@property (nonatomic, strong) WIPinchableContainerView *pinchView;
@property (nonatomic, strong) WIContactsView           *contactsView;
@property (nonatomic, strong) WIRouteStopsView         *stopsView;
@property (nonatomic, strong) WIDirectionsView         *directionsView;
@property (nonatomic, strong) WIInspectionsView        *inspectionsView;
@property (nonatomic, strong) WIFeatureView            *featureView;

@property (nonatomic, strong) WIPinnedView             *inpsectionPinnedView;
@property (nonatomic, strong) WIInspectionView         *inspectionView;

// dimmer
@property (nonatomic, strong) UIView                    *dimmerView;

@property (nonatomic, strong) WIWaitingView            *waitingView;

//graphics, etc.
@property (nonatomic, strong) AGSGraphic                *routeGraphic;
@property (nonatomic, strong) AGSGraphic                *turnHighlightGraphic;

/*** Model Objects ***/

//portal stuff
@property (nonatomic, strong) AGSPortal                 *portal;
@property (nonatomic, strong) AGSWebMap                 *webMap;

//Routing
@property (nonatomic, strong) WIRouteSolver            *routeSolver;
@property (nonatomic, strong) WIRoute                  *route;

//Basemaps
@property (nonatomic, strong) WIBasemaps               *basemaps;
@property (nonatomic, strong) AGSWebMap                 *baseMap;
@property (nonatomic, strong) AGSEnvelope               *savedEnvelope;

//Inspections
@property (nonatomic, strong) AGSFeatureLayer           *inspectionLayer;
@property (nonatomic, strong) WIInspections            *inspections;
@property (nonatomic, strong) AGSPopup                  *currentFeaturePopup;

/* Zoom the map to a particular geometry */
- (void)zoomToGeometry:(AGSGeometry *)geometry;

/* Called when our network connection status changes */
- (void)wifiChanged:(NSNotification *)n;
- (void)updateWifiAvailability;

/* Takes our feature layers offline */
- (void)goOffline;

- (AGSStopGraphic*)stopGraphicWithGeometry:(AGSGeometry*)geom name:(NSString*)name;

/* Displays a semi-transparent black rounded rect over the window with a status message and progress indicator */
- (void)showActivityIndicator:(BOOL)show withMessage:(NSString *)message;

@end

@implementation WIDeskViewController

@synthesize mapPinnedView           = _mapPinnedView;
@synthesize mapView                 = _mapView;
@synthesize toggleBasemapsSwipeView = _toggleBasemapsSwipeView;
@synthesize offlineTapeView         = _offlineTapeView;

@synthesize contactsLayer           = _contactsLayer;
@synthesize stopsLayer              = _stopsLayer;
@synthesize routeLayer              = _routeLayer;
@synthesize offlineFeatureLayers    = _offlineFeatureLayers;

@synthesize pinchView               = _pinchView;
@synthesize contactsView            = _contactsView;
@synthesize stopsView               = _stopsView;
@synthesize directionsView          = _directionsView;
@synthesize inspectionsView         = _inspectionsView;
@synthesize featureView             = _featureView;

@synthesize inpsectionPinnedView    = _inpsectionPinnedView;
@synthesize inspectionView          = _inspectionView;

@synthesize dimmerView              = _dimmerView;
@synthesize waitingView             = _waitingView;

@synthesize pinchPinnedView         = _pinchPinnedView;

@synthesize routeGraphic            = _routeGraphic;
@synthesize turnHighlightGraphic    = _turnHighlightGraphic;

@synthesize portal                  = _portal;
@synthesize webMap                  = _webMap;

@synthesize routeSolver             = _routeSolver;
@synthesize route                   = _route;

@synthesize inspections             = _inspections;
@synthesize inspectionLayer         = _inspectionLayer;
@synthesize currentFeaturePopup     = _currentFeaturePopup;

@synthesize basemaps                = _basemaps;
@synthesize baseMap                 = _baseMap;
@synthesize savedEnvelope           = _savedEnvelope;

- (void)dealloc
{
    if(_observingReachability)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:kReachabilityChangedNotification];
        _observingReachability = NO;
    }
    
    

    [self.pinchView setDelegate:nil];
    
    
    
    
    
    
            
}

//This application doesn't use any nibs. All views are created programatically, including the view controller's
//initial view
- (void)loadView
{ 
    UIView *v = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    
    // create our corkboard pattern with an image that gets tiled across the background
    v.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cork_background.png"]];
    
    //Assuming a fixed landscape orientation...  
    
    //other constants
    CGFloat landscapeHeight = 748.0f;
    CGFloat landscapeWidth = 1024.0f;
    CGFloat topYMargin = 15.0f;
    CGFloat xMargin = 15.0f;
    
    CGFloat foldersWidth = 320.0f;
    
    /*Map (and container) View */
    CGFloat xOriginOfMap = foldersWidth + 2*xMargin;
    CGFloat widthOfMap = landscapeWidth - xOriginOfMap - xMargin;
    CGRect mapRect = CGRectMake(xOriginOfMap, topYMargin, widthOfMap, landscapeHeight - 2*topYMargin);
    
    AGSMapView *mapView = [[AGSMapView alloc] initWithFrame:mapRect];
    mapView.backgroundColor = [UIColor whiteColor];
    mapView.layerDelegate   = self;
    mapView.touchDelegate   = self;
    mapView.calloutDelegate = self;
    
    self.mapView = mapView;
            
    // main pinned view that houses the map control
    WIPinnedView *mapPinnedView = [[WIPinnedView alloc] initWithContentView:self.mapView 
                                                                leftPinType:AGSPinnedViewTypeThumbtack 
                                                               rightPinType:AGSPinnedViewTypeThumbtack];
    
    self.mapPinnedView = mapPinnedView;
    
    //will reside on top of map view... allows a user to swipe up and down on top of map
    //to reveal/hide basemaps
    UIView *swipeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mapRect.size.width, 40)];
    
    UISwipeGestureRecognizer *downRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleShowingBasemaps)];
    downRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    downRecognizer.delegate = self;
    [swipeView addGestureRecognizer:downRecognizer];
    
    UISwipeGestureRecognizer *upRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(toggleShowingBasemaps)];
    upRecognizer.direction = UISwipeGestureRecognizerDirectionUp;
    upRecognizer.delegate = self;
    [swipeView addGestureRecognizer:upRecognizer];
    
    self.toggleBasemapsSwipeView = swipeView;
    
    [self.mapPinnedView addSubview:self.toggleBasemapsSwipeView];
    
    [v addSubview:self.mapPinnedView];
        
    /* Dimmer View - visible when the pinch view animates to show other list views */
    self.dimmerView = [[UIView alloc] initWithFrame:v.bounds];
    self.dimmerView.alpha = 0.0f;
    self.dimmerView.backgroundColor = [UIColor blackColor];
    self.dimmerView.userInteractionEnabled = NO;
    self.dimmerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [v addSubview:self.dimmerView];
    

    /* Pinchable View - stack of lists that can be pinched to show the views */
    CGRect pinchViewRect = CGRectMake(10, topYMargin, foldersWidth, landscapeHeight - 2*topYMargin);
    _origPinchFrame = pinchViewRect;
    self.pinchView = [[WIPinchableContainerView alloc] initWithFrame:pinchViewRect];
    self.pinchView.delegate = self;
    /* Pinned View */
    self.pinchPinnedView = [[WIPinnedView alloc] initWithContentView:self.pinchView 
                                                           leftPinType:AGSPinnedViewTypePushPin 
                                                          rightPinType:AGSPinnedViewTypeNone];
    self.pinchPinnedView.leftPinXOffset = foldersWidth/2;
    self.pinchPinnedView.leftPinYOffset = 3.0f;
    self.pinchPinnedView.useShadow = NO;
    [v addSubview:self.pinchPinnedView];
    
    //All of the views that will go in the pinchable view
    WIInspectionsView *iv = [[WIInspectionsView alloc] initWithFrame:self.pinchView.bounds withInspections:self.inspections];
    iv.delegate = self;
    iv.inspectionsDelegate = self;
    self.inspectionsView = iv;
    [self.pinchView addListView:self.inspectionsView];
    
    WIRouteStopsView *rsv = [[WIRouteStopsView alloc] initWithFrame:self.pinchView.bounds withRoute:self.route];
    rsv.delegate = self;
    rsv.stopsDelegate = self;
    self.stopsView = rsv;
    
    [self.pinchView addListView:self.stopsView];

    
    WIContactsView *cv = [[WIContactsView alloc] initWithFrame:self.pinchView.bounds 
                                                    withContacts:[WIContactsManager sharedContactsManager].allContactsWithAddresses];
    cv.delegate = self;
    cv.contactDelegate = self;
    self.contactsView = cv;
    
    [self.pinchView addListView:self.contactsView]; 

    self.view = v;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.offlineFeatureLayers = [NSMutableDictionary dictionary];
    
    //credential. Add your own credential if you want to hit a non-public map 
    //on your own account
    AGSCredential *cred = nil;
    
    //create new portal
    NSURL *portalUrl = [NSURL URLWithString:kPortalURL];
    AGSPortal *newPortal = [[AGSPortal alloc] initWithURL:portalUrl credential:cred];
    newPortal.delegate = self;
    self.portal = newPortal;
    
    
    /*Configure and check for reachability 
     We want to be notified whenever we lose connection so we don't try to 
     make requests over the network
     */
    if (!_observingReachability) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(wifiChanged:) 
                                                     name:kReachabilityChangedNotification 
                                                   object:nil];
        _observingReachability = YES;
    }
        
    [self updateWifiAvailability];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //
    // limit our application to a landscape orientation
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

#pragma mark -
#pragma mark Lazy Loads
- (WIInspections *)inspections
{
    if(_inspections == nil)
    {
        self.inspections = [WIInspections inspectionsWithFeatureLayer:nil];
    }
    
    return _inspections;
}

- (WIRoute *)route
{
    if(_route == nil)
    {
        self.route = [WIRoute route];
    }
    
    return _route;
}
- (AGSGraphic *)routeGraphic
{
    if(_routeGraphic == nil)
    {        
        self.routeGraphic = [AGSGraphic graphicWithGeometry:nil 
                                                     symbol:[WIStringSymbol stringSymbol] 
                                                 attributes:nil 
                                       infoTemplateDelegate:nil];
    }
    
    return _routeGraphic;
}

- (AGSGraphic *)turnHighlightGraphic
{
    if(_turnHighlightGraphic == nil)
    {
        AGSSimpleMarkerSymbol *sms = [AGSSimpleMarkerSymbol simpleMarkerSymbolWithColor:[[UIColor blackColor] colorWithAlphaComponent:.1]];
        sms.style = AGSSimpleMarkerSymbolStyleCircle;
        sms.size = CGSizeMake(130, 130);
        
        AGSSimpleLineSymbol *blackLine = [AGSSimpleLineSymbol simpleLineSymbolWithColor:[UIColor darkGrayColor]];
        blackLine.width = 1.5;
        
        sms.outline = blackLine;
        
        self.turnHighlightGraphic = [AGSGraphic graphicWithGeometry:nil 
                                                             symbol:sms
                                                         attributes:nil 
                                               infoTemplateDelegate:nil];
    }
    
    return _turnHighlightGraphic;
}

- (UIImageView *)offlineTapeView
{
    if(_offlineTapeView == nil)
    {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"offline_tape.png"]];
        iv.frame = CGRectMake(865, 645, 197, 143);
        self.offlineTapeView = iv;
    }
    
    return _offlineTapeView;
}

#pragma mark -
#pragma mark AGSPortalDelegate
-(void)portalDidLoad:(AGSPortal*)portal
{
    //Create a new webmap using the new portal
    AGSWebMap *newWebmap = [AGSWebMap webMapWithItemId:kWebMapId portal:self.portal];
    newWebmap.delegate = self;
    self.webMap = newWebmap;
    
    //Go grab basemaps in the background too...
    NSLog(@"basemap query %@", self.portal.portalInfo.basemapGalleryGroupQuery);
    AGSPortalQueryParams *queryParams = [AGSPortalQueryParams queryParamsWithQuery:self.portal.portalInfo.basemapGalleryGroupQuery];
    [self.portal findGroupsWithQueryParams:queryParams];
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFindGroups:(AGSPortalQueryResultSet*)resultSet
{
    //found basemap group. Query for items in the basemap group
    AGSPortalGroup *basemapsGroup = (AGSPortalGroup *)[resultSet.results objectAtIndex:0];
    AGSPortalQueryParams *params = [AGSPortalQueryParams queryParamsForItemsOfType:AGSPortalItemTypeWebMap inGroup:basemapsGroup.groupId];
    [self.portal findItemsWithQueryParams:params];
}

-(void)portal:(AGSPortal*)portal operation:(NSOperation*)op didFindItems:(AGSPortalQueryResultSet*)resultSet
{
    //Filter out all of the Bing basemaps since this application doesn't have a key. If you have a Bing key, go
    //ahead and remove this code, and implement the AGSWebMapDelegate method to return your Bing App key
    NSMutableArray *onlineBasemapArray = [NSMutableArray arrayWithCapacity:6];
    for (AGSPortalItem *pi in resultSet.results)
    {
        if ([pi.title rangeOfString:@"Bing"].location == NSNotFound) {
            [onlineBasemapArray addObject:pi];
        }
    }
    
    //Create basemaps model object
    WIBasemaps *basemaps = [[WIBasemaps alloc] initWithOnlineBasemaps:onlineBasemapArray];
    self.basemaps = basemaps;
    
    //Put basemap view right behind map
    WIBasemapsView *basemapsView = [[WIBasemapsView alloc] initWithFrame:CGRectMake(self.mapPinnedView.frame.origin.x, self.mapPinnedView.frame.origin.y, 659, 685) withBasemaps:self.basemaps];
    basemapsView.delegate = self;
    [self.view insertSubview:basemapsView belowSubview:self.mapPinnedView];
}

#pragma mark -
#pragma mark AGSWebMapDelegate
- (void)webMapDidLoad:(AGSWebMap *)webMap
{
    //if there is a basemap, we need to open that
    if (self.baseMap) {
        [self.webMap openIntoMapView:self.mapView withAlternateBaseMap:webMap.baseMap];
    }
    //opening actual map
    else 
    {
        [webMap openIntoMapView:self.mapView];
    }
}

- (void)didOpenWebMap:(AGSWebMap*)webMap intoMapView:(AGSMapView*)mapView
{
    //take all feature layers offline
    [self goOffline];
    
    //Map is done initializing with web map... Add auxiliary layers for identifying
    //and for routing
    if(_contactsLayer == nil)
    {
        self.contactsLayer  = [AGSGraphicsLayer graphicsLayer];
    }
    if(_routeLayer == nil)
    {
        self.routeLayer     = [AGSGraphicsLayer graphicsLayer];
    }
    if(_stopsLayer == nil)
    {
        self.stopsLayer     = [AGSGraphicsLayer graphicsLayer];
    }
    
    [mapView addMapLayer:self.contactsLayer withName:@"Contacts Layer"];
    [mapView addMapLayer:self.routeLayer withName:@"Route Layer"];
    [mapView addMapLayer:self.stopsLayer withName:@"Stops Layer"];
    
    
    //lazy load a route solve for the map
    if(_routeSolver == nil)
    {
        //US Route Server
        NSURL *routeUrl = [NSURL URLWithString:kRoutingServiceURL];
        
        self.routeSolver = [WIRouteSolver routeSolverWithSpatialReference:self.mapView.spatialReference routingServiceUrl:routeUrl];
        self.routeSolver.delegate = self;
    }
    
    //if we were opening a new basemp, nil out since we don't anymore
    if(_changingBasemap)
    {
        _changingBasemap = NO;
        
        [self.mapView zoomToEnvelope:self.savedEnvelope animated:NO];
        self.savedEnvelope = nil;
        self.baseMap = nil;
    }
}

#pragma mark -
#pragma mark WIContactsViewDelegate
- (void)contactsView:(WIContactsView *)cv wantsToShowContact:(AGSGraphic *)contact
{
    contact.infoTemplateDelegate = self;
    [self.contactsLayer addGraphic:contact];
    
    [self zoomToGeometry:contact.geometry];
}


#pragma mark -
#pragma mark AGSFeatureLayerQueryDelegate

//This method will get called if a user has input a custom URI (see method handleApplicationURL:). If we find a feature,  find it on map,
//zoom to it, and show callout.
- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didQueryFeaturesWithFeatureSet:(AGSFeatureSet *)featureSet
{
    if (featureSet.features.count == 0) {
        return;
    }
    
    AGSGraphic *selectedFeature = [featureSet.features objectAtIndex:0];
    
    //Make sure the callout shows
    [self mapView:self.mapView shouldShowCalloutForGraphic:selectedFeature];
    [self.mapView.callout showCalloutAtPoint:[selectedFeature.geometry getLocationPoint]  forGraphic:selectedFeature animated:YES];
    [self.mapView centerAtPoint:[selectedFeature.geometry getLocationPoint] animated:YES];
    
    //Make sure the feature popup shows up on the left
    [self calloutView:nil wantsMoreInfoForGraphic:selectedFeature];
}

#pragma mark -
#pragma mark AGSMapViewTouchDelegate

- (BOOL)mapView:(AGSMapView *)mapView shouldShowCalloutForGraphic:(AGSGraphic *)graphic
{
    //no callouts for the stops layer, routing layer, or inspections layer.
    if (graphic.layer == self.stopsLayer || graphic.layer == self.inspectionLayer || graphic.layer == self.routeLayer) {
        return NO;
    }
    
    //'hide' the default callout properties so our custom callout is the only item showing
    mapView.callout.accessoryButtonHidden = NO;
    mapView.callout.leaderPositionFlags = AGSCalloutLeaderPositionRight;
    mapView.callout.color = [[UIColor whiteColor] colorWithAlphaComponent:0.0];
    mapView.callout.highlight = [[UIColor whiteColor] colorWithAlphaComponent:0.0];
    mapView.callout.margin = CGSizeZero;
    
    WICustomCalloutView *calloutView = [[WIArrowCalloutView alloc] initWithGraphic:graphic];
    calloutView.delegate = self;
    mapView.callout.customView = calloutView;
    
    return YES;
}

#pragma mark -
#pragma mark AGSMapViewCalloutDelegate
- (void)mapViewDidDismissCallout:(AGSMapView*)mapView
{
    //Remove feature view once user has tapped off it
    [self.pinchView removeListView:self.featureView];
}

#pragma mark -
#pragma mark WICustomCalloutDelegate
- (void)calloutView:(WICustomCalloutView *)cv wantsToAddStopForGraphic:(AGSGraphic *)graphic
{
    AGSStopGraphic *sg = nil;
    
    //use the contact's name to populate stop graphic name
    if (graphic.layer == self.contactsLayer) {
        WIContactGraphic *cg = (WIContactGraphic *)graphic;
        sg = [self stopGraphicWithGeometry:cg.geometry name:cg.contactName];
    }
    else {
        sg = [self stopGraphicWithGeometry:graphic.geometry name:[NSString stringWithFormat:@"Stop #%d", self.route.stops.count + 1]];
    }

    [self.route addStop:sg];
    [self.stopsLayer addGraphic:sg];
    
    //update appropriate views
    [self.stopsView reloadData];
}

- (void)calloutView:(WICustomCalloutView *)cv wantsMoreInfoForGraphic:(AGSGraphic *)graphic
{
    //Client side popup
    AGSPopupInfo *popupInfo = [AGSPopupInfo popupInfoForGraphic:graphic];
	if (!popupInfo){
		return;
	}
    
    //filter popup to make some properties invisible (OBJECTID, GLOBALID, etc)
    [self filterPopupInfo:popupInfo];
    
    popupInfo.title = [graphic attributeAsStringForKey:@"name"];
    
	// create a popup from the popupInfo and a feature
	self.currentFeaturePopup = [[AGSPopup alloc]initWithGraphic:graphic popupInfo:popupInfo];
    
    self.currentFeaturePopup.allowEdit = NO;
    self.currentFeaturePopup.allowDelete = NO;
    self.currentFeaturePopup.allowEditGeometry = NO;

    if (self.featureView) {
        [self.pinchView removeListView:self.featureView];
        self.featureView = nil;
    }
    
    //Create a new feature view, and add it to list
    WIFeatureView *fv = [[WIFeatureView alloc] initWithFrame:self.pinchView.bounds withPopup:self.currentFeaturePopup];
    fv.delegate = self;
    fv.featureDelegate = self;
    self.featureView = fv;
    
    [self.pinchView addListView:fv];
}

#pragma mark -
#pragma mark WIRouteSolverDelegate
- (void)routeSolver:(WIRouteSolver *)rs didSolveRoute:(WIRoute *)route
{    
    [self showActivityIndicator:NO withMessage:nil];
    
    self.routeGraphic.geometry = route.directions.mergedGeometry;
    
    [self zoomToGeometry:self.routeGraphic.geometry.envelope];
    
    //Add graphics to map
    [self.routeLayer addGraphic:self.routeGraphic];
    
    //add a pin for all turns in route
    for(AGSDirectionGraphic *dg in route.directions.graphics)
    {
        AGSPoint *pt = [dg.geometry head];
        
        AGSPictureMarkerSymbol *pinSymbol = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"PushPinGrey.png"]];
        pinSymbol.size = CGSizeMake(50.0f, 45.0f);
        pinSymbol.offset = CGPointMake(3, 22);
        
        AGSGraphic *pinGraphic = [AGSGraphic graphicWithGeometry:pt symbol:pinSymbol attributes:nil infoTemplateDelegate:nil];
        
        [self.routeLayer addGraphic:pinGraphic];
    }
    
    //show directions in side panel
    if(_directionsView == nil)
    {
        WIDirectionsView *dv = [[WIDirectionsView alloc] initWithFrame:self.pinchView.bounds withRoute:route];
        dv.delegate = self;
        dv.directionsDelegate = self;
        self.directionsView = dv;
    }
    
    self.directionsView.route = route;
    [self.pinchView addListView:self.directionsView];
}

- (void)routeSolverIsReadyToRoute:(WIRouteSolver *)rs
{
    NSLog(@"Ready to route Stub. Fill in with anything that might be of use");
}

- (void)routeSolver:(WIRouteSolver *)rs didFailToSolveRoute:(WIRoute *)route error:(NSError *)error
{
    NSLog(@"Failed to solve route stub.");
}

#pragma mark -
#pragma mark WIRouteStopsViewDelegate
- (void)routeStopsView:(WIRouteStopsView *)rsv wantsToRoute:(WIRoute *)route
{
    //Clear old route
    [self.routeLayer removeAllGraphics];
    
    //Clear old directions
    [self.pinchView removeListView:self.directionsView];
    self.directionsView  = nil;
    
    [self.routeSolver solveRoute:route];
    
    [self showActivityIndicator:YES withMessage:@"Routing"];
}


- (void)routeStopsView:(WIRouteStopsView *)rsv willDeleteStop:(AGSStopGraphic *)stop
{
    [self.stopsLayer removeGraphic:stop];
}

#pragma mark -
#pragma mark WIDirectionsViewDelegate
- (void)directionsViewWantsToHideDirections:(WIDirectionsView *)dv
{
    [self.routeLayer removeAllGraphics];
    
    [self.pinchView removeListView:self.directionsView];
    self.directionsView = nil;
}

- (void)directionsViewWantsToStartGPS:(WIDirectionsView *)dv
{
    [self startAutoNav];
}

- (void)directionsView:(WIDirectionsView *)dv didTapOnRouteOverviewForRoute:(WIRoute *)route
{
    dv.selectedDirection = nil;
    
    [self.routeLayer removeGraphic:self.turnHighlightGraphic];
    
    [self zoomToGeometry:route.directions.mergedGeometry.envelope];
}

- (void)directionsView:(WIDirectionsView *)dv didTapOnDirectionGraphic:(AGSDirectionGraphic *)directionGraphic
{
    //Zoom to head of the leg of the selected direction segment
    
    dv.selectedDirection = directionGraphic;
    [self.routeLayer removeGraphic:self.turnHighlightGraphic];
    self.turnHighlightGraphic.geometry = [directionGraphic.geometry head];
    
    [self zoomToGeometry:self.turnHighlightGraphic.geometry];
    
    [self.routeLayer addGraphic:self.turnHighlightGraphic];
    

}

#pragma mark -
#pragma mark WIFeatureViewDelegate
- (void)featuresViewWantsToClose:(WIFeatureView *)fv
{
    [self.pinchView removeListView:self.featureView];
    self.featureView = nil;
}

- (void)featuresView:(WIFeatureView *)fv wantsToInspectFeature:(AGSPopup *)feature
{    
    //Map may not have an inpsection layer.
    if(!self.inspectionLayer)
    {
        return;
    }
    
    //Add inpsection form to map
    CGRect ivFrame = CGRectInset(self.mapPinnedView.frame, 8, 5);
    ivFrame.origin.x += 10; //offset from map a bit
    
    WIInspectionView *iv = [[WIInspectionView alloc] initWithFrame:ivFrame 
                                                withFeatureToInspect:feature 
                                                     inspectionLayer:self.inspectionLayer];
    iv.delegate = self;
    self.inspectionView = iv;
    
    WIPinnedView *inspectionPinnedView = [[WIPinnedView alloc] initWithContentView:self.inspectionView 
                                                                   leftPinType:AGSPinnedViewTypePushPin 
                                                                  rightPinType:AGSPinnedViewTypeNone];
    
    //slightly off center pin
    inspectionPinnedView.leftPinXOffset = ivFrame.size.width/2 - 30;
    self.inpsectionPinnedView = inspectionPinnedView;
    
    [self.view addSubview:self.inpsectionPinnedView];
    self.pinchView.userInteractionEnabled = NO;
}

#pragma mark -
#pragma mark WIInspectionViewDelegate

- (void)inspectionView:(WIInspectionView *)inspectionView didCancelCollectingInspection:(WIInspection *)inspection
{
    //only remove the graphic completely if we aren't editing an inspection
    if(!_editingInspection)
    {
        [self.inspectionLayer removeGraphic:inspection.popup.graphic];
    }
    
    _editingInspection = NO;
    
    [self.inpsectionPinnedView removeFromSuperview];
    
    self.inpsectionPinnedView   = nil;
    self.inspectionView         = nil;
    
    self.pinchView.userInteractionEnabled = YES;
}

- (void)inspectionView:(WIInspectionView *)inspectionView didFinishWithInspection:(WIInspection *)inspection
{       
    [self.inpsectionPinnedView removeFromSuperview];
    
    [self.inspections addInspection:inspection];
    [self.inspectionsView reloadData];
    
    
    self.inpsectionPinnedView   = nil;
    self.inspectionView         = nil;
    
    self.pinchView.userInteractionEnabled = YES;
    
    //bring inspections sheet to the forefront
    [self.pinchView removeListView:self.inspectionsView];
    [self.pinchView addListView:self.inspectionsView];
    self.pinchView.activeView = self.inspectionsView;
}

#pragma mark -
#pragma mark WIInspectionsViewDelegate
- (BOOL)inspectionsViewShouldSyncInspections:(WIInspectionsView *)iv
{
    //only let inspections view kick off synchronization if we have wifi access
    return _hasWifiConnection;
}

- (void)inspectionsView:(WIInspectionsView *)inspectionView didTapOnInspection:(WIInspection *)inspection
{
    //Allow a user to edit an inspection
    _editingInspection = YES;
    
    CGRect ivFrame = CGRectInset(self.mapPinnedView.frame, 5, 5);
    ivFrame.origin.x += 20; //offset from map a bit
    
    WIInspectionView *iv = [[WIInspectionView alloc] initWithFrame:ivFrame 
                                                          inspection:inspection];
    iv.delegate = self;
    self.inspectionView = iv;
    
    WIPinnedView *inspectionPinnedView = [[WIPinnedView alloc] initWithContentView:self.inspectionView 
                                                                         leftPinType:AGSPinnedViewTypePushPin 
                                                                        rightPinType:AGSPinnedViewTypeNone];
    
    //slightly off center pin
    inspectionPinnedView.leftPinXOffset = ivFrame.size.width/2 - 30;
    self.inpsectionPinnedView = inspectionPinnedView;
    
    [self.view addSubview:self.inpsectionPinnedView];
    self.pinchView.userInteractionEnabled = NO;
}

- (void)inspectionsView:(WIInspectionsView *)iv startedSyncingInspections:(WIInspections *)inspections
{
    [self showActivityIndicator:YES withMessage:@"Syncing..."];
}

- (void)inspectionsView:(WIInspectionsView *)iv finishedSyncingInspections:(WIInspections *)inspections
{
    [self showActivityIndicator:NO withMessage:nil];
}

#pragma mark - 
#pragma mark WIPinchContainerViewDelegate

//
// we get notified when our pinchView has been "pinched". We use the scale to calculate the opacity
// of our dimmerView, and remove the pin holding up the stack of views
- (void)pinchView:(WIPinchableContainerView *)pinchView pinchingWithScale:(CGFloat)scale {
    CGFloat adjScale = scale - 1.0f;
    if (adjScale >= 0.0f && adjScale <= 0.75f) {
        self.dimmerView.alpha = adjScale;
    }
    self.pinchPinnedView.leftPinType = AGSPinnedViewTypeNone;
}

- (void)pinchViewWillAnimateBack:(WIPinchableContainerView *)pinchView {
    // animate our dimmerView out
    [UIView animateWithDuration:0.5f
                     animations:^{
                         self.dimmerView.alpha = 0.0f; 
                     }];
}

- (void)pinchViewDidAnimateOut:(WIPinchableContainerView *)pinchView
{
    //By disabling each of the list views, they can now respond to a tap for selection
    //purposes
    self.contactsView.enabled       = NO;
    self.stopsView.enabled          = NO;
    self.directionsView.enabled     = NO;
    self.inspectionsView.enabled    = NO;
    self.featureView.enabled        = NO;
    self.pinchPinnedView.frame = CGRectMake(self.pinchPinnedView.frame.origin.x, 
                                            self.pinchPinnedView.frame.origin.y, 
                                            self.view.bounds.size.width - (2*self.pinchPinnedView.frame.origin.x), 
                                            self.pinchPinnedView.frame.size.height);
}

- (void)pinchViewDidAnimateBack:(WIPinchableContainerView *)pinchView
{
    //By enabling each of the list views, they can now respond to default tableview swipe
    //gestures
    self.contactsView.enabled       = YES;
    self.stopsView.enabled          = YES;
    self.directionsView.enabled     = YES;
    self.inspectionsView.enabled    = YES;
    self.featureView.enabled        = YES;
    self.pinchPinnedView.frame      = _origPinchFrame;
    self.pinchPinnedView.leftPinType = AGSPinnedViewTypePushPin;    
}

#pragma mark -
#pragma mark WIBasemapsViewDelegate
- (void)basemapsViewDidLoad:(WIBasemapsView *)basemapview
{
    //user can swipe map now
    _basemapsLoaded = YES;
}

- (void)basemapView:(WIBasemapsView *)basemapView wantsToChangeToBasemap:(AGSPortalItem *)pi
{
     _changingBasemap = YES;
    
    self.baseMap = [AGSWebMap webMapWithPortalItem:pi];
    self.baseMap.delegate = self;
    
    self.savedEnvelope = self.mapView.visibleArea.envelope;
    
    [self toggleShowingBasemaps];
}

//We are going to assume that by changing to a local tile layer that the user does not want to go back to the server
//and actually open the web map again. Instead, we will use the cached feature layers and recreate the map from scratch
- (void)basemapView:(WIBasemapsView *)basemapView wantsToChangeToLocalTiledLayer:(AGSLocalTiledLayer *)localTiledLayer {
    
    self.savedEnvelope = self.mapView.visibleArea.envelope;
    
    //Remove all layers from the map
    [self.mapView reset];
    
    //add basemap, in this case, a local tiled layer
    [self.mapView addMapLayer:localTiledLayer withName:@"localLayer"];
    
    //add all feature layers
    for(NSString *flName in self.offlineFeatureLayers.allKeys)
    {
        [self.mapView addMapLayer:[self.offlineFeatureLayers objectForKey:flName] withName:flName];
    }
        
    // add our graphic layers
    [self.mapView addMapLayer:self.contactsLayer withName:@"Contacts Layer"];
    [self.mapView addMapLayer:self.routeLayer withName:@"Route Layer"];
    [self.mapView addMapLayer:self.stopsLayer withName:@"Stops Layer"];
    
    [self.mapView zoomToEnvelope:self.savedEnvelope animated:NO];
    self.savedEnvelope = nil;
    
    [self toggleShowingBasemaps];
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    //if basemaps haven't loaded, shouldn't even allow user to swipe map
    if(!_basemapsLoaded)
    {
        return NO;
    }
    
    UISwipeGestureRecognizer *swipeRecognizer = (UISwipeGestureRecognizer *)gestureRecognizer;
    
    //only recognize an up swipe if we are showing the basemaps.  Only recognize a down swipe 
    //if we aren't showing the basemaps
    return ((swipeRecognizer.direction == UISwipeGestureRecognizerDirectionDown && !_showingBasemaps) || 
            (swipeRecognizer.direction == UISwipeGestureRecognizerDirectionUp && _showingBasemaps));
}

#pragma mark -
#pragma mark WIListTableViewDelegate
- (void)listTableViewTapped:(WIListTableView *)ltv
{
    self.pinchView.activeView = ltv;
    ltv.layer.borderWidth = 8.0f;
    ltv.layer.borderColor = [[UIColor redColor] CGColor];

    [self performSelector:@selector(animatePinchViewBack:) withObject:ltv afterDelay:0.5f];
}

- (void)animatePinchViewBack:(WIListTableView*)ltv {
    //
    // bring our selected view to the front of the list
    [self.pinchView bringSubviewToFront:ltv];    
    
    // 
    // animate our pinchView back into place
    [self.pinchView animateBack];    
}

#pragma mark - 
#pragma mark Document Handling 

//The application is registered to handle CSV files (See sample CSV file with project). CSV files have a list
//of stops that we will add to the application that a user can route against.
- (void)handleDocumentOpenURL:(NSURL*)url 
{
    [self.route removeAllStops];
    [self.stopsLayer removeAllGraphics];
    
    //update appropriate views
    [self.stopsView reloadData];
    
    //
    // parse CSV here then add stops
    
    // read everything from text
    WISimpleCSVParser *csvParser = [[WISimpleCSVParser alloc] initWithFileURL:url];
    csvParser.latField = @"Lat";
    csvParser.longField = @"Long";
    csvParser.nameField = @"Name";
    NSArray *rows = [csvParser parse];
    
    for (NSArray *item in rows) {
        double latitude = [[item objectAtIndex:csvParser.latFieldIndex] doubleValue];
        double longitude = [[item objectAtIndex:csvParser.longFieldIndex] doubleValue];        
        NSString *name = [item objectAtIndex:csvParser.nameFieldIndex];
        
        //
        // we know our CSV data results in a wgs84 point because we created the CSV in this case
        AGSPoint *pt = [AGSPoint pointWithX:longitude y:latitude spatialReference:[AGSSpatialReference wgs84SpatialReference]];
        
        //
        // if our map is NOT in wgs84, reproject it to our map's SR
        if (![pt.spatialReference isEqualToSpatialReference:self.mapView.spatialReference]) {
            pt = (AGSPoint*)[[AGSGeometryEngine defaultGeometryEngine] projectGeometry:pt 
                                                                    toSpatialReference:self.mapView.spatialReference];
        }
        
        AGSStopGraphic *stopGraphic = [self stopGraphicWithGeometry:pt name:name];
        [self.route addStop:stopGraphic];
        [self.stopsLayer addGraphic:stopGraphic];
    }
    
    //update appropriate views
    [self.stopsView reloadData];
    
    //
    // since we just got new stops, lets remove any directions we have visible
    [self directionsViewWantsToHideDirections:self.directionsView];
    [self zoomToGeometry:self.stopsLayer.fullEnvelope];
}

//The app is registered to handle custom URIs. This can be useful when wanting to invoke the app from email, text, another
//app, QR codes (as seen in the original demo), etc. 
//
//The format of the custom URI is as follows:  inspectiondemo://(Layer Name)/(Object ID of feature that wants to be inspected)
//                                         Ex: inspectiondemo://WaterTanksLayer/45
- (void)handleApplicationURL:(NSURL *)url
{
    NSString *schemeString = @"inspectiondemo://";
    NSString *stringWithoutHeader = [url.absoluteString stringByReplacingOccurrencesOfString:schemeString withString:@""];
    stringWithoutHeader = [stringWithoutHeader stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableArray *components = [NSMutableArray arrayWithArray:[stringWithoutHeader componentsSeparatedByString:@"/"]];
    
    NSString  *layerName = [components objectAtIndex:0];
    NSUInteger objectIDValue = [[components objectAtIndex:1] integerValue];
    
    for (AGSLayer *lyr in self.mapView.mapLayers)
    {
        //Found the layer
        if([lyr.name isEqualToString:layerName])
        {
            AGSFeatureLayer *fl = (AGSFeatureLayer *)lyr;
            fl.queryDelegate = self;
            
            //Query for the object id that was represented in the string
            AGSQuery *query = [AGSQuery query];
            query.objectIds = [NSArray arrayWithObject:[NSNumber numberWithInt:objectIDValue]];
            [fl queryFeatures:query];
            break;
        }
    }
}

#pragma mark -
#pragma mark Private Methods

//Animation to hide and show the basemaps
- (void)toggleShowingBasemaps
{    
    _showingBasemaps = !_showingBasemaps;
    
    CGRect mapRect = self.mapPinnedView.frame;
    CGFloat heightDifference = 690.0f;
    
    mapRect.origin.y += (_showingBasemaps) ? heightDifference : -heightDifference;
    
    self.mapPinnedView.useShadow = NO;
    self.mapPinnedView.leftPinType = AGSPinnedViewTypeNone;
    self.mapPinnedView.rightPinType = AGSPinnedViewTypeNone;
    
    [UIView animateWithDuration:0.6f animations:^
     {
         self.mapPinnedView.frame = mapRect;
     }
                     completion:^(BOOL completed)
     {
         self.mapPinnedView.leftPinType = AGSPinnedViewTypeThumbtack;
         self.mapPinnedView.rightPinType = AGSPinnedViewTypeThumbtack;
         
         if(!_showingBasemaps)
         {
             self.mapPinnedView.useShadow = YES;
         }
     }
     ];
}

- (void)startAutoNav {
    // set our default mode to always keep us centered
    self.mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanModeDefault;
    [self.mapView.locationDisplay startDataSource];
}

- (void)endAutoNav {
    // rotate our map back to 0 degrees
    [self.mapView setRotationAngle:0 animated:YES];
    [self.mapView.locationDisplay stopDataSource];
}


//Creates a new stop graphic that we can place on the map. The stop graphic is a composite symbol
//of a picture with a stop sign, and some text to indicate the name of the stop
- (AGSStopGraphic*)stopGraphicWithGeometry:(AGSGeometry*)geom name:(NSString*)name {    
    AGSCompositeSymbol *cs = [AGSCompositeSymbol compositeSymbol];
    
    AGSPictureMarkerSymbol *pms = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImage:[UIImage imageNamed:@"StopSymbol.png"]];
    pms.size = CGSizeMake(160.0f, 67.0f);
    pms.offset = CGPointMake(63,0);
    [cs addSymbol:pms];
    
    AGSTextSymbol *ts = [AGSTextSymbol textSymbolWithText:name color:[UIColor blackColor]];
    ts.vAlignment = AGSTextSymbolVAlignmentMiddle;
    ts.hAlignment = AGSTextSymbolHAlignmentCenter;
    ts.fontSize = 12.0f;
    ts.fontFamily = @"Courier";
    ts.offset = CGPointMake(74,-14);
    [cs addSymbol:ts];
    
    AGSPoint *stopPoint = [[geom getLocationPoint] copy];
    AGSStopGraphic *sg = [AGSStopGraphic graphicWithGeometry:stopPoint 
                                                      symbol:cs 
                                                  attributes:nil 
                                        infoTemplateDelegate:nil];
    
    sg.name = name;
    return sg;
}

- (void)zoomToGeometry:(AGSGeometry *)geometry
{
    //
    // if we are auto-nav'ing, stop
    [self endAutoNav];
    
    AGSMutableEnvelope  *mutEnv;
    
    if ([geometry isKindOfClass:[AGSPoint class]]) {
    
        double fRatio = 10000.0 / self.mapView.mapScale;
        mutEnv =[self.mapView.visibleArea.envelope mutableCopy];
        [mutEnv expandByFactor:fRatio];
        [mutEnv centerAtPoint:(AGSPoint *)geometry];
    }
    else 
    {
        mutEnv = [geometry.envelope mutableCopy];
        [mutEnv expandByFactor:1.4];
    }
    
    [self.mapView zoomToEnvelope:mutEnv animated:YES];
}

- (void)wifiChanged:(NSNotification *)n
{
    [self updateWifiAvailability];
}

- (void)updateWifiAvailability
{
    WIAppDelegate *app = [[UIApplication sharedApplication] delegate];
    NetworkStatus netStatus = [app.wifiReachability currentReachabilityStatus];
    if (netStatus == ReachableViaWiFi){        
        [self.offlineTapeView removeFromSuperview];
        self.offlineTapeView = nil;
        _hasWifiConnection = YES;
    }
    else {
        [self.view addSubview:self.offlineTapeView];
        _hasWifiConnection = NO;
    }    
}

//Ensure some fields can't be seen in popup
- (void)filterPopupInfo:(AGSPopupInfo *)popupInfo
{
    NSArray *fieldInfos = popupInfo.fieldInfos;
    NSArray *fieldNamesToFilter = [NSArray arrayWithObjects:@"objectid", @"globalid", @"website", nil];
    
    for (AGSPopupFieldInfo *fi in fieldInfos) {
        if ([fieldNamesToFilter containsObject:fi.fieldName]) {
            fi.visible = NO;
        }
    }
}


- (void)goOffline {    
    //
    // this method takes us offline...
    
    // get a copy of our layers in case something else is modifying them (shouldn't be, but be safe)
    NSArray *layers = [self.mapView.mapLayers copy];
    
    for (AGSLayer *lyr in layers) {
        //Look for all feature layers to take offline
        if ([lyr isKindOfClass:[AGSFeatureLayer class]]) {
            AGSFeatureLayer *fl = (AGSFeatureLayer*)lyr;
            
            //Look for feature layer in offlineFeatureLayers
            NSString *name = fl.name;
            NSLog(@"%@", name);
            AGSFeatureLayer *newFL = [self.offlineFeatureLayers objectForKey:fl.name];
              
            //lazy loaded feature layer
            if(newFL == nil)
            {
                //
                // create a new one in snapshot mode
                newFL = [[AGSFeatureLayer alloc] initWithURL:fl.URL mode:AGSFeatureLayerModeSnapshot credential:fl.credential];
                newFL.outFields = [NSArray arrayWithObject:@"*"];
                newFL.infoTemplateDelegate = newFL;                
                
                //add into dictionary
                [self.offlineFeatureLayers setObject:newFL forKey:name];
            }
             
            //Remove webmap version of the feature layer and add our snapshot version back in
            [self.mapView removeMapLayerWithName:name];            
            [self.mapView addMapLayer:newFL withName:name];
            
            //Found inspection layer!
            if ([newFL.URL.absoluteString rangeOfString:kInspectionLayerSubstring].location != NSNotFound) {
                self.inspectionLayer = newFL;
                
                //let inspections object know about feature layer
                self.inspections.featureLayer = self.inspectionLayer;
            }
        }
    }
}

- (void)showActivityIndicator:(BOOL)show withMessage:(NSString *)message
{
    if(show)
    {
        if(_waitingView == nil)
        {
            WIWaitingView *wv = [[WIWaitingView alloc] initWithFrame:CGRectMake(412, 309, 200, 150) message:message];
            self.waitingView = wv;
        }
        
        if (self.waitingView.superview == nil) {
            [self.view addSubview:self.waitingView];
        }
        
        self.waitingView.messageLabel.text = message;
    }
    else 
    {
        [self.waitingView removeFromSuperview];
        self.waitingView = nil;
    }    
}
@end
