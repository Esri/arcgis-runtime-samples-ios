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

#import "PopupHelper.h"


@interface PopupHelper() {
    NSString *_webMapId;
    UIActivityIndicatorView *_activityIndicator;
    NSMutableArray *_outstandingQueries;
    NSMutableArray* _queryTasks;
    id<PoupupHelperDelegate> __weak _delegate;
}
@end

@implementation PopupHelper

@synthesize outstandingQueries = _outstandingQueries;
@synthesize queryTasks = _queryTasks;
@synthesize delegate = _delegate;


- (void) findPopupsForMapView:(AGSMapView*) mapView withGraphics:(NSDictionary *)graphics atPoint:(AGSPoint*)mappoint  andWebMap:(AGSWebMap*)webmap withQueryableLayers:(NSArray*)queryableLayers  {
    
    if(!self.outstandingQueries)
        self.outstandingQueries = [[NSMutableArray alloc] init];
    if(!self.queryTasks)
        self.queryTasks = [[NSMutableArray alloc] init];
    
    NSMutableArray *popups = [NSMutableArray array];

    // Create a popup for each feature in each feature layer at the point tapped
    if ([graphics allValues].count>0) {
        NSArray *graphicsArrays = [graphics allValues];
                for (NSArray *graphicsArray in graphicsArrays) {
            for (AGSGraphic *graphic in graphicsArray) {
                if ([graphic.layer isKindOfClass:[AGSFeatureLayer class]]) {
                    AGSPopupInfo *popupInfo = [webmap popupInfoForFeatureLayer:(AGSFeatureLayer*)graphic.layer];
                    AGSPopup *popup = [AGSPopup popupWithGraphic:graphic popupInfo:popupInfo];
                    [popups addObject:popup];
                }
                
            }
        }
    }
    
    //Check if we might have additional popups
    //For example, if we need to query any map service layers
    

    
    // For each queryable layer...
    for (AGSLayer *layer in queryableLayers) {
        
        AGSWebMapLayerInfo *layerInfo = [webmap layerInfoForLayer:layer];
        if(layerInfo==nil){
            //skip this layer because absence of layerInfo implies the
            //webmap does not contain a popup definition for any sub-layers of this layer.
            continue;
        }
        
        
        // If the layer is a tiled map service layer...
        if([layer isKindOfClass:[AGSTiledMapServiceLayer class]] || ([layer isKindOfClass:[AGSDynamicMapServiceLayer class]] && layerInfo) ) {
            
            
            // Skip this layer if the  layer view is hidden or completely transparent, or if the
            // layer is out of scale range
            if (!layer.visible || layer.opacity == 0 || ![layer isInScale]) {
                continue;
            }
        }
        
        //If we reach this point, we haven't skipped the layer yet :-)
                
        
        NSString *layerURLString = [layerInfo.URL absoluteString];
        
        // For each sublayer of the map service layer... (feature layers will have a nil layers property)
        for (AGSWebMapSubLayerInfo *subLayerInfo in layerInfo.layers) {
            
            BOOL isSubLayerVisible = YES;
            
            if ([layer isKindOfClass:[AGSDynamicMapServiceLayer class]]) {
                
                AGSDynamicMapServiceLayer* dynamicLayer = (AGSDynamicMapServiceLayer*)layer;
                
                // For each map service layer info..
                for (AGSMapServiceLayerInfo *msLayerInfo in dynamicLayer.mapServiceInfo.layerInfos) {
                    
                    // If the map service layer info corresponds to the sublayer info
                    if (msLayerInfo.layerId == subLayerInfo.layerId) {
                        // query if the layer is visible at the current scale
                        isSubLayerVisible =[dynamicLayer subLayer:msLayerInfo isVisibleAtMapScale:mapView.mapScale];
                        break;
                    }
                }
                
                
            }
            
            else if ([layer isKindOfClass:[AGSTiledMapServiceLayer class]]) {
                
                AGSTiledMapServiceLayer* tiledLayer =
                (AGSTiledMapServiceLayer*)layer;
                // For each map service layer info..
                for (AGSMapServiceLayerInfo *msLayerInfo in tiledLayer.mapServiceInfo.layerInfos) {
                    
                    // If the map service layer info corresponds to the sublayer info
                    if (msLayerInfo.layerId == subLayerInfo.layerId) {
                        // query if the layer is visible at the current scale
                        isSubLayerVisible = [tiledLayer subLayer:msLayerInfo isVisibleAtMapScale:mapView.mapScale];
                        break;
                    }
                }
                
            }
            
            //Skip the sublayer if the sublayer is not visible, or we didn't find a popup definition for the sublayer
            if (!isSubLayerVisible || subLayerInfo.popupInfo==nil) {
                continue;
            }
            
            //At this point, we know we need to query the sub-layer because it is visible and has a popup definition
            
            
            
            
            // Check to see if this is a "dumb" tile service by testing the presence of layerURL property
            AGSQueryTask *queryTask = nil;
            if (subLayerInfo.layerURL) {
                //if so use the URL provided to perform the query
                queryTask = [[AGSQueryTask alloc] initWithURL:subLayerInfo.layerURL];
            }
            else {
                // Otheriwse (this is not a dumb tile service)
                // Construct the URL to the sublayer by appending /{layerId} to the map service URL
                NSString *newURLString = [layerURLString stringByAppendingString:[NSString stringWithFormat:@"/%d",subLayerInfo.layerId]];
                
                // Create a query task with the query
                queryTask = [[AGSQueryTask alloc] initWithURL:[NSURL URLWithString:newURLString]];
            }
            
            queryTask.delegate = self;
            
            // Create a query
            AGSQuery* query = [AGSQuery query];
            
            // Buffer the mappoint by 10 pixels so we can query by intersection
            AGSGeometryEngine *geometryEngine = [AGSGeometryEngine defaultGeometryEngine];
            AGSPolygon *buffer = [geometryEngine bufferGeometry:mappoint byDistance:(10 *mapView.resolution)];
            query.geometry = buffer;
            query.outSpatialReference = mapView.spatialReference;
            
            // Have the query request all attribute fields
            query.outFields = [NSArray arrayWithObject:@"*"];
            
            // Keep track of what layer's popupInfo goes with each query by setting the state
            // property of the request operation
            AGSRequestOperation *op = (AGSRequestOperation*)[queryTask executeWithQuery:query];
            [op.state setDictionary:[NSDictionary dictionaryWithObject:subLayerInfo.popupInfo forKey:@"popupInfo"]];
            
            // Keep track of request operations
            [self.outstandingQueries addObject:op];
            [self.queryTasks addObject:queryTask];
            
        }
    }
    
    // If we never made any queries,
        bool more = (self.outstandingQueries.count > 0);
        [self.delegate foundPopups:popups atMapPonit:mappoint withMoreToFollow:more];
     
}


#pragma  mark - Query Task delegate methods 
- (void) queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didExecuteWithFeatureSetResult:(AGSFeatureSet *)featureSet {
    
    [self.outstandingQueries removeObject:op];
    [self.queryTasks removeObject:((AGSRequestOperation*)op).securedResource];

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
    
    
}



// If the query task fails log the error and release its memory
- (void)queryTask:(AGSQueryTask *)queryTask operation:(NSOperation *)op didFailWithError:(NSError *)error {
    
    NSLog(@"Query failed with the following error: %@", error);
    [self.outstandingQueries removeObject:op];
    [self.queryTasks removeObject:((AGSRequestOperation*)op).securedResource];
}

- (void)cancelOutstandingRequests{
    
    for (AGSRequestOperation* op in self.outstandingQueries) {
        [op cancel];
    }
    [self.outstandingQueries removeAllObjects];
    [self.queryTasks removeAllObjects];
}



@end

#pragma mark - AGSTiledMapServiceLayer (PopupHelper) category
@implementation AGSTiledMapServiceLayer (PopupHelper) 

- (BOOL) subLayer:(AGSMapServiceLayerInfo*)layerInfo isVisibleAtMapScale:(double)mapScale{

    BOOL layerVisible = YES;
    
    //get the ppi of the device
    double ppi = [[AGSDevice currentDevice] ppi];
    
    BOOL retinaDisplay = ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0)) ? YES : NO;
    
    if (retinaDisplay && !self.renderNativeResolution) {
        ppi = ppi / 2;
    }
    
    //We use this factor to adjust the mapscale before comparing it to sub-layers scale range
    double dpiFactor = ppi / self.tileInfo.dpi;

    
    // Check if the current map scale is not in the visible range of the sub-layer (if maxScale is 0 then the layer is visible at all scales)
    
    if(
       (layerInfo.minScale!=0 && (mapScale/dpiFactor)  > layerInfo.minScale )
       || (layerInfo.maxScale!=0 && (mapScale/dpiFactor) < layerInfo.maxScale)
       ){
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


#pragma mark - AGSDynamicMapServiceLayer (PopupHelper) category

@implementation AGSDynamicMapServiceLayer (PopupHelper)

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
    
    // If the current map scale is not in the visible range of the layer (if maxScale & minscale is 0 then the layer is visible at all scales)
    if(
        (layerInfo.minScale!=0 && mapScale > layerInfo.minScale )
        ||
        (layerInfo.maxScale!=0 && mapScale < layerInfo.maxScale)
       )
    {
        layerVisible = NO;
    }
    
    // If the sub-layer is visibl e, we should also check if the parent sub-layer is visible
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

#pragma mark - AGSWebMap (PopupHelper) category

@implementation AGSWebMap (PopupHelper)

- (AGSWebMapLayerInfo*) layerInfoForLayer:(AGSLayer*) layer {
    if ([layer isKindOfClass:[AGSTiledMapServiceLayer class]]) {
        AGSTiledMapServiceLayer *tiledLayer = (AGSTiledMapServiceLayer*)layer;
        for (int i = 0; i <self.operationalLayers.count; i++) {
            AGSWebMapLayerInfo *layerInfo = [self.operationalLayers objectAtIndex:i];
            if ([tiledLayer.URL.absoluteString isEqualToString:layerInfo.URL.absoluteString])
                return layerInfo;
        }
        return nil; //we didn't find a layer info
    }else  if ([layer isKindOfClass:[AGSDynamicMapServiceLayer class]]) {
        AGSDynamicMapServiceLayer *dynamicLayer = (AGSDynamicMapServiceLayer*)layer;
        for (int i = 0; i <self.operationalLayers.count; i++) {
            AGSWebMapLayerInfo *layerInfo = [self.operationalLayers objectAtIndex:i];
            if ([dynamicLayer.URL.absoluteString isEqualToString:layerInfo.URL.absoluteString])
                return layerInfo;
        }
        return nil; //we didn't find a layer info
    }else{
        //for all other layer types
        return nil;
    }
}

@end

