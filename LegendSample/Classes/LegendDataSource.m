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

#import "LegendDataSource.h"

@interface LegendDataSource (Private)


- (NSMutableArray*) processLayerTreeStartingAt:(AGSMapContentsLayerInfo*)layerNode;


@end

@implementation LegendDataSource

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (id)initWithLayerTree:(AGSMapContentsTree*)tree{
    self = [super init];
    if (self) {
        self.layerTree = tree;
    }
    return self;
}



#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	self.tableView = tableView;
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    self.legendInfos = [self processLayerTreeStartingAt:self.layerTree.root];
    
	//Number of legend items we have
	return [self.legendInfos count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	
	// Set up the cell with the legend image, text, and detail
	LegendInfo *legendInfo = [self.legendInfos objectAtIndex:indexPath.row];
	cell.detailTextLabel.text = legendInfo.detail;
	cell.textLabel.font = [UIFont systemFontOfSize:12.0];
	cell.textLabel.text = legendInfo.name;
	cell.imageView.image = legendInfo.image;
	
    return cell;
}

- (NSMutableArray*) processLayerTreeStartingAt:(AGSMapContentsLayerInfo*)layerNode{
    NSMutableArray* legendInfos = [[NSMutableArray alloc]init];
    if(layerNode.legendItems && layerNode.legendItems.count){
        for (AGSMapContentsLegendElement* legendElement in layerNode.legendItems) {
            LegendInfo* li = [[LegendInfo alloc]init];
            li.name = layerNode.layerName;
            li.detail = legendElement.title;
            li.image = legendElement.swatch;
            [legendInfos addObject:li];
        }
    }
    
    for (AGSMapContentsLayerInfo* subLayerNode in layerNode.subLayers) {
        [legendInfos addObjectsFromArray:[self processLayerTreeStartingAt:subLayerNode]];
    }
    return legendInfos;
    
}

@end

//A convenience class to hold information about each legend item
@implementation LegendInfo


@end