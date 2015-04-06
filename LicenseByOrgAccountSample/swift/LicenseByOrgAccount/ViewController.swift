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

class ViewController: UIViewController {

    @IBOutlet weak var licenseLevelLabel:UILabel!
    @IBOutlet weak var expiryLabel:UILabel!
    @IBOutlet weak var licenseButton:UIButton!
    @IBOutlet weak var networkImageView:UIImageView!
    @IBOutlet weak var portalConnectionLabel:UILabel!
    @IBOutlet weak var logTextView:UITextView!
    
    var signedIn:Bool {
        //we're signed in if the LicenseHelper has a credential.
        return (LicenseHelper.sharedInstance.credential != nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if LicenseHelper.sharedInstance.savedInformationExists() {
            //if the license helper has saved information, log in immediately
            self.signInAction(self.licenseButton)
            self.updateLogWithString("Signing in...")
        }
        else {
            //update UI and wait for user to sign in
            self.updateLogWithString("")
            self.updateStatusWithCredential(nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func signInAction(sender:UIButton) {
        if self.signedIn {
            //User wants to sign out, reset saved information
            LicenseHelper.sharedInstance.resetSavedInformation()
            self.updateLogWithString("The application has been signed out and all saved license and credential information has been deleted.")
            self.networkImageView.image = nil
            self.portalConnectionLabel.text = ""
            self.updateStatusWithCredential(nil)
        }
        else {
            //Use the helper to allow the user to sign in and license the app
            LicenseHelper.sharedInstance.standardLicenseFromPortal(NSURL(string: kPortalUrl)!, parentViewController: self, completion: { (licenseResult, usedSavedLicenseInfo, portal, credential, error) -> Void in
                if licenseResult == .Valid {
                    if usedSavedLicenseInfo {
                        self.updateLogWithString("The application was licensed at Standard level using the saved license info in the keychain")
                    }
                    else {
                        self.updateLogWithString("The application was licensed at Standard level by logging into the portal.")
                    }
                }
                else {
                    let errorDescription = error?.localizedDescription ?? ""
                    self.updateLogWithString("Couldn't initialize a Standard level license.\n  license status: \(AGSLicenseResultAsString(licenseResult))\n  reason: \(errorDescription)")
                }
                if portal != nil {
                    self.networkImageView.image = UIImage(named: "blue-network")
                    self.portalConnectionLabel.text = "Connected to portal"
                }
                else{
                    self.networkImageView.image = UIImage(named: "gray-network")
                    self.portalConnectionLabel.text = "Could not connect to portal"
                }
                
                self.updateStatusWithCredential(credential)
            })
            
            self.updateLogWithString("Signing in...")
        }
    }
    
    //MARK: - Internal
    
    func updateStatusWithCredential(credential:AGSCredential?) {
        let license = AGSRuntimeEnvironment.license()
        self.licenseLevelLabel.text = AGSLicenseLevelAsString(license.licenseLevel)
        
        var expiryString:String!
        if license.licenseLevel == AGSLicenseLevel.Developer || license.licenseLevel == AGSLicenseLevel.Basic {
            expiryString = "None"
        }
        else {
            expiryString = NSDateFormatter.localizedStringFromDate(license.expiry, dateStyle: .MediumStyle, timeStyle: .ShortStyle)
        }
        self.expiryLabel.text = expiryString
        let name = credential?.username ?? ""
        self.licenseButton.setTitle(self.signedIn ? "Sign Out \(name)" : "Sign In", forState: .Normal)
    }
    
    func updateLogWithString(logText:String) {
        if !logText.isEmpty {
            self.logTextView.text = logText
        }
    }

}

