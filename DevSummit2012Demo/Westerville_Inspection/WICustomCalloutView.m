/*
 WICustomCalloutView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WICustomCalloutView.h"

@interface WICustomCalloutView () 

- (void)addStopButtonPressed:(id)sender;
- (void)moreInfoButtonPressed:(id)sender;

@end

@implementation WICustomCalloutView

@synthesize delegate            = _delegate;

@synthesize addStopButton       = _addStopButton;
@synthesize moreInfoButton      = _moreInfoButton;
@synthesize showMoreInfoButton  = _showMoreInfoButton;

@synthesize graphic             = _graphic;


- (id)initWithFrame:(CGRect)frame withGraphic:(AGSGraphic *)graphic
{    
    self = [super initWithFrame:frame];
    if(self)
    {
        self.graphic = graphic;
    }
    
    return self;
}

- (UIButton *)addStopButton
{
    if(_addStopButton == nil)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *stopImage = [UIImage imageNamed:@"stop48.png"];
        [button setImage:stopImage forState:UIControlStateNormal];
        [button addTarget:self action:@selector(addStopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.addStopButton = button;
    }
    
    return _addStopButton;
}

- (UIButton *)moreInfoButton
{
    if(_moreInfoButton == nil)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];        
        [button setImage:[UIImage imageNamed:@"info48.png"] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(moreInfoButtonPressed:) forControlEvents:UIControlEventTouchUpInside]; 
        
        self.moreInfoButton = button;
    }
    
    return _moreInfoButton;
}

- (void)setShowMoreInfoButton:(BOOL)showMoreInfoButton
{
    self.moreInfoButton.hidden = !showMoreInfoButton;
}

- (void)addStopButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(calloutView:wantsToAddStopForGraphic:)]) {
        [self.delegate calloutView:self wantsToAddStopForGraphic:self.graphic];
    }
}

- (void)moreInfoButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(calloutView:wantsMoreInfoForGraphic:)]) {
        [self.delegate calloutView:self wantsMoreInfoForGraphic:self.graphic];
    }
}

@end
