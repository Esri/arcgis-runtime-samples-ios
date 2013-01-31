/*
 WIDirectionsView.h
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

@class WIRoute;
@class AGSDirectionGraphic;
@protocol WIDirectionsViewDelegate;

/*
 List view that shows all of the directions from a route. The user
 can initiate stopping the showing of directions. The user can kick
 off autopan mode for the directions list too.
 */

@interface WIDirectionsView : WIListTableView <WIListTableViewDataSource>

@property (nonatomic, unsafe_unretained) id<WIDirectionsViewDelegate> directionsDelegate;
@property (nonatomic, strong) WIRoute                      *route;
@property (nonatomic, strong) AGSDirectionGraphic           *selectedDirection;

- (id)initWithFrame:(CGRect)frame withRoute:(WIRoute *)route;

@end

@protocol WIDirectionsViewDelegate <NSObject>

@optional

- (void)directionsViewWantsToHideDirections:(WIDirectionsView *)dv;
- (void)directionsViewWantsToStartGPS:(WIDirectionsView *)dv;
- (void)directionsView:(WIDirectionsView *)dv didTapOnRouteOverviewForRoute:(WIRoute *)route;
- (void)directionsView:(WIDirectionsView *)dv didTapOnDirectionGraphic:(AGSDirectionGraphic *)directionGraphic;

@end
