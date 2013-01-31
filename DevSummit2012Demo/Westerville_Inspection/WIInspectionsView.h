/*
 WIInspectionsView.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */


#import "WIListTableView.h"
#import "WIInspections.h"

@class WIInspection;
@class WIInspections;
@protocol WIInspectionsViewDelegate; 

/*
 List of inspections that have been synced, and/or need syncing. The user can initiate
 that unsynced features can be synced from this page or even edit previously created
 inspections
 */

@interface WIInspectionsView : WIListTableView <WIInspectionsDelegate>

@property (nonatomic, strong) WIInspections *inspections;

@property (nonatomic, unsafe_unretained) id<WIInspectionsViewDelegate>    inspectionsDelegate;

- (id)initWithFrame:(CGRect)frame withInspections:(WIInspections *)inspections;

@end

@protocol WIInspectionsViewDelegate <NSObject>

@required

- (BOOL)inspectionsViewShouldSyncInspections:(WIInspectionsView *)iv;

@optional
- (void)inspectionsView:(WIInspectionsView *)iv didTapOnInspection:(WIInspection *)inspection;
- (void)inspectionsView:(WIInspectionsView *)iv startedSyncingInspections:(WIInspections *)inspections;
- (void)inspectionsView:(WIInspectionsView *)iv finishedSyncingInspections:(WIInspections *)inspections;

@end
