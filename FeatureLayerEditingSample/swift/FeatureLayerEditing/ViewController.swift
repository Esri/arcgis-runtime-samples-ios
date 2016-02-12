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

class ViewController: UIViewController, AGSMapViewLayerDelegate, AGSMapViewTouchDelegate, AGSCalloutDelegate, AGSWebMapDelegate, AGSFeatureLayerEditingDelegate, FeatureTemplateDelegate, AGSPopupsContainerDelegate, AGSAttachmentManagerDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    var webmap:AGSWebMap!
    var activeFeatureLayer:AGSFeatureLayer!
    var popupVC:AGSPopupsContainerViewController!
    var sketchLayer:AGSSketchGraphicsLayer!
    var featureTemplatePickerController:FeatureTemplatePickerController!
    @IBOutlet weak var bannerView:UIView!
    var pickTemplateButton:UIBarButtonItem!
    var sketchCompleteButton:UIBarButtonItem!
    var newFeature:AGSGraphic!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the navigation bar buttons
        self.pickTemplateButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "presentFeatureTemplatePicker")
        self.sketchCompleteButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "sketchComplete")
        
        //Display the pickTemplateButton initially so that user can start collecting a new feature
        self.navigationItem.rightBarButtonItem = self.pickTemplateButton
        
        //Set up the map view
        self.mapView.layerDelegate = self
        self.mapView.touchDelegate = self
        self.mapView.callout.delegate = self
        self.mapView.showMagnifierOnTapAndHold = true
        
        self.webmap = AGSWebMap(itemId: "b31153c71c6c429a8b24c1751a50d3ad", credential:nil)
        //designate a delegate to be notified as web map is opened
        self.webmap.delegate = self
        self.webmap.openIntoMapView(self.mapView)
        
        //Initialize the template picker view controller
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        self.featureTemplatePickerController = storyboard.instantiateViewControllerWithIdentifier("FeatureTemplatePickerController") as! FeatureTemplatePickerController
        self.featureTemplatePickerController.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSWebMapDelegate methods
    
    func webMap(webMap: AGSWebMap!, didLoadLayer layer: AGSLayer!) {
        
        //The last feature layer we encounter we will use for editing features
        //If the web map contains more than one feature layer, the sample may need to be modified to handle that
        if layer is AGSFeatureLayer {
            let featureLayer = layer as! AGSFeatureLayer
            self.activeFeatureLayer = featureLayer
            
            //set the feature layer as its calloutDelegate
            //this will then automatically set the callout's title to a value
            //from the display field of the feature service
            featureLayer.calloutDelegate = featureLayer
            
            //Get all the fields
            featureLayer.outFields = ["*"]
            
            //This view controller should be notified when features are edited
            featureLayer.editingDelegate = self
            
            //Add templates from this layer to the Feature Template Picker
            self.featureTemplatePickerController.addTemplatesFromLayer(self.activeFeatureLayer)
        }
    }
    
    func didOpenWebMap(webMap: AGSWebMap!, intoMapView mapView: AGSMapView!) {
        //Once all the layers in the web map are loaded
        //we will add a dormant sketch layer on top. We will activate the sketch layer when the time is right.
        self.sketchLayer = AGSSketchGraphicsLayer()
        self.mapView.addMapLayer(self.sketchLayer, withName:"Sketch Layer")
        //register self for receiving notifications from the sketch layer
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "respondToGeomChanged:", name: AGSSketchGraphicsLayerGeometryDidChangeNotification, object:nil)
    }
    
    func webMap(webMap: AGSWebMap!, didFailToLoadLayer layerInfo: AGSWebMapLayerInfo!, baseLayer: Bool, federated: Bool, withError error: NSError!) {
        print("Failed to load layer : \(layerInfo.title)")
        print("Sample may not work at expected")
        
        //continue anyway
        self.webmap.continueOpenAndSkipCurrentLayer()
    }
    
    //MARK: - AGSSketchGraphicsLayer notifications
    func respondToGeomChanged(notification:NSNotification) {
        //Check if the sketch geometry is valid to decide whether to enable
        //the sketchCompleteButton
        if self.sketchLayer.geometry != nil && self.sketchLayer.geometry.isValid() && !self.sketchLayer.geometry.isEmpty() {
            self.sketchCompleteButton.enabled = true
        }
    }
    
    
    //MARK: - FeatureTemplatePickerDelegate methods
    
    func featureTemplatePickerViewControllerWasDismissed(controller: FeatureTemplatePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func featureTemplatePickerViewController(controller: FeatureTemplatePickerController, didSelectFeatureTemplate template: AGSFeatureTemplate, forFeatureLayer featureLayer: AGSFeatureLayer) {
        
        //create a new feature based on the template
        self.newFeature = self.activeFeatureLayer.featureWithTemplate(template)
        
        //Add the new feature to the feature layer's graphic collection
        //This is important because then the popup view controller will be able to
        //find the feature layer associated with the graphic and inspect the field metadata
        //such as domains, subtypes, data type, length, etc
        //Also note, if the user cancels before saving the new feature to the server,
        //we will manually need to remove this
        //feature from the feature layer (see implementation for popupsContainer:didCancelEditingGraphicForPopup: below)
        self.activeFeatureLayer.addGraphic(self.newFeature)
        
        //Iniitalize a popup view controller
        self.popupVC = AGSPopupsContainerViewController(webMap: self.webmap, forFeature: self.newFeature, usingNavigationControllerStack: false)
        self.popupVC.delegate = self
        
        //Only for iPad, set presentation style to Form sheet
        //We don't want it to cover the entire screen
        self.popupVC.modalPresentationStyle = .FormSheet
        
        //Animate by flipping horizontally
        self.popupVC.modalTransitionStyle = .FlipHorizontal
        
        //First, dismiss the Feature Template Picker
        self.dismissViewControllerAnimated(false, completion:nil)
        
        //Next, Present the popup view controller
        self.presentViewController(self.popupVC, animated: true) { () -> Void in
            self.popupVC.startEditingCurrentPopup()
        }
        
    }
    
    //MARK: - AGSCalloutDelegate methods
    
    func didClickAccessoryButtonForCallout(callout: AGSCallout!) {
        let graphic = callout.representedObject as! AGSGraphic
        self.activeFeatureLayer = graphic.layer as! AGSFeatureLayer
        
        //Show popup for the graphic because the user tapped on the callout accessory button
        self.popupVC = AGSPopupsContainerViewController(webMap: self.webmap, forFeature: graphic, usingNavigationControllerStack: false)
        self.popupVC.delegate = self
        self.popupVC.modalTransitionStyle = .FlipHorizontal
        
        //If iPad, use a modal presentation style
        self.popupVC.modalPresentationStyle = .FormSheet
        self.presentViewController(self.popupVC, animated:true, completion:nil)
    }
    
    
    //MARK: -  AGSPopupsContainerDelegate methods
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, wantsNewMutableGeometryForPopup popup: AGSPopup!) -> AGSGeometry! {
        //Return an empty mutable geometry of the type that our feature layer uses
        return AGSMutableGeometryFromType((popup.graphic.layer as! AGSFeatureLayer).geometryType, self.mapView.spatialReference)
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, readyToEditGeometry geometry: AGSGeometry!, forPopup popup: AGSPopup!) {
        //Dismiss the popup view controller
        self.dismissViewControllerAnimated(true, completion:nil)
        
        //Prepare the current view controller for sketch mode
        self.bannerView.hidden = false
        self.mapView.touchDelegate = self.sketchLayer //activate the sketch layer
        self.mapView.callout.hidden = true
        
        //Dont show callout when the sketch layer is active.
        //The user is sketching and even if he taps on a feature,
        //we don't want to display the callout and interfere with the sketching workflow
        self.mapView.allowCallout = false
        
        //Assign the sketch layer the geometry that is being passed to us for
        //the active popup's graphic. This is the starting point of the sketch
        self.sketchLayer.geometry = geometry
        
        
        //zoom to the existing feature's geometry
        var env:AGSEnvelope!
        
        let geoType = AGSGeometryTypeForGeometry(self.sketchLayer.geometry)
        if geoType == .Polygon {
            env = self.sketchLayer.geometry.envelope
        }
        else if geoType == .Polyline {
            env = self.sketchLayer.geometry.envelope
        }
        
        if env != nil {
            let mutableEnv  = env.mutableCopy() as! AGSMutableEnvelope
            mutableEnv.expandByFactor(1.4)
            self.mapView.zoomToEnvelope(mutableEnv, animated:true)
        }
        
        //replace the button in the navigation bar to allow a user to
        //indicate that the sketch is done
        self.navigationItem.rightBarButtonItem = self.sketchCompleteButton
        self.sketchCompleteButton.enabled = false
        //hide the back button
        self.navigationItem.hidesBackButton = true
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, wantsToDeleteForPopup popup: AGSPopup!) {
        //Call method on feature layer to delete the feature
        let number = self.activeFeatureLayer.objectIdForFeature(popup.graphic)
        let oids = [NSNumber(longLong: number)]
        self.activeFeatureLayer.deleteFeaturesWithObjectIds(oids)
        SVProgressHUD.showWithStatus("Deleting feature...")
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didFinishEditingForPopup popup: AGSPopup!) {
        // simplify the geometry, this will take care of self intersecting polygons and
        popup.graphic.geometry = AGSGeometryEngine.defaultGeometryEngine().simplifyGeometry(popup.graphic.geometry)
        //normalize the geometry, this will take care of geometries that extend beyone the dateline
        //(ifwraparound was enabled on the map)
        popup.graphic.geometry = AGSGeometryEngine.defaultGeometryEngine().normalizeCentralMeridianOfGeometry(popup.graphic.geometry)
        
        let oid = self.activeFeatureLayer.objectIdForFeature(popup.graphic)
        
        if oid > 0 {
            //feature has a valid objectid, this means it exists on the server
            //and we simply update the exisiting feature
            self.activeFeatureLayer.updateFeatures([popup.graphic])
        }
        else {
            //objectid does not exist, this means we need to add it as a new feature
            self.activeFeatureLayer.addFeatures([popup.graphic])
        }
        
        //Tell the user edits are being saved int the background
        SVProgressHUD.showWithStatus("Saving feature details...")
        
        //we will wait to post attachments till when the updates succeed
    }
    
    func popupsContainerDidFinishViewingPopups(popupsContainer: AGSPopupsContainer!) {
        //dismiss the popups view controller
        self.dismissViewControllerAnimated(true, completion:nil)
        self.popupVC = nil
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didCancelEditingForPopup popup: AGSPopup!) {
        //dismiss the popups view controller
        self.dismissViewControllerAnimated(true, completion:nil)
        
        //if we had begun adding a new feature, remove it from the layer because the user hit cancel.
        if self.newFeature != nil {
            self.activeFeatureLayer.removeGraphic(self.newFeature)
            self.newFeature = nil
        }
        
        //reset any sketch related changes we made to our main view controller
        self.sketchLayer.clear()
        self.mapView.touchDelegate = self
        self.mapView.callout.delegate = self
        self.bannerView.hidden = true
        self.popupVC = nil
    }
    
    //MARK: -
    
    func warnUserOfErrorWithMessage(message:String) {
        //Display an alert to the user
        UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "OK").show()
        
        //Restart editing the popup so that the user can attempt to save again
        self.popupVC.startEditingCurrentPopup()
    }
    
    //MARK: - AGSFeatureLayerEditingDelegate methods
    
    func featureLayer(featureLayer: AGSFeatureLayer!, operation op: NSOperation!, didFeatureEditsWithResults editResults: AGSFeatureLayerEditResults!) {
        
        //Remove the activity indicator
        SVProgressHUD.dismiss()
        
        //We will assume we have to update the attachments unless
        //1) We were adding a feature and it failed
        //2) We were updating a feature and it failed
        //3) We were deleting a feature
        var updateAttachments = true
        
        if editResults.addResults != nil && editResults.addResults.count > 0 {
            //we were adding a new feature
            let result = editResults.addResults[0] as! AGSEditResult
            if !result.success {
                //Add operation failed. We will not update attachments
                updateAttachments = false
                //Inform user
                self.warnUserOfErrorWithMessage("Could not add feature. Please try again")
            }
        }
        else if editResults.updateResults != nil && editResults.updateResults.count > 0 {
            //we were updating a feature
            let result = editResults.updateResults[0] as! AGSEditResult
            if !result.success {
                //Update operation failed. We will not update attachments
                updateAttachments = false
                //Inform user
                self.warnUserOfErrorWithMessage("Could not update feature. Please try again")
            }
        }
        else if editResults.deleteResults != nil && editResults.deleteResults.count > 0 {
            //we were deleting a feature
            updateAttachments = false
            let result = editResults.deleteResults[0] as! AGSEditResult
            if !result.success {
                //Delete operation failed. Inform user
                self.warnUserOfErrorWithMessage("Could not delete feature. Please try again")
            }
            else {
                //Delete operation succeeded
                //Dismiss the popup view controller and hide the callout which may have been shown for
                //the deleted feature.
                self.mapView.callout.hidden = true
                self.dismissViewControllerAnimated(true, completion:nil)
                self.popupVC = nil
            }
        }
        
        //if edits pertaining to the feature were successful...
        if updateAttachments {
            self.sketchLayer.clear()
            
            //...we post edits to the attachments
            let attMgr = featureLayer.attachmentManagerForFeature(self.popupVC.currentPopup.graphic)
            attMgr.delegate = self
            
            if attMgr.hasLocalEdits() {
                attMgr.postLocalEditsToServer()
                SVProgressHUD.showWithStatus("Saving feature attachments...")
            }
        }
    }
    
    func featureLayer(featureLayer: AGSFeatureLayer!, operation op: NSOperation!, didFailFeatureEditsWithError error: NSError!) {
        print("Could not commit edits because: \(error.localizedDescription)")
        
        SVProgressHUD.dismiss()
        self.warnUserOfErrorWithMessage("Could not save edits. Please try again")
    }
    
    //MARK: - AGSAttachmentManagerDelegate
    
    func attachmentManager(attachmentManager: AGSAttachmentManager!, didPostLocalEditsToServer attachmentsPosted: [AnyObject]!) {
        SVProgressHUD.dismiss()
        
        //loop through all attachments looking for failures
        var anyFailure = false
        
        for attachment in attachmentsPosted as! [AGSAttachment] {
            if attachment.networkError != nil || attachment.editResultError != nil {
                anyFailure = true
                var reason:String!
                if attachment.networkError != nil {
                    reason = attachment.networkError.localizedDescription
                }
                else if attachment.editResultError != nil {
                    reason = attachment.editResultError.errorDescription
                }
                print("Attachment \(attachment.attachmentInfo.name) could not be synced with server because \(reason)")
            }
        }
        
        if anyFailure {
            self.warnUserOfErrorWithMessage("Some attachment edits could not be synced with the server. Please try again")
        }
    }
    
    //MARK: - actions
    
    func presentFeatureTemplatePicker() {
        self.featureTemplatePickerController.modalPresentationStyle = .FormSheet
        
        self.presentViewController(self.featureTemplatePickerController, animated: true, completion: nil)
    }
    
    func sketchComplete() {
        self.navigationItem.hidesBackButton = false
        self.navigationItem.rightBarButtonItem = self.pickTemplateButton
        self.presentViewController(self.popupVC, animated:true, completion:nil)
        self.mapView.touchDelegate = self
        self.bannerView.hidden = true
        self.mapView.allowCallout = true
    }
}


