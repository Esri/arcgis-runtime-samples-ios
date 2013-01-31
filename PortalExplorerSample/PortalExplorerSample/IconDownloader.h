
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

@protocol IconDownloaderDelegate;

@interface IconDownloader : NSObject

@property (nonatomic, weak) id <IconDownloaderDelegate> delegate;

+ (IconDownloader *)iconDownloaderWithContentType:(id)contentType indexPath:(NSIndexPath *)indexPath iconSize:(CGSize)iconSize;

- (void)startIconDownload;
- (void)cancelDownload;

@end

@protocol IconDownloaderDelegate <NSObject>

@optional
- (void)iconDownloader:(IconDownloader *)iconDownloader didDownloadIcon:(UIImage *)icon ofContentType:(id)contentType atIndexPath:(NSIndexPath *)indexPath;
- (void)iconDownloader:(IconDownloader *)iconDownloader didFailToDownloadIconAtIndexPath:(NSIndexPath *)indexPath error:(NSError *)error;

@end