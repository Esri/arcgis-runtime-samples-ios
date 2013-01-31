/*
 WIPinnedView.h
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
    AGSPinnedViewTypeNone = 0,      //default
    AGSPinnedViewTypePushPin,       //pin type is a read push pin
    AGSPinnedViewTypeThumbtack,     //pin type is a thumbtack
    AGSPinnedViewTypeTape           //pin type is a piece of tape
} AGSPinnedViewType;

/*
 Container view. Input view can be made to look like its pinned, tacked, or taped to the superview
 */

@interface WIPinnedView : UIView

/* View being pinned */
@property (nonatomic,strong) UIView             *contentView;

/* User can define the left and right pin types */
@property (nonatomic, assign) AGSPinnedViewType leftPinType;
@property (nonatomic, assign) AGSPinnedViewType rightPinType;

/* User can offset the left pin by some offset for a custom look */
@property (nonatomic, assign) CGFloat           leftPinXOffset;
@property (nonatomic, assign) CGFloat           leftPinYOffset;

/* User can offset the right pin by some offset for a custom look */
@property (nonatomic, assign) CGFloat           rightPinXOffset;
@property (nonatomic, assign) CGFloat           rightPinYOffset;

/*Have the content view render using a shadow. */
@property (nonatomic, assign) BOOL              useShadow;


- (id)initWithContentView:(UIView *)cv leftPinType:(AGSPinnedViewType)leftPin rightPinType:(AGSPinnedViewType)rightPinType;

@end
