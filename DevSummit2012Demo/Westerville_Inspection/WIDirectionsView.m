/*
 WIDirectionsView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <ArcGIS/ArcGIS.h>
#import "WIDirectionsView.h"
#import "WIDefaultListTableViewCell.h"
#import "WIRoute.h"
#import "WIListRowView.h"
#import "WIDirectionsTableViewCell.h"

#define kOverviewDirectionString @"See Directions Overview"

@interface WIDirectionsView () 

@property (nonatomic, strong) UIButton                      *doneRoutingButton;
@property (nonatomic, strong) UIButton                      *startGPSButton;
@property (nonatomic, strong) WIDefaultListTableViewCell   *sizingCell;

- (void)doneButtonPressed:(id)sender;
- (void)startGPSButtonPressed:(id)sender;

- (BOOL)selectedDirectionIsOverview;

@end

@implementation WIDirectionsView

@synthesize directionsDelegate  = _directionsDelegate;
@synthesize route               = _route;
@synthesize doneRoutingButton   = _doneRoutingButton;
@synthesize startGPSButton      = _startGPSButton;
@synthesize selectedDirection   = _selectedDirection;
@synthesize sizingCell          = _sizingCell;

- (void)dealloc
{
    self.route              = nil;
    self.selectedDirection  = nil;
    
}

- (id)initWithFrame:(CGRect)frame withRoute:(WIRoute *)route
{
    self = [super initWithFrame:frame listViewTableViewType:AGSListviewTypeStaticTitle datasource:self];
    if(self)
    {
        self.route = route;
        
        self.backgroundColor = [UIColor whiteColor];
        
        self.doneRoutingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.doneRoutingButton.frame = CGRectMake(210, frame.size.height - 100, 85, 85);
        [self.doneRoutingButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.startGPSButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.startGPSButton.frame = CGRectMake(10, frame.size.height - 100, 85, 85);
        [self.startGPSButton addTarget:self action:@selector(startGPSButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
        [self setSplashImage:[UIImage imageNamed:@"stop_splash.png"]];
        
        [self addSubview:self.doneRoutingButton];
        [self addSubview:self.startGPSButton];
    }
    
    return self;
}

#pragma mark -
#pragma mark  Private
- (BOOL)selectedDirectionIsOverview
{
    return (self.selectedDirection == nil);
}

#pragma mark -
#pragma mark Custom Setters
//Custom Setter.. Make sure to reload if direction set changes
- (void)setRoute:(WIRoute *)route
{
    if (_route == route) {
        return;
    }
    
    _route = route;
    
    [self reloadData];
}

- (void)setSelectedDirection:(AGSDirectionGraphic *)selectedDirection
{
    if(_selectedDirection == selectedDirection)
    {
        return;
    }
    
    _selectedDirection = selectedDirection;
    
    [self reloadData];
}

#pragma mark -
#pragma mark Overrides
- (WIDefaultListTableViewCell *)defaultRowCell
{
    static NSString *defaultCellStringID = @"directionsCellId";
    WIDirectionsTableViewCell *cell = [self.tableview dequeueReusableCellWithIdentifier:defaultCellStringID];
    if(!cell)
    {
        cell = [[WIDirectionsTableViewCell alloc] initWithReuseIdentifier:defaultCellStringID];
    }
    
    return cell;
}

#pragma Lazy Loads
- (WIDefaultListTableViewCell *)sizingCell
{
    if(_sizingCell == nil)
    {
        WIDefaultListTableViewCell *cell = [[WIDefaultListTableViewCell alloc] initWithReuseIdentifier:@"Esri"];
        self.sizingCell = cell;
    }
    
    return _sizingCell;
}

#pragma mark - 
#pragma mark Button Interaction
- (void)doneButtonPressed:(id)sender
{
    if([self.directionsDelegate respondsToSelector:@selector(directionsViewWantsToHideDirections:)])
    {
        [self.directionsDelegate directionsViewWantsToHideDirections:self];
    }
}

- (void)startGPSButtonPressed:(id)sender
{
    if ([self.directionsDelegate respondsToSelector:@selector(directionsViewWantsToStartGPS:)]) {
        [self.directionsDelegate directionsViewWantsToStartGPS:self];
    }
    
}

#pragma mark -
#pragma AGSListTableViewDatasource
- (NSUInteger)numberOfRows
{
    //Adding a row to show an "Overview" direction
    return self.route.directions.graphics.count + 1; 
}

- (WIListTableViewCell *)listView:(WIListTableView *)tv rowCellForIndex:(NSUInteger)index
{
    WIDirectionsTableViewCell *cell = (WIDirectionsTableViewCell *)[tv defaultRowCell];

    NSString *text = nil;
    
     //Adding an "Overview" direction
     if(index == 0)
     {
         text = kOverviewDirectionString;
         cell.isSelectedDirection = [self selectedDirectionIsOverview];
     }
     else if(index <= self.route.directions.graphics.count)
     {
         AGSDirectionGraphic *dirGraphic = (AGSDirectionGraphic *)[self.route.directions.graphics objectAtIndex:index-1];  //account for overview
         text = dirGraphic.text;
         cell.isSelectedDirection = (dirGraphic == self.selectedDirection);
     }
    
    cell.nameLabel.text = text;
    
    //Configure height of cell
    CGRect cellFrame = cell.frame;
    CGRect nameFrame = cell.nameLabel.frame;
    
    CGSize constrainedSize = CGSizeMake(self.sizingCell.nameLabel.bounds.size.width, 10000);
    
    CGSize newSize = [text sizeWithFont:self.sizingCell.nameLabel.font 
                                     constrainedToSize:constrainedSize 
                                         lineBreakMode:UILineBreakModeCharacterWrap];
    
    CGFloat newHeight = newSize.height + cell.topMargin + cell.bottomMargin;
    
    cellFrame.size.height = (newHeight < 44.0f) ? 44.0f : newHeight;
    
    nameFrame.size.height = newSize.height;
    
    cell.frame = cellFrame;
    cell.nameLabel.frame = nameFrame; 
     
    return cell;
}

- (NSString *)titleString
{
    return @"Directions";
}

#pragma mark -
#pragma mark UITableViewDelegate/Datasource Overrides
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *text = nil;
    if(indexPath.row == 0)
    {
        text = kOverviewDirectionString;
    }
    else if(indexPath.row <= self.route.directions.graphics.count)
    {
        AGSDirectionGraphic *dirGraphic = (AGSDirectionGraphic *)[self.route.directions.graphics objectAtIndex:indexPath.row-1];  //account for overview
        text = dirGraphic.text;
    }
    
    //Resizing the cell to fit the entire direction text
    CGSize constrainedSize = CGSizeMake(self.sizingCell.nameLabel.bounds.size.width, 10000);
    
    CGSize newSize = [text sizeWithFont:self.sizingCell.nameLabel.font 
                      constrainedToSize:constrainedSize 
                          lineBreakMode:UILineBreakModeCharacterWrap];
    
    CGFloat newHeight = newSize.height + self.sizingCell.topMargin + self.sizingCell.bottomMargin;
    
    return (newHeight < 44.0f) ? 44.0f : newHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) 
    {
        if([self.directionsDelegate respondsToSelector:@selector(directionsView:didTapOnRouteOverviewForRoute:)])
        {
            [self.directionsDelegate directionsView:self didTapOnRouteOverviewForRoute:self.route];
        }
    }
    else if(indexPath.row <= self.route.directions.graphics.count)
    {
        if([self.directionsDelegate respondsToSelector:@selector(directionsView:didTapOnDirectionGraphic:)])
        {
            [self.directionsDelegate directionsView:self didTapOnDirectionGraphic:[self.route.directions.graphics objectAtIndex:indexPath.row-1]];
        }
    }
    
    //else do nothing
}

@end
