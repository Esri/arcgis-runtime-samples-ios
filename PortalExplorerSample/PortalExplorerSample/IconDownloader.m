
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
#import "IconDownloader.h"
#import <ArcGIS/ArcGIS.h>


#define kAppIconHeight 128

@interface IconDownloader () <AGSPortalItemDelegate, AGSPortalGroupDelegate>

@property (nonatomic, strong) NSOperation *icOp;
@property (nonatomic, assign) CGSize iconSize;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) id contentType;

@end

@implementation IconDownloader

@synthesize delegate = _delegate;
@synthesize icOp = _icOp;
@synthesize contentType = _contentType;
@synthesize indexPath = _indexPath;
@synthesize iconSize = _iconSize;

#pragma mark - 

//returns an autorelease instance of the class. 
+ (IconDownloader *)iconDownloaderWithContentType:(id)contentType indexPath:(NSIndexPath *)indexPath iconSize:(CGSize)iconSize
{    
    IconDownloader *iconDownloader = [[IconDownloader alloc] init];    
    iconDownloader.contentType = contentType;
    iconDownloader.indexPath = indexPath;
	iconDownloader.iconSize = iconSize;	
	return iconDownloader;    
}

- (void)dealloc
{
    self.delegate = nil;    
    [self.icOp cancel];
    
}


#pragma mark - AGSPortalItemDelegate

-(void)portalItem:(AGSPortalItem*)portalItem operation:(NSOperation*)op didFetchThumbnail:(UIImage*)thumbnail
{
    // call our delegate and tell it that our icon is ready for display
    if ([self.delegate respondsToSelector:@selector(iconDownloader:didDownloadIcon:ofContentType:atIndexPath:)]) 
    {
        [self.delegate iconDownloader:self didDownloadIcon:thumbnail ofContentType:self.contentType atIndexPath:self.indexPath];
    }
    
    // nil out to release data
    self.icOp = nil;
}

-(void)portalItem:(AGSPortalItem*)portalItem operation:(NSOperation*)op didFailToFetchThumbnailWithError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(iconDownloader:didFailToDownloadIconAtIndexPath:error:)]) 
    {
        [self.delegate iconDownloader:self didFailToDownloadIconAtIndexPath:self.indexPath error:error];
    }
    // nil out to release data
    self.icOp = nil;
}

#pragma mark - AGSPortalGroupDelegate

-(void)portalGroup:(AGSPortalGroup*)portalGroup operation:(NSOperation*)op didFetchThumbnail:(UIImage*)thumbnail
{
    // call our delegate and tell it that our icon is ready for display
    if ([self.delegate respondsToSelector:@selector(iconDownloader:didDownloadIcon:ofContentType:atIndexPath:)]) 
    {
        [self.delegate iconDownloader:self didDownloadIcon:thumbnail ofContentType:self.contentType atIndexPath:self.indexPath];
    }
    
    // nil out to release data
    self.icOp = nil;
}

-(void)portalGroup:(AGSPortalGroup*)portalGroup operation:(NSOperation*)op didFailToFetchThumbnailWithError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(iconDownloader:didFailToDownloadIconAtIndexPath:error:)]) 
    {
        [self.delegate iconDownloader:self didFailToDownloadIconAtIndexPath:self.indexPath error:error];
    }
    // nil out to release data
    self.icOp = nil;
}


#pragma mark - Helper


- (void)startIconDownload
{
    //for the item
    if([self.contentType isKindOfClass:[AGSPortalItem class]])
    {
        AGSPortalItem *portalItem = (AGSPortalItem *)self.contentType;
        portalItem.delegate = self;
        self.icOp = [portalItem fetchThumbnail];
    }
    
    //for the group
    else if ([self.contentType isKindOfClass:[AGSPortalGroup class]])
    {
        AGSPortalGroup *group = (AGSPortalGroup *)self.contentType;
        group.delegate = self;
        self.icOp = [group fetchThumbnail];
    }
}

- (void)cancelDownload
{
    self.delegate = nil;    
    [self.icOp cancel];
    self.icOp = nil;
}

@end

