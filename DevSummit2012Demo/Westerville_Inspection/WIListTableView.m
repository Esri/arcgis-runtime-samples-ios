/*
 WIListTableView.m
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
#import "WIDefaultListTableViewCell.h"
#import "WIListTitleView.h"
#import "WIListTitleViewCell.h"
#import <QuartzCore/QuartzCore.h>

#define kTitleRowHeight 88.0f

@interface WIListTableView () 
{
@private
    AGSListTableviewType   _type;
}

@property (nonatomic, strong) WIListTitleView  *titleView;
@property (nonatomic, strong) UIImageView       *splashView;

- (WIListTitleViewCell *)defaultTitleCellWithTitle:(NSString *)title;
- (void)listViewTapped:(UITapGestureRecognizer *)tapRecognizer;

@end

@implementation WIListTableView

@synthesize dataSource          = _dataSource;
@synthesize delegate            = _delegate;
@synthesize tableview           = _tableview;
@synthesize titleView           = _titleView;
@synthesize enabled             = _enabled;
@synthesize splashView          = _splashView;


- (id)initWithFrame:(CGRect)frame listViewTableViewType:(AGSListTableviewType)type datasource:(id<WIListTableViewDataSource>)datasource
{
    self = [super initWithFrame:frame];
    if(self)
    {
        _type = type;
        
        self.dataSource = datasource;
                
        CGRect tableViewFrame = self.bounds;
        
        if (_type == AGSListviewTypeStaticTitle) {
            
            CGFloat titleRowHeight = kTitleRowHeight;
            
            NSString *title = nil;
            if([self.dataSource respondsToSelector:@selector(titleString)])
            {
                title = self.dataSource.titleString;
            }
            
            WIListTitleView *titleView = [[WIListTitleView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, titleRowHeight) title:title];
            
            self.titleView = titleView;
            
            [self addSubview:self.titleView];
            
            //update frame of tableview
            tableViewFrame.origin.y = titleRowHeight;
            tableViewFrame.size.height -= titleRowHeight;
        }
        
        UITableView *tableview = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
        tableview.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableview.dataSource = self;
        tableview.delegate = self;
        self.tableview = tableview;
        
        [self addSubview:tableview];
        
        //Tap will only be recognized if user interaction is disabled
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(listViewTapped:)];
        tapRecognizer.numberOfTapsRequired = 1;
        tapRecognizer.delegate = self;
        
        [self addGestureRecognizer:tapRecognizer];
        
        self.enabled = YES;
        
        //add a border
        self.layer.borderWidth = 1.0f;
        self.layer.borderColor = [[UIColor blackColor] CGColor];
    }
    return self;
}

//Custom setter
- (void)setEnabled:(BOOL)enabled
{
    self.tableview.userInteractionEnabled = enabled;
}

//Custom getter
- (BOOL)enabled
{
    return self.tableview.userInteractionEnabled;
}

//Wrapper for tableview
- (void)reloadData
{
    [self.tableview reloadData];
}

- (void)setSplashImage:(UIImage *)splashImage
{
    if(splashImage == nil)
    {
        [self.splashView removeFromSuperview];
        self.splashView = nil;
    }
    
    CGFloat splashHeight = 171.0f;
    
    if(_splashView == nil)
    {
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - splashHeight, 320, splashHeight)];
        self.splashView = iv;
    }
    
    if (self.splashView.superview == nil) {
        [self addSubview:self.splashView];
        
        CGRect tvRect = self.tableview.frame;
        tvRect.size.height -= splashHeight;
        self.tableview.frame = tvRect; 
    }
    
    self.splashView.image = splashImage;
}

#pragma mark -
#pragma mark TableViewDataSource

/*  Not implemented in base... Should be implemented by derived classes if they want bigger tableview cells
- (void)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUInteger numRows = [self.dataSource numberOfRows];
    
    //need to count title as a row... There should only be one section
    if(_type == AGSListviewTypeIncorporatedTitle)
    {
        numRows++;
    }
    
    return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if(_type == AGSListviewTypeIncorporatedTitle)
    {
        if(indexPath.row == 0)
        {
            NSString *title = @"";
            if ([self.dataSource respondsToSelector:@selector(titleString)]) {
                title = self.dataSource.titleString;
            }
            
            WIListTitleViewCell *titleCell = [self defaultTitleCellWithTitle:title];
            cell = titleCell;            
        }
        else {
            cell = [self.dataSource listView:self rowCellForIndex:indexPath.row -1];
        }
        
    }
    else
    {
        cell = [self.dataSource listView:self rowCellForIndex:indexPath.row];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(_type == AGSListviewTypeIncorporatedTitle && indexPath.row == 0)
    {
        return kTitleRowHeight;
    }
    
    return 44.0f;
}

#pragma mark -
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (WIDefaultListTableViewCell *)defaultRowCell
{
    static NSString *defaultCellStringID = @"defaultCellID";
    WIDefaultListTableViewCell *cell = [self.tableview dequeueReusableCellWithIdentifier:defaultCellStringID];
    if(!cell)
    {
        cell = [[WIDefaultListTableViewCell alloc] initWithReuseIdentifier:defaultCellStringID];
    }
    
    return cell;
}

- (WIListTitleViewCell *)defaultTitleCellWithTitle:(NSString *)title
{
    static NSString *defaultCellStringID = @"defaultTitleCellID";
    WIListTitleViewCell *cell = [self.tableview dequeueReusableCellWithIdentifier:defaultCellStringID];
    if(!cell)
    {
        cell = [[WIListTitleViewCell alloc] initWithReuseIdentifier:defaultCellStringID withTitle:title];
    }
    
    return cell;
}

#pragma mark -
#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    //only recognize taps if tableview is disabled
    return !self.tableview.userInteractionEnabled;
}

#pragma mark -
#pragma mark Private Methods
- (void)listViewTapped:(UITapGestureRecognizer *)tapRecognizer
{
    if([self.delegate respondsToSelector:@selector(listTableViewTapped:)])
    {
        [self.delegate listTableViewTapped:self];
    }
}

@end
