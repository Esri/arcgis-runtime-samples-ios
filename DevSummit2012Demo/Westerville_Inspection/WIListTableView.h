/*
 WIListTableView.h
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

typedef enum
{
    AGSListviewTypeStaticTitle = 0,      //title is separate from tableview and doesn't scroll
    AGSListviewTypeIncorporatedTitle = 1 //title is part of tableview and scrolls
    
} AGSListTableviewType;

@protocol WIListTableViewDataSource;
@protocol WIListTableViewDelegate; 
@class WIListTableViewCell;
@class WIDefaultListTableViewCell;

/*
 A skinned tableview that will resemble a 'todo' list. Instead of subclassing, the WIListTableView
 contains a tableview, and only exposes some of the necessary methods we typically need for a tableiview (like reloadData).
 */

@interface WIListTableView : UIView <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITableView                       *tableview;
@property (nonatomic, assign) BOOL                              enabled;
@property (nonatomic, unsafe_unretained) id<WIListTableViewDelegate>      delegate;
@property (nonatomic, unsafe_unretained) id<WIListTableViewDataSource>    dataSource;     

- (id)initWithFrame:(CGRect)frame listViewTableViewType:(AGSListTableviewType)type datasource:(id<WIListTableViewDataSource>)datasource;

- (void)reloadData;

- (void)setSplashImage:(UIImage *)splashImage;

//gives user a default cell from the tableview. Will dequeue one if appropriate, or return a
//new autoreleased cell.
- (WIDefaultListTableViewCell *)defaultRowCell;

@end

//Wrapper for UITableViewDataSource
@protocol WIListTableViewDataSource <NSObject>

- (NSUInteger)numberOfRows;
- (WIListTableViewCell *)listView:(WIListTableView *)tv rowCellForIndex:(NSUInteger)index;

@optional

- (NSString *)titleString;

@end

//Wrapper for UITableViewDelegate
@protocol WIListTableViewDelegate <NSObject>

@optional
- (void)listTableViewTapped:(WIListTableView *)ltv;

@end
