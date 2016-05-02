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

class OfflineEditingViewController: UIViewController, AGSMapViewTouchDelegate, AGSPopupsViewControllerDelegate {
    
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
    private var sketchGraphicsOverlay = AGSSketchGraphicsOverlay()
    private let FEATURE_SERVICE_URL = NSURL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
    private var featureTable:AGSServiceFeatureTable!
    private var syncTask:AGSGeodatabaseSyncTask!
    private var generatedGeodatabase:AGSGeodatabase!
    private var generateJob:AGSGenerateGeodatabaseJob!
    private var syncJob:AGSSyncGeodatabaseJob!
    private var featureServiceInfo:AGSArcGISFeatureServiceInfo!
    private var featureLayerInfos:[AGSArcGISFeatureLayerInfo]!
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
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(path: tpkPath))
        
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        self.addFeatureLayers()
        
        //setup extent view
        self.extentView.layer.borderColor = UIColor.redColor().CGColor
        self.extentView.layer.borderWidth = 3
        
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        self.mapView.graphicsOverlays.addObject(self.sketchGraphicsOverlay)
        
        //initialize sync task
        self.syncTask = AGSGeodatabaseSyncTask(URL: self.FEATURE_SERVICE_URL)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtScreenPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        SVProgressHUD.showWithStatus("Loading", maskType: .Gradient)
        self.mapView.identifyLayersAtScreenPoint(screen, tolerance: 5) { [weak self] (results: [AGSIdentifyLayerResult]?, error: NSError?) -> Void in

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
                    self?.popupsVC = AGSPopupsViewController(popups: popups, usingNavigationControllerStack: false)
                    self?.popupsVC.delegate = self!
                    self?.presentViewController(self!.popupsVC, animated: true, completion: nil)
                }
                else {
                    print("No feature selected")
                }
            }
        }
    }
    
    //MARK: - Helper methods
    
    func addFeatureLayers() {
        self.featureServiceInfo = AGSArcGISFeatureServiceInfo(URL: self.FEATURE_SERVICE_URL)
        self.featureServiceInfo.loadWithCompletion { [weak self] (error) -> Void in
            if let error = error {
                print(error)
            }
            else {
                if let featureLayerInfos = self?.featureServiceInfo.featureLayerInfos {
                    self?.featureLayerInfos = featureLayerInfos
                    for featureLayerInfo in featureLayerInfos {
                        let featureTable = AGSServiceFeatureTable(URL: featureLayerInfo.URL!)
                        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                        self?.map.operationalLayers.addObject(featureLayer)
                    }
                }
            }
            //enable generate geodatabase bbi
            self?.barButtonItem.enabled = true
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
            let count = self.numberOfEditsInGeodatabase(self.generatedGeodatabase)
            self.syncBBI?.enabled = count > 0
            self.instructionsLabel?.text = "Data from geodatabase : \(count) edits"
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
    
    func numberOfEditsInGeodatabase(geodatabase:AGSGeodatabase) -> Int64 {
        var total:Int64 = 0
        for featureTable in geodatabase.geodatabaseFeatureTables {
            if featureTable.loadStatus == .Loaded {
                total += featureTable.addedFeatureCount() + featureTable.deletedFeatureCount() + featureTable.updatedFeatureCount()
            }
        }
        return total
    }
    
    func geometryChanged(notification:NSNotification) {
        //Check if the sketch geometry is valid to decide whether to enable
        //the done bar button item
        if let geometry = self.sketchGraphicsOverlay.geometry where !geometry.empty {
            self.doneBBI.enabled = true
        }
    }
    
    private func clearSketchGraphicsOverlay() {
        self.mapView.touchDelegate = self
        self.sketchGraphicsOverlay.clear()
        self.sketchToolbar.hidden = true
    }
    
    func displayLayersFromGeodatabase(geodatabase:AGSGeodatabase) {
        self.generatedGeodatabase.loadWithCompletion({ [weak self] (error:NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                self?.liveMode = false
                
                self?.map.operationalLayers.removeAllObjects()
                for featureTable in geodatabase.geodatabaseFeatureTables {
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    self?.map.operationalLayers.addObject(featureLayer)
                }
                
                SVProgressHUD.showInfoWithStatus("Now showing layers from the geodatabase")
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
            
            self.featureLayersVC?.featureLayerInfos = self.featureLayerInfos
        }
        else {
            //get selected layer ids
            let selectedLayerIds = self.featureLayersVC.selectedLayerIds
            
            if selectedLayerIds.count == 0 {
                UIAlertView(title: "Error", message: "Please select at least one layer", delegate: nil, cancelButtonTitle: "Ok").show()
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
        
        //name for the geodatabase
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        //create a generate job from the sync task
        self.generateJob = self.syncTask.generateJobWithParameters(params, downloadFilePath: dateFormatter.stringFromDate(NSDate()))
        
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
                //add te
                self?.displayLayersFromGeodatabase(object as! AGSGeodatabase)
            }
        }
    }
    
    @IBAction func switchToServiceMode(sender:AnyObject) {
        let count = self.numberOfEditsInGeodatabase(self.generatedGeodatabase)
        if count > 0 {
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
            UIAlertView(title: "Info", message: "No local edits", delegate: nil, cancelButtonTitle: "Ok").show()
            return
        }
        
        var syncLayerOptions = [AGSSyncLayerOption]()
        for layerInfo in self.featureLayerInfos {
            let layerOption = AGSSyncLayerOption(layerID: layerInfo.serviceLayerID, syncDirection: .Bidirectional)
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
    
    func popupsViewController(popupsViewController: AGSPopupsViewController, wantsNewGeometryBuilderForPopup popup: AGSPopup) -> AGSGeometryBuilder {
        //Return an empty mutable geometry of the type that our feature layer uses
        return AGSGeometryBuilder(geometryType: popup.geoElement.geometry!.geometryType, spatialReference: self.map.spatialReference)
    }
    
    func popupsViewController(popupsViewController: AGSPopupsViewController, readyToEditGeometryWithBuilder geometryBuilder: AGSGeometryBuilder, forPopup popup: AGSPopup) {
        //Dismiss the popup view controller
        self.dismissViewControllerAnimated(true, completion: nil)
        
        //Prepare the current view controller for sketch mode
        self.mapView.touchDelegate = self.sketchGraphicsOverlay //activate the sketch layer
        self.mapView.callout.hidden = true
        
        //Assign the sketch layer the geometry that is being passed to us for
        //the active popup's graphic. This is the starting point of the sketch
        self.sketchGraphicsOverlay.geometryBuilder = geometryBuilder
        
        //zoom to the existing feature's geometry
        self.mapView.setViewpointGeometry(geometryBuilder.extent, padding: 10, completion: nil)
        
        //TODO: Hide the feature
        
        //hide the back button
        self.navigationItem.hidesBackButton = true
        //disable the code button
        self.navigationItem.rightBarButtonItem?.enabled = false
        //unhide the sketchToolbar
        self.sketchToolbar.hidden = false
        //disable the done button until any geometry changes
        self.doneBBI.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OfflineEditingViewController.geometryChanged(_:)), name: AGSSketchGraphicsOverlayGeometryDidChangeNotification, object: nil)
    }
    
    func popupsViewController(popupsViewController: AGSPopupsViewController, didDeleteForPopup popup: AGSPopup) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func popupsViewController(popupsViewController: AGSPopupsViewController, didFinishEditingForPopup popup: AGSPopup) {
        
        self.clearSketchGraphicsOverlay()
        
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
        
        self.clearSketchGraphicsOverlay()
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


