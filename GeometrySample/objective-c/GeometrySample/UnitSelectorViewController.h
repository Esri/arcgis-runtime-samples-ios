//
//  UnitSelectorViewController.h
//  GeometrySample
//
//  Created by Sam Cunningham on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@protocol UnitSelectorViewDelegate;

@interface UnitSelectorViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id<UnitSelectorViewDelegate> delegate;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *distanceUnits;
@property (nonatomic, strong) NSArray *areaUnits;
@property (nonatomic, assign) BOOL useAreaUnits;

@end

// A protocol to update the delegate on what unit was selected
@protocol UnitSelectorViewDelegate <NSObject>
@required
// A method update the distance unit
- (void)didSelectDistanceUnit:(AGSSRUnit)unit;

// A method to update the area units
-(void)didSelectAreaUnit:(AGSAreaUnits)unit;

@end