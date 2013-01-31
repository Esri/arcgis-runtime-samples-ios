/*
 WIInspectionsView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIInspectionsView.h"
#import "WIDefaultListTableViewCell.h"
#import "WIInspectionsTableViewCell.h"
#import "WIInspections.h"

@interface WIInspectionsView () 

@property (nonatomic, strong) UIButton      *syncButton;

- (void)syncButtonPressed:(id)sender;

@end

@implementation WIInspectionsView

@synthesize inspectionsDelegate = _inspectionsDelegate;
@synthesize inspections         = _inspections;
@synthesize syncButton          = _syncButton;


- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame withInspections:nil];
}

- (id)initWithFrame:(CGRect)frame withInspections:(WIInspections *)inspections
{
    self = [super initWithFrame:frame listViewTableViewType:AGSListviewTypeStaticTitle datasource:inspections];
    if(self)
    {
        self.inspections = inspections;
        self.inspections.delegate = self;
        
        [self setSplashImage:[UIImage imageNamed:@"inspection_splash.png"]];
    
        self.syncButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.syncButton.frame = CGRectMake(165, 600, 80, 80);
        [self.syncButton addTarget:self action:@selector(syncButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:self.syncButton];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (void)reloadData
{
    [super reloadData];
    self.syncButton.enabled = (self.inspections.numUnsyncedInspections > 0);
}

- (WIDefaultListTableViewCell *)defaultRowCell
{
    static NSString *defaultCellStringID = @"inspectionCellID";
    WIInspectionsTableViewCell *cell = [self.tableview dequeueReusableCellWithIdentifier:defaultCellStringID];
    if(!cell)
    {
        cell = [[WIInspectionsTableViewCell alloc] initWithReuseIdentifier:defaultCellStringID];
    }
    
    return cell;
}

#pragma mark -
#pragma mark Button Press

- (void)syncButtonPressed:(id)sender
{
    if (![self.inspectionsDelegate inspectionsViewShouldSyncInspections:self]) {
        return;
    }
         
    //start syncing inspections
    [self.inspections syncUnsyncedFeatures];
    
    if([self.inspectionsDelegate respondsToSelector:@selector(inspectionsView:startedSyncingInspections:)])
    {
        [self.inspectionsDelegate inspectionsView:self startedSyncingInspections:self.inspections];
    }
}

#pragma mark -
#pragma mark AGSInspectionsDelegate
- (void)inspections:(WIInspections *)inspections didSucceedInSyncingInspection:(AGSPopup *)succcessInspection
{
    NSLog(@"Succeeded in syncing an inspection!!");
    [self reloadData];
}

- (void)inspections:(WIInspections *)inspections didFailInSyncingInspection:(AGSPopup *)failedInspection
{
    NSLog(@"Failed syncing a feature Stub. Fill in for more customized behavior");
}

- (void)inspectionsDidFinishInspections:(WIInspections *)inspections
{
    if ([self.inspectionsDelegate respondsToSelector:@selector(inspectionsView:finishedSyncingInspections:)]) {
        [self.inspectionsDelegate inspectionsView:self finishedSyncingInspections:self.inspections];
    }
}

#pragma mark -
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    WIInspection *selectedInspection = [self.inspections inspectionAtIndex:indexPath.row];
    if([self.inspectionsDelegate respondsToSelector:@selector(inspectionsView:didTapOnInspection:)])
    {
        [self.inspectionsDelegate inspectionsView:self didTapOnInspection:selectedInspection];
    }
}
@end
