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

#import "LicenseHelper.h"
#import "LicenseHelperConstants.h"

#define kUntrustedHostAlertViewTag 0
#define kErrorAlertViewTag         1
#define kCredentialKey @"credential"
#define kLicenseKey @"license"

@interface LicenseHelper () <AGSPortalDelegate>

@property (nonatomic, strong) AGSOAuthLoginViewController* oauthLoginVC;
@property (nonatomic, strong) AGSViewController* parentVC;
@property (nonatomic, strong) NSURL* portalURL;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong, readwrite) AGSPortal* portal;
@property (nonatomic, strong) void(^completionBlock)(AGSLicenseResult licenseResult, BOOL usedSavedLicenseInfo, AGSPortal *portal, AGSCredential *credentail, NSError *error);
@property (nonatomic, strong, readwrite) AGSCredential* credential;
@property (nonatomic, strong) AGSKeychainItemWrapper* keychainWrapper;

@end

@implementation LicenseHelper

static LicenseHelper* _sharedLicenseHelper = nil;

+(LicenseHelper*)sharedLicenseHelper {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLicenseHelper = [[super alloc] init];
        _sharedLicenseHelper.keychainWrapper = [[AGSKeychainItemWrapper alloc]
                                                initWithIdentifier:kKeyChainKey accessGroup:nil];
    });
    
    return _sharedLicenseHelper;
}

+(id)alloc {
    @synchronized([LicenseHelper class]) {
        NSAssert(YES, @"Cannot alloc LicenseHelper, use 'sharedLicenseHelper' to access the LicenseHelper.");
    }
    return nil;
}

-(void)standardLicenseFromPortal:(NSURL *)portalURL
            parentViewController:(UIViewController *)parentVC
                      completion:(void (^)(AGSLicenseResult licenseResult,
                                           BOOL usedSavedLicenseInfo,
                                           AGSPortal *portal,
                                           AGSCredential *credential,
                                           NSError *error))completion
{
    
    self.completionBlock = completion;
    self.parentVC = parentVC;
    self.portalURL = portalURL;
    
    //check if we have credential
        //yes - load portal with credential
        //refresh license info
    
        //no - ask user to authenticate
        //
    
    //Determine if we have credential in the keychain
    NSDictionary *keyChainDict = (NSDictionary *)[self.keychainWrapper keychainObject];
    self.credential = (AGSCredential *)keyChainDict[kCredentialKey];
    
    if (self.credential) {
        // Use credentials to load portal.  The completion block will by called by
        // either portalDidLoad: or portal:didFailToLoadWithError:
        self.portal = [[AGSPortal alloc]initWithURL:self.portalURL credential:self.credential];
        self.portal.delegate = self;
    }
    else {
        // Need user to log in
        [self login];
    }
}

-(void)resetSavedInformation {
    //reset the portal
    self.portal = nil;
    self.credential = nil;
    
    //remove stored license info, which will force a login next time the app starts
    [self.keychainWrapper setKeychainObject:nil];
}

-(BOOL)savedInformationExists {
    return ([self.keychainWrapper keychainObject] != nil);
}

-(AGSLicenseLevel)licenseLevel {
    return [[AGSRuntimeEnvironment license] licenseLevel];
}

-(NSDate *)expiryDate {
    return [[AGSRuntimeEnvironment license] expiry];
}

#pragma mark - AGSPortalDelegate

-(void)portalDidLoad:(AGSPortal *)portal {
    
    // Update our reference to the credential
    // The credential associated with the portal has information about the user etc
    self.credential = self.portal.credential;
    
    //portal loaded Ok, get license info
    NSError *error = nil;
    AGSLicenseResult result;
    AGSLicenseInfo *licenseInfo = [[AGSLicenseInfo alloc] initWithPortalInfo:portal.portalInfo];


    result = [[AGSRuntimeEnvironment license] setLicenseInfo:licenseInfo];
    
    if (result == AGSLicenseResultExpired) {
        error = [self errorWithDescription:@"License has expired"];
    }
    else if (result == AGSLicenseResultInvalid) {
        error = [self errorWithDescription:@"License is invalid"];
    }
    else if (result == AGSLicenseResultValid) {
        //store license info json and credential in a new dictionary
        //we know we don't already have stored keychain data because of the first check above
        NSDictionary *keyChainDict = @{ kLicenseKey : [licenseInfo encodeToJSON],
                                    kCredentialKey : self.credential,
                                    };

        //store the new dictionary in the keychain
        [self.keychainWrapper setKeychainObject:keyChainDict];
    }
    
    //we're done, call the completion handler
    [self callCompletionHandler:result usedSavedLicenseInfo:NO portal:portal credential:portal.credential error:error];
}

-(void)portal:(AGSPortal *)portal didFailToLoadWithError:(NSError *)error {
    BOOL usingSavedLicenseInfo = YES;
    
    //Determine if we have info in the keychain
    NSDictionary *keyChainDict = (NSDictionary *)[self.keychainWrapper keychainObject];
    
    //get the saved license info
    NSDictionary *licenseInfoJSON = keyChainDict[kLicenseKey];
    //if (licenseInfoJSON) {
        //Create license info and set it into the license, then check the result
        AGSLicenseInfo *licenseInfo = [[AGSLicenseInfo alloc] initWithJSON:licenseInfoJSON];
        AGSLicenseResult result = [[AGSRuntimeEnvironment license] setLicenseInfo:licenseInfo];
        if (result != AGSLicenseResultValid) {
            //There's a problem with the saved license (maybe it expired)
            //[self.keychainWrapper reset];
        }
    //}
    
    [self callCompletionHandler:result usedSavedLicenseInfo:usingSavedLicenseInfo portal:nil credential:self.credential error:error];
}

#pragma mark - internal

-(void)cancelLogin {
    [self.parentVC dismissViewControllerAnimated:YES completion:^{
        [self callCompletionHandler:AGSLicenseResultLoginRequired usedSavedLicenseInfo:NO portal:self.portal credential:self.credential error:[self userCancelledError]];
    }];
}

-(BOOL)autoLicense {
    
    BOOL success = NO;
    
   
    
    return success;
}

-(void)login {
    self.oauthLoginVC = [[AGSOAuthLoginViewController alloc] initWithPortalURL:self.portalURL clientID:kClientID];
    self.oauthLoginVC.cancelButtonHidden = NO;
    
    UINavigationController* nvc = [[UINavigationController alloc]initWithRootViewController:self.oauthLoginVC];
    nvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.oauthLoginVC.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelLogin)];
    [self.parentVC presentViewController:nvc animated:YES completion:nil];
    
    __weak LicenseHelper *safeSelf = self;
    self.oauthLoginVC.completion = ^(AGSCredential *credential, NSError *error) {
        if (error) {
            if (error.code == NSUserCancelledError) {
                [safeSelf cancelLogin];
            } else if (error.code == NSURLErrorServerCertificateUntrusted){
                //keep a reference to the error so that the uialertview deleate can accesss it
                safeSelf.error = error;

                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Error" message:[[error localizedDescription] stringByAppendingString:[error localizedRecoverySuggestion]] delegate:safeSelf cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
                av.tag = kUntrustedHostAlertViewTag;
                [av show];
            }
            else {
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                av.tag = kErrorAlertViewTag;
                [av show];
            }
        } else {
            //update the portal explorer with the credential provided by the user.
            AGSPortal* portal = [[AGSPortal alloc]initWithURL:safeSelf.portalURL credential:credential];
            portal.delegate = safeSelf;
            safeSelf.portal = portal;
            safeSelf.credential = credential;
            
            [safeSelf.parentVC dismissViewControllerAnimated:YES completion:nil];
            //The execution will continue in the AGSPortalDelegate methods
        }
    };
}

-(NSError *)errorWithDescription:(NSString *)description {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:@"com.esri.arcgis.licensehelper.error"
                               code:0
                           userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

-(NSError *)userCancelledError {
    return [self errorWithDescription:@"User cancelled portal login"];
}

-(void)callCompletionHandler:(AGSLicenseResult)licenseResult usedSavedLicenseInfo:(BOOL)usedSavedLicenseInfo portal:(AGSPortal *)portal credential:(AGSCredential*)credential error:(NSError *)error {
    if (self.completionBlock) {
        self.completionBlock(licenseResult, usedSavedLicenseInfo, portal, credential, error);
        self.completionBlock = nil;
    }
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == kErrorAlertViewTag) {
        //error, retry until user cancels
        [self.oauthLoginVC reload];
    }
    else if (alertView.tag == kUntrustedHostAlertViewTag) {
        //host is untrusted
        if (buttonIndex == 0) {
            //user doesn't want to trust host
            [self cancelLogin];
        } else {
            NSURL* url = [self.error userInfo][NSURLErrorFailingURLErrorKey];
            //add to trusted hosts
            [[NSURLConnection ags_trustedHosts]addObject:[url host]];
            //make a test connection to force UIWebView to accept the host
            AGSJSONRequestOperation* rop = [[AGSJSONRequestOperation alloc]initWithURL:url];
            [[AGSRequestOperation sharedOperationQueue] addOperation:rop];
            [self.oauthLoginVC reload];
        }
    }
}


@end
