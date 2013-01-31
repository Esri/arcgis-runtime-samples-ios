/*
 WIRouteStopsList.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIRouteStopsView.h"
#import "WIRoute.h"
#import <ArcGIS/ArcGIS.h>
#import "WIDefaultListTableViewCell.h"

@interface WIRouteStopsView ()

@property (nonatomic, strong) UIButton      *routeButton;

- (void)routeButtonPressed:(id)sender;

@end

@implementation WIRouteStopsView

@synthesize stopsDelegate   = _stopsDelegate;
@synthesize route           = _route;
@synthesize routeButton     = _routeButton;


- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame withRoute:nil];
}

- (id)initWithFrame:(CGRect)frame withRoute:(WIRoute *)route
{
    self = [super initWithFrame:frame listViewTableViewType:AGSListviewTypeStaticTitle datasource:self];
    if(self)
    {
        self.route = route;

        self.routeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.routeButton.frame = CGRectMake(20, 590, 100, 100);
        [self.routeButton addTarget:self action:@selector(routeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.routeButton setTitle:@"Route" forState:UIControlStateNormal];
        
        [self addSubview:self.routeButton];
 
        self.backgroundColor = [UIColor whiteColor];
        
        self.routeButton.enabled = [self.route canRoute];
        
        [self setSplashImage:[UIImage imageNamed:@"route_splash.png"]];
        
        //always editing
        self.tableview.editing = YES;
    }
    
    return self;
}

- (void)reloadData
{
    [super reloadData];
    self.routeButton.enabled = [self.route canRoute];
}

#pragma mark -
#pragma mark Buttons
- (void)routeButtonPressed:(id)sender
{
    if([self.stopsDelegate respondsToSelector:@selector(routeStopsView:wantsToRoute:)])
    {
        [self.stopsDelegate routeStopsView:self wantsToRoute:self.route];
    }
}

#pragma mark -
#pragma mark AGSListTableViewDataSource
- (NSUInteger)numberOfRows
{
    return self.route.stops.count;
}

- (WIListTableViewCell *)listView:(WIListTableView *)tv rowCellForIndex:(NSUInteger)index
{
    WIDefaultListTableViewCell *cell = [tv defaultRowCell];
    
    AGSStopGraphic *stopGraphic = (AGSStopGraphic *)[self.route.stops objectAtIndex:index];
    cell.nameLabel.text = stopGraphic.name;
    cell.editing = YES;
    return cell;
}

- (NSString *)titleString
{
    return @"My Stops";
}


#pragma mark -
#pragma mark UITableViewDataSource/Delegate Overrides
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath 
{
    if (fromIndexPath == toIndexPath)
        return;
        
    id itemToMove = [self.route.stops objectAtIndex:fromIndexPath.row];
    [self.route.stops removeObjectAtIndex:fromIndexPath.row];
    
    [self.route.stops insertObject:itemToMove atIndex:toIndexPath.row];
}


-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self.stopsDelegate respondsToSelector:@selector(routeStopsView:willDeleteStop:)])
    {
        [self.stopsDelegate routeStopsView:self willDeleteStop:[self.route.stops objectAtIndex:indexPath.row]];
    }
    
    [self.route.stops removeObjectAtIndex:indexPath.row];
    
    //show delete animation
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                          withRowAnimation:UITableViewRowAnimationFade];
    
    self.routeButton.enabled = [self.route canRoute];
}

@end
