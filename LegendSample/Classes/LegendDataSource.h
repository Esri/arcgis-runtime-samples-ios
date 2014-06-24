// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//


#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

@interface LegendDataSource : NSObject <UITableViewDataSource>

@property (nonatomic,strong) AGSMapContentsTree* layerTree;
@property (nonatomic, strong) UITableView* tableView;
@property (nonatomic, strong) NSMutableArray* legendInfos;


- (id) initWithLayerTree:(AGSMapContentsTree*)layerTree;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView ;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section ;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath ;

@end

@interface LegendInfo : NSObject

@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *detail;
@property (readwrite,strong) UIImage *image;

@end