/*
 COPYRIGHT 2013 ESRI

 TRADE SECRETS: ESRI PROPRIETARY AND CONFIDENTIAL
 Unpublished material - all rights reserved under the
 Copyright Laws of the United States and applicable international
 laws, treaties, and conventions.

 For additional information, contact:
 Environmental Systems Research Institute, Inc.
 Attn: Contracts and Legal Services Department
 380 New York Street
 Redlands, California, 92373
 USA

 email: contracts@esri.com
 */

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

/** @file OfflineTestViewController.h */ //Required for Globals API doc

/** @brief
 
 @define{OfflineTestViewController.h, ArcGIS}
 @since 
 */
@interface OfflineTestViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *mapContainer;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIView *leftContainer;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addFeatureButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteGDBButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *syncButton;
@property (strong, nonatomic) IBOutlet UILabel *offlineStatusLabel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *goOfflineButton;


- (IBAction)deleteGDBAction:(id)sender;
- (IBAction)addFeatureAction:(id)sender;
- (IBAction)syncAction:(id)sender;
- (IBAction)goOfflineAction:(id)sender;

- (id)initWithFSURL:(NSURL*)url TPKURL:(NSURL*)tpkurl;
@end
