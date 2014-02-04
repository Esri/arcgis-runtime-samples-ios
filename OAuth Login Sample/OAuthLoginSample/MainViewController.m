// Copyright 2013 ESRI
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
#import "MainViewController.h"
#import "UserContentViewController.h"

#define kPortalUrl @"https://www.arcgis.com"
#define kClientID @"pqN3y96tSb1j8ZAY"

@interface MainViewController ()
@property (nonatomic,strong) AGSOAuthLoginViewController* oauthLoginVC;
@property (nonatomic,strong) NSError* error;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"oAuth Sample";
    [[NSURLConnection ags_trustedHosts]addObject:@"www.arcgis.com"];
    
    //Check to see if we previously saved the user's credentails in the keychain
    //and if so, use it to sign in to the portal
    AGSKeychainItemWrapper* wrapper = [[AGSKeychainItemWrapper alloc]initWithIdentifier:@"com.esri.OAuthLoginSample" accessGroup:nil];
    AGSCredential* credential = (AGSCredential*)[wrapper keychainObject];
    if (credential) {
        NSLog(@"Found credential in keychain. Logging into portal");
        
        //Connect to the portal
        AGSPortal* portal = [[AGSPortal alloc]initWithURL:[NSURL URLWithString: kPortalUrl] credential:credential];
        
        //Display the user's items
        UserContentViewController* uvc = [[UserContentViewController alloc]initWithPortal:portal];
        [self.navigationController setViewControllers:@[uvc] animated:YES];

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signIn:(id)sender {
    self.oauthLoginVC = [[AGSOAuthLoginViewController alloc] initWithPortalURL:[NSURL URLWithString:kPortalUrl] clientID:kClientID];
    //request a permanent refresh token so user doesn't have to login in
    self.oauthLoginVC.refreshTokenExpirationInterval = -1;
    
    UINavigationController* nvc = [[UINavigationController alloc]initWithRootViewController:self.oauthLoginVC];
    nvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.oauthLoginVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelLogin)];
    
    [self presentViewController:nvc animated:YES completion:nil];
    
    __weak MainViewController *safeSelf = self;
    self.oauthLoginVC.completion = ^(AGSCredential *credential, NSError *error){
        if(error){
            
            if(error.code == NSUserCancelledError){
                [safeSelf cancelLogin];
            }else if (error.code == NSURLErrorServerCertificateUntrusted){
                //keep a reference to the error so that the uialertview deleate can accesss it
                safeSelf.error = error;
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Error" message:[[error localizedDescription] stringByAppendingString:[error localizedRecoverySuggestion]] delegate:safeSelf cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
                [av show];
            }
            else{
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }else{
            
            //Store the credential securely in the keychain so that we can use it later
            //when the app is restarted.
            AGSKeychainItemWrapper* wrapper = [[AGSKeychainItemWrapper alloc]initWithIdentifier:@"com.esri.OAuthLoginSample" accessGroup:nil];
            [wrapper setKeychainObject:credential];

            //Connect to the portal using the credential provided by the user.
            AGSPortal* portal = [[AGSPortal alloc]initWithURL:[NSURL URLWithString: kPortalUrl] credential:credential];
            
            //Display the user's  items
            [safeSelf dismissViewControllerAnimated:NO completion:^(){
                UserContentViewController* uvc = [[UserContentViewController alloc]initWithPortal:portal];
                [safeSelf.navigationController setViewControllers:@[uvc] animated:YES];
            }];
            
            
        }
        
    };
}

- (void) cancelLogin{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex==0){
        [self cancelLogin];
    }else{
        NSURL* url = [self.error userInfo][NSURLErrorFailingURLErrorKey];
        //add to trusted hosts
        [[NSURLConnection ags_trustedHosts]addObject:[url host]];
        //make a test connection to force UIWebView to accept the host
        AGSJSONRequestOperation* rop = [[AGSJSONRequestOperation alloc]initWithURL:url];
        [[AGSRequestOperation sharedOperationQueue] addOperation:rop];
        [self.oauthLoginVC reload];
    }
    
}

@end
