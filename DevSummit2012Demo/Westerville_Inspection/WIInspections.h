/*
 WIInspections.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>
#import "WIListTableView.h"

@class AGSFeatureLayer;
@class WIInspection;
@protocol WIInspectionsDelegate;

/* 
 Object representing the group of un-synced inspections for a given feature layer 
 */
@interface WIInspections : NSObject <WIListTableViewDataSource, AGSFeatureLayerEditingDelegate, AGSAttachmentManagerDelegate>

@property (nonatomic, strong) AGSFeatureLayer               *featureLayer;
@property (nonatomic, assign) BOOL                          isSyncing;
@property (nonatomic, unsafe_unretained) id<WIInspectionsDelegate>    delegate;

/* Create our 'empty' inspections object with a feature layer */
- (id)initWithFeatureLayer:(AGSFeatureLayer *)featureLayer;

/* Sync our unsynced inspections */
- (void)syncUnsyncedFeatures;

/* Adds an inspection to be synced */
- (void)addInspection:(WIInspection *)inspection; 

/* Returns the number of inspections waiting to be synced */
- (NSUInteger)numUnsyncedInspections;

/* Tells us if we have a feature layer we can sync with */
- (BOOL)valid;

/* Access a specific inspection */
- (WIInspection *)inspectionAtIndex:(NSUInteger)index;

/* Create an autoreleased inspection */
+ (WIInspections *)inspectionsWithFeatureLayer:(AGSFeatureLayer *)fl;

@end

/* Delegate to be notified when a sync has succeeded/failed */
@protocol WIInspectionsDelegate <NSObject>

@optional

- (void)inspections:(WIInspections *)inspections didSucceedInSyncingInspection:(WIInspection *)succcessInspection;
- (void)inspections:(WIInspections *)inspections didFailInSyncingInspection:(WIInspection *)failedInspection;
- (void)inspectionsDidFinishInspections:(WIInspections *)inspections;

@end
