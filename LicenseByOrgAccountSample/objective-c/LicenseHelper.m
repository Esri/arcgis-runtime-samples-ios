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

static NSArray *kAGSLicenseStatusStrings;

NSArray *AGSLicenseStatusStrings() {
    if (!kAGSLicenseStatusStrings) {
        kAGSLicenseStatusStrings = @[@"invalid",
                                     @"expired",
                                     @"login required",
                                     @"valid"];
    }
    
    return kAGSLicenseStatusStrings;
}

AGSLicenseStatus AGSLicenseStatusFromString(NSString *licenseStatusString) {
    return (AGSLicenseStatus)[AGSLicenseStatusStrings() indexOfObject:licenseStatusString];
}

NSString* AGSLicenseStatusAsString(AGSLicenseStatus licenseStatus) {
    return [AGSLicenseStatusStrings() objectAtIndex:licenseStatus];
}

#pragma mark - License Level

static NSArray *kAGSLicenseLevelStrings;

NSArray *AGSLicenseLevelStrings() {
    if (!kAGSLicenseLevelStrings) {
        kAGSLicenseLevelStrings = @[@"Developer",
                                    @"Lite",
                                    @"Basic",
                                    @"Standard",
                                    @"Advanced"];
    }
    return kAGSLicenseLevelStrings;
}

AGSLicenseLevel AGSLicenseLevelFromString(NSString *licenseLevelString) {
    return (AGSLicenseLevel)[AGSLicenseLevelStrings() indexOfObject:licenseLevelString];
}

NSString* AGSLicenseLevelAsString(AGSLicenseLevel licenseLevel) {
    return [AGSLicenseLevelStrings() objectAtIndex:licenseLevel];
}

@interface LicenseHelper ()

@property (nonatomic, strong) NSURL* portalURL;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong, readwrite) AGSPortal* portal;
@property (nonatomic, strong) void(^completionBlock)(AGSLicenseResult *licenseResult, BOOL usedSavedLicenseInfo, AGSPortal *portal, AGSCredential *credentail, NSError *error);
@property (nonatomic, strong, readwrite) AGSCredential* credential;
@property (nonatomic, strong) AGSKeychainItem* keychainItem;

@end

@implementation LicenseHelper

static LicenseHelper* _sharedLicenseHelper = nil;

+(LicenseHelper*)sharedLicenseHelper {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLicenseHelper = [[super alloc] init];
        _sharedLicenseHelper.keychainItem = [[AGSKeychainItem alloc]
                                             initWithIdentifier:kKeyChainKey accessGroup:nil acrossDevices: NO];
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
                      completion:(void (^)(AGSLicenseResult *licenseResult,
                                           BOOL usedSavedLicenseInfo,
                                           AGSPortal *portal,
                                           AGSCredential *credential,
                                           NSError *error))completion
{
    
    self.completionBlock = completion;
    self.portalURL = portalURL;

    __weak __typeof(self) weakSelf = self;
    
    self.portal = [AGSPortal portalWithURL:self.portalURL loginRequired:YES];
    [self.portal loadWithCompletion:^(NSError * _Nullable error) {
        if (error != nil) {
            [weakSelf portalFailedToLoadWithError:error];
            
        }
        else {
            [weakSelf portalLoaded];
        }
    }];
}

-(void)resetSavedInformationWithCompletion:(void (^)(NSError * _Nullable))completion {
    //reset the portal
    self.portal = nil;
    self.credential = nil;
    [[[AGSAuthenticationManager sharedAuthenticationManager] credentialCache] removeAllCredentials];
    
    //remove stored license info, which will force a login next time the app starts
    [self.keychainItem removeObjectFromKeychainWithCompletion:completion];
}

-(BOOL)savedInformationExists {
    return ([self.keychainItem readObjectFromKeychain] != nil);
}

-(AGSLicenseLevel)licenseLevel {
    return [[AGSArcGISRuntimeEnvironment license] licenseLevel];
}

-(NSDate *)expiryDate {
    return [[AGSArcGISRuntimeEnvironment license] expiry];
}

#pragma mark - Portal block methods

-(void)portalLoaded {
    // Update our reference to the credential
    // The credential associated with the portal has information about the user etc
    self.credential = self.portal.credential;
    
    //portal loaded Ok, get license info
    NSError *error = nil;
    AGSLicenseResult *result;
    AGSLicenseInfo *licenseInfo = self.portal.portalInfo.licenseInfo;
    
    
    result = [AGSArcGISRuntimeEnvironment setLicenseInfo:licenseInfo error:&error];
    
    if (error != nil) {
        
    }
    else if (result.licenseStatus == AGSLicenseStatusExpired) {
        error = [self errorWithDescription:@"License has expired"];
    }
    else if (result == AGSLicenseStatusInvalid) {
        error = [self errorWithDescription:@"License is invalid"];
    }
    else if (result.licenseStatus == AGSLicenseStatusValid) {
        //store the license info json in the keychain
        [self.keychainItem writeObjectToKeychain:[licenseInfo toJSON:nil] completion:^(NSError * _Nullable error) {
            if (error) NSLog(@"Keychain Error: %@", error);
        }];
    }
    
    //we're done, call the completion handler
    [self callCompletionHandler:result
               usedSavedLicenseInfo:NO
                             portal:self.portal
                         credential:self.portal.credential
                              error:error];
}

-(void)portalFailedToLoadWithError:(NSError*)error {
    BOOL usingSavedLicenseInfo = YES;
    AGSLicenseResult *result = nil;
    
    //get the saved license info
    id licenseInfoJSON = [self.keychainItem readObjectFromKeychain];
    if (licenseInfoJSON) {
        //Create license info and set it into the license, then check the result
        AGSLicenseInfo *licenseInfo = [AGSLicenseInfo fromJSON:licenseInfoJSON error:nil];
        result = [AGSArcGISRuntimeEnvironment setLicenseInfo:licenseInfo error:nil];
        if (result.licenseStatus != AGSLicenseStatusValid) {
            //There's a problem with the saved license (maybe it's expired)
            [self.keychainItem removeObjectFromKeychainWithCompletion:nil];
        }
    }
    
    [self callCompletionHandler:result usedSavedLicenseInfo:usingSavedLicenseInfo portal:nil credential:self.credential error:error];
}

#pragma mark - internal

-(NSError *)errorWithDescription:(NSString *)description {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:@"com.esri.arcgis.licensehelper.error"
                               code:0
                           userInfo:[NSDictionary dictionaryWithDictionary:userInfo]];
}

-(void)callCompletionHandler:(AGSLicenseResult*)licenseResult
               usedSavedLicenseInfo:(BOOL)usedSavedLicenseInfo
                             portal:(AGSPortal *)portal
                         credential:(AGSCredential*)credential
                              error:(NSError *)error {
    if (self.completionBlock) {
        self.completionBlock(licenseResult, usedSavedLicenseInfo, portal, credential, error);
        self.completionBlock = nil;
    }
}


@end
