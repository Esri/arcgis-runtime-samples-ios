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

import Foundation
import UIKit
import ArcGIS

let kTilePackageName = "SanFrancisco"
let kFeatureServiceURL = "http://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer"

class ViewController:UIViewController, AGSLayerDelegate, AGSMapViewTouchDelegate, AGSMapViewLayerDelegate, AGSCalloutDelegate, FeatureTemplatePickerDelegate, AGSPopupsContainerDelegate {
    
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var geometryEditToolbar: UIToolbar!
    @IBOutlet weak var liveActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var offlineStatusLabel: UILabel!
    @IBOutlet weak var logsLabel: UILabel!
    @IBOutlet weak var logsTextView: UITextView!
    @IBOutlet weak var goOfflineButton: UIBarButtonItem!
    @IBOutlet weak var syncButton: UIBarButtonItem!
    @IBOutlet weak var badgeView: UIView!
    
    var badge:JSBadgeView!
    var geodatabase:AGSGDBGeodatabase!
    var gdbTask:AGSGDBSyncTask!
    var cancellable:AGSCancellable!
    var localTiledLayer:AGSLocalTiledLayer!
    var featureTemplatePickerVC:FeatureTemplatePickerViewController!
    var popupsVC:AGSPopupsContainerViewController!
    var sketchGraphicsLayer:AGSSketchGraphicsLayer!
    
    var goingLocal = false
    var goingLive = false
    var viewingLocal = false
    var newlyDownloaded = false
    
    var allStatus:String = ""
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //        self.navigationController.navigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add the basemap layer from a tile package
        self.localTiledLayer = AGSLocalTiledLayer(name: kTilePackageName)
        
        //Add layer delegate to catch errors in case the local tiled layer is replaced and problems arise
        self.localTiledLayer.delegate = self
        
        //setup the map view
        self.mapView.addMapLayer(self.localTiledLayer)
        self.mapView.touchDelegate = self
        self.mapView.layerDelegate = self
        self.mapView.callout.delegate = self
        
        //Add a swipe gesture recognizer that will show the logs text view
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "showLogsGesture:")
        swipeGestureRecognizer.direction = .Up
        self.logsLabel.addGestureRecognizer(swipeGestureRecognizer)
        
        //Add a tap gesture recognizer that will hide the logs text view
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "hideLogsGesture:")
        self.logsTextView.addGestureRecognizer(tapGestureRecognizer)
        
        self.switchToLiveData()
    }
    
    //MARK: - Gesture recognizers
    
    func hideLogsGesture(gestureRecognizer:UIGestureRecognizer) {
        self.logsTextView.hidden = true
    }
    
    func showLogsGesture(gestureRecognizer:UIGestureRecognizer) {
        self.logsTextView.hidden = false
        print("textview text \(self.logsTextView.text)")
    }
    
    //MARK: - AGSLayerDelegate methods
    
    func layerDidLoad(layer: AGSLayer!) {
        if layer is AGSFeatureTableLayer {
            let featureTableLayer = layer as! AGSFeatureTableLayer
            if self.mapView.mapScale > featureTableLayer.minScale {
                self.mapView.zoomToScale(featureTableLayer.minScale, animated: true)
            }
            SVProgressHUD.popActivity()
        }
    }
    
    func layer(layer: AGSLayer!, didFailToLoadWithError error: NSError!) {
        var errormsg:String!
        if layer is AGSFeatureTableLayer {
            let featureTableLayer = layer as! AGSFeatureTableLayer
            errormsg = "Failed to load \(featureTableLayer.name). Error: \(error)"
            
            //activity shown when loading online layer, dismiss this
            SVProgressHUD.popActivity()
        }
        else if layer is AGSLocalTiledLayer {
            errormsg = "Failed to load local tiled layer. Error:\(error)"
        }
        self.logStatus(errormsg)
    }
    
    //MARK: - AGSMapViewTouchDelegate methods
    
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        
        //Show popups for features that were tapped on
        var tappedFeatures = [AGSFeature]()
        
        for (_, value) in features {
            let graphics = value as! [AGSFeature]
            for graphic in graphics as [AGSFeature] {
                tappedFeatures.append(graphic)
            }
        }
        if tappedFeatures.count > 0 {
            self.showPopupsForFeatures(tappedFeatures)
        }
        else{
            self.hidePopupsVC()
        }
    }
    
    //MARK: - Showing popups
    
    func showPopupsForFeatures(features:[AGSFeature]) {
        
        var popups = [AGSPopup]()
        
        for feature in features as [AGSFeature] {
            
            let gdbFeature = feature as! AGSGDBFeature
            let popupInfo = AGSPopupInfo(forGDBFeatureTable: gdbFeature.table)
            let popup = AGSPopup(GDBFeature: gdbFeature, popupInfo: popupInfo)
            popups.append(popup)
            
        }
        self.showPopupsVCForPopups(popups)
    }
    
    func hidePopupsVC() {
        if self.popupsVC != nil {
            self.popupsVC.dismissViewControllerAnimated(true, completion: {
                self.popupsVC = nil
            })
        }
    }
    
    func showPopupsVCForPopups(popups:[AGSPopup]) {
        self.hidePopupsVC()
        
        //Create the view controller for the popups
        self.popupsVC = AGSPopupsContainerViewController(popups: popups, usingNavigationControllerStack: false)
        self.popupsVC.delegate = self
        self.popupsVC.style = .Black
        
        self.popupsVC.modalPresentationStyle = .FormSheet
        self.presentViewController(self.popupsVC, animated: true, completion: nil)
    }
    
    //MARK: - Action methods
    
    @IBAction func addFeatureAction(sender:AnyObject) {
        
        //Initialize the template picker view controller
        if self.featureTemplatePickerVC == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
            if let controller = storyboard.instantiateViewControllerWithIdentifier("FeatureTemplatePickerViewController") as? FeatureTemplatePickerViewController {
                self.featureTemplatePickerVC = controller
                self.featureTemplatePickerVC.delegate = self
                self.featureTemplatePickerVC.addTemplatesForLayersInMap(self.mapView)
                self.featureTemplatePickerVC.modalPresentationStyle = .FormSheet
            }
            
        }
        
        self.presentViewController(self.featureTemplatePickerVC, animated: true, completion: nil)
    }
    
    @IBAction func deleteGDBAction(sender:AnyObject) {
        if self.viewingLocal || self.goingLocal {
            self.logStatus("cannot delete local data while displaying it")
            return
        }
        self.geodatabase = nil
        
        //Remove all files with .geodatabase, .geodatabase-shm and .geodatabase-wal file extensions
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let path = paths[0]
        do {
            let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
            for file in files {
                let remove = file.hasSuffix(".geodatabase") || file.hasSuffix(".geodatabase-shm") || file.hasSuffix(".geodatabase-wal")
                if remove {
                    try NSFileManager.defaultManager().removeItemAtPath((path as NSString).stringByAppendingPathComponent(file))
                    self.logStatus("deleting file: \(file)")
                }
            }
            self.logStatus("deleted all local data")
        }
        catch {
            print(error)
        }
    }
    
    @IBAction func syncAction() {
        if (self.cancellable != nil) {
            //if already syncing just return
            return
        }
        
        SVProgressHUD.showWithStatus("Synchronizing \n changes")
        self.logStatus("Starting sync process...")
        
        //Create default sync params based on the geodatabase
        //You can modify the param to change sync options (sync direction, included layers, etc)
        let params = AGSGDBSyncParameters(geodatabase: self.geodatabase)
        
        //kick off the sync operation
        self.cancellable = self.gdbTask.syncGeodatabase(self.geodatabase, params: params, status: { [weak self] (status, userInfo) -> Void in
            if let weakSelf = self {
                let statusString = weakSelf.statusMessageForAsyncStatus(status)
                weakSelf.logStatus("sync status: \(statusString)")
            }
            }, completion: { [weak self] (editErrors, syncError) -> Void in
                if let weakSelf = self {
                    weakSelf.cancellable = nil
                    if syncError != nil {
                        weakSelf.logStatus("error sync'ing: \(syncError)")
                        SVProgressHUD.showErrorWithStatus("Error encountered")
                    }
                    else {
                        //TODO: Handle sync edit errors
                        weakSelf.logStatus("sync complete")
                        SVProgressHUD.showSuccessWithStatus("Sync complete")
                        
                        //Remove the local edits badge from the sync button
                        weakSelf.showEditsInGeodatabaseAsBadge(nil)
                    }
                }
        })
    }
    
    @IBAction func switchModeAction(sender:AnyObject) {
        if self.goingLocal {
            return
        }
        
        if self.viewingLocal {
            if self.geodatabase.hasLocalEdits() {
                let alertView = UIAlertView(title: "Local data contains edit", message: "Do you want to sync them with the service?", delegate: nil, cancelButtonTitle: "Later", otherButtonTitles: "Ok")
                alertView.showWithCompletion({ (alertView, buttonIndex) -> Void in
                    if buttonIndex == 0 { //No just switch to live
                        self.switchToLiveData()
                    }
                    else { //Yes, sync instead
                        self.syncAction()
                    }
                })
                return
            }
            else {
                self.switchToLiveData()
            }
        }
        else {
            self.switchToLocalData()
        }
    }
    
    //MARK: - Online/Offline methods
    
    func switchToLiveData() {
        
        SVProgressHUD.showWithStatus("Loading Live Data")
        self.goingLive = true
        self.logStatus("loading live data")
        
        //Clear out the template picker so that we create it again when needed using templates in the live data
        self.featureTemplatePickerVC = nil
        
        self.gdbTask = AGSGDBSyncTask(URL: NSURL(string: kFeatureServiceURL))
        self.gdbTask.loadCompletion = { [weak self] error in
            if let weakSelf = self {
                SVProgressHUD.dismiss()
                if error != nil {
                    weakSelf.logStatus("Error while switching to live data : \(error)")
                    return
                }
                
                //remove all local feature layers
                for layer in weakSelf.mapView.mapLayers {  //tried using the optional chaining in the for loop but getting an error
                    if layer is AGSFeatureTableLayer {
                        weakSelf.mapView.removeMapLayer(layer as! AGSFeatureTableLayer)
                    }
                }
                
                //Add live feature layers
                for info in weakSelf.gdbTask.featureServiceInfo.layerInfos as! [AGSMapServiceLayerInfo] {
                    let url = weakSelf.gdbTask.URL.URLByAppendingPathComponent("\(info.layerId)")
                    
                    let featureServiceTable = AGSGDBFeatureServiceTable(serviceURL: url, credential: weakSelf.gdbTask.credential, spatialReference: weakSelf.mapView.spatialReference)
                    let featureTableLayer = AGSFeatureTableLayer(featureTable: featureServiceTable)
                    featureTableLayer.delegate = weakSelf
                    
                    weakSelf.mapView.addMapLayer(featureTableLayer)
                    weakSelf.logStatus("Loading: \(featureServiceTable.serviceURL.absoluteString)")
                }
                
                weakSelf.logStatus("now in live mode")
                weakSelf.updateStatus()
            }
        }
        
        self.goingLive = false
        self.viewingLocal = false
    }
    
    func switchToLocalData() {
        self.goingLocal = true
        
        //Clear out the template picker so that we create it again when needed using templates in the local data
        self.featureTemplatePickerVC = nil
        
        let params = AGSGDBGenerateParameters(featureServiceInfo: self.gdbTask.featureServiceInfo)
        
        //NOTE: You should typically set this to a smaller envelope covering an area of interest
        //Setting to maxEnvelope here because sample data covers limited area in San Franscisco
        
        params.extent = self.mapView.maxEnvelope
        params.outSpatialReference = self.mapView.spatialReference
        var layers = [UInt]()
        for layerInfo in self.gdbTask.featureServiceInfo.layerInfos as! [AGSMapServiceLayerInfo] {
            layers += [layerInfo.layerId]
        }
        params.layerIDs = layers
        self.newlyDownloaded = false
        SVProgressHUD.showWithStatus("Preparing to \n download")
        self.gdbTask.generateGeodatabaseWithParameters(params, downloadFolderPath: nil, useExisting: true, status: { [weak self] (status, userInfo) -> Void in
            if let weakSelf = self {
                //If we are fetching result, display download progress
                if status == AGSResumableTaskJobStatus.FetchingResult {
                    weakSelf.newlyDownloaded = true
                    let totalBytesDownloaded: AnyObject? = userInfo?["AGSDownloadProgressTotalBytesDownloaded"]
                    let totalBytesExpected: AnyObject? = userInfo?["AGSDownloadProgressTotalBytesExpected"]
                    if totalBytesDownloaded != nil && totalBytesExpected != nil {
                        let dPercentage = Float(totalBytesDownloaded! as! NSNumber)/Float(totalBytesExpected! as! NSNumber)
                        SVProgressHUD.showProgress(dPercentage, status: "Downloading \n features")
                    }
                }
                else {
                    //don't want to log status for "fetching result" state because
                    //status block gets called many times a second when downloading
                    //we only log status for other states here
                    weakSelf.logStatus("Status: \(weakSelf.statusMessageForAsyncStatus(status))")
                }
            }
            }) { [weak self] (geodatabase, error) -> Void in
                if let weakSelf = self {
                    if (error != nil) {
                        //handle the error
                        weakSelf.goingLocal = false
                        weakSelf.viewingLocal = false
                        weakSelf.logStatus("error taking feature layers offline: \(error)")
                        print(error)
                        SVProgressHUD.showErrorWithStatus("Couldn't download features")
                    }
                    else {
                        //take app into offline mode
                        weakSelf.goingLocal = false
                        weakSelf.viewingLocal = true
                        weakSelf.logStatus("now viewing local data")
                        BackgroundHelper.postLocalNotificationIfAppNotActive("Features downloaded.")
                        
                        //remove the live feature layers
                        for layer in weakSelf.mapView.mapLayers as! [AGSLayer] { //check if explicitly assigning AGSLayer affects layer from being AGSFeatureLayer
                            if layer is AGSFeatureTableLayer {
                                weakSelf.mapView.removeMapLayer(layer)
                            }
                        }
                        
                        //Add layers from local database
                        weakSelf.geodatabase = geodatabase
                        for featureTable in geodatabase.featureTables() as! [AGSFeatureTable] {
                            if featureTable.hasGeometry() {
                                weakSelf.mapView.addMapLayer(AGSFeatureTableLayer(featureTable: featureTable))
                            }
                        }
                        
                        if weakSelf.newlyDownloaded {
                            SVProgressHUD.showSuccessWithStatus("Finished \n downloading")
                        }
                        else {
                            
                            SVProgressHUD.dismiss()
                            weakSelf.showEditsInGeodatabaseAsBadge(geodatabase)
                            let alertView = UIAlertView(title: "Found local data", message: "It may contain edits or may be out of date. Do you want to synchronize it with the service?", delegate: nil, cancelButtonTitle: "Later", otherButtonTitles: "Yes")
                            
                            alertView.showWithCompletion({ [weak self] (alertView, buttonIndex) -> Void in
                                if let weakSelf = self {
                                    if buttonIndex == 1 { //Yes, sync
                                        weakSelf.syncAction()
                                    }
                                }
                            })
                        }
                    }
                    
                    weakSelf.updateStatus()
                }
        }
        //
    }
    
    //MARK: - FeatureTemplatePickerViewControllerDelegate methods
    
    func featureTemplatePickerViewController(controller: FeatureTemplatePickerViewController, didSelectFeatureTemplate template: AGSFeatureTemplate, forLayer layer: AGSGDBFeatureSourceInfo) {
        //same for ipad and iphone
        controller.dismissViewControllerAnimated(true, completion: { () -> Void in
            
            //Create new feature with template
            let featureTable = layer as! AGSGDBFeatureTable
            let feature = featureTable.featureWithTemplate(template)
            
            //Create popup for new feature, commence edit mode
            let popupInfo = AGSPopupInfo(forGDBFeatureTable: featureTable)
            let popup = AGSPopup(GDBFeature: feature, popupInfo: popupInfo)
            
            self.showPopupsVCForPopups([popup])
            self.popupsVC.startEditingCurrentPopup()
        })
    }
    
    func featureTemplatePickerViewControllerWasDismissed(controller: FeatureTemplatePickerViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - AGSPopupsContainerDelegate methods
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, wantsNewMutableGeometryForPopup popup: AGSPopup!) -> AGSGeometry! {
        switch popup.gdbFeatureSourceInfo.geometryType {
        case .Point:
            return AGSMutablePoint(spatialReference: self.mapView.spatialReference)
        case .Polygon:
            return AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
        case .Polyline:
            return AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        default:
            return AGSMutablePoint(spatialReference: self.mapView.spatialReference)
        }
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, readyToEditGeometry geometry: AGSGeometry!, forPopup popup: AGSPopup!) {
        if self.sketchGraphicsLayer == nil {
            self.sketchGraphicsLayer = AGSSketchGraphicsLayer(geometry: geometry)
            self.mapView.addMapLayer(self.sketchGraphicsLayer)
            self.mapView.touchDelegate = sketchGraphicsLayer
        }
        else {
            sketchGraphicsLayer.geometry = geometry
        }
        
        //Hide the popupsVC and show editing UI
        self.popupsVC.dismissViewControllerAnimated(true, completion: nil)
        self.toggleGeometryEditUI()
    }
    
    func popupsContainerDidFinishViewingPopups(popupsContainer: AGSPopupsContainer!) {
        //this clears _currentPopups
        self.hidePopupsVC()
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didCancelEditingForPopup popup: AGSPopup!) {
        self.mapView.removeMapLayer(self.sketchGraphicsLayer)
        self.sketchGraphicsLayer = nil
        self.mapView.touchDelegate = self
        self.hidePopupsVC()
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didFinishEditingForPopup popup: AGSPopup!) {
        
        //Remove sketch layer
        self.mapView.removeMapLayer(self.sketchGraphicsLayer)
        self.sketchGraphicsLayer = nil
        self.mapView.touchDelegate = self
        
        //popup vc has already committed edits to the local geodatabase at this point
        
        if self.viewingLocal {
            //if we are in local data mode, show edits as badge over the sync button
            //and wait for the user to explicitly sync changes back up to the service
            self.showEditsInGeodatabaseAsBadge(popup.gdbFeatureTable.geodatabase)
            self.logStatus("feature saved in local geodatabase")
            self.hidePopupsVC()
        }
        else {
            //we are in live data mode, apply edits to the service immediately
            SVProgressHUD.showWithStatus("Applying edit to server...")
            let featureServiceTable = popup.gdbFeatureTable as! AGSGDBFeatureServiceTable
            featureServiceTable.applyFeatureEditsWithCompletion({ [weak self] (featureEditErrors, error) -> Void in
                if let weakSelf = self {
                    SVProgressHUD.dismiss()
                    if error != nil {
                        let alertView = UIAlertView(title: "Error", message: "Could not apply edit to server", delegate: nil, cancelButtonTitle: "OK")
                        alertView.show()
                        weakSelf.logStatus("Error while applying edit: \(error.localizedDescription)")
                    }
                    else {
                        for featureEditError in featureEditErrors as! [AGSGDBFeatureEditError] {
                            weakSelf.logStatus("Edit to feature (OBJECTID = \(featureEditError.objectID) rejected by server because : \(featureEditError.localizedDescription))")
                        }
                        
                        //if the dataset support attachments, apply attachment edits
                        if featureServiceTable.hasAttachments {
                            SVProgressHUD.showWithStatus("Applying attachment edits to server...")
                            
                            featureServiceTable.applyAttachmentEditsWithCompletion({ [weak self] (attachmentEditErrors, error) -> Void in
                                if let weakSelf = self {
                                    SVProgressHUD.dismiss()
                                    
                                    if error != nil {
                                        UIAlertView(title: "Error", message: "Could not apply edit to server", delegate: nil, cancelButtonTitle: "OK").show()
                                        weakSelf.logStatus("Error while applying attachment edit : \(error.localizedDescription)")
                                    }
                                    else {
                                        if attachmentEditErrors != nil {
                                            for attachmentEditError in attachmentEditErrors as! [AGSGDBFeatureEditError] {
                                                weakSelf.logStatus("Edit to attachment (OBJECTID = \(attachmentEditError.attachmentID) rejected by server because : \(attachmentEditError.localizedDescription))")
                                            }
                                        }
                                        
                                        //Dismiss the popups VC, All edits have been applied
                                        weakSelf.hidePopupsVC()
                                    }
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didDeleteForPopup popup: AGSPopup!) {
        //popup vc has already committed edits to the local geodatabase at this point
        
        if self.viewingLocal {
            //if we are in local data mode, show edits as badge over the sync button
            //and wait for the user to explicitly sync changes back up to the service
            self.logStatus("delete succeeded")
            self.showEditsInGeodatabaseAsBadge(popup.gdbFeatureTable.geodatabase)
            self.hidePopupsVC()
        }
        else {
            //we are in live data mode, apply edits to the service immediately
            SVProgressHUD.showWithStatus("Applying edit to server...")
            let featureServiceTable = popup.gdbFeatureTable as! AGSGDBFeatureServiceTable
            featureServiceTable.applyFeatureEditsWithCompletion({ [weak self] (featureEditErrors, error) -> Void in
                if let weakSelf = self {
                    SVProgressHUD.dismiss()
                    if error != nil {
                        let alertView = UIAlertView(title: "Error", message: "Could not apply edit to server", delegate: nil, cancelButtonTitle: "OK")
                        alertView.show()
                        weakSelf.logStatus("Error while applying edit: \(error.localizedDescription)")
                    }
                    else {
                        for featureEditError in featureEditErrors as! [AGSGDBFeatureEditError] {
                            weakSelf.logStatus("Deleting feature (OBJECTID = \(featureEditError.objectID) rejected by server because : \(featureEditError.localizedDescription))")
                        }
                        weakSelf.logStatus("feature deleted in server")
                        weakSelf.hidePopupsVC()
                    }
                }
            })
        }
    }
    
    
    //MARK: - Convenience methods
    
    func numberOfEditsInGeodatabase(geodatabase:AGSGDBGeodatabase) -> Int {
        var total = 0
        for featureTable in geodatabase.featureTables() as! [AGSGDBFeatureTable] {
            total += featureTable.addedFeatures().count + featureTable.deletedFeatures().count + featureTable.updatedFeatures().count
        }
        return total
    }
    
    func logStatus(var status:String) {
        
        dispatch_async(dispatch_get_main_queue(), {
            
            //show basic status
            self.logsLabel.text = status
            
            let hideText = "\nTap to hide..."
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .NoStyle
            dateFormatter.timeStyle = .ShortStyle
            status = "\(dateFormatter.stringFromDate(NSDate())) - \(status)\n\n"
            self.allStatus = status+self.allStatus
            //            println("self.allStatus \(self.allStatus)")
            self.logsTextView.text = hideText + "\n\n" + self.allStatus
            //            println("textview text \(self.logsTextView.text)")
            
            //write to log file
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.logAppStatus(status)
            
            let delay = 2 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue(), {
                self.clearStatus()
            })
        })
    }
    
    func clearStatus() {
        self.logsLabel.text = "swipe up to show activity log"
    }
    
    func updateStatus() {
        
        dispatch_async(dispatch_get_main_queue(), {
            //set status
            if self.goingLocal {
                self.offlineStatusLabel.text = "switching to local data..."
            }
            else if self.goingLive {
                self.offlineStatusLabel.text = "switching to live data..."
            }
            else if self.viewingLocal {
                self.offlineStatusLabel.text = "Local data"
                self.goOfflineButton.title = "switch to live"
            }
            else if !self.viewingLocal {
                self.offlineStatusLabel.text = "Live data"
                self.goOfflineButton.title = "download"
                self.showEditsInGeodatabaseAsBadge(nil)
            }
            
            self.goOfflineButton.enabled = !self.goingLocal && !self.goingLive
            self.syncButton.enabled = self.viewingLocal
        })
    }
    
    func statusMessageForAsyncStatus(status:AGSResumableTaskJobStatus) -> String {
        return AGSResumableTaskJobStatusAsString(status)
    }
    
    func showEditsInGeodatabaseAsBadge(geodatabase:AGSGDBGeodatabase?) {
        if self.badge != nil {
            self.badge.removeFromSuperview()
        }
        if geodatabase != nil && geodatabase!.hasLocalEdits() {
            self.badge = JSBadgeView(parentView: self.badgeView, alignment: .CenterRight)
            self.badge.badgeText = "\(self.numberOfEditsInGeodatabase(geodatabase!))"
        }
    }
    
    //MARK: - Sketch toolbar UI
    
    func toggleGeometryEditUI() {
        self.geometryEditToolbar.hidden = !self.geometryEditToolbar.hidden
    }
    
    @IBAction func cancelEditGeometry(sender:AnyObject) {
        self.doneEditingGeometry()
    }
    
    @IBAction func doneEditingGeometry() {
        if self.sketchGraphicsLayer != nil {
            self.mapView.removeMapLayer(self.sketchGraphicsLayer)
            self.sketchGraphicsLayer = nil
            self.mapView.touchDelegate = self
            self.toggleGeometryEditUI()
            self.presentViewController(self.popupsVC, animated: true, completion: nil)
        }
    }
}