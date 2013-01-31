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

#import "LayerInfo.h"

@interface LayerInfo() <AGSMapServiceInfoDelegate>

//flattens the tree and give all the elements and legend, if needed, as a single array. 
- (void)flattenElementsWithLegend:(BOOL)withLegend inArray:(NSMutableArray *)flattenedArray;

//retrieves the feature layer legend info. 
-(NSMutableArray *)legendElementsForFeatureLayer:(AGSFeatureLayer *)fl;

//helper method which is recursively called to construct the layer tree. 
- (void)constructTree:(AGSMapServiceInfo *)mapServiceInfo;

//adds the corresponding levels for the nodes after the tree is constructed. 
- (void)addLegendLevels;

//this is for determining whether a layer is truly visible depending on the parents' visibility. 
- (BOOL)trulyVisible;

//determines the visibility of the calling layer and manipulates the visible layers array. 
- (void)decideVisibility:(NSMutableArray *)visibleLayers;

//returns all the visible leafs in the layer tree. 
- (void)visibleLayersWithParentsRemoved:(NSMutableArray *)visibleLayers;

@end

@implementation LayerInfo

@synthesize layerID = _layerID, layer = _layer, layerName = _layerName, legendElements = _legendElements;
@synthesize parent = _parent, children = _children, flattenedTreeCache = _flattenedTreeCache;
@synthesize visible = _visible, canChangeVisibility = _canChangeVisibility, inclusive = _inclusive;

#pragma mark -
#pragma mark Initializers


- (id)initWithLayer:(AGSLayer*)layer layerID:(NSInteger)layerID name:(NSString*)name target:(id)target
{
    
    if(self = [super init])
    {   
        //assign the relevant properties.
        self.layer = layer;            
        self.layerName = name;            
        self.layerID = layerID; 
        
        //initially the layer will not show the sub layers. 
        self.inclusive = NO;
        
        //since this is a dynamic layer, it can change the visibility. 
        self.canChangeVisibility = YES;
        
        //checks if the layer is nil or not. 
        if(layer)
        {                        
            //check if the layer is dynamic map service layer
            if([layer isKindOfClass:[AGSDynamicMapServiceLayer class]])
            {
                //cast it accordingly. 
                AGSDynamicMapServiceLayer *dynamicMSL = (AGSDynamicMapServiceLayer *)layer;
                
                //only if the layer id is > -1, we should create a legend info dictionary. 
                if(self.layerID > -1)
                {
                    AGSMapServiceLayerInfo *msli = [dynamicMSL.mapServiceInfo.layerInfos objectAtIndex:layerID]; 
                    
                    //assign the defaulty visibility. 
                    _visible = msli.defaultVisibility;
                    
                    //construct the legends if exists. 
                    if(msli.legendLabels)
                    {
                        self.legendElements = [NSMutableArray array];
                        for (int i = 0 ; i < msli.legendLabels.count; i++) {
                            LegendElement *le = [LegendElement legendElementWithTitle:[msli.legendLabels objectAtIndex:i] withSwatch:[msli.legendImages objectAtIndex:i]];                            
                            [self.legendElements addObject:le];
                        }
                    }
                }
                
                //otherwise, when the layer is the root, we retrieve the legend info. 
                else
                {
                    //since this is the root layer on the map, we depend on the view's hidden property. 
                    _visible = self.layer.visible;
                    
                    //assigning mapserviceinfo delegate
                    dynamicMSL.mapServiceInfo.delegate = self;
                    
                    //retrieving the legend info. 
                    [dynamicMSL.mapServiceInfo retrieveLegendInfo];
                    
                    return self;
                }         
                
                //if the layer info is > -1 and that the legend info is retrieved, we recursively construct the tree. 
                [self constructTree:dynamicMSL.mapServiceInfo];              
            }
            
             //check if the layer is tiled map service layer
            if([layer isKindOfClass:[AGSTiledMapServiceLayer class]])
            {
                AGSTiledMapServiceLayer *tiledMSL = (AGSTiledMapServiceLayer *)layer;

                if(self.layerID > -1)
                {
                    //all layers can change visibility for non single fused map cache.  
                    self.canChangeVisibility = !tiledMSL.mapServiceInfo.singleFusedMapCache;      
                    
                    AGSMapServiceLayerInfo *msli = [tiledMSL.mapServiceInfo.layerInfos objectAtIndex:layerID]; 
                    
                    //assign the defaulty visibility. 
                    _visible = msli.defaultVisibility;
                    
                    //construct the legend
                    if(msli.legendLabels)
                    {
                        self.legendElements = [NSMutableArray array];
                        for (int i = 0 ; i < msli.legendLabels.count; i++) {
                            LegendElement *le = [LegendElement legendElementWithTitle:[msli.legendLabels objectAtIndex:i] withSwatch:[msli.legendImages objectAtIndex:i]];                            
                            [self.legendElements addObject:le];
                        }
                    }                    
                }
                else
                { 
                    _visible = self.layer.visible;
                    tiledMSL.mapServiceInfo.delegate = self;
                    [tiledMSL.mapServiceInfo retrieveLegendInfo];
                    return self;                     
                } 
                
                //call this method to recursively construct the tree. 
                [self constructTree:tiledMSL.mapServiceInfo];
            }
            
            
             //check if the layer is feature layer
            if([layer isKindOfClass:[AGSFeatureLayer class]])
            {
                AGSFeatureLayer *featureLayer = (AGSFeatureLayer *)layer;
                
                //since feature layer will not have any children (only legend), the visibility depends on the actual view. 
                _visible = self.layer.visible;
                
                //extract the legend from the feature layer, which is a graphic layer. 
                self.legendElements = [self legendElementsForFeatureLayer:featureLayer];
                
            }
            
             //check if the layer is Bing Map layer or Open Street Map layer
            if([layer isKindOfClass:[AGSBingMapLayer class]] || [layer isKindOfClass:[AGSOpenStreetMapLayer class]])
            {
                _visible = self.layer.visible;
                
                //no legend elements for these layers. 
                self.legendElements = nil;   
             
                
            }
        }
        
        //if the layer view is nil, then it is the map level layer info. Hence, we leave it as visible and inclusive. 
        else
        {
            self.inclusive = YES;
            _visible = YES;
        }
    }    
    return self;
}

             
             

#pragma mark -
#pragma mark Custom Properties

//setter for the visible property. 
- (void)setVisible:(BOOL)visible
{
    _visible = visible;
    
    //if this is the root layer, the view's visibility is changed. 
    if(self.layerID == -1)
    {
        self.layer.visible = visible;
        return;
    }
    
    if(self.layer)
    {
        //check if the layer object is dynamic map service layer
        if([self.layer isKindOfClass:[AGSDynamicMapServiceLayer class]])
        {
            //cast it accordingly. 
            AGSDynamicMapServiceLayer *dynamicMSL = (AGSDynamicMapServiceLayer *)self.layer;
            
            //create a visible layers array
            NSMutableArray *visibileLayersArray = [[NSMutableArray alloc] initWithArray:dynamicMSL.visibleLayers];
            
            //manipulate the visible layers array by deciding the vibility of the current layer. 
            [self decideVisibility:visibileLayersArray];
            
            //assigning the visible layers to the dynamic layer. 
            dynamicMSL.visibleLayers = visibileLayersArray;
            
            //release the allocated array.
        }
    }    
}

//getter for children. 
- (NSMutableArray *)children {
	if (!_children) {
		self.children = [[NSMutableArray alloc] init];
	}
	
	return _children;
}

#pragma mark -
#pragma mark Utility Methods

- (NSUInteger)descendantCount {
	NSUInteger cnt = 0;
	
    //checks if the children and legend of this object needs to be included or not. 
    if (self.inclusive) 
    {
        //recursively calls the descendants for increasing count.
        for (LayerInfo *child in self.children) 
        {
            cnt++;
            if (child.children.count > 0) {
                cnt += [child descendantCount];
            }
			
        }	
	}	
	return cnt;
}

//this method is used by the TOC for combined display of legend and layers. 
- (NSUInteger)descendantAndLegendCount {
	NSUInteger cnt = 0;
    
    //checks if the children and legend of this object needs to be included or not.
    if (self.inclusive) 
    {
        if(self.legendElements)
            cnt += self.legendElements.count;
        
        //recursively calls the descendants for increasing count.
        for (LayerInfo *child in self.children)
        {
			cnt++;
            cnt += [child descendantAndLegendCount];  
        }
	}	
	return cnt;
}

- (BOOL)containsChildWithLayerName:(NSString *)layerName
{
    for (LayerInfo *layerInfo in self.children) {
        if([layerInfo.layerName isEqualToString:layerName])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isRoot {
    return (!self.parent);
}
                       

- (void)addChild:(LayerInfo *)newChild {
	newChild.parent = self;
	[self.children addObject:newChild];
}

- (void)removeChildWithLayerName:(NSString *)layerName {    
    for (LayerInfo *layerInfo in self.children) {
        if([layerInfo.layerName isEqualToString:layerName])
        {
            [self.children removeObject:layerInfo];
            break;
        }
    }    
}

- (void)insertChild:(LayerInfo *)newChild atIndex:(int)index {
    newChild.parent = self;
	[self.children insertObject:newChild atIndex:index];
}

- (NSUInteger)levelDepth {
	if (!self.parent) return 0;
	
    //recursively calls the predecessors to count.
	NSUInteger cnt = 0;
	cnt += 1 + [self.parent levelDepth];
	
	return cnt;
}

- (BOOL)hasChildren {
	return (self.children.count > 0);
}

- (void)flattenElementsWithLegend:(BOOL)withLegend inArray:(NSMutableArray *)flattenedArray {
    
    //if it is inclusive, start adding the children and their descendants. 
    if (self.inclusive) 
    {            
        if (withLegend) {                
            for (LegendElement *legendElement in self.legendElements) {
                [flattenedArray addObject:legendElement];
            }
        }	
        
        for (LayerInfo *child in self.children) {
            [flattenedArray addObject:child];
            [child flattenElementsWithLegend:withLegend inArray:flattenedArray];
        }
    }    
}

- (NSArray *)flattenElementsWithCacheRefresh:(BOOL)invalidate withLegend:(BOOL)withLegend {
	if (!self.flattenedTreeCache || invalidate) {
		//if there was a previous cache and due for invalidate, release resources first
		if (self.flattenedTreeCache) {
			self.flattenedTreeCache = nil;            
		}     
        self.flattenedTreeCache = [NSMutableArray array];
        [self flattenElementsWithLegend:withLegend inArray:self.flattenedTreeCache];
    }
    return self.flattenedTreeCache;
}


#pragma mark -
#pragma mark AGSMapServiceInfoDelegate
-(void)mapServiceInfo:(AGSMapServiceInfo *)mapServiceInfo operationDidRetrieveLegendInfo:(NSOperation *)op{                 
        
    //construct the tree. 
    [self constructTree:mapServiceInfo];
    
    //add the appropriate depth info on the legends. 
    [self addLegendLevels];
}

-(void)mapServiceInfo:(AGSMapServiceInfo *)mapServiceInfo operation:(NSOperation *)op didFailToRetrieveLegendInfoWithError:(NSError *)error{ 
    //construct the tree. 
    [self constructTree:mapServiceInfo];
    
}

#pragma mark -
#pragma mark Helpers

-(NSMutableArray *)legendElementsForFeatureLayer:(AGSFeatureLayer *)fl
{
    NSMutableArray *elementsArray = [NSMutableArray arrayWithCapacity:2];
    
    //for the simple renderer class 
    if ([fl.renderer isKindOfClass:[AGSSimpleRenderer class]]) {
        
        AGSSimpleRenderer *sr = (AGSSimpleRenderer *)fl.renderer;
        UIImage *swatch = [sr.symbol swatchForGeometryType:fl.geometryType size:CGSizeMake(20, 20)];
        LegendElement *le = [LegendElement legendElementWithTitle:fl.serviceLayerName withSwatch:swatch];
        le.level = 1;
        
        [elementsArray addObject:le];
    }
    
    //for the class break renderer. 
    else if([fl.renderer isKindOfClass:[AGSClassBreaksRenderer class]])
    {
        AGSClassBreaksRenderer *cbr = (AGSClassBreaksRenderer *)fl.renderer;
        
        for(AGSClassBreak *cb in cbr.classBreaks)
        {
            UIImage *swatch = [cb.symbol swatchForGeometryType:fl.geometryType size:CGSizeMake(20, 20)];
            LegendElement *le = [LegendElement legendElementWithTitle:cb.label withSwatch:swatch];
            le.level = 1;
            
            [elementsArray addObject:le];
        }
    }
    
    //for the unique value renderer. 
    else if([fl.renderer isKindOfClass:[AGSUniqueValueRenderer class]])
    {
        AGSUniqueValueRenderer *uvr = (AGSUniqueValueRenderer *)fl.renderer;
        for (AGSUniqueValue *uv in uvr.uniqueValues)
        {
            UIImage *swatch = [uv.symbol swatchForGeometryType:fl.geometryType size:CGSizeMake(20, 20)];
            LegendElement *le = [LegendElement legendElementWithTitle:uv.label withSwatch:swatch];
            le.level = 1;
            
            [elementsArray addObject:le];
        }
    }
    
    return elementsArray;
}

- (void)constructTree:(AGSMapServiceInfo *)mapServiceInfo
{
    //for the next layer in the array, start adding the children in a recursive fasion. 
    for (int i = self.layerID + 1 ; i < mapServiceInfo.layerInfos.count; i++ ) {                
        
        AGSMapServiceLayerInfo *msli = [mapServiceInfo.layerInfos objectAtIndex:i]; 
        
        //this is required to find out whether the layer's parent is self so as to add it as a child. 
        if(msli.parentLayerID == self.layerID)
        {
            LayerInfo *childLayerInfo = [[LayerInfo alloc] initWithLayer:self.layer layerID:msli.layerId name:msli.name target:nil];
            [self addChild:childLayerInfo];  
            continue;
        }
        
        //this check is done to avoid iterating through the rest of the layers and significantly reduces the loop time. 
        if(msli.parentLayerID == ([self isRoot] ? -1 : self.parent.layerID))
            break;                
    }    
    
    //check if the layer is dynamic map service layer to set its visible layers property as initially it would be empty. 
    if([self.layer isKindOfClass:[AGSDynamicMapServiceLayer class]] && self.layerID == -1)
    {
        //cast it accordingly. 
        AGSDynamicMapServiceLayer *dynamicMSL = (AGSDynamicMapServiceLayer *)self.layer;
        
        //create a visible layers array
        NSMutableArray *visibileLayersArray = [NSMutableArray array];
        
        //manipulate the visible layers array by deciding the vibility of the current layer. 
        [self visibleLayersWithParentsRemoved:visibileLayersArray];
        
        //assigning the visible layers to the dynamic layer. 
        dynamicMSL.visibleLayers = visibileLayersArray;            
    }              
}

- (void)addLegendLevels
{    
    //recursively add the legend depth to the children. 
    for (LayerInfo *child in self.children) {
        if(child.legendElements)
        {
            for (LegendElement *le in child.legendElements) {
                le.level = child.levelDepth;
            }
        }   
        [child addLegendLevels];            
    }
}

- (BOOL)trulyVisible
{
    //recursively calls the parent's visibility info to calculate the true visibility. 
    if (self.parent.layerID == -1) return _visible;
    return _visible && [self.parent trulyVisible];
}

- (void)decideVisibility:(NSMutableArray *)visibleLayers
{    
    //until the node is a leaf, iterate to find out the true visibility and manipulate the visible layers array.
    if(![self hasChildren])
    {
        //if truly visible, add the layer to the visible layers array. 
        if(self.trulyVisible) {
            [visibleLayers addObject:[NSNumber numberWithInt:self.layerID]];
        }            
        
        //else remove it from the array
        else
        {
            for (int i = 0 ; i < visibleLayers.count ; i ++)
            {
                NSNumber *number = [visibleLayers objectAtIndex:i];
                if(number.intValue == self.layerID) {
                     [visibleLayers removeObjectAtIndex:i];  
                }                                 
            }
        }
        return;
    }
    
    //do the same for all the children. 
    for (LayerInfo *layerInfo in self.children) {
        [layerInfo decideVisibility:visibleLayers];
    }
}

//takes an unfiltered list of layers to show, and removes all parent group layers 
- (void)visibleLayersWithParentsRemoved:(NSMutableArray *)visibleLayers
{
    //until the node is a leaf, iterate to find out the true visibility and manipulate the visible layers array.
    if(![self hasChildren])
    {
        //if truly visible, add the layer to the visible layers array. 
        if(self.trulyVisible) {
            [visibleLayers addObject:[NSNumber numberWithInt:self.layerID]];
        }                
        return;
    }
    
    //do the same for all the children. 
    for (LayerInfo *layerInfo in self.children) {
        [layerInfo decideVisibility:visibleLayers];
    }

}

@end

#pragma mark -
#pragma mark Legend Element Implementation

@implementation LegendElement

@synthesize title = _title;
@synthesize swatch = _swatch;
@synthesize level = _level;

-(id)initWithTitle:(NSString *)aTitle withSwatch:(UIImage *)aSwatch
{
    if(self = [super init])
    {
        self.title = aTitle;
        self.swatch = aSwatch;
    }
    
    return self;
}

+(LegendElement *)legendElementWithTitle:(NSString *)aTitle withSwatch:(UIImage *)aSwatch
{
    LegendElement *le = [[LegendElement alloc] initWithTitle:aTitle withSwatch:aSwatch];
    return le;
}


@end



