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

class ProfileViewController: UIViewController, AGSPortalUserDelegate {

    @IBOutlet weak var thumbnailView:UIImageView!
    
    @IBOutlet weak var fullNameTextField:JVFloatLabeledTextField!
    @IBOutlet weak var usernameTextField:JVFloatLabeledTextField!
    @IBOutlet weak var emailTextField:JVFloatLabeledTextField!
    @IBOutlet weak var memberSinceTextField:JVFloatLabeledTextField!
    @IBOutlet weak var roleTextField:JVFloatLabeledTextField!
    @IBOutlet weak var bioTextView:JVFloatLabeledTextView!
    
    @IBOutlet weak var signOutButton:UIButton!
    
    var portal:AGSPortal!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //disable back button
        self.navigationItem.hidesBackButton = true
        
        //add corner radius and border for the thumbnail
        self.thumbnailView.layer.cornerRadius = self.thumbnailView.bounds.size.width/2
        self.thumbnailView.layer.borderColor = UIColor.whiteColor().CGColor
        self.thumbnailView.layer.borderWidth = 2
        
        //add corner radius for the button
        self.signOutButton.layer.cornerRadius = self.signOutButton.bounds.size.height/2
        
        //setup text view
        self.setupTextView()

        //populate the data using the user object on portal
        self.populateData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func populateData() {
        //if thumbnail already loaded then simply assign it
        //else initiate the fetch
        if self.portal.user.thumbnail != nil {
            self.thumbnailView.image = self.portal.user.thumbnail
        }
        else {
            self.portal.user.delegate = self
            if self.portal.user.thumbnailFileName != nil && !self.portal.user.thumbnailFileName.isEmpty {
                self.portal.user.fetchThumbnail()
            }
        }
        
        //show the corresponding values in the textfields
        self.fullNameTextField.text = self.portal?.user?.fullName ?? "NA"
        self.usernameTextField.text = self.portal?.user?.username ?? "NA"
        self.emailTextField.text = self.portal?.user?.email ?? "NA"
        self.roleTextField.text = self.roleDescription(self.portal?.user?.role ?? .None)
        
        //show the date in medium style
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        if let created = self.portal.user.created {
            self.memberSinceTextField.text = dateFormatter.stringFromDate(created)
        }
        else {
            self.memberSinceTextField.text = "NA"
        }
        
        if let userDescription = self.portal.user.userDescription {
            if !userDescription.isEmpty {
                self.bioTextView.text = userDescription
            }
        }
    }
    
    func setupTextView() {
        //setup text view
        self.bioTextView.placeholder = "Bio"
        self.bioTextView.layer.borderColor = UIColor(red: 75.0/255.0, green: 131.0/255.0, blue: 201.0/255.0, alpha: 1.0).CGColor
        self.bioTextView.layer.borderWidth = 1
        self.bioTextView.layer.cornerRadius = 8
        self.bioTextView.textContainerInset = UIEdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
        self.bioTextView.floatingLabelShouldLockToTop = 0
    }
    
    //get a description for the role enum
    func roleDescription(role:AGSPortalUserRole) -> String {
        var roleDescription:String!
        switch role {
        case .None:
            roleDescription = "The user does not belong to an organization"
        case .User:
            roleDescription = "Information worker"
        case .Publisher:
            roleDescription = "Publisher"
        case .Admin:
            roleDescription = "Administrator"
        }
        return roleDescription
    }

    //MARK: - AGSPortalUserDelegate methods
    
    func portalUser(portalUser: AGSPortalUser!, operation op: NSOperation!, didFetchThumbnail thumbnail: UIImage!) {
        self.thumbnailView.image = thumbnail
    }
    
    func portalUser(portalUser: AGSPortalUser!, operation op: NSOperation!, didFailToFetchThumbnailWithError error: NSError!) {
        print("Error while loading user thumbnail :: \(error.localizedDescription)")
    }
    
    //MARK: - Actions
    
    @IBAction func signOutAction() {
        (UIApplication.sharedApplication().delegate as! AppDelegate).removeCredentialFromKeychain()
        self.navigationController?.popViewControllerAnimated(true)
    }
}
