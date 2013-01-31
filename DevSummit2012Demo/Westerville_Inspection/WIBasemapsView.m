/*
 WIBasemapsView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIBasemapsView.h"
#import "WIBasemaps.h"
#import "WIPinnedView.h"
#import "WITapeLabelView.h"
#import "WIBasemapView.h"

//so it fits nicely on screen...
#define kMaxNumberOfOnlineBasemaps 6

#define kLocalLayerViewTagOffset    1000

@interface WIBasemapsView () 
{
    NSUInteger  _numOfBasemapsLeftToDownload;
}

@property (nonatomic, strong) WIBasemaps        *basemaps;
@property (nonatomic, strong) WITapeLabelView   *onlineBasemapsImageView;
@property (nonatomic, strong) WITapeLabelView   *localBasemapsImageView;
@property (nonatomic, strong) UIImageView       *selectedBasemapCheckView;
@property (nonatomic, strong) NSMutableArray    *basemapViews;

- (void)showSelectedCheckmarkAtOrigin:(CGPoint)origin;
- (void)basemapLoaded;
- (void)layoutBasemaps;
- (void)basemapViewTapped:(UITapGestureRecognizer *)tapRecognizer;

@end

@implementation WIBasemapsView

@synthesize basemaps    = _basemaps;
@synthesize delegate    = _delegate;

@synthesize onlineBasemapsImageView = _onlineBasemapsImageView;
@synthesize localBasemapsImageView  = _localBasemapsImageView;
@synthesize basemapViews            = _basemapViews;
@synthesize selectedBasemapCheckView = _selectedBasemapCheckView;


- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame withBasemaps:nil];
}

- (id)initWithFrame:(CGRect)frame withBasemaps:(WIBasemaps *)basemaps
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.basemaps = basemaps;
        
        WITapeLabelView *tapeView = [[WITapeLabelView alloc] initWithOrigin:CGPointMake(250, -13) withName:@"Online Basemaps"];
        self.onlineBasemapsImageView = tapeView;
        
        [self addSubview:self.onlineBasemapsImageView];
        
        WITapeLabelView *tapeView2 = [[WITapeLabelView alloc] initWithOrigin:CGPointMake(250, 385) withName:@"Local Basemaps"];
        self.localBasemapsImageView = tapeView2;
        
        [self addSubview:self.localBasemapsImageView];
        
        [self layoutBasemaps];
    }
    
    return self;
}

//Creates a number of basemap views for each basemap and lays them out in a grid.
- (void)layoutBasemaps
{
    NSUInteger numberOfBasemapsPerRow = 3;
    CGFloat xMargin = 20.0;
    CGFloat yMargin = self.onlineBasemapsImageView.frame.origin.y + self.onlineBasemapsImageView.frame.size.height + xMargin;
    CGFloat widthOfBasemap = (self.frame.size.width - (xMargin *(numberOfBasemapsPerRow + 1)))/numberOfBasemapsPerRow; 
    CGFloat heightOfBasemap = 130.0f;
        
    NSUInteger numBasemaps = self.basemaps.onlineBasemaps.count;
    numBasemaps = (numBasemaps > kMaxNumberOfOnlineBasemaps) ? kMaxNumberOfOnlineBasemaps : numBasemaps;
    _numOfBasemapsLeftToDownload = numBasemaps;
    
    for(int i = 0; i < numBasemaps; i++)
    {
        int row = i/numberOfBasemapsPerRow;
        int column = i%numberOfBasemapsPerRow;
        
        CGFloat xOrigin = (column * widthOfBasemap) +             //account for map icons
        ((column + 1) * xMargin);     //account for margins
        
        
        CGFloat yOrigin = (row * heightOfBasemap) +             //account for map icons
        yMargin   +
        (row * xMargin);       //account for margins
        
        WIBasemapView *v = [[WIBasemapView alloc] initWithFrame:CGRectMake(xOrigin, yOrigin, widthOfBasemap, heightOfBasemap)  
                                                   withPortalItem:[self.basemaps.onlineBasemaps objectAtIndex:i]];
        v.delegate = self;
        
        WIPinnedView *pv = [[WIPinnedView alloc] initWithContentView:v 
                                                     leftPinType:AGSPinnedViewTypePushPin 
                                                    rightPinType:AGSPinnedViewTypeNone];
        
        pv.leftPinXOffset = 75.0f;
        pv.leftPinYOffset = -13.0f;
        pv.tag = i;
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(basemapViewTapped:)];
        [pv addGestureRecognizer:tapRecognizer];
        
        
        [self addSubview:pv];
        
        
        //put a checkmark on topographic
        AGSPortalItem *basemap = [self.basemaps.onlineBasemaps objectAtIndex:i];
        if ([basemap.title isEqualToString:@"Topographic"]) {
            [self showSelectedCheckmarkAtOrigin:CGPointMake(pv.frame.size.width  + pv.frame.origin.x - 40, pv.frame.size.height + pv.frame.origin.y - 40)];
        }
        
    }
    
    NSUInteger numLocalLayers = self.basemaps.localBasemaps.count;
    for (int i = 0; i < numLocalLayers; i++) {
        int row = i/numberOfBasemapsPerRow;
        int column = i%numberOfBasemapsPerRow;
        
        CGFloat xOrigin = (column * widthOfBasemap) +             //account for map icons
        ((column + 1) * xMargin);     //account for margins
        
        CGFloat yOrigin = 400 + (row * heightOfBasemap) +             //account for map icons
        yMargin   +
        (row * xMargin);       //account for margins
        
        WIBasemapView *v = [[WIBasemapView alloc] initWithFrame:CGRectMake(xOrigin, yOrigin, widthOfBasemap, heightOfBasemap)  
                                                   withLocalLayer:[self.basemaps.localBasemaps objectAtIndex:i]];
        
        WIPinnedView *pv = [[WIPinnedView alloc] initWithContentView:v 
                                                     leftPinType:AGSPinnedViewTypePushPin
                                                    rightPinType:AGSPinnedViewTypeNone];
        
        pv.leftPinXOffset = 75.0f;
        pv.leftPinYOffset = -13.0f;
        pv.tag = kLocalLayerViewTagOffset + i;
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(localLayerViewTapped:)];
        [pv addGestureRecognizer:tapRecognizer];
        
        
        [self addSubview:pv];
    }
}

#pragma mark -
#pragma mark Selected Basemap Stuff
- (UIImageView *)selectedBasemapCheckView
{
    if(_selectedBasemapCheckView == nil)
    {
        UIImageView *iv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"green_check.png"]];
        iv.frame = CGRectMake(0, 0, 55, 48);
        self.selectedBasemapCheckView = iv;
    }
    
    return _selectedBasemapCheckView;
}

//Show checkmark imageview at a defined origin
- (void)showSelectedCheckmarkAtOrigin:(CGPoint)origin
{
    CGRect checkFrame = self.selectedBasemapCheckView.frame;
    checkFrame.origin = origin;
    self.selectedBasemapCheckView.frame = checkFrame;
    
    if(self.selectedBasemapCheckView.superview == nil)
    {
        [self addSubview:self.selectedBasemapCheckView];
    }
    
    [self bringSubviewToFront:self.selectedBasemapCheckView];
}

#pragma mark Basemap Interaction
- (void)localLayerViewTapped:(UITapGestureRecognizer *)tapRecognizer 
{
    WIPinnedView *pv = (WIPinnedView*)tapRecognizer.view;
    
    [self showSelectedCheckmarkAtOrigin:CGPointMake(pv.frame.size.width  + pv.frame.origin.x - 40, pv.frame.size.height + pv.frame.origin.y - 40)];
    
    AGSLocalTiledLayer *selectedLocalLayer = [self.basemaps.localBasemaps objectAtIndex:pv.tag - kLocalLayerViewTagOffset];
    
    if ([self.delegate respondsToSelector:@selector(basemapView:wantsToChangeToLocalTiledLayer:)]) 
    {
        [self.delegate basemapView:self wantsToChangeToLocalTiledLayer:selectedLocalLayer];
    }
}

- (void)basemapViewTapped:(UITapGestureRecognizer *)tapRecognizer
{
    WIPinnedView *pv = (WIPinnedView *)tapRecognizer.view;
    
    [self showSelectedCheckmarkAtOrigin:CGPointMake(pv.frame.size.width  + pv.frame.origin.x - 40, pv.frame.size.height + pv.frame.origin.y - 40)];
    
    AGSPortalItem *selectedBasemap = [self.basemaps.onlineBasemaps objectAtIndex:pv.tag];
    
    if([self.delegate respondsToSelector:@selector(basemapView:wantsToChangeToBasemap:)])
    {
        [self.delegate basemapView:self wantsToChangeToBasemap:selectedBasemap];
    }
}

#pragma mark -
#pragma mark AGSBasemapViewDelegate
- (void)basemapViewDidLoad:(WIBasemapView *)basemapView
{
    [self basemapLoaded];
}

- (void)basemapViewDidFailToLoad:(WIBasemapView *)basemapView
{
    [self basemapLoaded];
}


//Keep track of when basemaps are loaded. Once all are loaded, tell delegate view is good to show
- (void)basemapLoaded
{
    _numOfBasemapsLeftToDownload--;
    
    if((_numOfBasemapsLeftToDownload == 0) && [self.delegate respondsToSelector:@selector(basemapsViewDidLoad:)])
    {
        [self.delegate basemapsViewDidLoad:self];
    }
}

@end
