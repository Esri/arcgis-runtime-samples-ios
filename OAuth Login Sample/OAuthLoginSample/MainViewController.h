//
//  MainViewController.h
//  OAuthLoginSample
//
//  Created by Divesh Goyal on 9/3/13.
//
//

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface MainViewController : UIViewController <UIAlertViewDelegate,AGSPortalDelegate>
@property (nonatomic, strong)AGSPortal* portal;
- (IBAction)signIn:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@end
