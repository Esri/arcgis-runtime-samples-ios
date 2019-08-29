//
// Copyright © 2019 Esri.
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
//

import UIKit
import ArcGIS

class EditAndSyncFeaturesViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize map with a basemap.
            let tileCache = AGSTileCache(name: "SanFrancisco")
            let tiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
            let map = AGSMap(basemap: AGSBasemap(baseLayer: tiledLayer))
            // Assign the map to the map view.
            mapView.map = map
            
            // Create a geodatabase sync task using the feature service URL.
            let featureServiceString = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer"
            let featureServiceURL = URL(string: featureServiceString)
            geodatabaseSyncTask = AGSGeodatabaseSyncTask(url: featureServiceURL!)
            self.addFeatureLayers()
        }
    }
    
    @IBOutlet var extentView: UIView! {
        didSet {
            // Set up extent view.
            extentView.layer.borderColor = UIColor.red.cgColor
            extentView.layer.borderWidth = 3
        }
    }
    
    @IBOutlet private var toolBar: UIToolbar!
    @IBOutlet private var barButtonItem: UIBarButtonItem!
    @IBOutlet private var instructionsLabel: UILabel!
    
    private var generateJob: AGSGenerateGeodatabaseJob?
    private var syncJob: AGSSyncGeodatabaseJob?
    private var geodatabaseSyncTask: AGSGeodatabaseSyncTask!
    private var geodatabase: AGSGeodatabase!
    private var selectedFeature: AGSFeature!
    private var areaOfInterest: AGSEnvelope!
    private var selectedFeatureLayer: AGSFeatureLayer!
    
    private func extentViewFrameToEnvelope() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        
        // Set the lower-left coner.
        let minPoint = mapView.screen(toLocation: frame.origin)
        
        // Set the upper-right corner.
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        
        // Return the envenlope covering the entire extent frame.
        return AGSEnvelope(min: minPoint, max: maxPoint)
    }
    
    private func addFeatureLayers() {
        // Iterate through the layers in the service.
        let featureServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")
        geodatabaseSyncTask?.load { [weak self] (error) in
            if let error = error {
                print("Could not load feature service \(error)")
            } else {
                guard let self = self else {
                    return
                }
                if let featureServiceInfo = self.geodatabaseSyncTask?.featureServiceInfo,
                    let map = self.mapView.map {
                    for index in featureServiceInfo.layerInfos.indices.reversed() {
                        let layerInfo = featureServiceInfo.layerInfos[index]
                        // For each layer in the serice, add a layer to the map.
                        let layerURL = featureServiceURL?.appendingPathComponent(String(index))
                        let featureTable = AGSServiceFeatureTable(url: layerURL!)
                        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                        featureLayer.name = layerInfo.name
                        map.operationalLayers.add(featureLayer)
                    }
                }
            }
        }
    }
    
    // Clears selection in all layers of the map.
    private func clearSelection() {
        for layer in mapView.map!.operationalLayers {
            if let layer = layer as? AGSFeatureLayer {
                layer.clearSelection()
            }
        }
    }
    
    private func didMove() {
        self.selectedFeature = nil
        self.barButtonItem.isEnabled = true
        self.barButtonItem.title = "Sync geodatabase"
        self.instructionsLabel.text = String("Tap the sync button")
        self.selectedFeatureLayer.clearSelection()
    }
    
    func geodatabaseDidLoad() {
        if let error = geodatabase.loadError {
            self.presentAlert(error: error)
        } else {
            // Iterate through the feature tables in the geodatabase and add new layers to the map.
            self.mapView.map?.operationalLayers.removeAllObjects()
            for geodatabaseFeatureTable in self.geodatabase.geodatabaseFeatureTables {
                geodatabaseFeatureTable.load { [weak self, unowned geodatabaseFeatureTable] (error: Error?) in
                    if let error = error {
                        self?.presentAlert(error: error)
                    } else {
                        // Create a new feature layer from the table and add it to the map.
                        let featureLayer = AGSFeatureLayer(featureTable: geodatabaseFeatureTable)
                        self?.mapView.map?.operationalLayers.add(featureLayer)
                    }
                }
            }
            self.generateJob = nil
            self.barButtonItem.isEnabled = false
            self.instructionsLabel.text = String("Tap on a feature")
            self.mapView.touchDelegate = self
        }
    }
    
    func geodatabaseDidSync() {
        self.presentAlert(title: "Geodatabase sync sucessful")
        self.barButtonItem.isEnabled = false
        self.instructionsLabel.text = String("Tap on a feature")
    }
    
    func generateGeodatabase() {
        // Hide the unnecessary items.
        barButtonItem.isEnabled = false
        extentView.isHidden = true
        
        // Get the area outlined by the extent view.
        areaOfInterest = self.extentViewFrameToEnvelope()
        
        geodatabaseSyncTask.defaultGenerateGeodatabaseParameters(withExtent: areaOfInterest) { [weak self] (params: AGSGenerateGeodatabaseParameters?, error: Error?) in
            if let params = params,
                let self = self {
                // Don't include attachments to minimize the geodatabase size.
                params.returnAttachments = false
                
                // Create a temporary file for the geodatabase.
                let dateFormatter = ISO8601DateFormatter()
                
                let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let downloadFileURL = documentDirectoryURL
                    .appendingPathComponent(dateFormatter.string(from: Date()))
                    .appendingPathExtension("geodatabase")
               
                // Request a job to generate the geodatabase.
                let generateGeodatabaseJob = self.geodatabaseSyncTask.generateJob(with: params, downloadFileURL: downloadFileURL)
                self.generateJob = generateGeodatabaseJob
                generateGeodatabaseJob.start(
                    statusHandler: { (status: AGSJobStatus) in
                        SVProgressHUD.show(withStatus: status.statusString()) //Show job status.
                    },
                    completion: { [weak self] (_, error: Error?) in
                        SVProgressHUD.dismiss()
                        
                        if let error = error {
                            self?.presentAlert(error: error)
                        } else {
                            // Load the geodatabase when the job is done.
                            self?.geodatabase = generateGeodatabaseJob.result
                            self?.geodatabase.load { [weak self] (error: Error?) in
                                self?.geodatabaseDidLoad()
                            }
                        }
                    }
                )
            } else {
                self!.presentAlert(title: "Could not generate default parameters: \(error!)")
            }
        }
    }
    
    func syncGeodatabase() {
        clearSelection()
        barButtonItem.isEnabled = false
        selectedFeature = nil
        
        // Create parameters for the sync task.
        let syncGeodatabaseParameters = AGSSyncGeodatabaseParameters()
        syncGeodatabaseParameters.geodatabaseSyncDirection = .bidirectional
        syncGeodatabaseParameters.rollbackOnFailure = false
        
        // Specify the layer IDs of the feature tables to sync.
        for geodatabaseFeatureTable in geodatabase.geodatabaseFeatureTables {
            let serviceLayerId = geodatabaseFeatureTable.serviceLayerID
            let syncLayerOption = AGSSyncLayerOption(layerID: serviceLayerId, syncDirection: .bidirectional)
            syncGeodatabaseParameters.layerOptions.append(syncLayerOption)
        }
        // Create a sync job with the parameters and start it.
        let syncGeodatabaseJob = geodatabaseSyncTask.syncJob(with: syncGeodatabaseParameters, geodatabase: geodatabase)
        self.syncJob = syncGeodatabaseJob
        syncGeodatabaseJob.start(statusHandler: { (status: AGSJobStatus) in
            SVProgressHUD.show(withStatus: status.statusString())
        }, completion: { [weak self] (result: [AGSSyncLayerResult]?, error: Error?) in
            SVProgressHUD.dismiss()
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                self?.geodatabaseDidSync()
            }
        })
    }
    
    @IBAction func generateOrSync() {
        if barButtonItem.title == "Sync geodatabase" {
            syncGeodatabase()
        } else {
            generateGeodatabase()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAndSyncFeaturesViewController"]
    }
}

// Allows the user to interactively select and move features on the map.
extension EditAndSyncFeaturesViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Move the selected feature to the tapped location and update it in the feature table.
        if let feature = self.selectedFeature {
            let point = mapView.screen(toLocation: screenPoint)
            if AGSGeometryEngine.geometry(point, intersects: areaOfInterest) {
                feature.geometry = point
                feature.featureTable?.update(feature) { [weak self] ( error: Error?) in
                    if let error = error, let featureLayer = self?.selectedFeatureLayer{
                        self?.presentAlert(error: error)
                        self?.selectedFeature = nil
                        featureLayer.clearSelection()
                    } else {
                        self?.didMove()
                    }
                }
            } else {
                self.presentAlert(title: "Cannot move feature outside downloaded area")
            }
        } else { // Identify which feature was tapped and select it.
            mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 22.0, returnPopupsOnly: false, maximumResultsPerLayer: 1) { [weak self] (results: [AGSIdentifyLayerResult]?, error: Error?) in
                if let error = error {
                    self?.presentAlert(error: error)
                } else if let results = results {
                    self?.instructionsLabel.text = String("Tap on the map to move the feature")
                    if let firstResult = results.first {
                        let layerContent = firstResult.layerContent
                        
                        // Check that the result is a feature layer and has elements.
                        if let featureLayer = layerContent as? AGSFeatureLayer, let feature = firstResult.geoElements.first as? AGSFeature {
                            featureLayer.select(feature)
                            self?.selectedFeatureLayer = featureLayer
                            self?.selectedFeature = feature
                        }
                    }
                }
            }
        }
    }
}
