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

let kPortalUrl = "https://www.arcgis.com"
let kClientID = "pqN3y96tSb1j8ZAY"

class SignInViewController: UIViewController, UIAlertViewDelegate, AGSPortalDelegate {

    @IBOutlet weak var signInButton:UIButton!
    
    var oauthLoginVC:AGSOAuthLoginViewController!
    var error:NSError!
    var portal:AGSPortal!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NSURLConnection.ags_trustedHosts().addObject("www.arcgis.com")
        
        //Check to see if we previously saved the user's credentails in the keychain
        //and if so, use it to sign in to the portal
        if let credential = (UIApplication.sharedApplication().delegate as! AppDelegate).fetchCredentialFromKeychain() {
            
            //Connect to the portal
            self.portal = AGSPortal(URL: NSURL(string: kPortalUrl), credential:credential)
            self.portal.delegate = self
        }
    }
    
    override func viewWillAppear(animated:Bool) {
        super.viewWillAppear(animated)
        if let _ = (UIApplication.sharedApplication().delegate as! AppDelegate).fetchCredentialFromKeychain() {
            
            self.signInButton.setTitle("Signing in...", forState: .Normal)
            self.signInButton.enabled = false
        }
        else {
            self.signInButton.setTitle("Sign In", forState: .Normal)
            self.signInButton.enabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func signIn(sender:UIButton) {
        self.oauthLoginVC = AGSOAuthLoginViewController(portalURL: NSURL(string: kPortalUrl), clientID:kClientID)
        //request a permanent refresh token so user doesn't have to login in
        self.oauthLoginVC.refreshTokenExpirationInterval = -1
        
        let nvc = UINavigationController(rootViewController: self.oauthLoginVC)
        self.oauthLoginVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Bordered, target: self, action: "cancelLogin")
        
        self.presentViewController(nvc, animated:true, completion:nil)
        
        self.oauthLoginVC.completion = { [weak self] (credential, error) in
            if let weakSelf = self {
                if error != nil {
                    if error.code == NSUserCancelledError { //if user cancelled login
                        weakSelf.cancelLogin()
                    }
                    else if error.code == NSURLErrorServerCertificateUntrusted { //if self-signed certificate error
                        
                        //keep a reference to the error so that the uialertview deleate can accesss it
                        weakSelf.error = error

                        UIAlertView(title: "Error", message: error.localizedDescription, delegate: weakSelf, cancelButtonTitle: "Cancel", otherButtonTitles: "Yes").show()
                        
                    }
                    else { //all other errors
                        
                        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
                    }
                }
                else{
                    //Connect to the portal using the credential provided by the user.
                    weakSelf.portal = AGSPortal(URL: NSURL(string: kPortalUrl), credential:credential)
                    weakSelf.portal.delegate = weakSelf
                    
                    //disable cancel button on the navigation bar
                    self?.oauthLoginVC.navigationItem.rightBarButtonItem?.enabled = false
                }
            }
        }
    }
    
    func cancelLogin() {
    
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    //MARK: - UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        //This alert view is asking the user if he/she wants to trust the self signed certificate
        if buttonIndex == 0 { //No, don't trust
            self.cancelLogin()
        }
        else { //Yes, trust
            
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
    
    
    //MARK: - AGSPortalDelegate methods
    
    func portalDidLoad(portal: AGSPortal!) {
        
        //Now that we were able to connect to the portal using the credential,
        //store the credential securely in the keychain so that we can use it later
        //when the app is restarted.
        (UIApplication.sharedApplication().delegate as! AppDelegate).saveCredentialToKeychain(portal.credential)
        
        //If we presented any other view controller, dismiss it
        if self.presentedViewController != nil {
            self.dismissViewControllerAnimated(true, completion:nil)
        }
        //show the profile view controller
        self.performSegueWithIdentifier("SegueProfileVC", sender: self)
    }
    
    func portal(portal: AGSPortal!, didFailToLoadWithError error: NSError!) {
        UIAlertView(title: "Error", message: "Could not connect to portal", delegate: nil, cancelButtonTitle: "Ok").show()
        
        if error.localizedDescription.rangeOfString("expired", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) !=  nil {
            //The oAuth refresh token probably expired, user needs to sign in again.
            //This will probably never happen in this sample because we set the refreshTokenExpirationInterval to -1 (never expires)
            self.signInButton.setTitle("Sign In", forState:.Normal)
            self.signInButton.enabled = true
        }
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SegueProfileVC" {
            let controller = segue.destinationViewController as! ProfileViewController
            controller.portal = self.portal
        }
    }
}
