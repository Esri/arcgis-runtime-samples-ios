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

class ViewController: UIViewController, AGSWebMapDelegate, AGSCalloutDelegate, AGSMapViewTouchDelegate, AGSPopupsContainerDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    
    var webMap:AGSWebMap!
    var webMapId:String!
    var activityIndicator:UIActivityIndicatorView!
    var popupVC:AGSPopupsContainerViewController!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webMapId = "9ade9e5c9a2042178ec3128d6d922bbf"
        // Create a webmap and open it into the map
        self.webMap = AGSWebMap(itemId: self.webMapId, credential: nil)
        self.webMap.delegate = self
        self.webMap.openIntoMapView(self.mapView)
        
        self.mapView.callout.delegate = self
        self.mapView.touchDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - AGSMapViewTouchDelegate methods
    
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        
        let geometryEngine = AGSGeometryEngine.defaultGeometryEngine()
        let buffer = geometryEngine.bufferGeometry(mappoint, byDistance:(10 * mapView.resolution))
        let willFetch = self.webMap.fetchPopupsForExtent(buffer.envelope)
        if !willFetch {
            print("Sorry, try again")
        }
        else {
            self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
            self.mapView.callout.customView = self.activityIndicator
            self.activityIndicator.startAnimating()
            self.mapView.callout.showCalloutAt(mappoint, screenOffset:CGPointZero, animated:true)
        }
        self.popupVC = nil
    }
    
    //MARK: - AGSCallout methods
    
    func didClickAccessoryButtonForCallout(callout: AGSCallout!) {
        self.presentViewController(self.popupVC, animated:true, completion:nil)
    }
    
    //MARK: - AGSWebMapDelegate methods
    func didOpenWebMap(webMap: AGSWebMap!, intoMapView mapView: AGSMapView!) {
        if !webMap.hasPopupsDefined() {
            UIAlertView(title: "", message: "This webmap does not have any popups", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    func webMap(webMap: AGSWebMap!, didFailToLoadWithError error: NSError!) {
        // If the web map failed to load report an error
        print("Error while loading webMap: \(error.localizedDescription)")
        
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    func didFailToLoadLayer(layerTitle: String!, url: NSURL!, baseLayer: Bool, withError error: NSError!) {
        print("Error while loading webMap: \(error.localizedDescription)")
        
        // If we have an error loading the layer report an error
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "OK").show()
        
        // skip loading this layer
        self.webMap.continueOpenAndSkipCurrentLayer()
    }
    
    func webMap(webMap: AGSWebMap!, didFetchPopups popups: [AnyObject]!, forExtent extent: AGSEnvelope!) {
        // If we've found one or more popups
        if popups.count > 0 {
            
            if self.popupVC == nil {
                //Create a popupsContainer view controller with the popups
                self.popupVC = AGSPopupsContainerViewController(popups: popups, usingNavigationControllerStack: false)
                self.popupVC.style = .Black
                self.popupVC.delegate = self
            }else{
                self.popupVC.showAdditionalPopups(popups)
            }
            
            // For iPad, display popup view controller in the callout
            if AGSDevice.currentDevice().isIPad() {
                self.mapView.callout.customView = self.popupVC.view
                
                //set the modal presentation options for subsequent popup view transitions
                self.popupVC.modalPresenter =  self
                self.popupVC.modalPresentationStyle = .FormSheet
                
                // Start the activity indicator in the upper right corner of the
                // popupsContainer view controller while we wait for the query results
                self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
                let blankButton = UIBarButtonItem(customView: self.activityIndicator)
                self.popupVC.actionButton = blankButton
                self.activityIndicator.startAnimating()
            }
            else {
                //For iphone, display summary info in the callout
                self.mapView.callout.title = "\(self.popupVC.popups.count) Results"
                self.mapView.callout.accessoryButtonHidden = false
                self.mapView.callout.detail = "loading more..."
                self.mapView.callout.customView = nil
            }
            
        }
    }
    
    func webMap(webMap: AGSWebMap!, didFinishFetchingPopupsForExtent extent: AGSEnvelope!) {
        if self.popupVC != nil {
            if AGSDevice.currentDevice().isIPad() {
                self.activityIndicator.stopAnimating()
                self.popupVC.actionButton = self.popupVC.defaultActionButton
            }
            else {
                self.mapView.callout.detail = ""
            }
        }
        else{
            self.activityIndicator.stopAnimating()
            self.mapView.callout.customView = nil
            self.mapView.callout.accessoryButtonHidden = true
            self.mapView.callout.title = "No Results"
            self.mapView.callout.detail = ""
        }
    }
    
    //MARK: - AGSPopupsContainerDelegate methods
    func popupsContainerDidFinishViewingPopups(popupsContainer: AGSPopupsContainer!) {
        //cancel any outstanding requests
        self.webMap.cancelFetchPopups()
        
        // If we are on iPad dismiss the callout
        if AGSDevice.currentDevice().isIPad() {
            self.mapView.callout.hidden = true
        }
        else {
            //dismiss the modal viewcontroller for iPhone
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    
    //MARK: - AGSPopupsContainerDelegate edit methods
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, readyToEditGeometry geometry: AGSGeometry!, forPopup popup: AGSPopup!) {
        
        UIAlertView(title: "Not Implemented", message:"This sample only demonstrates how to display popups. It does not implement editing or deleting features. Please refer to the Feature Layer Editing Sample instead.", delegate:nil, cancelButtonTitle:"OK").show()
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didFinishEditingForPopup popup: AGSPopup!) {
        
        UIAlertView(title: "Not Implemented", message:"This sample only demonstrates how to display popups. It does not implement editing or deleting features. Please refer to the Feature Layer Editing Sample instead.", delegate:nil, cancelButtonTitle:"OK").show()
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, wantsToDeleteForPopup popup: AGSPopup!) {
        
        UIAlertView(title: "Not Implemented", message:"This sample only demonstrates how to display popups. It does not implement editing or deleting features. Please refer to the Feature Layer Editing Sample instead.", delegate:nil, cancelButtonTitle:"OK").show()
        
    }
}
