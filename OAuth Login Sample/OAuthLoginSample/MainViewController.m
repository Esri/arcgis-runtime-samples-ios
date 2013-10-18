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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signIn:(id)sender {
    NSString* portalURL = @"https://www.arcgis.com";
    self.oauthLoginVC = [[AGSOAuthLoginViewController alloc] initWithPortalURL:[NSURL URLWithString:portalURL] clientID:@"pqN3y96tSb1j8ZAY" ];
    
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
            
            //update the portal explorer with the credential provided by the user.
            AGSPortal* portal = [[AGSPortal alloc]initWithURL:[NSURL URLWithString: portalURL] credential:credential];
            
            
            
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
