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

@interface LayerLegendCell : UITableViewCell {
    UIImageView *_legendImage;
	UILabel *_legendLabel;
    
    int _level;
}

@property (nonatomic, strong) UIImageView *legendImage;
@property (nonatomic, strong) UILabel *legendLabel;
@property (nonatomic) int level;

- (id)initWithStyle:(UITableViewCellStyle)style 
	reuseIdentifier:(NSString *)reuseIdentifier 
			  level:(NSUInteger)level;

@end