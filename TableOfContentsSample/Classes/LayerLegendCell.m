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

#import "LayerLegendCell.h"

#define IMG_HEIGHT_WIDTH 25
#define CELL_HEIGHT 44
#define SCREEN_WIDTH 320
#define LEVEL_INDENT 32
#define YOFFSET 12
#define XOFFSET 6

@interface LayerLegendCell (Private)

- (UILabel *)labelWithPrimaryColor:(UIColor *)primaryColor 
						selectedColor:(UIColor *)selectedColor 
							 fontSize:(CGFloat)fontSize 
								 bold:(BOOL)bold;

@end


@implementation LayerLegendCell

@synthesize legendLabel = _legendLabel, legendImage = _legendImage;
@synthesize level = _level;

- (id)initWithStyle:(UITableViewCellStyle)style 
	reuseIdentifier:(NSString *)reuseIdentifier 
			  level:(NSUInteger)level {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		self.level = level;
		
		UIView *content = self.contentView;
		
		self.legendLabel = [self labelWithPrimaryColor:[UIColor blackColor] 
                         selectedColor:[UIColor whiteColor] 
                              fontSize:16.0 bold:YES];
		self.legendLabel.textAlignment = UITextAlignmentLeft;
		[content addSubview:self.legendLabel];
		
		self.legendImage = [[UIImageView alloc] initWithImage:nil];
		[content addSubview:self.legendImage];
    }
    return self;
}


#pragma mark -
#pragma mark Memory Management


#pragma mark -
#pragma mark Other overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
	
    if (!self.editing) {
		
		// get the X pixel spot
        CGFloat boundsX = contentRect.origin.x;
        
		CGRect frame = CGRectMake((boundsX + self.level + 1) * LEVEL_INDENT, 
						   0, 
						   SCREEN_WIDTH - (self.level * LEVEL_INDENT), 
						   CELL_HEIGHT);
		self.legendLabel.frame = frame;
        		
		CGRect imgFrame = CGRectMake(((boundsX + self.level + 1) * LEVEL_INDENT) - (IMG_HEIGHT_WIDTH + XOFFSET), 
							  YOFFSET, 
							  IMG_HEIGHT_WIDTH, 
							  IMG_HEIGHT_WIDTH);
		self.legendImage.frame = imgFrame;
	}
}

#pragma mark -
#pragma mark Private category

- (UILabel *)labelWithPrimaryColor:(UIColor *)primaryColor 
						selectedColor:(UIColor *)selectedColor 
							 fontSize:(CGFloat)fontSize 
								 bold:(BOOL)bold {
    UIFont *font;
    if (bold) {
        font = [UIFont boldSystemFontOfSize:fontSize];
    } else {
        font = [UIFont systemFontOfSize:fontSize];
    }
	
	UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	newLabel.backgroundColor = [UIColor whiteColor];
	newLabel.opaque = YES;
	newLabel.textColor = primaryColor;
	newLabel.highlightedTextColor = selectedColor;
	newLabel.font = font;
	newLabel.numberOfLines = 0;
	
	return newLabel;
}

@end
