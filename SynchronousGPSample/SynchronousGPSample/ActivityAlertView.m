// Copyright 2011 ESRI
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

#import "ActivityAlertView.h"

@implementation ActivityAlertView

@synthesize activityView = _activityView;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
	{
        self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 50, 30, 30)];
		[self addSubview:self.activityView];
		self.activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
		[self.activityView startAnimating];
    }
	
    return self;
}

- (void) close
{
	[self dismissWithClickedButtonIndex:0 animated:YES];
}


@end
