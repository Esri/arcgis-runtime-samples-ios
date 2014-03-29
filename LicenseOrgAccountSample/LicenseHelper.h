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

#import <Foundation/Foundation.h>
#import <ArcGIS/ArcGIS.h>

#import "LicenseHelperConstants.h"


/** @brief A helper class designed for use when an application wants to alow users to
 sign into a portal and then take the application offline and use functinality for
 which a Standard license is required.
 */
@interface LicenseHelper : NSObject <AGSPortalDelegate>

/** The Portal the user logged in to.  If portal is nil, the user is not signed in.
 */
@property (nonatomic, readonly) AGSPortal* portal;

/** The credential used to log into the portal.
 */
@property (nonatomic, readonly) AGSCredential* credential;

/** The license level for the license.
 */
@property (nonatomic, readonly) AGSLicenseLevel licenseLevel;

/** The expiry date for the license.
 */
@property (nonatomic, readonly) NSDate *expiryDate;

/** Retrieves the shared license helper.
 */
+(LicenseHelper *)sharedLicenseHelper;

/** Allows the user license an application by logging into a portal.  This method will:
 - check to see if there is a saved encrypted license string
 - if there is an encrypted license string, it will use that to license the application.
 - if there is no saved encrypted license string, it will prompt the user for credentials and then
 login to the portal
 - once the portal login is completed, it will create the license info and use that to license the core
 
 The completion handler will be called with no error when the portal has successfully loaded and the set
 license info operation returns a 'valid' license result.
 
 The completion handler will be called with an error when:
 - the user cancels the portal login process
 - the user chooses not to trust an untrusted host when logging in via OAuth
 - the portal fails to load
 - the portal loads succesffully, but the set license info operation return an invalid or expired result
 
 This method needs to be called from an existing, visible view controller, since it may need to display
 the AGSOAuthLoginViewController.
 @param portalURL The URL of the portal to use, if there is no saved encrypted license string.
 @param parentVC The parent view controller the login view will be displayed from.
 @param completion The code block to be called when the licensing process is finished.
 */
-(void)standardLicenseFromPortal:(NSURL *)portalURL
            parentViewController:(AGSViewController *)parentVC
                      completion:(void (^)(AGSLicenseResult licenseResult,
                                           BOOL usedSavedLicenseInfo,
                                           AGSPortal *portal,
                                           AGSCredential *credential,
                                           NSError *error))completion;

/** Unlicenses the application.
 */
-(void)resetSavedInformation;

/** Indicates whether there is saved license/credential information.
 */
-(BOOL)savedInformationExists;

@end
