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
            let featureServiceString = "https://sampleserver6.arcgisonline" + ".com/arcgis/rest/services/Sync/WildfireSync/FeatureServer"
            let featureServiceURL = URL(string: featureServiceString)
            geodatabaseSyncTask = AGSGeodatabaseSyncTask(url: featureServiceURL!)
            geodatabaseSyncTask.load { [weak self] (error: Error?) in
                if let error = error {
                    self?.presentAlert(error: error)
                } else {
                    for layerInfo in self!.geodatabaseSyncTask.featureServiceInfo!.layerInfos {
                        let featureLayerURL = URL(string: featureServiceString + "/" + String(layerInfo.id))
                        let onlineFeatureTable = AGSServiceFeatureTable(url: featureLayerURL!)
                        
                        onlineFeatureTable.load { (error: Error?) in
                            if let error = error {
                                self?.presentAlert(error: error)
                            } else {
                                if onlineFeatureTable.geometryType == AGSGeometryType.point {
                                    self?.mapView.map?.operationalLayers.add(AGSFeatureLayer(featureTable: onlineFeatureTable))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBOutlet var extentView: UIView! {
        didSet {
            // Set up extent view.
            extentView.layer.borderColor = UIColor.red.cgColor
            extentView.layer.borderWidth = 3
        }
    }
    
    @IBOutlet private var generateButton: UIButton!
    @IBOutlet private var syncButton: UIButton!
    @IBOutlet private var tapSyncLabel: UILabel!
    @IBOutlet private var moveFeatureLabel: UILabel!
    @IBOutlet private var tapFeatureLabel: UILabel!
    
    private var activeJob: AGSJob?
    private var geodatabaseSyncTask: AGSGeodatabaseSyncTask!
    private var geodatabase: AGSGeodatabase!
    private var selectedFeature: AGSFeature!
    private var areaOfInterest: AGSEnvelope!
    
    func extentViewFrameToEnvelope() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        
        // Set the lower-left coner.
        let minPoint = mapView.screen(toLocation: frame.origin)
        
        // Set the upper-right corner.
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        
        //return the envenlope covering the entire extent frame
        return AGSEnvelope(min: minPoint, max: maxPoint)
    }
    
    // Clears selection in all layers of the map.
    private func clearSelection() {
        for layer in mapView.map!.operationalLayers {
            let layer = layer as AnyObject?
            if layer!.isKind(of: AGSFeatureLayer.self) {
                let featureLayer = layer as? AGSFeatureLayer
                featureLayer?.clearSelection()
            }
        }
    }
    
    @IBAction func generateGeodatabase() {
        // Hide the unnecessary items.
        generateButton.isEnabled = false
        extentView.isHidden = true
        
        // Get the area outlined by the extent view.
        areaOfInterest = self.extentViewFrameToEnvelope()
        
        geodatabaseSyncTask.defaultGenerateGeodatabaseParameters(withExtent: areaOfInterest) { [weak self] (params: AGSGenerateGeodatabaseParameters?, error: Error?) in
            if let params = params,
                let self = self {
                // Don't include attachments to minimze the geodatabae size.
                params.returnAttachments = false
                
                // Create a temporary file for the geodatabase.
                let tempFile = "generatedGeodatabase"
                
                let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let downloadFileURL = documentDirectoryURL
                    .appendingPathComponent(tempFile)
                    .appendingPathExtension("geodatabase")
                
                // Request a job to generate the geodatabase.
                let generateGeodatabaseJob = self.geodatabaseSyncTask.generateJob(with: params, downloadFileURL: downloadFileURL)
                self.activeJob = generateGeodatabaseJob
                generateGeodatabaseJob.start(
                    statusHandler: { (status: AGSJobStatus) in
                        SVProgressHUD.show(withStatus: status.statusString()) //Show job status.
                    },
                    completion: { (object: AnyObject?, error: Error?) in
                        SVProgressHUD.dismiss()
                        
                        if let error = error {
                            self.presentAlert(error: error)
                        } else {
                            // Load the geodatabase when the job is done.
                            self.geodatabase = generateGeodatabaseJob.result
                            self.geodatabase.load { (error: Error?) in
                                if let error = error {
                                    self.presentAlert(error: error)
                                } else {
                                    // Iterate throught the feature tables in the geodatabgase and add new layers to the map.
                                    self.mapView.map?.operationalLayers.removeAllObjects()
                                    for geodatabaseFeatureTable in self.geodatabase.geodatabaseFeatureTables {
                                        geodatabaseFeatureTable.load { (error: Error?) in
                                            if let error = error {
                                                self.presentAlert(error: error)
                                            } else {
                                                // Create a new feature layer from the table and add it to the map.
                                                let featureLayer = AGSFeatureLayer(featureTable: geodatabaseFeatureTable)
                                                self.mapView.map?.operationalLayers.add(featureLayer)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        self.activeJob = nil
                        self.generateButton.isEnabled = false
                        self.tapFeatureLabel.isHidden = false
                        self.mapView.touchDelegate = self
                    }
                )
            } else {
                self!.presentAlert(title: "Could not generate default parameters: \(error!)")
            }
        }
    }
    
    @IBAction func syncGeodatabase() {
        clearSelection()
        syncButton.isEnabled = false
        selectedFeature = nil
        self.tapSyncLabel.isHidden = true
        
        // Create parameters for the sync task.
        let syncGeodatabaseParameters = AGSSyncGeodatabaseParameters()
        syncGeodatabaseParameters.geodatabaseSyncDirection = AGSSyncDirection.bidirectional
        syncGeodatabaseParameters.rollbackOnFailure = false
        
        // Specify the layer IDs of the feature tables to sync.
        for geodatabaseFeatureTable in geodatabase.geodatabaseFeatureTables {
            let serviceLayerId = geodatabaseFeatureTable.serviceLayerID
            let syncLayerOption = AGSSyncLayerOption(layerID: serviceLayerId, syncDirection: .bidirectional)
            syncGeodatabaseParameters.layerOptions.append(syncLayerOption)
        }
        // Create a sync job with the parameters and start it.
        let syncGeodatabaseJob = geodatabaseSyncTask.syncJob(with: syncGeodatabaseParameters, geodatabase: geodatabase)
        syncGeodatabaseJob.start(statusHandler: { (status: AGSJobStatus) in
            SVProgressHUD.show(withStatus: status.statusString())
        },
                                 completion: { (result: [AGSSyncLayerResult]?, error: Error?) in
                                    SVProgressHUD.dismiss()
                                    if let error = error {
                                        self.presentAlert(error: error)
                                    } else {
                                        self.presentAlert(title: "Geodatabase sync sucessful")
                                    }
        })
        syncButton.isEnabled = false
        syncButton.isHidden = true
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
        if self.selectedFeature != nil {
            let point = mapView.screen(toLocation: screenPoint)
            if AGSGeometryEngine.geometry(point, intersects: areaOfInterest) {
                selectedFeature.geometry = point
                selectedFeature.featureTable?.update(selectedFeature) { [weak self] (error: Error?) in
                    if let error = error {
                        self!.presentAlert(error: error)
                    } else {
                        self!.syncButton.isHidden = false
                        self!.syncButton.isEnabled = true
                        self!.tapFeatureLabel.isHidden = true
                        self!.moveFeatureLabel.isHidden = true
                        self!.generateButton.isHidden = true
                        self!.tapSyncLabel.isHidden = false
                    }
                }
            } else {
                self.presentAlert(title: "Cannot move feature outside downloaded area")
            }
        } else { // Identify which feature was tapped and select it.
            mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 22.0, returnPopupsOnly: false, maximumResultsPerLayer: 1) { (results: [AGSIdentifyLayerResult]?, error: Error?) in
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    self.tapFeatureLabel.isHidden = true
                    self.moveFeatureLabel.isHidden = false
                    self.tapSyncLabel.isHidden = true
                    if results!.isEmpty == false {
                        let firstResult = results!.first
                        let layerContent = firstResult!.layerContent
                        
                        // Check that the result is a feature layer and has elements.
                        if layerContent.isKind(of: AGSFeatureLayer.self) && firstResult!.geoElements.isEmpty == false {
                            let featureLayer = layerContent as? AGSFeatureLayer
                            let identifiedElement = firstResult?.geoElements.first
                            if identifiedElement!.isKind(of: AGSFeature.self) {
                                let feature = identifiedElement as? AGSFeature
                                featureLayer!.select(feature!)
                                self.selectedFeature = feature
                            }
                        }
                    }
                }
            }
        }
    }
}
