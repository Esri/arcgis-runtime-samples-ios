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

#import "DisplayPopupHelper.h"


@interface DisplayPopupHelper() {
    AGSWebMap *_webMap;
    AGSPopupsContainerViewController *_popupVC;
    AGSMapView *_mapView;
    NSString *_webMapId;
    UIActivityIndicatorView *_activityIndicator;
    NSMutableArray *_outstandingQueries;
    id<DisplayPoupupHelperDelegate> _delegate;
}
@end

@implementation DisplayPopupHelper

@synthesize outstandingQueries = _outstandingQueries;
@synthesize activityIndicator = _activityIndicator;
@synthesize webMap = _webMap;
@synthesize popupVC = _popupVC;
@synthesize mapView = _mapView;
@synthesize delegate = _delegate;

+ (DisplayPopupHelper *)sharedHelper{
    static DisplayPopupHelper *sharedHelper;
    
    @synchronized(self)
    {
        if (!sharedHelper)
            sharedHelper = [[DisplayPopupHelper alloc] init];
        
        return sharedHelper;
    }
}

- (void) displayPopupsForMapView:(AGSMapView*) mapView atPoint:(AGSPoint*)mappoint withGraphics:(NSDictionary *)graphics inWebMap:(AGSWebMap*)webmap withMapLayers:(NSDictionary*)mapLayers queryableLayers:(NSArray*)queryableLayers  {
    
    if(!self.outstandingQueries)
        self.outstandingQueries = [[[NSMutableArray alloc] init] autorelease];
    
    self.mapView = mapView;
    self.popupVC = nil;
    self.mapView.callout.accessoryButtonHidden = NO;
    self.webMap = webmap;
    NSMutableArray *popups = [NSMutableArray array];

    // Create a popup for each feature in each feature layer at the point tapped
    if ([graphics allValues].count>0) {
        NSArray *graphicsArrays = [graphics allValues];
                for (NSArray *graphicsArray in graphicsArrays) {
            for (AGSGraphic *graphic in graphicsArray) {
                if ([graphic.layer isKindOfClass:[AGSFeatureLayer class]]) {
                    AGSPopupInfo *popupInfo = [self.webMap popupInfoForFeatureLayer:(AGSFeatureLayer*)graphic.layer];
                    AGSPopup *popup = [AGSPopup popupWithGraphic:graphic popupInfo:popupInfo];
                    [popups addObject:popup];
                }
                
            }
        }
    }
    
      
    
    // Create a query
    AGSQuery* query = [AGSQuery query];
    
    // Buffer the mappoint by 10 pixels so we can query by intersection
    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
    AGSPolygon *buffer = [geometryEngine bufferGeometry:mappoint byDistance:(10 *self.mapView.resolution)];
    query.geometry = buffer;
    query.outSpatialReference = self.mapView.spatialReference;
    
    // Have the query request all attribute fields
    query.outFields = [NSArray arrayWithObject:@"*"];
    
    // For each queryable layer...
    for (AGSLayer *layer in queryableLayers) {
        
        // Index to the corresponding layerInfo object in the webmap's operational layers
        NSNumber *index = [mapLayers objectForKey:layer.name];
        AGSWebMapLayerInfo *layerInfo = nil;
        
        // Get the corresponding layerInfo object
        if (index != nil) {
            int layerInfoIndex = [index intValue];
            layerInfo = [self.webMap.operationalLayers  objectAtIndex:layerInfoIndex];
        }
        else {
            continue;
        }
        
        AGSTiledMapServiceLayer *tiledLayer = nil;
        AGSDynamicMapServiceLayer *dynamicLayer = nil;
        
        // If the layer is a tiled map service layer...
        if([layer isKindOfClass:[AGSTiledMapServiceLayer class]]) {
            
            // Get the corresponding layerView object
            tiledLayer = (AGSTiledMapServiceLayer*)layer;
            AGSTiledLayerView *layerView = [self.mapView.mapLayerViews objectForKey:layer.name];
            
            // Don't query if the layer view is hidden or completely transparent
            // TODO : implement check for layer scale range when CR 239428 is resolved
            if (layerView.hidden || layerView.alpha == 0) {
                continue;
            }
        }
        // Otherwise if the layer is a dynamic map service layer
        else if ([layer isKindOfClass:[AGSDynamicMapServiceLayer class]] && layerInfo) {
            
            // Get the corresponding layerView object
            dynamicLayer = (AGSDynamicMapServiceLayer*)layer;
            AGSDynamicLayerView *layerView = [self.mapView.mapLayerViews objectForKey:layer.name];
            
            // Don't query if the layer view is hidden or completely transparent, or if the
            // layer is out of scale range
            if (layerView.hidden || layerView.alpha == 0 ||
                ((self.mapView.mapScale > dynamicLayer.minScale || self.mapView.mapScale < dynamicLayer.maxScale) && dynamicLayer.maxScale != 0)) {
                continue;
            }
        }
        
        NSString *layerURLString = [layerInfo.URL absoluteString];
        
        // For each sublayer of the map service layer... (feature layers will have a nil layers property)
        for (AGSWebMapSubLayerInfo *subLayerInfo in layerInfo.layers) {
            
            BOOL layerVisible = YES;
            
            if ([layer isKindOfClass:[AGSDynamicMapServiceLayer class]]) {
                
                
                // For each map service layer info..
                for (AGSMapServiceLayerInfo *msLayerInfo in dynamicLayer.mapServiceInfo.layerInfos) {
                    
                    // If the map service layer info corresponds to the sublayer info
                    if (msLayerInfo.layerId == subLayerInfo.layerId) {
                        // query if the layer is visible at the current scale
                        layerVisible =[dynamicLayer subLayer:msLayerInfo isVisibleAtMapScale:self.mapView.mapScale];
                        break;
                    }
                }
                
                
            }
            
            else if ([layer isKindOfClass:[AGSTiledMapServiceLayer class]]) {
                
                // For each map service layer info..
                for (AGSMapServiceLayerInfo *msLayerInfo in tiledLayer.mapServiceInfo.layerInfos) {
                    
                    // If the map service layer info corresponds to the sublayer info
                    if (msLayerInfo.layerId == subLayerInfo.layerId) {
                        // query if the layer is visible at the current scale
                        layerVisible = [tiledLayer subLayer:msLayerInfo isVisibleAtMapScale:self.mapView.mapScale];
                        break;
                    }
                }
                
            }
            
            if (!layerVisible || subLayerInfo.popupInfo==nil) {
                continue;
            }
            
            
            //Note: There are some "dumb" tile service layers whose features cannot be reached by appending
            //the layerId to the map service URL. If these services wish to provide access to feature
            //information they must provide a URL to a feature service in the layerURL property on the
            //subLayerInfo
            
            // Check to see if this is a "dumb" map service, if so use the URL provided
            AGSQueryTask *queryTask = nil;
            if (subLayerInfo.layerURL) {
                queryTask = [[AGSQueryTask alloc] initWithURL:subLayerInfo.layerURL];
            }
            else {
                // Get the URL to the sublayer by appending /{layerId} to the map service URL
                NSString *newURLString = [layerURLString stringByAppendingString:[NSString stringWithFormat:@"/%d",subLayerInfo.layerId]];
                
                // Create a query task with the query
                queryTask = [[AGSQueryTask alloc] initWithURL:[NSURL URLWithString:newURLString]];
            }
            
            queryTask.delegate = self;
            
            // Keep track of what layer's popupInfo goes with each query by setting the state
            // property of the request operation
            AGSRequestOperation *op = (AGSRequestOperation*)[queryTask executeWithQuery:query];
            [op.state setDictionary:[NSDictionary dictionaryWithObject:subLayerInfo.popupInfo forKey:@"popupInfo"]];
            
            // Keep track of request operations
            [self.outstandingQueries addObject:op];
            
        }
    }
    
    // If we never made any queries,
        bool more = (self.outstandingQueries.count > 0);
        [self.delegate foundPopups:popups atMapPonit:mappoint withMoreToFollow:more];
     
}


//- (void) displayPopupsForMapView:(AGSMapView*) mapView atPoint:(AGSPoint*)mappoint withGraphics:(NSDictionary *)graphics inWebMap:(AGSWebMap*)webmap withMapLayers:(NSDictionary*)mapLayers queryableLayers:(NSArray*)queryableLayers  {
//    
//    if(!self.operationQueue)
//        self.operationQueue = [[[NSMutableArray alloc] init] autorelease];
//    
//    self.mapView = mapView;
//    self.popupVC = nil;
//    self.mapView.callout.accessoryButtonHidden = NO;
//    self.webMap = webmap;
//    
//    // Create a popup for each feature in each feature layer at the point tapped
//    if ([graphics allValues].count>0) {
//        NSArray *graphicsArrays = [graphics allValues];
//        NSMutableArray *popups = [NSMutableArray array];
//        for (NSArray *graphicsArray in graphicsArrays) {
//            for (AGSGraphic *graphic in graphicsArray) {
//                if ([graphic.layer isKindOfClass:[AGSFeatureLayer class]]) {
//                    AGSPopupInfo *popupInfo = [self.webMap popupInfoForFeatureLayer:(AGSFeatureLayer*)graphic.layer];
//                    AGSPopup *popup = [AGSPopup popupWithGraphic:graphic popupInfo:popupInfo];
//                    [popups addObject:popup];
//                }
//                
//            }
//        }
//        
//        // If we've found one or more features
//        if (popups.count > 0) {
//            //Create a popupsContainer view controller with the popups
//            self.popupVC = [[[AGSPopupsContainerViewController alloc] initWithPopups:popups usingNavigationControllerStack:false] autorelease];        
//            self.popupVC.style = AGSPopupsContainerStyleBlack;
//            self.popupVC.delegate = self;
//            
//            // Display initial results from feature layer
//            if ([[UIDevice currentDevice] isIPad]) { 
//                self.mapView.callout.customView = self.popupVC.view;
//            }
//            else {
//                self.mapView.callout.title = [NSString stringWithFormat:@"%d Results", popups.count];
//                self.mapView.callout.detail = @"loading more...";
//            }
//            
//            
//            // Start the activity indicator in the upper right corner of the
//            // popupsContainer view controller while we wait for the query results
//            self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
//            UIBarButtonItem *blankButton = [[[UIBarButtonItem alloc] initWithCustomView:(UIView*)self.activityIndicator] autorelease];
//            self.popupVC.actionButton = blankButton;
//            [self.activityIndicator startAnimating];
//        }
//    }
//    
//    // If we did not tap on a feature layer start the activity indicator
//    // in the callout while we wait for results
//    if(!self.popupVC) {
//        [self.mapView showCalloutAtPoint:mappoint];
//        self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
//        self.mapView.callout.customView = self.activityIndicator;
//        [self.activityIndicator startAnimating];
//        
//    }
//    
//    // Create a query
//    AGSQuery* query = [AGSQuery query];
//    
//    // Buffer the mappoint by 10 pixels so we can query by intersection
//    AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
//    AGSPolygon *buffer = [geometryEngine bufferGeometry:mappoint byDistance:(10 *self.mapView.resolution)];
//    query.geometry = buffer;
//    query.outSpatialReference = self.mapView.spatialReference;
//    
//    // Have the query request all attribute fields
//    query.outFields = [NSArray arrayWithObject:@"*"];
//    
//    // For each queryable layer...
//    for (AGSLayer *layer in queryableLayers) {
//        
//        // Index to the corresponding layerInfo object in the webmap's operational layers
//        NSNumber *index = [mapLayers objectForKey:layer.name];
//        AGSWebMapLayerInfo *layerInfo = nil;
//        
//        // Get the corresponding layerInfo object
//        if (index != nil) {
//            int layerInfoIndex = [index intValue];
//            layerInfo = [self.webMap.operationalLayers  objectAtIndex:layerInfoIndex];
//        }
//        else {
//            continue;
//        }
//        
//        AGSTiledMapServiceLayer *tiledLayer = nil;
//        AGSDynamicMapServiceLayer *dynamicLayer = nil;
//        
//        // If the layer is a tiled map service layer...
//        if([layer isKindOfClass:[AGSTiledMapServiceLayer class]]) {
//            
//            // Get the corresponding layerView object
//            tiledLayer = (AGSTiledMapServiceLayer*)layer;
//            AGSTiledLayerView *layerView = [self.mapView.mapLayerViews objectForKey:layer.name];
//            
//            // Don't query if the layer view is hidden or completely transparent
//            // TODO : implement check for layer scale range when CR 239428 is resolved
//            if (layerView.hidden || layerView.alpha == 0) {
//                continue;
//            }
//        }
//        // Otherwise if the layer is a dynamic map service layer
//        else if ([layer isKindOfClass:[AGSDynamicMapServiceLayer class]] && layerInfo) {
//            
//            // Get the corresponding layerView object
//            dynamicLayer = (AGSDynamicMapServiceLayer*)layer;
//            AGSDynamicLayerView *layerView = [self.mapView.mapLayerViews objectForKey:layer.name];
//            
//            // Don't query if the layer view is hidden or completely transparent, or if the 
//            // layer is out of scale range
//            if (layerView.hidden || layerView.alpha == 0 ||
//                ((self.mapView.mapScale > dynamicLayer.minScale || self.mapView.mapScale < dynamicLayer.maxScale) && dynamicLayer.maxScale != 0)) {
//                continue;
//            }
//        }
//        
//        NSString *layerURLString = [layerInfo.URL absoluteString];
//        
//        // For each sublayer of the map service layer... (feature layers will have a nil layers property)
//        for (AGSWebMapSubLayerInfo *subLayerInfo in layerInfo.layers) {
//            
//            BOOL layerVisible = YES;
//            
//            if ([layer isKindOfClass:[AGSDynamicMapServiceLayer class]]) {
//                
//                               
//                // For each map service layer info..
//                for (AGSMapServiceLayerInfo *msLayerInfo in dynamicLayer.mapServiceInfo.layerInfos) {
//                    
//                    // If the map service layer info corresponds to the sublayer info
//                    if (msLayerInfo.layerId == subLayerInfo.layerId) {
//                        // query if the layer is visible at the current scale
//                        layerVisible =[dynamicLayer subLayer:msLayerInfo isVisibleAtMapScale:self.mapView.mapScale];
//                        break;
//                    }
//                }
//                
//                
//            }
//            
//            else if ([layer isKindOfClass:[AGSTiledMapServiceLayer class]]) {
//                
//                // For each map service layer info..
//                for (AGSMapServiceLayerInfo *msLayerInfo in tiledLayer.mapServiceInfo.layerInfos) {
//                    
//                    // If the map service layer info corresponds to the sublayer info
//                    if (msLayerInfo.layerId == subLayerInfo.layerId) {
//                        // query if the layer is visible at the current scale
//                        layerVisible = [tiledLayer subLayer:msLayerInfo isVisibleAtMapScale:self.mapView.mapScale];
//                        break;
//                    }
//                }
//                
//            }
//            
//            if (!layerVisible || subLayerInfo.popupInfo==nil) {
//                continue;
//            }
//            
//            
//            //Note: There are some "dumb" tile service layers whose features cannot be reached by appending
//            //the layerId to the map service URL. If these services wish to provide access to feature
//            //information they must provide a URL to a feature service in the layerURL property on the
//            //subLayerInfo
//            
//            // Check to see if this is a "dumb" map service, if so use the URL provided
//            AGSQueryTask *queryTask = nil;
//            if (subLayerInfo.layerURL) {
//                queryTask = [[AGSQueryTask alloc] initWithURL:subLayerInfo.layerURL];
//            }
//            else {
//                // Get the URL to the sublayer by appending /{layerId} to the map service URL
//                NSString *newURLString = [layerURLString stringByAppendingString:[NSString stringWithFormat:@"/%d",subLayerInfo.layerId]];
//                
//                // Create a query task with the query
//                queryTask = [[AGSQueryTask alloc] initWithURL:[NSURL URLWithString:newURLString]];
//            }
//            
//            queryTask.delegate = self;
//            
//            // Keep track of what layer's popupInfo goes with each query by setting the state
//            // property of the request operation
//            AGSRequestOperation *op = (AGSRequestOperation*)[queryTask executeWithQuery:query];
//            [op.state setDictionary:[NSDictionary dictionaryWithObject:subLayerInfo.popupInfo forKey:@"popupInfo"]];
//            
//            // Keep track of request operations
//            [self.operationQueue addObject:op];
//            
//        }
//    }
//    
//    // If we never made any queries, 
//    if (self.operationQueue.count == 0){
//        //and we don't have popups, show 'No Results'
//        if(!self.popupVC){
//            self.mapView.callout.customView = nil;
//            self.mapView.callout.accessoryButtonHidden = YES;
//            self.mapView.callout.title = @"No Results";
//            self.mapView.callout.detail = @"";
//        }else{ //we have popups
//            //remove the activity indicator from the popup vc
//            self.popupVC.actionButton = nil;
//            self.mapView.callout.detail= @"";
//        }
//        
//    }
//    
//}

#pragma  mark - Query Task delegate methods 
- (void) queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didExecuteWithFeatureSetResult:(AGSFeatureSet *)featureSet {
    
    [self.outstandingQueries removeObject:op];
    
    // Retrieve the popupInfo
    AGSRequestOperation *operation = (AGSRequestOperation*)op;
    AGSPopupInfo *popupInfo = [operation.state objectForKey:@"popupInfo"];
    NSMutableArray *popups = [NSMutableArray array];
    
    // If our query returned any features...
    if (featureSet.features.count > 0) {
        
        // Create a popup for each feature
        NSArray *graphics = featureSet.features;
        for (AGSGraphic *graphic in graphics) {
            AGSPopup *popup = [AGSPopup popupWithGraphic:graphic popupInfo:popupInfo];
            [popups addObject:popup];
        }
    }
    
    [self.delegate foundAdditionalPopups:popups withMoreToFollow:(self.outstandingQueries.count>0)];
    
    [queryTask release];
    
}

//- (void) queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didExecuteWithFeatureSetResult:(AGSFeatureSet *)featureSet {
//    
//    [self.operationQueue removeObject:op];
//    
//    // Retrieve the popupInfo
//    AGSRequestOperation *operation = (AGSRequestOperation*)op;
//    AGSPopupInfo *popupInfo = [operation.state objectForKey:@"popupInfo"];
//    
//    // If our query returned any features...
//    if (featureSet.features.count > 0) {
//        
//        // Create a popup for each feature
//        NSMutableArray *popups = [NSMutableArray array];
//        NSArray *graphics = featureSet.features;
//        for (AGSGraphic *graphic in graphics) {
//            AGSPopup *popup = [AGSPopup popupWithGraphic:graphic popupInfo:popupInfo];
//            [popups addObject:popup];
//        }
//        
//        // If we already have a popupsContainerViewController from
//        // a feature layer, add the additional popups
//        if (self.popupVC) {
//            [self.popupVC showAdditionalPopups:popups];
//            
//            // If these are the results of the final query stop the activityIndicator
//            if ([self.operationQueue count]==0) {
//                [self.activityIndicator stopAnimating];
//                
//                // If we are on iPhone display the number of results returned
//                if (![[UIDevice currentDevice] isIPad]) {
//                    self.mapView.callout.customView = nil;
//                    NSString *results = self.popupVC.popups.count == 1 ? @"Result" : @"Results";
//                    self.mapView.callout.title = [NSString stringWithFormat:@"%d %@", self.popupVC.popups.count, results];
//                    self.mapView.callout.detail = nil;
//                }
//            }
//        }
//        // Otherwise create a new popupsContainer view controller
//        else {
//            self.popupVC = [[[AGSPopupsContainerViewController alloc] initWithPopups:popups] autorelease];
//            self.popupVC.delegate = self;
//            self.popupVC.style = AGSPopupsContainerStyleBlack;
//            
//            // If we are on iPad set the popupsContainerViewController to be the callout's customView
//            if ([[UIDevice currentDevice] isIPad]) {
//                self.mapView.callout.customView = self.popupVC.view;
//            }
//            
//            // If we have more queries coming start the indicator on the popupVC
//            if (self.operationQueue.count>0) {
//                
//                if ([[UIDevice currentDevice] isIPad] /* Divesh Commented || _webMapContainsFeatureLayer*/) {
//                    [self.activityIndicator stopAnimating];
//                    self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
//                    UIBarButtonItem *blankButton = [[[UIBarButtonItem alloc] initWithCustomView:(UIView*)self.activityIndicator] autorelease];
//                    self.popupVC.actionButton = blankButton;
//                    [self.activityIndicator startAnimating];
//                }
//                
//            }
//            // Otherwise if we are on iPhone display the number of results returned in the callout
//            else if (![[UIDevice currentDevice] isIPad]) {
//                self.mapView.callout.customView = nil;
//                NSString *results = self.popupVC.popups.count == 1 ? @"Result" : @"Results";
//                self.mapView.callout.title = [NSString stringWithFormat:@"%d %@", self.popupVC.popups.count, results];
//                self.mapView.callout.detail = nil;
//            }
//        }
//    }
//    else {
//        // If these are the results of the last query stop the activityIndicator
//        if (self.operationQueue.count==0) {
//            [self.activityIndicator stopAnimating];
//            
//            // If no query returned results
//            if (!self.popupVC) {
//                self.mapView.callout.customView = nil;
//                self.mapView.callout.accessoryButtonHidden = YES;
//                self.mapView.callout.title = @"No Results";
//            }
//            // Otherwise if we are on iPhone display the number of results returned in the callout
//            else if (![[UIDevice currentDevice] isIPad]) {
//                self.mapView.callout.customView = nil;
//                NSString *results = self.popupVC.popups.count == 1 ? @"Result" : @"Results";
//                self.mapView.callout.title = [NSString stringWithFormat:@"%d %@", self.popupVC.popups.count, results];
//                self.mapView.callout.detail = nil;
//            }
//        }
//    }
//    
//    [queryTask release];
//    
//}


// If the query task fails log the error and release its memory
- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didFailWithError:(NSError *)error {
    
    NSLog(@"Query failed with the following error: %@", error);
    [self.outstandingQueries removeObject:op];
    [queryTask release];
}

- (void)popupsContainerDidFinishViewingPopups:(id<AGSPopupsContainer>)popupsContainer {
    
    // If the user had pressed the done button
    // cancel all queries
    [self.outstandingQueries removeAllObjects];
    
    // If we are on iPad dismiss the callout
    if ([[UIDevice currentDevice] isIPad]) {
        self.mapView.callout.hidden = YES;
        return;
    }
    
    // Otherwise dismiss the modal viewcontroller
    [self.popupVC dismissModalViewControllerAnimated:YES];
        
}

- (void) presentPopupUsingViewController:(UIViewController*)viewController {
    // The callout accesory button will not get shown on iPad, so we are on iPhone
    // If it is pressed, modally display a popup
    [viewController presentModalViewController:self.popupVC animated:YES];
}


@end

#pragma mark - AGSTiledMapServiceLayer (DisplayPopupHelper) category
@implementation AGSTiledMapServiceLayer (DisplayPopupHelper) 

- (BOOL) subLayer:(AGSMapServiceLayerInfo*)layerInfo isVisibleAtMapScale:(double)mapScale{

    BOOL layerVisible = YES;
    
    //get the ppi of the device
    double ppi = [[UIDevice currentDevice] ppi];
    
    BOOL retinaDisplay = ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) ? YES : NO;
    
    if (retinaDisplay && !self.renderNativeResolution) {
        ppi = ppi / 2;
    }
    
    //We use this factor to adjust the mapscale before comparing it to sub-layers scale range
    double dpiFactor = ppi / self.tileInfo.dpi;

    
    // Check if the current map scale is not in the visible range of the sub-layer (if maxScale is 0 then the layer is visible at all scales)
    if (( (mapScale/dpiFactor)  > layerInfo.minScale || (mapScale/dpiFactor) < layerInfo.maxScale) && layerInfo.maxScale != 0) {
        layerVisible = NO;
    }
    
    
    
    // If the sub-layer is visible, we should also check if the parent sub-layer is visible
    if (layerVisible) {
        for (AGSMapServiceLayerInfo *info in self.mapServiceInfo.layerInfos) {
            if (layerInfo.parentLayerID == info.layerId) {
                return [self subLayer:info isVisibleAtMapScale:mapScale];
            }
        }
    }
    
    return layerVisible;
}


@end


#pragma mark - AGSDynamicMapServiceLayer (DisplayPopupHelper) category

@implementation AGSDynamicMapServiceLayer (DisplayPopupHelper)

- (BOOL) subLayer:(AGSMapServiceLayerInfo *)layerInfo isVisibleAtMapScale:(double)mapScale {
    
    BOOL layerVisible = YES;
    
    // first check if the dynamic layers has some sub-layers partially turned or or off
    if (self.visibleLayers && self.visibleLayers.count>1) {
        // If this sub-layer is not a group layer,
        // and if it is not in the list of visible layers,
        // then bail
        if (!layerInfo.subLayerIDs && ![self.visibleLayers containsObject:[NSNumber numberWithInt:layerInfo.layerId]] ) {
            layerVisible = NO;
        }
    }else
    // otherwise, check the default visibility set on the sub-layer
    if (!layerInfo.defaultVisibility ) {
           layerVisible = NO;
     }
    
    // If the current map scale is not in the visible range of the layer (if maxScale is 0 then the layer is visible at all scales)
    if ((mapScale > layerInfo.minScale || mapScale < layerInfo.maxScale) && layerInfo.maxScale != 0) {
        layerVisible = NO;
    }
    
    // If the sub-layer is visible, we should also check if the parent sub-layer is visible
    if (layerVisible) {
        for (AGSMapServiceLayerInfo *info in self.mapServiceInfo.layerInfos) {
            if (layerInfo.parentLayerID == info.layerId) {
                return [self subLayer:info isVisibleAtMapScale:mapScale];
            }
        }
    }
    
    return layerVisible;
    
}

@end

