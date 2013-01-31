/*
 WIIndexCardTableView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIIndexCardTableView.h"
#import "WIIndexCardTableViewCell.h"
#import "WIIndexCardRowView.h"

@interface WIIndexCardTableView () 

@property (nonatomic, strong) UITableView   *tableview;

@end

@implementation WIIndexCardTableView

@synthesize indexCardDataSource = _indexCardDataSource;
@synthesize indexCardDelegate   = _indexCardDelegate;

@synthesize tableview           = _tableview;


- (id)initWithFrame:(CGRect)frame datasource:(id<WIIndexCardTableViewDataSource>)datasource
{
    self = [super initWithFrame:frame];
    if(self)
    {        
        self.indexCardDataSource = datasource;
                
        CGRect tableViewFrame = self.bounds;
            
        CGFloat titleRowHeight = 60.0f;
                
        WIIndexCardRowView *titleView = [[WIIndexCardRowView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, titleRowHeight) isTitleRow:YES];        
        [self addSubview:titleView];
        
        //update frame of tableview
        tableViewFrame.origin.y = titleRowHeight;
        tableViewFrame.size.height -= titleRowHeight;
        
        UITableView *tableview = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
        tableview.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableview.dataSource = self;
        tableview.delegate = self;
        self.tableview = tableview;
        
        [self addSubview:tableview];
    }
    return self;
}

#pragma mark -
#pragma mark Public methods
- (void)reloadData
{
    [self.tableview reloadData];
}

#pragma mark -
#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.indexCardDataSource.numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WIIndexCardTableViewCell *cell = nil;
    cell = [self.indexCardDataSource indexCardTableView:self rowCellForIndex:indexPath.row];
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if([self.indexCardDelegate respondsToSelector:@selector(indexCardTableView:didSelectRowAtIndex:)])
    {
        [self.indexCardDelegate indexCardTableView:self didSelectRowAtIndex:indexPath.row];
    }
}

- (WIIndexCardTableViewCell *)defaultRowCell
{
    static NSString *defaultCellStringID = @"defaultCellID";
    WIIndexCardTableViewCell *cell = [self.tableview dequeueReusableCellWithIdentifier:defaultCellStringID];
    if(!cell)
    {
        cell = [[WIIndexCardTableViewCell alloc] initWithReuseIdentifier:defaultCellStringID isTitle:NO];
    }
    
    return cell;
}
@end
