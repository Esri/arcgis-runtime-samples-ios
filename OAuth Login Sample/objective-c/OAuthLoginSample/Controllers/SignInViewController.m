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

#define kPortalUrl @"https://www.arcgis.com"
#define kClientID @"pqN3y96tSb1j8ZAY"

@interface SignInViewController () <AGSPortalDelegate>

@property (nonatomic, weak) IBOutlet UIButton *signInButton;

@property (nonatomic, strong) AGSOAuthLoginViewController *oauthLoginVC;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) AGSPortal *portal;

@end

@implementation SignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSURLConnection ags_trustedHosts] addObject:@"www.arcgis.com"];
    
    //Check to see if we previously saved the user's credentails in the keychain
    //and if so, use it to sign in to the portal
    AGSCredential *credential = [((AppDelegate*)[[UIApplication sharedApplication] delegate]) fetchCredentialFromKeychain];
    if (credential) {
        //Connect to the portal
        self.portal = [[AGSPortal alloc] initWithURL:[[NSURL alloc] initWithString:kPortalUrl] credential:credential];
        self.portal.delegate = self;
    }
}

-(void)viewWillAppear:(BOOL)animated {
    AGSCredential* credential = [(AppDelegate*)[UIApplication sharedApplication].delegate fetchCredentialFromKeychain];
    if (credential) {
        
        [self.signInButton setTitle:@"Signing in..." forState:UIControlStateNormal];
        self.signInButton.enabled = NO;
    }
    else {
        [self.signInButton setTitle:@"Sign In" forState:UIControlStateNormal];
        self.signInButton.enabled = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signIn:(id)sender {
    self.oauthLoginVC = [[AGSOAuthLoginViewController alloc] initWithPortalURL:[NSURL URLWithString:kPortalUrl] clientID:kClientID];
    //request a permanent refresh token so user doesn't have to login in
    self.oauthLoginVC.refreshTokenExpirationInterval = -1;
    
    UINavigationController* nvc = [[UINavigationController alloc]initWithRootViewController:self.oauthLoginVC];
    self.oauthLoginVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelLogin)];
    
    [self presentViewController:nvc animated:YES completion:nil];
    
    __weak SignInViewController *safeSelf = self;
    self.oauthLoginVC.completion = ^(AGSCredential *credential, NSError *error){
        if(error){
            if(error.code == NSUserCancelledError){ //if user cancelled login
                
                [safeSelf cancelLogin];
                
            }else if (error.code == NSURLErrorServerCertificateUntrusted){ //if self-signed certificate error
                
                //keep a reference to the error so that the uialertview deleate can accesss it
                safeSelf.error = error;
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Error" message:[[error localizedDescription] stringByAppendingString:[error localizedRecoverySuggestion]] delegate:safeSelf cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
                [av show];
                
            } else { //all other errors
                
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }
        else{
            //Connect to the portal using the credential provided by the user.
            safeSelf.portal = [[AGSPortal alloc]initWithURL:[NSURL URLWithString: kPortalUrl] credential:credential];
            safeSelf.portal.delegate = safeSelf;
            
            //disable cancel button on the navigation bar
            safeSelf.oauthLoginVC.navigationItem.rightBarButtonItem.enabled = NO;
        }
    };
}

- (void) cancelLogin{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //This alert view is asking the user if he/she wants to trust the self signed certificate
    if(buttonIndex==0){ //No, don't trust
        [self cancelLogin];
    }else { //Yes, trust
        NSURL* url = [self.error userInfo][NSURLErrorFailingURLErrorKey];
        //add to trusted hosts
        [[NSURLConnection ags_trustedHosts]addObject:[url host]];
        //make a test connection to force UIWebView to accept the host
        AGSJSONRequestOperation* rop = [[AGSJSONRequestOperation alloc]initWithURL:url];
        [[AGSRequestOperation sharedOperationQueue] addOperation:rop];
        //Reload the OAuth vc
        [self.oauthLoginVC reload];
    }
    
}

#pragma mark - AGSPortalDelegate methods

- (void)portalDidLoad:(AGSPortal *)portal {
    
    //Now that we were able to connect to the portal using the credential,
    //store the credential securely in the keychain so that we can use it later
    //when the app is restarted.
    [(AppDelegate*)[UIApplication sharedApplication].delegate saveCredentialToKeychain:portal.credential];
    
    //If we presented any other view controller, dismiss it
    if(self.presentedViewController)
        [self dismissViewControllerAnimated:YES completion:nil];
    
    //show the profile view controller
    [self performSegueWithIdentifier:@"SegueProfileVC" sender:self];
}

- (void)portal:(AGSPortal *)portal didFailToLoadWithError:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Could not connect to portal"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
    NSLog(@"%@",[error localizedDescription]);
    if([[error localizedDescription] containsString:@"expired"]){
        //The oAuth refresh token probably expired, user needs to sign in again.
        //This will probably never happen in this sample because we set the refreshTokenExpirationInterval to -1 (never expires)
        [self.signInButton setTitle:@"Sign In" forState:UIControlStateNormal];
        self.signInButton.enabled = YES;
    }
}

#pragma mark: - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SegueProfileVC"]) {
        ProfileViewController *controller = (ProfileViewController*)segue.destinationViewController;
        controller.portal = self.portal;
    }
}

@end
