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

import UIKit
import ArcGIS

let kUntrustedHostAlertViewTag = 0
let kErrorAlertViewTag = 1
let kCredentialKey = "credential"
let kLicenseKey = "license"

private let _licenseHelperSharedInstance = LicenseHelper()

/** @brief A helper class designed for use when an application wants to alow users to
sign into a portal and then take the application offline and use functinality for
which a Standard license is required.
*/
class LicenseHelper: NSObject, AGSPortalDelegate, UIAlertViewDelegate {
   
    class var sharedInstance:LicenseHelper {
        return _licenseHelperSharedInstance
    }
    
    /** The Portal the user logged in to.  If portal is nil, the user is not signed in.
    */
    var portal:AGSPortal!
    
    /** The credential used to log into the portal.
    */
    var credential:AGSCredential!
    
    /** The license level for the license.
    */
     var licenseLevel:AGSLicenseLevel {
        return AGSRuntimeEnvironment.license().licenseLevel
    }
    
    /** The expiry date for the license.
    */
    var expiryDate:NSDate {
        return AGSRuntimeEnvironment.license().expiry
    }
    
    var oauthLoginVC:AGSOAuthLoginViewController!
    var parentVC:UIViewController!
    var portalURL:NSURL!
    var error:NSError!
    var completionBlock:((licenseResult:AGSLicenseResult, usedSavedLicenseInfo:Bool, portal:AGSPortal?, credential:AGSCredential?, error:NSError?) -> Void)!
    var keychainWrapper:AGSKeychainItemWrapper!
    
    
    override init() {
        self.keychainWrapper = AGSKeychainItemWrapper(identifier: kKeyChainKey, accessGroup: nil)
    }
    
    func standardLicenseFromPortal(portalURL:NSURL, parentViewController parentVC:UIViewController, completion:(licenseResult:AGSLicenseResult, usedSavedLicenseInfo:Bool, portal:AGSPortal?, credential:AGSCredential?, error:NSError?) -> Void) {
    
        self.completionBlock = completion
        self.parentVC = parentVC
        self.portalURL = portalURL
        
        //check if we have credential
        //yes - load portal with credential
        //refresh license info
        
        //no - ask user to authenticate
        //
        
        //Determine if we have credential in the keychain
        if let keychainDict = self.keychainWrapper.keychainObject() as? [String: NSObject] {
            self.credential = keychainDict[kCredentialKey] as! AGSCredential
       
            // Use credentials to load portal.  The completion block will by called by
            // either portalDidLoad: or portal:didFailToLoadWithError:
            self.portal = AGSPortal(URL: self.portalURL, credential: self.credential)
            self.portal.delegate = self
        }
        else {
            // Need user to log in
            self.login()
        }
    }
    
    func resetSavedInformation() {
        //reset the portal
        self.portal = nil
        self.credential = nil
        
        //remove stored license info, which will force a login next time the app starts
        self.keychainWrapper.setKeychainObject(nil)
    }
    
    func savedInformationExists() -> Bool {
        return (self.keychainWrapper.keychainObject() != nil) ?? false
    }
    
    //MARK: - AGSPortalDelegate
    
    func portalDidLoad(portal: AGSPortal!) {
        
        // Update our reference to the credential
        // The credential associated with the portal has information about the user etc
        self.credential = self.portal.credential
        
        //portal loaded Ok, get license info
        var error:NSError?
        
        let licenseInfo = AGSLicenseInfo(portalInfo: portal.portalInfo)
        let result = AGSRuntimeEnvironment.license().setLicenseInfo(licenseInfo)
        
        if result == .Expired {
            error = self.errorWithDescription("License has expired")
        }
        else if result == .Invalid {
            error = self.errorWithDescription("License is invalid")
        }
        else if result == .Valid {
            //store license info json and credential in a new dictionary
            //we know we don't already have stored keychain data because of the first check above
            let keychainDict = [kLicenseKey: licenseInfo.encodeToJSON(), kCredentialKey: self.credential];
            
            //store the new dictionary in the keychain
            self.keychainWrapper.setKeychainObject(keychainDict)
        }
        
        //we're done, call the completion handler
        self.callCompletionHandler(result, usedSavedLicenseInfo:false, portal:portal, credential:portal.credential, error:error)
    }
    
    func portal(portal: AGSPortal!, didFailToLoadWithError error: NSError!) {
        let usingSavedLicenseInfo = true
        
        //Determine if we have info in the keychain
        let keychainDict = self.keychainWrapper.keychainObject() as! [String:NSObject]
        
        //get the saved license info
        let licenseInfoJSON = keychainDict[kLicenseKey] as! [NSObject:AnyObject]
        //if (licenseInfoJSON) {
        //Create license info and set it into the license, then check the result
        let licenseInfo = AGSLicenseInfo(JSON: licenseInfoJSON)
        let result = AGSRuntimeEnvironment.license().setLicenseInfo(licenseInfo)
        if result != .Valid {
            //There's a problem with the saved license (maybe it expired)
            //self.keychainWrapper.reset()
        }
        //}
        
        self.callCompletionHandler(result, usedSavedLicenseInfo:usingSavedLicenseInfo, portal:nil, credential:self.credential, error:error)
    }
    
    //MARK: - internal
    
    func cancelLogin() {
        self.parentVC.dismissViewControllerAnimated(true, completion: { [weak self] () -> Void in
            if let weakSelf = self {
                weakSelf.callCompletionHandler(.LoginRequired, usedSavedLicenseInfo: false, portal: weakSelf.portal, credential: weakSelf.credential, error: weakSelf.error)
            }
        })
    }
    
    func autoLicense() -> Bool {
    
        let success = false
        
        return success
    }
    
    func login() {
        self.oauthLoginVC = AGSOAuthLoginViewController(portalURL: self.portalURL, clientID:kClientID)
        self.oauthLoginVC.cancelButtonHidden = false
        
        let nvc = UINavigationController(rootViewController: self.oauthLoginVC)
        nvc.modalTransitionStyle = .FlipHorizontal
        self.oauthLoginVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Bordered, target: self, action: "cancelLogin")
        
        self.parentVC.presentViewController(nvc, animated:true, completion:nil)
        
        self.oauthLoginVC.completion = { [weak self] (credential, error) in
            if let weakSelf = self {
                if error != nil {
                    if error.code == NSUserCancelledError { //if user cancelled login
                        weakSelf.cancelLogin()
                    }
                    else if error.code == NSURLErrorServerCertificateUntrusted { //if self-signed certificate error
                        
                        //keep a reference to the error so that the uialertview deleate can accesss it
                        weakSelf.error = error
                        let av = UIAlertView(title: "Error", message: error.localizedDescription, delegate: weakSelf, cancelButtonTitle: "Cancel", otherButtonTitles: "Yes")
                        av.tag = kUntrustedHostAlertViewTag
                        av.show()
                        
                    }
                    else { //all other errors
                        
                        let av = UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok")
                        av.tag = kErrorAlertViewTag
                        av.show()
                    }
                }
                else{
                    //Connect to the portal using the credential provided by the user.
                    weakSelf.portal = AGSPortal(URL: weakSelf.portalURL, credential:credential)
                    weakSelf.portal.delegate = weakSelf
                    weakSelf.credential = credential
                    
                    weakSelf.parentVC.dismissViewControllerAnimated(true, completion:nil)
                    //disable cancel button on the navigation bar
                    self?.oauthLoginVC.navigationItem.rightBarButtonItem?.enabled = false
                }
            }
        }
    }
    
    func errorWithDescription(description:String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey: description]
        return NSError(domain: "com.esri.arcgis.licensehelper.error", code: 0, userInfo: userInfo)
    }
    
    func userCancelledError() -> NSError {
        return self.errorWithDescription("User cancelled portal login")
    }
    
    func callCompletionHandler(licenseResult: AGSLicenseResult, usedSavedLicenseInfo:Bool, portal:AGSPortal?, credential:AGSCredential?, error:NSError?) {
        if self.completionBlock != nil {
            self.completionBlock(licenseResult: licenseResult, usedSavedLicenseInfo: usedSavedLicenseInfo, portal: portal, credential: credential, error: error)
            self.completionBlock = nil
        }
    }
    
    //MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == kErrorAlertViewTag {
            //error, retry until user cancels
            self.oauthLoginVC.reload()
        }
        else if alertView.tag == kUntrustedHostAlertViewTag {
            //host is untrusted
            if buttonIndex == 0 {
                //user doesn't want to trust host
                self.cancelLogin()
            }
            else {
                if let url = self.error.userInfo[NSURLErrorFailingURLErrorKey] as? NSURL {
                    //add to trusted hosts
                    if let host = url.host {
                        NSURLConnection.ags_trustedHosts().addObject(host)
                    }
                    //make a test connection to force UIWebView to accept the host
                    let rop = AGSJSONRequestOperation(URL: url)
                    AGSRequestOperation.sharedOperationQueue().addOperation(rop)
                    //Reload the OAuth vc
                    self.oauthLoginVC.reload()
                }
            }
        }
    }
}
