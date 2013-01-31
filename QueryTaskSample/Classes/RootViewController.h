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

#import <ArcGIS/ArcGIS.h>


@class DetailsViewController;

//constants for title, search bar placeholder text and data layer
#define kViewTitle @"US Counties Info"
#define kSearchBarPlaceholder @"Find Counties (e.g. Los Angeles)"
#define kMapServiceLayerURL @"http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Demographics/ESRI_Census_USA/MapServer/3"

//Search bar and query task delegates to get at the query and result behavior
@interface RootViewController : UITableViewController <UISearchBarDelegate, AGSQueryTaskDelegate> {
	
	//search bar to get user input
	//search string setnt via query task
	//the query itself
	//results are put in to a feature set
	//results displayed in another view
	
	UISearchBar *_searchBar;
	
	AGSQueryTask *_queryTask;
	AGSQuery *_query;
	AGSFeatureSet *_featureSet;
	DetailsViewController *_detailsViewController;
}

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;

@end
