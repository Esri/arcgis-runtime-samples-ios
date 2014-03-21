/*
 Copyright 2014 Esri
 
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

#import "ViewController.h"
#import "LicenseHelper.h"

@interface ViewController()

@property (strong, nonatomic) IBOutlet UILabel *licenseLevelLabel;
@property (strong, nonatomic) IBOutlet UILabel *expiryLabel;
@property (strong, nonatomic) IBOutlet UIButton *licenseButton;
@property (weak, nonatomic) IBOutlet UIImageView *networkImageView;
@property (weak, nonatomic) IBOutlet UILabel *portalConnectionLabel;
@property (strong, nonatomic) IBOutlet UITextView *logTextView;

@property (assign, nonatomic, readonly) BOOL signedIn;
@end

@implementation ViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

    if ([[LicenseHelper sharedLicenseHelper] savedInformationExists]) {
        //if the license helper has saved information, log in immediately
        [self signInAction:self.licenseButton];
        [self updateLogWithString:@"Signing in..."];
    }
    else {
        [self updateLogWithString:@""];
        [self updateStatusWithCredential:nil];
    }
}

- (IBAction)signInAction:(id)sender {
    
    if (self.signedIn) {
        [[LicenseHelper sharedLicenseHelper] unlicense];
        [self updateLogWithString:@"The application has been signed out and all saved license and credential information has been deleted."];
      self.networkImageView.image = nil;
      self.portalConnectionLabel.text = @"";
      [self updateStatusWithCredential:nil];
    }
    else {
        [[LicenseHelper sharedLicenseHelper] standardLicenseFromPortal:[NSURL URLWithString:kPortalUrl]
                parentViewController:self
              completion:^(AGSLicenseResult licenseResult, BOOL usedSavedLicenseInfo, AGSPortal *portal, AGSCredential *credential, NSError *error) {
                    if (error) {
                      
                        [self updateLogWithString:[NSString stringWithFormat:@"There was an error licensing the app:\n  license result: %@\n  error: %@",AGSLicenseResultAsString(licenseResult), error.localizedDescription]];
                    } else {
                        if (usedSavedLicenseInfo) {
                            [self updateLogWithString:@"The application was licensed using the saved license info in the keychain"];
                        }else {
                            [self updateLogWithString:@"The application was licensed by logging into the portal."];
                        }
                    }
                
                  if(portal){
                    self.networkImageView.image = [UIImage imageNamed:@"blue-network"];
                    self.portalConnectionLabel.text = @"Connected to portal";
                  }else{
                    self.networkImageView.image = [UIImage imageNamed:@"gray-network"];
                    self.portalConnectionLabel.text = @"Could not connect to portal";
                  }
                
                    [self updateStatusWithCredential:credential];
        }];
        
        [self updateLogWithString:@"Signing in..."];
    }
}

#pragma mark - Internal

-(BOOL)signedIn {
    //we're signed in if the LicenseHelper has a credential.
    return [LicenseHelper sharedLicenseHelper].credential != nil;
}

-(void)updateStatusWithCredential:(AGSCredential*)credential {
    AGSLicense *license = [AGSRuntimeEnvironment license];
    self.licenseLevelLabel.text = AGSLicenseLevelAsString(license.licenseLevel);

    NSString *expiryString;
    if (license.licenseLevel == AGSLicenseLevelDeveloper || license.licenseLevel == AGSLicenseLevelBasic) {
        expiryString = @"None";
    }
    else {
        expiryString = [NSDateFormatter localizedStringFromDate:license.expiry
                                                      dateStyle:NSDateFormatterMediumStyle
                                                      timeStyle:NSDateFormatterShortStyle];
    }
    self.expiryLabel.text = expiryString;
    [self.licenseButton setTitle:(self.signedIn ? [@"Sign Out" stringByAppendingFormat:@" (%@)",credential.username] : @"Sign In") forState:UIControlStateNormal];
}

-(void)updateLogWithString:(NSString *)logText
{
    if (logText) {
      self.logTextView.text = logText;
    }
}

@end
