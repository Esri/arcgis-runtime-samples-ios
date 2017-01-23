//
// Copyright 2016 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class OfflineEditingViewController: UIViewController, AGSGeoViewTouchDelegate, AGSPopupsViewControllerDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var extentView: UIView!
    @IBOutlet var sketchToolbar:UIToolbar!
    @IBOutlet var serviceModeToolbar:UIToolbar!
    @IBOutlet var geodatabaseModeToolbar:UIToolbar!
    @IBOutlet var doneBBI:UIBarButtonItem!
    @IBOutlet var barButtonItem:UIBarButtonItem!
    @IBOutlet var syncBBI:UIBarButtonItem!
    @IBOutlet var instructionsLabel:UILabel!
    @IBOutlet var featureLayersContainerView:UIView!
    
    private var map:AGSMap!
    private var sketchEditor:AGSSketchEditor!
    private let FEATURE_SERVICE_URL = NSURL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
    private var featureTable:AGSServiceFeatureTable!
    private var syncTask:AGSGeodatabaseSyncTask!
    private var generatedGeodatabase:AGSGeodatabase!
    private var generateJob:AGSGenerateGeodatabaseJob!
    private var syncJob:AGSSyncGeodatabaseJob!
    private var popupsVC:AGSPopupsViewController!
    private var featureLayersVC:FeatureLayersViewController!
    
    private var liveMode = true {
        didSet {
            self.updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OfflineEditingViewController", "FeatureLayersViewController"]
        
        //use the san francisco tpk as the basemap
        let tpkPath = NSBundle.mainBundle().pathForResource("SanFrancisco", ofType: "tpk")!
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(fileURL: NSURL(fileURLWithPath: tpkPath)))
        
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        
        //setup extent view
        self.extentView.layer.borderColor = UIColor.redColor().CGColor
        self.extentView.layer.borderWidth = 3
        
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        //initialize sketch editor and assign to map view
        self.sketchEditor = AGSSketchEditor()
        self.mapView.sketchEditor = self.sketchEditor
        
        //initialize sync task
        self.syncTask = AGSGeodatabaseSyncTask(URL: self.FEATURE_SERVICE_URL)
        
        //add online feature layers
        self.addFeatureLayers()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        SVProgressHUD.showWithStatus("Loading", maskType: .Gradient)
        self.mapView.identifyLayersAtScreenPoint(screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResultsPerLayer: 10) { [weak self] (results: [AGSIdentifyLayerResult]?, error: NSError?) -> Void in

            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription)
            }
            else {
                SVProgressHUD.dismiss()
                
                var popups = [AGSPopup]()
                for result in results! {
                    for geoElement in result.geoElements {
                        popups.append(AGSPopup(geoElement: geoElement))
                    }
                }
                if popups.count > 0 {
                    self?.popupsVC = AGSPopupsViewController(popups: popups, containerStyle: .NavigationBar)
                    self?.popupsVC.delegate = self!
                    self?.presentViewController(self!.popupsVC, animated: true, completion: nil)
                }
                else {
                    SVProgressHUD.showInfoWithStatus("No features selected", maskType: .Gradient)
                }
            }
        }
    }
    
    //MARK: - Helper methods
    func addFeatureLayers() {
        
        //Iterate through the layers in the service
        self.syncTask.loadWithCompletion { [weak self] (error) -> Void in
            if let error = error {
                print("Could not load feature service \(error)")
            } else {
                guard let weakSelf = self else {
                    return
                }
                for (index, layerInfo) in weakSelf.syncTask.featureServiceInfo!.layerInfos.enumerate().reverse() {
                    
                    //For each layer in the serice, add a layer to the map
                    let layerURL = weakSelf.FEATURE_SERVICE_URL.URLByAppendingPathComponent(String(index))
                    let featureTable = AGSServiceFeatureTable(URL:layerURL!)
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    featureLayer.name = layerInfo.name
                    weakSelf.map.operationalLayers.addObject(featureLayer)
                }
                
                //enable generate geodatabase bbi
                weakSelf.barButtonItem.enabled = true
            }
        }
    }
    
    
    func frameToExtent() -> AGSEnvelope {
        let frame = self.mapView.convertRect(self.extentView.frame, fromView: self.view)
        
        let minPoint = self.mapView.screenToLocation(frame.origin)
        let maxPoint = self.mapView.screenToLocation(CGPoint(x: frame.origin.x+frame.width, y: frame.origin.y+frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    func updateUI() {
        if self.liveMode {
            self.serviceModeToolbar.hidden = false
            self.instructionsLabel.hidden = true
            self.barButtonItem.title = "Generate geodatabase"
        }
        else {
            self.serviceModeToolbar.hidden = true
            self.updateLabelWithEdits()
        }
    }
    
    func updateLabelWithEdits() {
        let dispatchGroup = dispatch_group_create()
        var totalCount = 0
        
        for featureTable in self.generatedGeodatabase.geodatabaseFeatureTables {
            if featureTable.loadStatus == .Loaded {
                
                dispatch_group_enter(dispatchGroup)
                featureTable.addedFeaturesCountWithCompletion({ (count: Int, error: NSError?) in
                    totalCount = totalCount + count
                    dispatch_group_leave(dispatchGroup)
                })
                
                dispatch_group_enter(dispatchGroup)
                featureTable.updatedFeaturesCountWithCompletion({ (count: Int, error: NSError?) in
                    totalCount = totalCount + count
                    dispatch_group_leave(dispatchGroup)
                })
                
                dispatch_group_enter(dispatchGroup)
                featureTable.deletedFeaturesCountWithCompletion({ (count: Int, error: NSError?) in
                    totalCount = totalCount + count
                    dispatch_group_leave(dispatchGroup)
                })
            }
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { [weak self] in
            self?.syncBBI?.enabled = totalCount > 0
            self?.instructionsLabel?.text = "Data from geodatabase : \(totalCount) edits"
        }
    }
    
    func switchToServiceMode() {
        //unregister geodatabase
        self.syncTask.unregisterGeodatabase(self.generatedGeodatabase) { (error: NSError?) -> Void in
            if let error = error {
                print("Error while unregistering geodatabase :: \(error.localizedDescription)")
            }
        }
        
        //remove all layers added from the geodatabase
        self.mapView.map?.operationalLayers.removeAllObjects()
        
        //add layers from the service
        self.addFeatureLayers()
        
        //update the flag
        self.liveMode = true
        
        self.generatedGeodatabase = nil
        
        //delete exisiting geodatabases
        self.deleteAllGeodatabases()
    }
    
    private func deleteAllGeodatabases() {
        //Remove all files with .geodatabase, .geodatabase-shm and .geodatabase-wal file extensions
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        do {
            let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
            for file in files {
                let remove = file.hasSuffix(".geodatabase") || file.hasSuffix(".geodatabase-shm") || file.hasSuffix(".geodatabase-wal")
                if remove {
                    try NSFileManager.defaultManager().removeItemAtPath((path as NSString).stringByAppendingPathComponent(file))
                    print("deleting file: \(file)")
                }
            }
            print("deleted all local data")
        }
        catch {
            print(error)
        }
    }
    
    func sketchChanged(notification:NSNotification) {
        //Check if the sketch geometry is valid to decide whether to enable
        //the done bar button item
        if let geometry = self.mapView.sketchEditor?.geometry where !geometry.empty {
            self.doneBBI.enabled = true
        }
    }
    
    private func disableSketchEditor() {
        self.mapView.sketchEditor?.stop()
        self.mapView.sketchEditor?.clearGeometry()
        self.sketchToolbar.hidden = true
    }
    
    func displayLayersFromGeodatabase() {
        self.generatedGeodatabase.loadWithCompletion({ [weak self] (error:NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                self?.liveMode = false
                
                self?.map.operationalLayers.removeAllObjects()
                
                AGSLoadObjects(self!.generatedGeodatabase.geodatabaseFeatureTables, { (success: Bool) in
                    if success {
                        for featureTable in self!.generatedGeodatabase.geodatabaseFeatureTables.reverse() {
                            //check if feature table has geometry
                            if featureTable.hasGeometry {
                                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                                self?.map.operationalLayers.addObject(featureLayer)
                            }
                        }
                        SVProgressHUD.showInfoWithStatus("Now showing layers from the geodatabase")
                    }
                })
            }
        })
    }
    
    //MARK: - Actions
    
    @IBAction func generateGeodatabaseAction() {
        if self.barButtonItem.title! == "Generate geodatabase" {
            //show the instructions label and update the text
            self.instructionsLabel.hidden = false
            self.instructionsLabel.text = "Choose an extent by keeping the desired area within the shown block"
            
            //show the extent view
            self.extentView.hidden = false
            
            //update to done button
            self.barButtonItem.title = "Done"
        }
        else if self.barButtonItem.title! == "Done" {
            //hide extent view
            self.extentView.hidden = true
            
            //update the instructions label
            self.instructionsLabel.text = "Select the feature layers to be included"
            
            //show options to pick layers
            self.featureLayersContainerView.hidden = false
            
            //update to download button
            self.barButtonItem.title = "Download"
            
            self.featureLayersVC?.featureLayerInfos = self.syncTask.featureServiceInfo!.layerInfos
        }
        else {
            //get selected layer ids
            let selectedLayerIds = self.featureLayersVC.selectedLayerIds
            
            if selectedLayerIds.count == 0 {
                SVProgressHUD.showErrorWithStatus("Please select at least one layer", maskType: .Gradient)
                return
            }
            
            //hide featureLayersVC
            self.featureLayersContainerView.hidden = true
            
            //generate a geodatabase
            self.generateGeodatabase(selectedLayerIds, extent: self.frameToExtent())
        }
    }
    
    func generateGeodatabase(layerIDs:[Int], extent:AGSEnvelope) {
        //create AGSGenerateLayerOption objects with selected layerIds
        var layerOptions = [AGSGenerateLayerOption]()
        for layerID in layerIDs {
            let layerOption = AGSGenerateLayerOption(layerID: layerID)
            layerOptions.append(layerOption)
        }
        
        //parameters
        let params = AGSGenerateGeodatabaseParameters()
        params.extent = extent
        params.layerOptions = layerOptions
        params.returnAttachments = true
        params.attachmentSyncDirection = .Bidirectional
        
        //name for the geodatabase
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fullPath = "\(path)/\(dateFormatter.stringFromDate(NSDate())).geodatabase"
            
        //create a generate job from the sync task
        self.generateJob = self.syncTask.generateJobWithParameters(params, downloadFileURL: NSURL(string: fullPath)!)
        
        //start the job
        self.generateJob.startWithStatusHandler({ (status: AGSJobStatus) -> Void in
            SVProgressHUD.showWithStatus(status.statusString(), maskType: .Gradient)
            
        }) { [weak self] (object: AnyObject?, error: NSError?) -> Void in
            
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription)
            }
            else {
                SVProgressHUD.dismiss()
                //save a reference to the geodatabase
                self?.generatedGeodatabase = object as! AGSGeodatabase
                //add the layers from geodatabase
                self?.displayLayersFromGeodatabase()
            }
        }
    }
    
    @IBAction func switchToServiceMode(sender:AnyObject) {
        if self.generatedGeodatabase.hasLocalEdits() {
            let yesAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { [weak self] (action:UIAlertAction) -> Void in
                self?.syncAction({ () -> Void in
                    self?.switchToServiceMode()
                })
            })
            let noAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: { [weak self] (action: UIAlertAction) -> Void in
                self?.switchToServiceMode()
            })
            
            let alert = UIAlertController(title: nil, message: "Would you like to sync the changes before switching?", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(noAction)
            alert.addAction(yesAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            self.switchToServiceMode()
        }
    }
    
    
    @IBAction func syncAction() {
        self.syncAction(nil)
    }
    
    func syncAction(completion: (() -> Void)?) {
        if !self.generatedGeodatabase.hasLocalEdits() {
            SVProgressHUD.showInfoWithStatus("No local edits", maskType: .Gradient)
            return
        }
        
        var syncLayerOptions = [AGSSyncLayerOption]()
        for layerInfo in self.syncTask.featureServiceInfo!.layerInfos {
            let layerOption = AGSSyncLayerOption(layerID: layerInfo.ID, syncDirection: .Bidirectional)
            syncLayerOptions.append(layerOption)
        }
        
        let params = AGSSyncGeodatabaseParameters()
        params.layerOptions = syncLayerOptions
        
        self.syncJob = self.syncTask.syncJobWithParameters(params, geodatabase: self.generatedGeodatabase)
        self.syncJob.startWithStatusHandler({ (status: AGSJobStatus) -> Void in
            
            SVProgressHUD.showWithStatus(status.statusString(), maskType: .Gradient)
            
        }, completion: { (results: [AGSSyncLayerResult]?, error: NSError?) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription)
            }
            else {
                //TODO: use the results object
                SVProgressHUD.dismiss()
                self.updateUI()
            }
            
            //call completion
            completion?()
        })
        
    }
    
    @IBAction func sketchDoneAction() {
        self.navigationItem.hidesBackButton = false
        self.navigationItem.rightBarButtonItem?.enabled = true
        self.presentViewController(self.popupsVC, animated:true, completion:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: - AGSPopupsViewControllerDelegate

    func popupsViewController(popupsViewController: AGSPopupsViewController, sketchEditorForPopup popup: AGSPopup) -> AGSSketchEditor? {
        
        
        if let geometry = popup.geoElement.geometry {
            
            //start sketch editor
            self.mapView.sketchEditor?.startWithGeometry(geometry)
            
            //zoom to the existing feature's geometry
            self.mapView.setViewpointGeometry(geometry.extent, padding: 10, completion: nil)
        }
        
        return self.sketchEditor
    }
    
    func popupsViewController(popupsViewController: AGSPopupsViewController, readyToEditGeometryWithSketchEditor sketchEditor: AGSSketchEditor?, forPopup popup: AGSPopup) {
        
        //Dismiss the popup view controller
        self.dismissViewControllerAnimated(true, completion: nil)
        
        //Prepare the current view controller for sketch mode
        self.mapView.callout.hidden = true
        
        //TODO: Hide the feature
        
        //hide the back button
        self.navigationItem.hidesBackButton = true
        //disable the code button
        self.navigationItem.rightBarButtonItem?.enabled = false
        //unhide the sketchToolbar
        self.sketchToolbar.hidden = false
        //disable the done button until any geometry changes
        self.doneBBI.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OfflineEditingViewController.sketchChanged(_:)), name: AGSSketchEditorGeometryDidChangeNotification, object: nil)
    }
    
    func popupsViewController(popupsViewController: AGSPopupsViewController, didFinishEditingForPopup popup: AGSPopup) {
        
        self.disableSketchEditor()
        
        let feature = popup.geoElement as! AGSFeature
        // simplify the geometry, this will take care of self intersecting polygons and
        feature.geometry = AGSGeometryEngine.simplifyGeometry(feature.geometry!)
        //normalize the geometry, this will take care of geometries that extend beyone the dateline
        //(ifwraparound was enabled on the map)
        feature.geometry = AGSGeometryEngine.normalizeCentralMeridianOfGeometry(feature.geometry!)
        
        
        //sync changes if in service mode
        if self.liveMode {
            
            //Tell the user edits are being saved int the background
            SVProgressHUD.showWithStatus("Saving feature details...", maskType: .Gradient)
            
            (feature.featureTable as! AGSServiceFeatureTable).applyEditsWithCompletion { (featureEditResult: [AGSFeatureEditResult]?, error: NSError?) -> Void in
                
                if let error = error {
                    SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                }
                else {
                    SVProgressHUD.showSuccessWithStatus("Edits applied successfully")
                }
            }
        }
        else {
            //update edit count and enable/disable sync button otherwise
            self.updateUI()
        }
    }
    
    func popupsViewController(popupsViewController: AGSPopupsViewController, didCancelEditingForPopup popup: AGSPopup) {
        
        self.disableSketchEditor()
    }
    
    func popupsViewControllerDidFinishViewingPopups(popupsViewController: AGSPopupsViewController) {
        //dismiss the popups view controller
        self.dismissViewControllerAnimated(true, completion:nil)
        self.popupsVC = nil
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FeatureLayersVCSegue" {
            self.featureLayersVC = segue.destinationViewController as! FeatureLayersViewController
        }
    }
}


