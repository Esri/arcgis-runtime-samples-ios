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

#import <UIKit/UIKit.h>
#import "IconDownloader.h"
#import <ArcGIS/ArcGIS.h>

@interface ContentViewControllerBase : UITableViewController <IconDownloaderDelegate, UITableViewDataSource, UITableViewDelegate>


@property (nonatomic, strong) AGSPortal *portal;
@property (nonatomic, strong) NSMutableDictionary *currentIconDownloads;

//This is the array of search responses.
@property (nonatomic, strong) NSMutableArray *searchResponseArray;

@property (nonatomic) BOOL doneLoading;

- (NSInteger) numberOfRowsInSection:(NSInteger)section;
- (id)contentForRowAtIndex:(NSIndexPath *)indexPath;
- (void)loadMoreResults:(NSInteger)section;
- (void)startIconDownload:(id)contentType forIndexPath:(NSIndexPath *)indexPath withSize:(CGSize)size;



@end
