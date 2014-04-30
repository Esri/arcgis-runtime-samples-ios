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

#import "LoginViewController.h"

@interface LoginViewController() <UITextFieldDelegate>

//text fields for the username and password. 
@property (nonatomic,strong) IBOutlet UITextField *txtUsername;
@property (nonatomic,strong) IBOutlet UITextField *txtPassword;

//credential
@property (nonatomic,strong) AGSCredential *credential;

- (IBAction)login;
- (IBAction)cancel;

@end

@implementation LoginViewController

- (void)dealloc {
    
    self.delegate = nil;
    
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //title
    self.title = @"Login";
    
    //set text in the fields for the log in. 
    self.txtUsername.text = @"";
    self.txtUsername.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.txtPassword.text = @"";
    self.txtPassword.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    //set text fields' delegate
    self.txtUsername.delegate = self;
    self.txtPassword.delegate = self;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.delegate = nil;
    self.txtUsername = nil;
    self.txtPassword = nil;
    self.credential = nil;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES;
}


#pragma mark - Table view data source
#pragma mark Button Actions

- (IBAction)login {
    
    //strip the white space character for username and password. 
    NSString *username = [self.txtUsername.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *password = [self.txtPassword.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //create the credential object
    self.credential = [[AGSCredential alloc] initWithUser:username password:password];
    
    //call the appropriate delegate method to provide the credential. 
    if([self.delegate respondsToSelector:@selector(userDidProvideCredential:)])
    {
        [self.delegate userDidProvideCredential:self.credential];
    }
    
}

- (IBAction)cancel {
    
    //call the appropriate delegate method to cancel logging in. 
    if([self.delegate respondsToSelector:@selector(userDidCancelLogin)])
    {
        [self.delegate userDidCancelLogin];
    }
}



#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    
	if(theTextField == self.txtPassword) {
        [theTextField resignFirstResponder];
        [self login];
    }
    else {
        [self.txtPassword becomeFirstResponder];
    }
	return YES;
}

-(CGSize)contentSizeForViewInPopover
{
    return self.view.bounds.size;
}
@end
