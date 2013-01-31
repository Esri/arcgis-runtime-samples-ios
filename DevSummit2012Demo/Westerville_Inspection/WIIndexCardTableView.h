/*
 WIIndexCardTableView.h
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

@protocol WIIndexCardTableViewDataSource;
@protocol WIIndexCardTableViewDelegate;

@class WIIndexCardTableViewCell;
@class AGSDefaultIndexCardTableViewCell;

/*
 View that mimicks an index card. Contains a table view and custom cells to replicate
 the look and feel.
 */

@interface WIIndexCardTableView : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, unsafe_unretained) id<WIIndexCardTableViewDelegate>     indexCardDelegate;
@property (nonatomic, unsafe_unretained) id<WIIndexCardTableViewDataSource>   indexCardDataSource;

-(id)initWithFrame:(CGRect)frame datasource:(id<WIIndexCardTableViewDataSource>)datasource;

- (void)reloadData;

//gives user a default cell from the tableview. Will dequeue one if appropriate, or return a
//new autoreleased cell.
- (WIIndexCardTableViewCell *)defaultRowCell;

@end

@protocol WIIndexCardTableViewDataSource <NSObject>

@required
- (NSUInteger)numberOfRows;
- (WIIndexCardTableViewCell *)indexCardTableView:(WIIndexCardTableView *)tv rowCellForIndex:(NSUInteger)index;

@end


@protocol WIIndexCardTableViewDelegate <NSObject>

@optional
- (void)indexCardTableView:(WIIndexCardTableView *)tv didSelectRowAtIndex:(NSUInteger)index;

@end
