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

#import <Foundation/Foundation.h>
#import "LayerInfo.h"
#import <ArcGIS/ArcGIS.h>


@interface LayerInfo : NSObject {
    
    //this view could contain can any layer type - 
    //Openstreet Map, Bing Map, Tiled Service, Dynamic Service, Feature Layer
    AGSLayer *__weak _layer;
    
    //stores the layer ID for the corresponding layer in the service
	int _layerID;	
    
    //name of the layer. 
    NSString * _layerName;
    
    //stores all the legend info, if any, after retrieving it. 
    NSMutableArray *_legendElements;
    
    //parent of this layerinfo node
	LayerInfo *__weak _parent;
    
    //array containing all the children
	NSMutableArray *_children;
    
    //this indicates whether this layer is visible in the tree or not
	BOOL _visible;
    
    //this indicates whether the visibility of this layer
    //can be changed or not.
	BOOL _canChangeVisibility;
    
    //decides whether the children of this layer info node
    //will be included in the display or not. 
    BOOL _inclusive;
    
    //an array storing the tree nodes in a flattened array.   
	NSMutableArray *_flattenedTreeCache;
}

@property (nonatomic) int layerID;
@property (nonatomic, weak) AGSLayer *layer;
@property (nonatomic, strong) NSString *layerName;
@property (nonatomic, weak) LayerInfo *parent;
@property (nonatomic, strong) NSMutableArray *children;
@property (nonatomic, strong) NSMutableArray *legendElements;
@property (nonatomic, strong) NSMutableArray *flattenedTreeCache;
@property (nonatomic) BOOL visible;
@property (nonatomic) BOOL canChangeVisibility;
@property (nonatomic) BOOL inclusive;

//this method is called to instantiate the first object with layer id of -1 
//and the original layer view, its name and the target. all subsequent calls will be 
//made with the corresponding sublayer ids and names but with the same layer view. 
- (id)initWithLayer:(AGSLayer*)layer
            layerID:(NSInteger)layerID 
                name:(NSString*)name 
             target:(id)target;

//used to add a child to any layer info node. 
- (void)addChild:(LayerInfo *)newChild;

//used to insert a child to any layer info node at a particular index. Mainly useful at the root level
//to show the order of map layers. 
- (void)insertChild:(LayerInfo *)newChild atIndex:(int)index;

//used to remove a child with a specified name. 
- (void)removeChildWithLayerName:(NSString *)layerName;

//gives back the number of nodes which emerge from the calling node. 
//Includes the sub nodes too. 
- (NSUInteger)descendantCount;

//gives back the flat number of descendants which emerge from 
//the calling layer info along with each of the descendant's legent elements, if exists. 
- (NSUInteger)descendantAndLegendCount;

//checks whether the node contains any immediate child with the specified layer name. 
- (BOOL)containsChildWithLayerName:(NSString *)layerName;

//verifies whether the caller is the root node - map layer level. 
- (BOOL)isRoot;

//gives the depth of a node
- (NSUInteger)levelDepth;

//finds out whether the layer has any sub layers. 
- (BOOL)hasChildren;

//Can be called explicitly to do the same action but decides 
//whether the already existing cache needs to be invalidated ot not. 
- (NSArray *)flattenElementsWithCacheRefresh:(BOOL)invalidate withLegend:(BOOL)withLegend;


@end

/*
 Model object for representing one element in a legend.
 In the hierarchical tree representing the legend, a LegendElement
 is a leaf component and does not contain additional nodes.
 The Title and Swatch are both optional. 
 */
@interface LegendElement : NSObject
{
    NSString *_title;
    UIImage  *_swatch;
    
    NSUInteger _level;
}

/*label associated with legend element */
@property (nonatomic, strong) NSString *title;

/*an image associated with legend element. May be nil if
 only a title is appropriate */
@property (nonatomic, strong) UIImage *swatch;

/*The level at which the legend should be shown in hierarchy.
 Between 0 -> ... */
@property (nonatomic, readwrite) NSUInteger level;

-(id)initWithTitle:(NSString *)aTitle withSwatch:(UIImage *)aSwatch;
+(LegendElement *)legendElementWithTitle:(NSString *)aTitle withSwatch:(UIImage *)aSwatch;

@end

