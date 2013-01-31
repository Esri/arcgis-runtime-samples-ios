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

#import "LoadingTableViewCell.h"

@interface LoadingTableViewCell()

@property (nonatomic, strong) IBOutlet UIView *content;

@end


@implementation LoadingTableViewCell

@synthesize loadingLabel = _loadingLabel;
@synthesize content = _content;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {            
        [[NSBundle mainBundle] loadNibNamed:@"LoadingTableViewCell"
                                          owner:self
                                        options:nil];
        [self addSubview:self.content];        
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {    
    [super setSelected:selected animated:animated];    
    // Configure the view for the selected state.
}




@end
