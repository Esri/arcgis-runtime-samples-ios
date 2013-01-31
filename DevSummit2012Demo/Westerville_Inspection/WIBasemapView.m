/*
 WIBasemapView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
*/

#import "WIBasemapView.h"

@interface WIBasemapView () 

@property (nonatomic, strong) AGSLocalTiledLayer *localLayer;
@property (nonatomic, strong) AGSPortalItem *portalItem;

- (void)finishBasemapLoaded;

@end

@implementation WIBasemapView

@synthesize portalItem  = _portalItem;
@synthesize localLayer  = _localLayer;
@synthesize delegate    = _delegate;


- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame withPortalItem:nil];
}

- (id)initWithFrame:(CGRect)frame withPortalItem:(AGSPortalItem *)pi
{
    self = [super initWithFrame:frame];
    if(self)
    {
        self.portalItem = pi;
        if(self.portalItem.thumbnail == nil)
        {
            //become the portal item's delegate, and fetch it's thumbnail
            self.portalItem.delegate = self;
            [self.portalItem fetchThumbnail];
        }
        
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame withLocalLayer:(AGSLocalTiledLayer*)localLayer {
    self = [super initWithFrame:frame];
    if(self)
    {
        self.localLayer = localLayer;
        self.backgroundColor = [UIColor whiteColor];
        
        
        //local layer already has a defined thumbnail. Use that.
        self.image = [localLayer thumbnail];
        
        [self performSelector:@selector(finishBasemapLoaded) withObject:nil afterDelay:0.0];
    }
    return self;
}

#pragma mark -
#pragma mark Private
- (void)finishBasemapLoaded
{
    if([self.delegate respondsToSelector:@selector(basemapViewDidLoad:)])
    {
        [self.delegate basemapViewDidLoad:self];
    }
}

#pragma mark -
#pragma mark AGSPortalItemDelegate
- (void)portalItem:(AGSPortalItem*)portalItem operation:(NSOperation*)op didFetchThumbnail:(UIImage*)thumbnail
{
    self.image = thumbnail;
    [self finishBasemapLoaded];
}

-(void)portalItem:(AGSPortalItem*)portalItem operation:(NSOperation*)op didFailToFetchThumbnailWithError:(NSError*)error
{
    if([self.delegate respondsToSelector:@selector(basemapViewDidFailToLoad:)])
    {
        [self.delegate basemapViewDidFailToLoad:self];
    }
}

@end
