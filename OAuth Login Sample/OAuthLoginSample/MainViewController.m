//
//  MainViewController.m
//  OAuthLoginSample
//
//  Created by Divesh Goyal on 9/3/13.
//
//

#import "MainViewController.h"
#import "UserContentViewController.h"

@interface MainViewController ()
@property (nonatomic,strong) AGSOAuthLoginViewController* oauthLoginVC;

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
    self.oauthLoginVC = [[AGSOAuthLoginViewController alloc] initWithPortalURL:[NSURL URLWithString:@"https://www.arcgis.com"] clientID:@"pqN3y96tSb1j8ZAY" ];
    
    UINavigationController* nvc = [[UINavigationController alloc]initWithRootViewController:self.oauthLoginVC];
    nvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.oauthLoginVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelLogin)];
    
    [self presentViewController:nvc animated:YES completion:nil];
    
    __weak MainViewController *safeSelf = self;
    self.oauthLoginVC.completion = ^(AGSCredential *credential, NSError *error){
        if(error){
            
            if(error.code == NSUserCancelledError){
                [safeSelf cancelLogin];
            }else{
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [av show];
            }
        }else{
            
            //update the portal explorer with the credential provided by the user.
            AGSPortal* portal = [[AGSPortal alloc]initWithURL:[NSURL URLWithString: @"https://www.arcgis.com"] credential:credential];
            
           
            
            [safeSelf dismissViewControllerAnimated:NO completion:^(){
//                UserContentViewController* uvc = [[UserContentViewController alloc]initWithPortal:portal];
//                uvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//                [safeSelf presentModalViewController:uvc animated:YES];
                
                UserContentViewController* uvc = [[UserContentViewController alloc]initWithPortal:portal];
                
                [safeSelf.navigationController setViewControllers:@[uvc] animated:YES];
//                [safeSelf.navigationController pushViewController:uvc animated:YES];
            }];

            
        }
        
    };
}

- (void) cancelLogin{
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:nil message:@"You must sign in to continue."  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [av show];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
@end
