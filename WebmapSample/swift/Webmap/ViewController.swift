//
// Copyright 2014 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit
import ArcGIS

let CHOOSE_WEBMAP_TAG = 0
let SIGN_IN_WEBMAP_TAG = 1
let SIGN_IN_LAYER_TAG = 2

let kPublicWebmapId = "8a567ebac15748d39a747649a2e86cf4"
let kPrivateWebmapId = "9a5e8ffd9eb7438b894becd6c8a85751"

class ViewController: UIViewController, AGSCalloutDelegate, AGSWebMapDelegate, UIAlertViewDelegate, AGSPopupsContainerDelegate {
    
    @IBOutlet weak var mapView: AGSMapView!
    var webmap:AGSWebMap!
    var webmapId:String!
    var popups = [AGSPopup]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.callout.delegate = self
        //Ask the user which webmap to load : Public or Private?
        let webmapPickerAlertView = UIAlertView(title: "Which web map would you like to open?", message:"", delegate:self, cancelButtonTitle:nil)
        webmapPickerAlertView.addButtonWithTitle("Public")
        webmapPickerAlertView.addButtonWithTitle("Private")
        //Set tag so we know which action this alertview is being shown for
        webmapPickerAlertView.tag = CHOOSE_WEBMAP_TAG
        webmapPickerAlertView.show()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSWebMapDelegagte methods
    
    func webMapDidLoad(webMap: AGSWebMap!) {
        SVProgressHUD.dismiss()
    }
    
    func webMap(webMap: AGSWebMap!, didFailToLoadWithError error: NSError!) {
        
        print("Error while loading webMap: \(error.localizedDescription)")
        // If we have an error loading the webmap due to an invalid or missing credential
        // prompt the user for login information
        if error.ags_isAuthenticationError() {
            let alertView = UIAlertView(title:"Please sign in to access the web map", message:"Tip: use 'AGSSample' and 'agssample'", delegate:self, cancelButtonTitle:"Cancel", otherButtonTitles:"Login")
            alertView.alertViewStyle = UIAlertViewStyle.LoginAndPasswordInput
            //Set tag so we know which action this alertview is being shown for
            alertView.tag = SIGN_IN_WEBMAP_TAG
            alertView.show()
        }
            // For any other error alert the user
        else {
            UIAlertView(title: "Error", message: "Failed to load the webmap", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    func webMap(webMap: AGSWebMap!, didLoadLayer layer: AGSLayer!) {
        SVProgressHUD.dismiss()
    }
    
    func webMap(webMap: AGSWebMap!, didFailToLoadLayer layerInfo: AGSWebMapLayerInfo!, baseLayer: Bool, federated: Bool, withError error: NSError!) {
        print("Error while loading layer: \(error.localizedDescription)")
        
        // If we have an error loading the layer due to an invalid or missing credential
        // prompt the user for login information
        if error.ags_isAuthenticationError() {
            let alertView = UIAlertView(title:"This webmap uses a secure layer '\(layerInfo.title)'. \n Sign in to access the layer", message:"Tip: use 'sdksample' and 'sample@380'", delegate:self, cancelButtonTitle:"Cancel", otherButtonTitles:"Login")
            alertView.alertViewStyle = .LoginAndPasswordInput
            //Set tag so we know which action this alertview is being shown for
            alertView.tag = SIGN_IN_LAYER_TAG
            alertView.show()
        }
            // For any other error alert the user
        else {
            UIAlertView(title: "Error", message: "The layer \(layerInfo.title) cannot be displayed", delegate: nil, cancelButtonTitle: "OK").show()
            
            // and skip loading this layer
            self.webmap.continueOpenAndSkipCurrentLayer()
        }
    }
    
    func bingAppIdForWebMap(webMap: AGSWebMap!) -> String! {
        //this delegate method is called when the webmap contains a Bing Maps basemap layer
        //you should return a valid Bing Maps ID so that the basemap can be displayed.
        return "<your-bingid-goes-here>"
    }
    
    func webMap(webMap: AGSWebMap!, didFetchPopups popups: [AnyObject]!, forExtent extent: AGSEnvelope!) {
        //hold on to the results
        for popup in popups as! [AGSPopup] {
            //disable editing because this sample does not implement any editing functionality.
            //only permit viewing of popups
            popup.allowEdit = false
            popup.allowEditGeometry = false
            popup.allowDelete = false
            self.popups.append(popup)
        }
    }
    
    func webMap(webMap: AGSWebMap!, didFinishFetchingPopupsForExtent extent: AGSEnvelope!) {
        //show the popups
        let pvc = AGSPopupsContainerViewController(popups: self.popups)
        self.presentViewController(pvc, animated:true, completion:nil)
    }
    
    //MARK: - Sign in methods
    
    func signInWebMap(alertView:UIAlertView) {
        
        //Get the credential the user entered
        let username = alertView.textFieldAtIndex(0)?.text
        let password = alertView.textFieldAtIndex(1)?.text
        let credential = AGSCredential(user: username, password: password)
        
        // Recreate the webmap object; this time with the credentials
        self.webmap = AGSWebMap(itemId:self.webmapId, credential:credential)
        // set the delegate
        self.webmap.delegate = self
        // open webmap into mapview
        self.webmap.openIntoMapView(self.mapView)
        
        SVProgressHUD.showWithStatus("Loading")
        
    }
    
    func cancelSignInWebMap() {
        //Tell the user we cant load the private webmap
        //because we don't have a credential to use
        UIAlertView(title: "Failed to load the private webmap", message:"No credentials provided", delegate:nil, cancelButtonTitle:"Ok").show()
    }
    
    func signInLayer(alertView:UIAlertView) {
        //Get the credentials the user entered
        let username = alertView.textFieldAtIndex(0)?.text
        let password = alertView.textFieldAtIndex(1)?.text
        let credential = AGSCredential(user: username, password: password)
        
        // Pass the credential to the webmap so that it can
        // continue to open the layer with the credential
        self.webmap.continueOpenWithCredential(credential)
        
        SVProgressHUD.showWithStatus("Loading")
    }
    
    func cancelSignInLayer() {
        // skip loading this layer
        self.webmap.continueOpenAndSkipCurrentLayer()
    }
    
    //MARK: - AGSCalloutDelegte methods
    
    func didClickAccessoryButtonForCallout(callout:AGSCallout) {
        //fetch popups
        self.webmap.fetchPopupsForExtent(callout.mapLocation.envelope)
        
        //reinitialize the popups array that will hold the results
        self.popups = [AGSPopup]()
    }
    
    
    //MARK: - AGSPopupsContainerDelegate
    func popupsContainerDidFinishViewingPopups(popupsContainer: AGSPopupsContainer!) {
        (popupsContainer as! AGSPopupsContainerViewController).dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //MARK: - UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        // If the user was asked to pick a web map
        if alertView.tag == CHOOSE_WEBMAP_TAG {
            if buttonIndex == 0 {
                //user wants to open public webmap
                self.webmapId = kPublicWebmapId
                SVProgressHUD.showWithStatus("Loading")
            }
            else {
                //user want to open private webmap
                self.webmapId = kPrivateWebmapId
            }
            
            // The private webmap needs to be accessed with these credentials -
            // Username: AGSSample
            // Password: agssample  (note, lowercase)
            
            // Create a webmap using the ID
            self.webmap = AGSWebMap(itemId: self.webmapId, credential:nil)
            
            // Set self as the webmap's delegate so that we get notified
            // if the web map opens successfully or if errors are encounterer
            self.webmap.delegate = self
            
            // Open the webmap
            self.webmap.openIntoMapView(self.mapView)
        }
            // If the user was asked to sign in to access a secured web map
        else if alertView.tag == SIGN_IN_WEBMAP_TAG {
            switch (buttonIndex) {
            case 0:     //cancel button tapped
                self.cancelSignInWebMap()
            default:    //login button tapped
                self.signInWebMap(alertView)
            }
        }
            // If the user was asked to sign in to access a secured layer within the web map
        else if alertView.tag == SIGN_IN_LAYER_TAG {
            switch (buttonIndex) {
            case 0:     //cancel button tapped
                self.cancelSignInLayer()
            default:     //login button tapped
                self.signInLayer(alertView)
            }
        }
    }
}
