/*
 WIInspections.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIInspections.h"
#import "WIInspection.h"
#import "WISignatureView.h"
#import "WIAttributeUtility.h"
#import "WIDefaultListTableViewCell.h"
#import "WIInspectionsTableViewCell.h"
#import <ArcGIS/ArcGIS.h>

@interface WIInspections ()
{
    NSUInteger _currentInspectionIndex;
}

@property (nonatomic, strong) NSMutableArray    *syncedFeatures;
@property (nonatomic, strong) NSMutableArray    *unsyncedFeatures;
@property (nonatomic, strong) WIInspection     *currentInspectionSyncing;

- (void)syncNextInspection;
- (void)finalizeSynchronization;
- (void)setCurrentSyncIndexAndUpdateForStatus:(BOOL)status;

@end

@implementation WIInspections

@synthesize delegate                    = _delegate;
@synthesize featureLayer                = _featureLayer;
@synthesize syncedFeatures              = _syncedFeatures;
@synthesize unsyncedFeatures            = _unsyncedFeatures;
@synthesize currentInspectionSyncing    = _currentInspectionSyncing;

@synthesize isSyncing                   = _isSyncing;


- (id)initWithFeatureLayer:(AGSFeatureLayer *)featureLayer
{
    self = [super init];
    if(self)
    {
        self.featureLayer = featureLayer;
        self.featureLayer.editingDelegate = self;
        
        self.unsyncedFeatures = [NSMutableArray arrayWithCapacity:3];
        self.syncedFeatures = [NSMutableArray arrayWithCapacity:3];
    }
    
    return self;
}

+ (WIInspections *)inspectionsWithFeatureLayer:(AGSFeatureLayer *)fl
{
    WIInspections *i = [[WIInspections alloc] initWithFeatureLayer:fl];
    return i;
}

- (void)syncUnsyncedFeatures
{
    if (_isSyncing || self.unsyncedFeatures.count == 0 || !self.valid) {
        return;
    }
    
    _currentInspectionIndex = 0;
    
    [self syncNextInspection];
}

//adding an unsynced inspection.  If the inspection is is in the synced array,
//it will be moved to the unsynced array. If its in the unsynced array already,
//nothing will happen
- (void)addInspection:(AGSPopup *)inspection
{
    //if there is no inspection or if it already exists, no op
    if (!inspection || [self.unsyncedFeatures indexOfObject:inspection] != NSNotFound) 
    {
        return;
    }
    
    //it's in the synced array
    if ([self.syncedFeatures indexOfObject:inspection] != NSNotFound) {
        [self.syncedFeatures removeObject:inspection];
    }
    
    //finally, add to unsycned features
    [self.unsyncedFeatures addObject:inspection];
}

- (NSUInteger)numUnsyncedInspections
{
    return self.unsyncedFeatures.count;
}

- (BOOL)valid
{
    return (self.featureLayer != nil);
}

- (WIInspection *)inspectionAtIndex:(NSUInteger)index
{
    WIInspection *inspection = nil;
    
    if (index < (self.syncedFeatures.count + self.unsyncedFeatures.count)) 
    {
        if(index >= self.syncedFeatures.count)
        {
            inspection = [self.unsyncedFeatures objectAtIndex:(index - self.syncedFeatures.count)];
        }
        else {
            inspection = [self.syncedFeatures objectAtIndex:index];
        }
    }
        
    return inspection;
}

#pragma mark -
#pragma mark Custom Setters
- (void)setFeatureLayer:(AGSFeatureLayer *)featureLayer
{
    if (_featureLayer == featureLayer) {
        return;
    }
    
    _featureLayer.editingDelegate = nil;
    
    _featureLayer = featureLayer;
    _featureLayer.editingDelegate = self;
    
    //should we blow awy all inspections too?
}

#pragma mark -
#pragma mark WIListTableViewDataSource
- (NSUInteger)numberOfRows
{    
    return self.syncedFeatures.count + self.unsyncedFeatures.count;
}

- (WIListTableViewCell *)listView:(WIListTableView *)tv rowCellForIndex:(NSUInteger)index
{
    WIInspectionsTableViewCell *cell = (WIInspectionsTableViewCell *)[tv defaultRowCell];

    //were stacking the unsynced inspections on top of the synced inspections 
    BOOL syncedInspection = (index < self.syncedFeatures.count);
    cell.syncedInspection = syncedInspection;
    
    WIInspection *inspection = [self inspectionAtIndex:index];
    cell.date = (syncedInspection) ? inspection.dateSynced : inspection.dateModified;
    
    return cell;
}

- (NSString *)titleString
{
    return @"Inspections";
}

#pragma mark -
#pragma mark Sync Methods
- (void)syncNextInspection
{    
    if (_currentInspectionIndex == self.unsyncedFeatures.count) {
        [self finalizeSynchronization];
    }
    else {
        
        self.currentInspectionSyncing = [self.unsyncedFeatures objectAtIndex:_currentInspectionIndex];
                
        int oid = [self.featureLayer objectIdForFeature:self.currentInspectionSyncing.popup.graphic];
        
        [self.currentInspectionSyncing addAttachments];
        
        if (oid > 0){
            // post updates
            [self.featureLayer updateFeatures:[NSArray arrayWithObject:self.currentInspectionSyncing.popup.graphic]];
        }
        else {
            // add feature
            [self.featureLayer addFeatures:[NSArray arrayWithObject:self.currentInspectionSyncing.popup.graphic]];
        }
    }
}

//Finalize. Make sure everything synced. If it didn't, update inspections array, update status message, etc.
- (void)finalizeSynchronization
{    
    _isSyncing = NO;
    
    if([self.delegate respondsToSelector:@selector(inspectionsDidFinishInspections:)])
    {
        [self.delegate inspectionsDidFinishInspections:self];
    }
}

- (void)setCurrentSyncIndexAndUpdateForStatus:(BOOL)status
{
    //succeeded in syncing!
    if(status)
    {
        
        //remove inspection from unsynced and put in synced array
        [self.unsyncedFeatures removeObject:self.currentInspectionSyncing];
        [self.syncedFeatures addObject:self.currentInspectionSyncing];
        
        self.currentInspectionSyncing.dateSynced = [NSDate date];
        
        //no need to update inspection index since we removed successful inspection
        
        if([self.delegate respondsToSelector:@selector(inspections:didSucceedInSyncingInspection:)])
        {
            [self.delegate inspections:self didSucceedInSyncingInspection:self.currentInspectionSyncing];
        }
    }
    
    //failed!
    else 
    {
        _currentInspectionIndex++;
        
        if ([self.delegate respondsToSelector:@selector(inspections:didFailInSyncingInspection:)]) {
            [self.delegate inspections:self didFailInSyncingInspection:self.currentInspectionSyncing];
        }
    }
}

#pragma mark -
#pragma mark AGSFeatureEditingLayerDelegate

- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFeatureEditsWithResults:(AGSFeatureLayerEditResults *)editResults
{
    BOOL needsToDownloadAttachment = NO;
    
    //the result can be an add, or an update... pick source here
    NSArray *resultsSource = nil;
    if([editResults.addResults count] > 0)
    {
        resultsSource = editResults.addResults;
    }
    //assume an update if it's not an add since this app isn't deleting anything
    else 
    {
        resultsSource = editResults.updateResults;
    }
    
    //pick first result since we are doing synchronizations in sequential order
    AGSEditResult *result = [resultsSource objectAtIndex:0];
    if (result.success) {
        AGSAttachmentManager *am = [self.featureLayer attachmentManagerForFeature:self.currentInspectionSyncing.popup.graphic];
        needsToDownloadAttachment = [am hasLocalEdits];
        if (needsToDownloadAttachment) {
            am.delegate = self;
            [am postLocalEditsToServer];
        }
        //no attachments, increment and continue
        else {
            [self setCurrentSyncIndexAndUpdateForStatus:YES];
        }

    }
    //fail to post
    else
    {
        [self setCurrentSyncIndexAndUpdateForStatus:NO];
    }

    
    //only sync next one if we don't have any attachments to sync
    if (!needsToDownloadAttachment) {
        [self syncNextInspection];
    }    
}

- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation*)op didFailFeatureEditsWithError:(NSError *)error
{
    [self setCurrentSyncIndexAndUpdateForStatus:NO];
    [self syncNextInspection];
}

#pragma mark -
#pragma mark AGSAttachmentManagerDelegate

//Called when we have sucessfully posted an attachment
- (void)attachmentManager:(AGSAttachmentManager *)attachmentManager didPostLocalEditsToServer:(NSArray *)attachmentsPosted {
    
	NSLog(@"Attachments posted successfully...");
    
    [self setCurrentSyncIndexAndUpdateForStatus:YES];
    [self syncNextInspection];
}

@end
