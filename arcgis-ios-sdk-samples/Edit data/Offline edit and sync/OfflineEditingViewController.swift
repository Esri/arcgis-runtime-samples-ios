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
    private let FEATURE_SERVICE_URL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
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
        let tpkPath = Bundle.main.path(forResource: "SanFrancisco", ofType: "tpk")!
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(fileURL: URL(fileURLWithPath: tpkPath)))
        
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        
        //setup extent view
        self.extentView.layer.borderColor = UIColor.red.cgColor
        self.extentView.layer.borderWidth = 3
        
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        //initialize sketch editor and assign to map view
        self.sketchEditor = AGSSketchEditor()
        self.mapView.sketchEditor = self.sketchEditor
        
        //initialize sync task
        self.syncTask = AGSGeodatabaseSyncTask(url: self.FEATURE_SERVICE_URL)
        
        //add online feature layers
        self.addFeatureLayers()

    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        SVProgressHUD.show(withStatus: "Loading")
        self.mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResultsPerLayer: 10) { [weak self] (results: [AGSIdentifyLayerResult]?, error: Error?) -> Void in

            if let error = error {
                self?.presentAlert(error: error)
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
                    self?.popupsVC = AGSPopupsViewController(popups: popups, containerStyle: .navigationBar)
                    self?.popupsVC.delegate = self!
                    self?.present(self!.popupsVC, animated: true, completion: nil)
                }
                else {
                    self?.presentAlert(message: "No features selected")
                }
            }
        }
    }
    
    //MARK: - Helper methods
    func addFeatureLayers() {
        
        //Iterate through the layers in the service
        self.syncTask.load { [weak self] (error) -> Void in
            if let error = error {
                print("Could not load feature service \(error)")
            } else {
                guard let weakSelf = self else {
                    return
                }
                for (index, layerInfo) in weakSelf.syncTask.featureServiceInfo!.layerInfos.enumerated().reversed() {
                    
                    //For each layer in the serice, add a layer to the map
                    let layerURL = weakSelf.FEATURE_SERVICE_URL.appendingPathComponent(String(index))
                    let featureTable = AGSServiceFeatureTable(url:layerURL)
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    featureLayer.name = layerInfo.name
                    weakSelf.map.operationalLayers.add(featureLayer)
                }
                
                //enable generate geodatabase bbi
                weakSelf.barButtonItem.isEnabled = true
            }
        }
    }
    
    
    func frameToExtent() -> AGSEnvelope {
        let frame = self.mapView.convert(self.extentView.frame, from: self.view)
        
        let minPoint = self.mapView.screen(toLocation: frame.origin)
        let maxPoint = self.mapView.screen(toLocation: CGPoint(x: frame.origin.x+frame.width, y: frame.origin.y+frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    func updateUI() {
        if self.liveMode {
            self.serviceModeToolbar.isHidden = false
            self.instructionsLabel.isHidden = true
            self.barButtonItem.title = "Generate geodatabase"
        }
        else {
            self.serviceModeToolbar.isHidden = true
            self.updateLabelWithEdits()
        }
    }
    
    func updateLabelWithEdits() {
        let dispatchGroup = DispatchGroup()
        var totalCount = 0
        
        for featureTable in self.generatedGeodatabase.geodatabaseFeatureTables {
            if featureTable.loadStatus == .loaded {
                
                dispatchGroup.enter()
                featureTable.addedFeaturesCount(completion: { (count: Int, error: Error?) in
                    totalCount = totalCount + count
                    dispatchGroup.leave()
                })
                
                dispatchGroup.enter()
                featureTable.updatedFeaturesCount(completion: { (count: Int, error: Error?) in
                    totalCount = totalCount + count
                    dispatchGroup.leave()
                })
                
                dispatchGroup.enter()
                featureTable.deletedFeaturesCount(completion: { (count: Int, error: Error?) in
                    totalCount = totalCount + count
                    dispatchGroup.leave()
                })
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.syncBBI?.isEnabled = totalCount > 0
            self?.instructionsLabel?.text = "Data from geodatabase : \(totalCount) edits"
        }
    }
    
    func switchToServiceMode() {
        //unregister geodatabase
        self.syncTask.unregisterGeodatabase(self.generatedGeodatabase) { (error: Error?) -> Void in
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
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: path)
            for file in files {
                let remove = file.hasSuffix(".geodatabase") || file.hasSuffix(".geodatabase-shm") || file.hasSuffix(".geodatabase-wal")
                if remove {
                    try FileManager.default.removeItem(atPath: (path as NSString).appendingPathComponent(file))
                    print("deleting file: \(file)")
                }
            }
            print("deleted all local data")
        }
        catch {
            print(error)
        }
    }
    
    @objc func sketchChanged(_ notification:Notification) {
        //Check if the sketch geometry is valid to decide whether to enable
        //the done bar button item
        if let geometry = self.mapView.sketchEditor?.geometry , !geometry.isEmpty {
            self.doneBBI.isEnabled = true
        }
    }
    
    private func disableSketchEditor() {
        self.mapView.sketchEditor?.stop()
        self.mapView.sketchEditor?.clearGeometry()
        self.sketchToolbar.isHidden = true
    }
    
    func displayLayersFromGeodatabase() {
        self.generatedGeodatabase.load(completion: { [weak self] (error:Error?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                self?.liveMode = false
                
                self?.map.operationalLayers.removeAllObjects()
                
                AGSLoadObjects(self!.generatedGeodatabase.geodatabaseFeatureTables, { (success: Bool) in
                    if success {
                        for featureTable in self!.generatedGeodatabase.geodatabaseFeatureTables.reversed() {
                            //check if feature table has geometry
                            if featureTable.hasGeometry {
                                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                                self?.map.operationalLayers.add(featureLayer)
                            }
                        }
                        self?.presentAlert(message: "Now showing layers from the geodatabase")
                    }
                })
            }
        })
    }
    
    //MARK: - Actions
    
    @IBAction func generateGeodatabaseAction() {
        if self.barButtonItem.title! == "Generate geodatabase" {
            //show the instructions label and update the text
            self.instructionsLabel.isHidden = false
            self.instructionsLabel.text = "Choose an extent by keeping the desired area within the shown block"
            
            //show the extent view
            self.extentView.isHidden = false
            
            //update to done button
            self.barButtonItem.title = "Done"
        }
        else if self.barButtonItem.title! == "Done" {
            //hide extent view
            self.extentView.isHidden = true
            
            //update the instructions label
            self.instructionsLabel.text = "Select the feature layers to be included"
            
            //show options to pick layers
            self.featureLayersContainerView.isHidden = false
            
            //update to download button
            self.barButtonItem.title = "Download"
            
            self.featureLayersVC?.featureLayerInfos = self.syncTask.featureServiceInfo!.layerInfos
        }
        else {
            //get selected layer ids
            let selectedLayerIds = featureLayersVC.selectedLayerInfos.map { $0.id }
            
            if selectedLayerIds.isEmpty {
                presentAlert(message: "Please select at least one layer")
                return
            }
            
            //hide featureLayersVC
            self.featureLayersContainerView.isHidden = true
            
            //generate a geodatabase
            self.generateGeodatabase(selectedLayerIds, extent: self.frameToExtent())
        }
    }
    
    func generateGeodatabase(_ layerIDs:[Int], extent:AGSEnvelope) {
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
        params.attachmentSyncDirection = .bidirectional
        
        //name for the geodatabase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let fullPath = "\(path)/\(dateFormatter.string(from: Date())).geodatabase"
            
        //create a generate job from the sync task
        self.generateJob = self.syncTask.generateJob(with: params, downloadFileURL: URL(string: fullPath)!)
        
        //start the job
        self.generateJob.start(statusHandler: { (status: AGSJobStatus) -> Void in
            SVProgressHUD.show(withStatus: status.statusString())
            
        }) { [weak self] (object: AnyObject?, error: Error?) -> Void in
            
            if let error = error {
                self?.presentAlert(error: error)
            }
            else {
                SVProgressHUD.dismiss()
                //save a reference to the geodatabase
                self?.generatedGeodatabase = object as? AGSGeodatabase
                //add the layers from geodatabase
                self?.displayLayersFromGeodatabase()
            }
        }
    }
    
    @IBAction func switchToServiceMode(_ sender:AnyObject) {
        if self.generatedGeodatabase.hasLocalEdits() {
            let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
                self?.syncAction({ () -> Void in
                    self?.switchToServiceMode()
                })
            }
            let noAction = UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
                self?.switchToServiceMode()
            }
            
            let alert = UIAlertController(title: nil, message: "Would you like to sync the changes before switching?", preferredStyle: .alert)
            alert.addAction(noAction)
            alert.addAction(yesAction)
            self.present(alert, animated: true, completion: nil)
        }
        else {
            self.switchToServiceMode()
        }
    }
    
    
    @IBAction func syncAction() {
        self.syncAction(nil)
    }
    
    func syncAction(_ completion: (() -> Void)?) {
        if !self.generatedGeodatabase.hasLocalEdits() {
            presentAlert(message: "No local edits")
            return
        }
        
        var syncLayerOptions = [AGSSyncLayerOption]()
        for layerInfo in self.syncTask.featureServiceInfo!.layerInfos {
            let layerOption = AGSSyncLayerOption(layerID: layerInfo.id, syncDirection: .bidirectional)
            syncLayerOptions.append(layerOption)
        }
        
        let params = AGSSyncGeodatabaseParameters()
        params.layerOptions = syncLayerOptions
        
        self.syncJob = self.syncTask.syncJob(with: params, geodatabase: self.generatedGeodatabase)
        self.syncJob.start(statusHandler: { (status: AGSJobStatus) -> Void in
            
            SVProgressHUD.show(withStatus: status.statusString())
            
        }, completion: { (results: [AGSSyncLayerResult]?, error: Error?) -> Void in
            if let error = error {
                self.presentAlert(error: error)
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
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.present(self.popupsVC, animated:true, completion:nil)
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - AGSPopupsViewControllerDelegate

    func popupsViewController(_ popupsViewController: AGSPopupsViewController, sketchEditorFor popup: AGSPopup) -> AGSSketchEditor? {
        
        
        if let geometry = popup.geoElement.geometry {
            
            //start sketch editor
            self.mapView.sketchEditor?.start(with: geometry)
            
            //zoom to the existing feature's geometry
            self.mapView.setViewpointGeometry(geometry.extent, padding: 10, completion: nil)
        }
        
        return self.sketchEditor
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, readyToEditGeometryWith sketchEditor: AGSSketchEditor?, for popup: AGSPopup) {
        
        //Dismiss the popup view controller
        self.dismiss(animated: true, completion: nil)
        
        //Prepare the current view controller for sketch mode
        self.mapView.callout.isHidden = true
        
        //TODO: Hide the feature
        
        //hide the back button
        self.navigationItem.hidesBackButton = true
        //disable the code button
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        //unhide the sketchToolbar
        self.sketchToolbar.isHidden = false
        //disable the done button until any geometry changes
        self.doneBBI.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(OfflineEditingViewController.sketchChanged(_:)), name: .AGSSketchEditorGeometryDidChange, object: nil)
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didFinishEditingFor popup: AGSPopup) {
        
        self.disableSketchEditor()
        
        let feature = popup.geoElement as! AGSFeature
        // simplify the geometry, this will take care of self intersecting polygons and
        feature.geometry = AGSGeometryEngine.simplifyGeometry(feature.geometry!)
        //normalize the geometry, this will take care of geometries that extend beyone the dateline
        //(ifwraparound was enabled on the map)
        feature.geometry = AGSGeometryEngine.normalizeCentralMeridian(of: feature.geometry!)
        
        
        //sync changes if in service mode
        if self.liveMode {
            
            //Tell the user edits are being saved int the background
            SVProgressHUD.show(withStatus: "Saving feature details...")
            
            (feature.featureTable as! AGSServiceFeatureTable).applyEdits { [weak self] (featureEditResult: [AGSFeatureEditResult]?, error: Error?) -> Void in
                
                if let error = error {
                    self?.presentAlert(error: error)
                }
                else {
                    self?.presentAlert(message: "Edits applied successfully")
                }
            }
        }
        else {
            //update edit count and enable/disable sync button otherwise
            self.updateUI()
        }
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didCancelEditingFor popup: AGSPopup) {
        
        self.disableSketchEditor()
    }
    
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        //dismiss the popups view controller
        self.dismiss(animated: true, completion:nil)
        self.popupsVC = nil
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FeatureLayersVCSegue" {
            self.featureLayersVC = segue.destination as? FeatureLayersViewController
        }
    }
}


