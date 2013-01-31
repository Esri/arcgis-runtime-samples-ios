/*
 WICustomCalloutView.h
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
#import <ArcGIS/ArcGIS.h>

@protocol WICustomCalloutDelegate;

/*
 Base class for creating a custom callout.  Includes basic functionality. Not meant
 to be instantiated directly
 */

@interface WICustomCalloutView : UIView

@property (nonatomic, unsafe_unretained) id<WICustomCalloutDelegate>   delegate;
@property (nonatomic, strong) AGSGraphic                    *graphic;
@property (nonatomic, strong) UIButton                      *addStopButton;
@property (nonatomic, strong) UIButton                      *moreInfoButton;
@property (nonatomic, assign) BOOL                          showMoreInfoButton;

- (id)initWithFrame:(CGRect)frame withGraphic:(AGSGraphic *)graphic;

@end

@protocol WICustomCalloutDelegate <NSObject>

- (void)calloutView:(WICustomCalloutView *)cv wantsToAddStopForGraphic:(AGSGraphic *)graphic;
- (void)calloutView:(WICustomCalloutView *)cv wantsMoreInfoForGraphic:(AGSGraphic *)graphic;

@end
