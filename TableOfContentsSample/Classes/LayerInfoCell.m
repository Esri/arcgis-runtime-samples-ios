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

#import "LayerInfoCell.h"

#define IMG_HEIGHT_WIDTH 20
#define CHECKBOX_HEIGHT_WIDTH 25
#define CELL_HEIGHT 44
#define SCREEN_WIDTH 320
#define LEVEL_INDENT 32
#define YOFFSET 12
#define XOFFSET 6

@interface LayerInfoCell (Private)

- (UILabel *)labelWithPrimaryColor:(UIColor *)primaryColor 
						selectedColor:(UIColor *)selectedColor 
							 fontSize:(CGFloat)fontSize 
								 bold:(BOOL)bold;
- (IBAction)checkBoxClicked;

@end

@interface CheckBox : UIButton {
	BOOL _isChecked;
}

@property (nonatomic,readonly) BOOL isChecked;

- (id)initWithState:(BOOL)state;
- (void)changeCheckBox;

@end

@implementation LayerInfoCell

@synthesize valueLabel = _valueLabel, visibilitySwitch = _visibilitySwitch, arrowImage = _arrowImage;
@synthesize level = _level, expanded = _expanded, canChangeVisibility = _canChangeVisibility, layerInfoCellDelegate = _layerInfoCellDelegate;

- (id)initWithStyle:(UITableViewCellStyle)style 
	reuseIdentifier:(NSString *)reuseIdentifier 
			  level:(NSUInteger)level 
canChangeVisibility:(BOOL)canChangeVisibility
         visibility:(BOOL)visibility
		   expanded:(BOOL)expanded;  {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
		self.level = level;       
        self.canChangeVisibility = canChangeVisibility;
		self.expanded = expanded;
		
		UIView *content = self.contentView;
		
		self.valueLabel = 
        [self labelWithPrimaryColor:[UIColor blackColor] 
                         selectedColor:[UIColor whiteColor] 
                              fontSize:16.0 bold:YES];
		self.valueLabel.textAlignment = UITextAlignmentLeft;
		[content addSubview:self.valueLabel];
        
        if(_canChangeVisibility)
        {
            self.visibilitySwitch = [[CheckBox alloc] initWithState:visibility];
            [self.visibilitySwitch setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [self.visibilitySwitch setTitle:@"" forState:UIControlStateNormal];   
            [self.visibilitySwitch addTarget:self action:@selector(visibilityChanged) forControlEvents:UIControlEventTouchUpInside];
            [content addSubview:self.visibilitySwitch];
        }             
    
		self.arrowImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:self.expanded ? @"CircleArrowDown_sml" : @"CircleArrowRight_sml"]];
		[content addSubview:self.arrowImage];
    }
    return self;
}


#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	self.layerInfoCellDelegate = nil;
}

#pragma mark -
#pragma mark Other overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect contentRect = self.contentView.bounds;
	
    if (!self.editing) {
		
		// get the X pixel spot
        CGFloat boundsX = contentRect.origin.x;
		CGRect frame;
        
        CGRect imgFrame = CGRectMake(((boundsX + self.level + 1) * LEVEL_INDENT) - (IMG_HEIGHT_WIDTH + XOFFSET), 
							  YOFFSET, 
							  IMG_HEIGHT_WIDTH, 
							  IMG_HEIGHT_WIDTH);
		self.arrowImage.frame = imgFrame;
        
        if(self.canChangeVisibility)
        {           
            CGRect checkBoxFrame = CGRectMake(((boundsX + self.level + 1) * LEVEL_INDENT), 
                                       (CELL_HEIGHT - CHECKBOX_HEIGHT_WIDTH)/2, 
                                       CHECKBOX_HEIGHT_WIDTH,
                                       CHECKBOX_HEIGHT_WIDTH);
            self.visibilitySwitch.frame = checkBoxFrame;
            
            frame = CGRectMake((boundsX + self.level + 1) * LEVEL_INDENT + 30, 
                               0, 
                               SCREEN_WIDTH - (self.level * LEVEL_INDENT), 
                               CELL_HEIGHT);
            self.valueLabel.frame = frame;           
            
        }
		
		else
        {
            frame = CGRectMake((boundsX + self.level + 1) * LEVEL_INDENT, 
                               0, 
                               SCREEN_WIDTH - (self.level * LEVEL_INDENT), 
                               CELL_HEIGHT);
            self.valueLabel.frame = frame;
        }
		
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

- (IBAction)visibilityChanged {       
    [self.visibilitySwitch changeCheckBox];
    [self.layerInfoCellDelegate layerVisibilityChanged:self.visibilitySwitch.isChecked forCell:self];
}

@end



@implementation CheckBox

@synthesize isChecked = _isChecked;

- (id)initWithState:(BOOL)state {
    if (self = [super init]) {
        // Initialization code
		
		//self.frame =frame;
		self.contentHorizontalAlignment  = UIControlContentHorizontalAlignmentLeft;       

        if(state) {
            [self setImage:[UIImage imageNamed:@"checkbox_checked.png"] forState:UIControlStateNormal];	    
        }
        else {
            [self setImage:[UIImage imageNamed:@"checkbox_unchecked.png"] forState:UIControlStateNormal];	
        }
        _isChecked = state;			
	}
    return self;
}

- (void)changeCheckBox {
    _isChecked = !_isChecked;
    
    if(_isChecked) {		
		[self setImage:[UIImage imageNamed:@"checkbox_checked.png"] forState:UIControlStateNormal];			
	} else {
		[self setImage:[UIImage imageNamed:@"checkbox_unchecked.png"] forState:UIControlStateNormal];        
	}       
}





@end
