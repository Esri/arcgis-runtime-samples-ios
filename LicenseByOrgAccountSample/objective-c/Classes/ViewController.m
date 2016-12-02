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
#import "AppDelegate.h"

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
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([[LicenseHelper sharedLicenseHelper] savedInformationExists]) {
        //if the license helper has saved information, log in immediately
        [self signInAction:self.licenseButton];
        [self updateLogWithString:@"Signing in..."];
    }
    else {
        //update UI and wait for user to sign in
        [self updateLogWithString:@""];
        [self updateStatusWithCredential:nil];
    }
}

- (IBAction)signInAction:(id)sender {
    
    __weak __typeof(self) weakSelf = self;
    if (self.signedIn) {
        //User wants to sign out, reset saved information
        [[LicenseHelper sharedLicenseHelper] resetSavedInformationWithCompletion:^(NSError * _Nullable error) {
            [weakSelf updateLogWithString:@"The application has been signed out and all saved license and credential information has been deleted."];
            weakSelf.networkImageView.image = nil;
            weakSelf.portalConnectionLabel.text = @"";
            [weakSelf updateStatusWithCredential:nil];
        }];
    }
    else {
        NSURL *portalURL = ((AppDelegate*)[UIApplication sharedApplication].delegate).portalURL;
      
        //Use the helper to allow the user to sign in and license the app
        [[LicenseHelper sharedLicenseHelper] standardLicenseFromPortal:portalURL
              completion:^(AGSLicenseResult *licenseResult, BOOL usedSavedLicenseInfo, AGSPortal *portal, AGSCredential *credential, NSError *error) {
                
                if(licenseResult.licenseStatus==AGSLicenseStatusValid){
                  if (usedSavedLicenseInfo) {
                    [weakSelf updateLogWithString:@"The application was licensed using the saved license info in the keychain"];
                  }else {
                    [weakSelf updateLogWithString:@"The application was licensed by logging into the portal."];
                  }
                }else{
                  [weakSelf updateLogWithString:[NSString stringWithFormat:@"Couldn't initialize license.\n  license status: %ld\n  reason: %@", (long)licenseResult.licenseStatus, error.localizedDescription]];
                }
                if(portal){
                  weakSelf.networkImageView.image = [UIImage imageNamed:@"blue-network"];
                  weakSelf.portalConnectionLabel.text = @"Connected to portal";
                }else{
                  weakSelf.networkImageView.image = [UIImage imageNamed:@"gray-network"];
                  weakSelf.portalConnectionLabel.text = @"Could not connect to portal";
                }
              
                [weakSelf updateStatusWithCredential:credential];
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
    AGSLicense *license = [AGSArcGISRuntimeEnvironment license];
    self.licenseLevelLabel.text = [NSString stringWithFormat:@"Level: %@",AGSLicenseLevelAsString(license.licenseLevel)];

    NSString *expiryString;
    if (license.licenseLevel == AGSLicenseLevelDeveloper) {
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
