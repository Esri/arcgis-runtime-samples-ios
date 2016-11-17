/*
 Copyright 2015 Esri
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "SignInViewController.h"
#import <ArcGIS/ArcGIS.h>
#import "AppDelegate.h"
#import "ProfileViewController.h"

@interface SignInViewController ()

@property (nonatomic, weak) IBOutlet UIButton *signInButton;

@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) AGSPortal *portal;

@end

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // try to sign in first time view is loaded
    [self signIn:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signIn:(id)sender {
    
    [self.signInButton setTitle:@"Signing in..." forState:UIControlStateNormal];
    self.signInButton.enabled = NO;
    
    // Loading the portal will trigger an authentication challenge and if the credentials
    // are in the keychain they will automatically be used.
    //
    // Note - we need to use `retryLoadWithCompletion` so that it will retry loading
    // if it previously failed to load.
    
    __weak __typeof(self) weakSelf = self;
    
    NSURL *portalURL = ((AppDelegate*)[UIApplication sharedApplication].delegate).portalURL;
    
    self.portal = [AGSPortal portalWithURL:portalURL loginRequired:YES];
    [self.portal retryLoadWithCompletion:^(NSError * _Nullable error) {
        
        if (error){
            // error loading portal - display error
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not connect to portal"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            
            [alert show];
        }
        else{
            // loaded portal successfully - show the profile view controller
            [weakSelf performSegueWithIdentifier:@"SegueProfileVC" sender:self];
        }
        
        // reset button state whether or not there was an error
        [weakSelf.signInButton setTitle:@"Sign In" forState:UIControlStateNormal];
        weakSelf.signInButton.enabled = YES;
    }];
}


#pragma mark: - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SegueProfileVC"]) {
        ProfileViewController *controller = (ProfileViewController*)segue.destinationViewController;
        controller.portal = self.portal;
    }
}

@end
