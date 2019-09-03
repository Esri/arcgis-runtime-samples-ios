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

class OfflineEditingViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var extentView: UIView!
    @IBOutlet var sketchToolbar: UIToolbar!
    @IBOutlet var serviceModeToolbar: UIToolbar!
    @IBOutlet var geodatabaseModeToolbar: UIToolbar!
    @IBOutlet var doneBBI: UIBarButtonItem!
    @IBOutlet var barButtonItem: UIBarButtonItem!
    @IBOutlet var syncBBI: UIBarButtonItem!
    @IBOutlet var instructionsLabel: UILabel!
    
    private var sketchEditor: AGSSketchEditor?
    private let featureServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
    private var featureTable: AGSServiceFeatureTable?
    private var syncTask: AGSGeodatabaseSyncTask?
    private var generatedGeodatabase: AGSGeodatabase?
    private var generateJob: AGSGenerateGeodatabaseJob?
    private var syncJob: AGSSyncGeodatabaseJob?
    private var popupsVC: AGSPopupsViewController?
    
    private var liveMode = true {
        didSet {
            updateUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OfflineEditingViewController", "FeatureLayersViewController"]
        
        //use the san francisco tpk as the basemap
        let tpkURL = Bundle.main.url(forResource: "SanFrancisco", withExtension: "tpk")!
        let tileCache = AGSTileCache(fileURL: tpkURL)
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        let map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        //setup extent view
        extentView.layer.borderColor = UIColor.red.cgColor
        extentView.layer.borderWidth = 3
        
        mapView.map = map
        mapView.touchDelegate = self
        
        //initialize sketch editor and assign to map view
        sketchEditor = AGSSketchEditor()
        mapView.sketchEditor = sketchEditor
        
        //initialize sync task
        syncTask = AGSGeodatabaseSyncTask(url: featureServiceURL)
        
        //add online feature layers
        addFeatureLayers()
    }

    // MARK: - Helper methods
    
    private func addFeatureLayers() {
        //Iterate through the layers in the service
        syncTask?.load { [weak self] (error) in
            if let error = error {
                print("Could not load feature service \(error)")
            } else {
                guard let self = self else {
                    return
                }
                if let featureServiceInfo = self.syncTask?.featureServiceInfo,
                    let map = self.mapView.map {
                    for index in featureServiceInfo.layerInfos.indices.reversed() {
                        let layerInfo = featureServiceInfo.layerInfos[index]
                        //For each layer in the serice, add a layer to the map
                        let layerURL = self.featureServiceURL.appendingPathComponent(String(index))
                        let featureTable = AGSServiceFeatureTable(url: layerURL)
                        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                        featureLayer.name = layerInfo.name
                        map.operationalLayers.add(featureLayer)
                    }
                }
                
                //enable generate geodatabase bbi
                self.barButtonItem.isEnabled = true
            }
        }
    }
    
    private func frameToExtent() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        
        let minPoint = mapView.screen(toLocation: frame.origin)
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.origin.x + frame.width, y: frame.origin.y + frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    private func updateUI() {
        if liveMode {
            serviceModeToolbar.isHidden = false
            instructionsLabel.isHidden = true
            barButtonItem.title = "Generate Geodatabase"
        } else {
            serviceModeToolbar.isHidden = true
            updateLabelWithEdits()
        }
    }
    
    private func updateLabelWithEdits() {
        let dispatchGroup = DispatchGroup()
        var totalCount = 0
        
        for featureTable in generatedGeodatabase!.geodatabaseFeatureTables where featureTable.loadStatus == .loaded {
            dispatchGroup.enter()
            featureTable.addedFeaturesCount { (count, _) in
                totalCount += count
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            featureTable.updatedFeaturesCount { (count, _) in
                totalCount += count
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            featureTable.deletedFeaturesCount { (count, _) in
                totalCount += count
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            self?.instructionsLabel?.text = "Data from geodatabase: \(totalCount) edits"
        }
    }
    
    private func switchToServiceMode() {
        if let generatedGeodatabase = generatedGeodatabase {
            //unregister geodatabase
            syncTask?.unregisterGeodatabase(generatedGeodatabase) { (error: Error?) in
                if let error = error {
                    print("Error while unregistering geodatabase: \(error.localizedDescription)")
                }
            }
        }
        
        //remove all layers added from the geodatabase
        mapView.map?.operationalLayers.removeAllObjects()
        
        //add layers from the service
        addFeatureLayers()
        
        //update the flag
        liveMode = true
        
        generatedGeodatabase = nil
        
        //delete exisiting geodatabases
        deleteAllGeodatabases()
    }
    
    private func deleteAllGeodatabases() {
        //Remove all files with .geodatabase, .geodatabase-shm and .geodatabase-wal file extensions
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: documentDirectoryURL.path)
            for file in files {
                let remove = file.hasSuffix(".geodatabase") || file.hasSuffix(".geodatabase-shm") || file.hasSuffix(".geodatabase-wal")
                if remove {
                    let url = documentDirectoryURL.appendingPathComponent(file)
                    try FileManager.default.removeItem(at: url)
                }
            }
            print("Deleted all local data")
        } catch {
            print(error)
        }
    }
    
    @objc
    func sketchChanged(_ notification: Notification) {
        //Check if the sketch geometry is valid to decide whether to enable
        //the done bar button item
        if let geometry = self.mapView.sketchEditor?.geometry, !geometry.isEmpty {
            doneBBI.isEnabled = true
        }
    }
    
    private func disableSketchEditor() {
        mapView.sketchEditor?.stop()
        mapView.sketchEditor?.clearGeometry()
        sketchToolbar.isHidden = true
    }
    
    private func displayLayersFromGeodatabase() {
        guard let generatedGeodatabase = generatedGeodatabase else {
            return
        }
        generatedGeodatabase.load { [weak self] (error) in
            guard let self = self else {
                return
            }
            
            if let error = error {
                print(error)
            } else {
                self.liveMode = false
                
                self.mapView.map?.operationalLayers.removeAllObjects()
                
                AGSLoadObjects(generatedGeodatabase.geodatabaseFeatureTables) { (success) in
                    if success {
                        for featureTable in generatedGeodatabase.geodatabaseFeatureTables.reversed() {
                            //check if feature table has geometry
                            if featureTable.hasGeometry {
                                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                                self.mapView.map?.operationalLayers.add(featureLayer)
                            }
                        }
                        self.presentAlert(message: "Now showing layers from the geodatabase")
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func generateGeodatabaseAction(_ sender: UIBarButtonItem) {
        if sender.title == "Generate Geodatabase" {
            //show the instructions label and update the text
            instructionsLabel.isHidden = false
            instructionsLabel.text = "Choose an extent by keeping the desired area within the shown block"
            
            //show the extent view
            extentView.isHidden = false
            
            //update to done button
            sender.title = "Done"
        } else if sender.title == "Done" {
            performSegue(withIdentifier: "FeatureLayersSegue", sender: self)
        }
    }
    
    private func generateGeodatabase(_ layerIDs: [Int], extent: AGSEnvelope) {
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
        
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadFileURL = documentDirectoryURL
            .appendingPathComponent(dateFormatter.string(from: Date()))
            .appendingPathExtension("geodatabase")
        
        guard let syncTask = syncTask else {
            return
        }
            
        //create a generate job from the sync task
        let generateJob = syncTask.generateJob(with: params, downloadFileURL: downloadFileURL)
        self.generateJob = generateJob
        
        //start the job
        generateJob.start(statusHandler: { (status) in
            SVProgressHUD.show(withStatus: status.statusString())
        }, completion: { [weak self] (object, error) in
            SVProgressHUD.dismiss()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            } else if let geodatabase = object {
                //save a reference to the geodatabase
                self.generatedGeodatabase = geodatabase
                //add the layers from geodatabase
                self.displayLayersFromGeodatabase()
            }
        })
    }
    
    @IBAction func switchToServiceMode(_ sender: AnyObject) {
        if generatedGeodatabase?.hasLocalEdits() == true {
            let yesAction = UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
                self?.syncAction {
                    self?.switchToServiceMode()
                }
            }
            let noAction = UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
                self?.switchToServiceMode()
            }
            
            let alert = UIAlertController(title: nil, message: "Would you like to sync the changes before switching?", preferredStyle: .alert)
            alert.addAction(noAction)
            alert.addAction(yesAction)
            self.present(alert, animated: true)
        } else {
            switchToServiceMode()
        }
    }
    
    @IBAction func syncAction() {
        syncAction(nil)
    }
    
    private func syncAction(_ completion: (() -> Void)?) {
        guard let generatedGeodatabase = generatedGeodatabase,
            let syncTask = syncTask else {
            return
        }
        
        if !generatedGeodatabase.hasLocalEdits() {
            print("No local edits. Syncing anyway to fetch the latest remote data.")
        }
        
        var syncLayerOptions = [AGSSyncLayerOption]()
        for layerInfo in syncTask.featureServiceInfo!.layerInfos {
            let layerOption = AGSSyncLayerOption(layerID: layerInfo.id, syncDirection: .bidirectional)
            syncLayerOptions.append(layerOption)
        }
        
        let params = AGSSyncGeodatabaseParameters()
        params.layerOptions = syncLayerOptions
        
        let syncJob = syncTask.syncJob(with: params, geodatabase: generatedGeodatabase)
        self.syncJob = syncJob
        syncJob.start(statusHandler: { (status) in
            SVProgressHUD.show(withStatus: status.statusString())
        }, completion: { [weak self] (_, error) in
            SVProgressHUD.dismiss()
            
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                self?.updateUI()
            }
            
            //call completion
            completion?()
        })
    }
    
    @IBAction func sketchDoneAction() {
        navigationItem.hidesBackButton = false
        navigationItem.rightBarButtonItem?.isEnabled = true
        if let popupsVC = popupsVC {
             present(popupsVC, animated: true)
        }
        NotificationCenter.default.removeObserver(self, name: .AGSSketchEditorGeometryDidChange, object: nil)
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let featureLayerController = navController.viewControllers.first as? FeatureLayersViewController {
            featureLayerController.featureLayerInfos = syncTask?.featureServiceInfo?.layerInfos ?? []
            featureLayerController.onCompletion = { [weak self] selectedLayerIDs in
                //hide extent view
                self?.extentView.isHidden = true
                if let extent = self?.frameToExtent() {
                    self?.generateGeodatabase(selectedLayerIDs, extent: extent)
                }
            }
        }
    }
}

extension OfflineEditingViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        SVProgressHUD.show(withStatus: "Loading")
        
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResultsPerLayer: 10) { [weak self] (results: [AGSIdentifyLayerResult]?, error: Error?) in
            SVProgressHUD.dismiss()
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            } else if let results = results {
                var popups = [AGSPopup]()
                for result in results {
                    for geoElement in result.geoElements {
                        popups.append(AGSPopup(geoElement: geoElement))
                    }
                }
                if !popups.isEmpty {
                    let popupsVC = AGSPopupsViewController(popups: popups, containerStyle: .navigationBar)
                    self.popupsVC = popupsVC
                    popupsVC.delegate = self
                    self.present(popupsVC, animated: true)
                } else {
                    self.presentAlert(message: "No features selected")
                }
            }
        }
    }
}

extension OfflineEditingViewController: AGSPopupsViewControllerDelegate {
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, sketchEditorFor popup: AGSPopup) -> AGSSketchEditor? {
        if let geometry = popup.geoElement.geometry {
            //start sketch editor
            mapView.sketchEditor?.start(with: geometry)
            
            //zoom to the existing feature's geometry
            mapView.setViewpointGeometry(geometry.extent, padding: 10, completion: nil)
        }
        
        return sketchEditor
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, readyToEditGeometryWith sketchEditor: AGSSketchEditor?, for popup: AGSPopup) {
        //Dismiss the popup view controller
        dismiss(animated: true)
        
        //Prepare the current view controller for sketch mode
        mapView.callout.isHidden = true
        
        //hide the back button
        navigationItem.hidesBackButton = true
        //disable the code button
        navigationItem.rightBarButtonItem?.isEnabled = false
        //unhide the sketchToolbar
        sketchToolbar.isHidden = false
        //disable the done button until any geometry changes
        doneBBI.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(OfflineEditingViewController.sketchChanged(_:)), name: .AGSSketchEditorGeometryDidChange, object: nil)
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didFinishEditingFor popup: AGSPopup) {
        disableSketchEditor()
        
        let feature = popup.geoElement as! AGSFeature
        // simplify the geometry, this will take care of self intersecting polygons and
        feature.geometry = AGSGeometryEngine.simplifyGeometry(feature.geometry!)
        //normalize the geometry, this will take care of geometries that extend beyone the dateline
        //(ifwraparound was enabled on the map)
        feature.geometry = AGSGeometryEngine.normalizeCentralMeridian(of: feature.geometry!)
        
        //sync changes if in service mode
        if liveMode {
            //Tell the user edits are being saved int the background
            SVProgressHUD.show(withStatus: "Saving feature details...")
            
            (feature.featureTable as! AGSServiceFeatureTable).applyEdits { [weak self] (_, error) in
                SVProgressHUD.dismiss()
                
                if let error = error {
                    self?.presentAlert(error: error)
                } else {
                    self?.presentAlert(message: "Edits applied successfully")
                }
            }
        } else {
            //update edit count and enable/disable sync button otherwise
            updateUI()
        }
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didCancelEditingFor popup: AGSPopup) {
        disableSketchEditor()
    }
    
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        //dismiss the popups view controller
        dismiss(animated: true)
        popupsVC = nil
    }
}
