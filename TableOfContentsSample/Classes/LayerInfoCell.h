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

@class CheckBox;
@protocol LayerInfoCellDelegate;

@interface LayerInfoCell : UITableViewCell {
	UILabel *_valueLabel;
    CheckBox *_visibilitySwitch;
	UIImageView *_arrowImage;
	
	int _level;
    BOOL _canChangeVisibility;
	BOOL _expanded;
    
    id <LayerInfoCellDelegate> __weak _layerInfoCellDelegate;
}

@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) CheckBox *visibilitySwitch;
@property (nonatomic, strong) UIImageView *arrowImage;
@property (nonatomic) int level;
@property (nonatomic) BOOL expanded;
@property (nonatomic) BOOL canChangeVisibility;
@property (nonatomic, weak) id <LayerInfoCellDelegate> layerInfoCellDelegate;

- (id)initWithStyle:(UITableViewCellStyle)style 
	reuseIdentifier:(NSString *)reuseIdentifier 
			  level:(NSUInteger)level 
canChangeVisibility:(BOOL)canChangeVisibility
         visibility:(BOOL)visibility
		   expanded:(BOOL)expanded;

@end

@protocol LayerInfoCellDelegate <NSObject>

- (void)layerVisibilityChanged:(BOOL)visibility forCell:(UITableViewCell *)cell;

@end


