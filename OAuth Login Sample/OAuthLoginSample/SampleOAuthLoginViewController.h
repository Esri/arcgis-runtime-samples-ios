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

@class AGSCredential;
@protocol SampleOAuthLoginDelegate;

@interface SampleOAuthLoginViewController : UINavigationController

@property (nonatomic, weak) id<SampleOAuthLoginDelegate> loginDelegate;

- (id)initWithURL:(NSURL*)url appID:(NSString*)appID;
- (void)renewCredential;

@end


@protocol SampleOAuthLoginDelegate <NSObject>
@optional

- (void)loginViewController:(SampleOAuthLoginViewController*)loginVC didLoginWithCredential:(AGSCredential*)credential;
- (void)loginViewController:(SampleOAuthLoginViewController*)loginVC didRenewCredential:(AGSCredential*)credential;
- (void)loginViewController:(SampleOAuthLoginViewController*)loginVC didFailToRenewCredentialWithError:(NSError*)error;

- (void)loginViewController:(SampleOAuthLoginViewController*)loginVC didFailToLoginWithCredential:(AGSCredential*)credential;
- (void)loginViewControllerWasCancelled:(SampleOAuthLoginViewController*)loginVC;


@end