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
#import <ArcGIS/ArcGIS.h>


@interface DetailsViewController : UITableViewController {
	
	//store info from selected feature
	NSDictionary *_fieldAliases;
	AGSGraphic *__weak _feature;
	NSString *_displayFieldName;
	NSArray *_aliases;
}

@property (nonatomic, strong) NSDictionary *fieldAliases;
@property (nonatomic, copy) NSString *displayFieldName;

@property (nonatomic, weak) AGSGraphic *feature;

@end
