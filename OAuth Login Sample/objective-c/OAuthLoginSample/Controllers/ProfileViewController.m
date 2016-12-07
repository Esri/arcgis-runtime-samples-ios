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

#import "ProfileViewController.h"
#import "JVFloatLabeledTextField.h"
#import "JVFloatLabeledTextView.h"
#import "AppDelegate.h"

@interface ProfileViewController ()

@property (nonatomic, weak) IBOutlet UIImageView *thumbnailView;

@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *fullNameTextField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *usernameTextField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *emailTextField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *memberSinceTextField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *roleTextField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextView *bioTextView;

@property (nonatomic, weak) IBOutlet UIButton *signOutButton;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //disable back button
    self.navigationItem.hidesBackButton = YES;
    
    //add corner radius and border for the thumbnail
    self.thumbnailView.layer.cornerRadius = self.thumbnailView.bounds.size.width/2;
    self.thumbnailView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.thumbnailView.layer.borderWidth = 2;
    
    //add corner radius for the button
    self.signOutButton.layer.cornerRadius = self.signOutButton.bounds.size.height/2;
    
    //setup text view
    [self setupTextView];
    
    //populate the data using the user object on portal
    [self populateData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)populateData {
    
    //
    // Fetch and display thumbnail
    //
    
    // avoid retain cycle
    __weak AGSLoadableImage *loadableImage = self.portal.user.thumbnail;
    // This will return right away if it is already loaded
    [self.portal.user.thumbnail loadWithCompletion:^(NSError * _Nullable error) {
        if (error){
            NSLog(@"Error while loading user thumbnail :: %@", error.localizedDescription);
        }
        else{
            self.thumbnailView.image = loadableImage.image;
        }
    }];
    
    //show the corresponding values in the textfields
    self.fullNameTextField.text = self.portal.user.fullName ?: @"NA";
    self.usernameTextField.text = self.portal.user.username ?: @"NA";
    self.emailTextField.text = self.portal.user.email ?: @"NA";
    self.roleTextField.text = [self roleDescriptionForRole:self.portal.user.role];
    
    //show the date in medium style
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    if (self.portal.user.created) {
        self.memberSinceTextField.text = [dateFormatter stringFromDate:self.portal.user.created];
    }
    else {
        self.memberSinceTextField.text = @"NA";
    }
    
    if (self.portal.user.userDescription && self.portal.user.userDescription.length) {
        self.bioTextView.text = self.portal.user.userDescription;
    }
}

-(void)setupTextView {
    //setup text view
    self.bioTextView.placeholder = @"Bio";
    self.bioTextView.layer.borderColor = [UIColor colorWithRed:75.0/255.0 green: 131.0/255.0 blue: 201.0/255.0 alpha: 1.0].CGColor;
    self.bioTextView.layer.borderWidth = 1;
    self.bioTextView.layer.cornerRadius = 8;
    self.bioTextView.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8);
    self.bioTextView.floatingLabelShouldLockToTop = 0;
}

//get a description for the role enum
-(NSString*)roleDescriptionForRole:(AGSPortalUserRole)role {
    NSString *roleDescription;
    if (role == AGSPortalUserRoleUnknown) {
        roleDescription = @"The user does not belong to an organization";
    }
    else if (role == AGSPortalUserRoleUser) {
        roleDescription = @"Information worker";
    }
    else if (role == AGSPortalUserRolePublisher) {
        roleDescription = @"Publisher";
    }
    else if (role == AGSPortalUserRoleAdmin) {
        roleDescription = @"Administrator";
    }
    return roleDescription;
}

//MARK: - Actions

-(IBAction)signOutAction {
    
    // Remove all the credentials from the cache.
    // Since we enabled auto-sync to the keychain the credentials will be automatically removed from the
    // keychain as well.
    [[AGSAuthenticationManager sharedAuthenticationManager].credentialCache removeAllCredentials];
    
    [self.navigationController popViewControllerAnimated:YES];
}
@end
