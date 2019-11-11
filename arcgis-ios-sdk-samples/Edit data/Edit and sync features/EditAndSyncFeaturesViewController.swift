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
    
    private let featureServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")
    private let syncGeodatabaseTitle = "Sync geodatabase"
    private var generateJob: AGSGenerateGeodatabaseJob?
    private var syncJob: AGSSyncGeodatabaseJob?
    private var geodatabaseSyncTask: AGSGeodatabaseSyncTask!
    private var geodatabase: AGSGeodatabase!
    private var areaOfInterest: AGSEnvelope!

    private var selectedFeature: AGSFeature? {
        didSet {
            if let feature = selectedFeature {
                if let featureLayer = feature.featureTable?.layer as? AGSFeatureLayer {
                    featureLayer.select(feature)
                }
            } else {
                clearSelection()
            }
        }
    }

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
        geodatabaseSyncTask?.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                if let featureServiceInfo = self.geodatabaseSyncTask?.featureServiceInfo,
                    let map = self.mapView.map {
                    for index in featureServiceInfo.layerInfos.indices.reversed() {
                        let layerInfo = featureServiceInfo.layerInfos[index]
                        // For each layer in the serice, add a layer to the map.
                        if let layerURL = self.featureServiceURL?.appendingPathComponent(String(index)) {
                            let featureTable = AGSServiceFeatureTable(url: layerURL)
                            let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                            featureLayer.name = layerInfo.name
                            map.operationalLayers.add(featureLayer)
                        }
                    }
                }
            }
        }
    }
    
    // Clears selection in all layers of the map.
    private func clearSelection() {
        if let operationalLayers = mapView.map?.operationalLayers {
            for layer in operationalLayers {
                if let layer = layer as? AGSFeatureLayer {
                    layer.clearSelection()
                }
            }
        }
    }
    
    private func resetUI() {
        selectedFeature = nil
        barButtonItem.isEnabled = true
        barButtonItem.title = syncGeodatabaseTitle
        instructionsLabel.text = "Tap the sync button"
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
            self.instructionsLabel.text = "Tap on a feature"
            self.mapView.touchDelegate = self
        }
    }
    
    func geodatabaseDidSync() {
        self.presentAlert(title: "Geodatabase sync sucessful")
        self.barButtonItem.isEnabled = false
        self.instructionsLabel.text = "Tap on a feature"
    }
    
    func generateGeodatabase() {
        // Hide the unnecessary items.
        barButtonItem.isEnabled = false
        extentView.isHidden = true
        
        // Get the area outlined by the extent view.
        areaOfInterest = self.extentViewFrameToEnvelope()
        
        geodatabaseSyncTask.defaultGenerateGeodatabaseParameters(withExtent: areaOfInterest) { [weak self] (params: AGSGenerateGeodatabaseParameters?, error: Error?) in
            guard let self = self else { return }
            
            guard let params = params else { return self.presentAlert(title: "Could not generate default parameters: \(error!)") }
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
                        self?.geodatabase.load { [weak self] (_: Error?) in
                            self?.geodatabaseDidLoad()
                        }
                    }
                }
            )
        }
    }
    
    func syncGeodatabase() {
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
        }, completion: { [weak self] (_: [AGSSyncLayerResult]?, error: Error?) in
            SVProgressHUD.dismiss()
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                self?.geodatabaseDidSync()
            }
        })
    }
    
    @IBAction func generateOrSync() {
        if barButtonItem.title == syncGeodatabaseTitle {
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
                    if let error = error {
                        self?.presentAlert(error: error)
                        self?.selectedFeature = nil
                    } else {
                        self?.resetUI()
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
                    self?.instructionsLabel.text = "Tap on the map to move the feature"
                    if let feature = results.first?.geoElements.first as? AGSFeature {
                        self?.selectedFeature = feature
                    }
                }
            }
        }
    }
}
