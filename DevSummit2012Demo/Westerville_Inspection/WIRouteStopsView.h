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

#import <UIKit/UIKit.h>
#import "WIListTableView.h"

@class AGSStopGraphic;
@class WIRoute;
@protocol WIRouteStopsViewDelegate; 

/*
 List view that shows all of the stops the user has entered. The user can initiate
 a route request from this page as well
 */

@interface WIRouteStopsView : WIListTableView <WIListTableViewDataSource>

@property (nonatomic, unsafe_unretained) id<WIRouteStopsViewDelegate> stopsDelegate;
@property (nonatomic, strong) WIRoute                      *route;

- (id)initWithFrame:(CGRect)frame withRoute:(WIRoute *)route;

@end

@protocol WIRouteStopsViewDelegate <NSObject>

- (void)routeStopsView:(WIRouteStopsView *)rsv wantsToRoute:(WIRoute *)route;

@optional

- (void)routeStopsView:(WIRouteStopsView *)rsv willDeleteStop:(AGSStopGraphic *)stop;

@end
