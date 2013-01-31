/*
 WIFeatureView.h
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

@class AGSPopup;
@protocol WIFeatureViewDelegate;

/*
 Custom popup for a feature. Accepts an AGSPopup and displays it in a todo
 list-like tableview. A feature view can initiate an inspection if that
 feature is part of the inspections feature layer
 */

@interface WIFeatureView : WIListTableView <WIListTableViewDataSource>

@property (nonatomic, unsafe_unretained) id<WIFeatureViewDelegate> featureDelegate;

- (id)initWithFrame:(CGRect)frame withPopup:(AGSPopup *)popup;
- (void)inspectButtonPressed:(id)sender;

@end

@protocol WIFeatureViewDelegate <NSObject>

- (void)featuresView:(WIFeatureView *)fv wantsToInspectFeature:(AGSPopup *)feature;

@end
