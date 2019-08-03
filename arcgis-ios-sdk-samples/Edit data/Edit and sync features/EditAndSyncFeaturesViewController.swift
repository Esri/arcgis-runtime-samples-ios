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

            // Display graphics overlay of the download area.
//            displayGraphics()
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
                                //don't forget to add an error display message here////////////////////!!!!!!!!!!!!!!!!!!//////////////!!!!!!!!!!!!!
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
    
    private var graphicsOverlay: AGSGraphicsOverlay!
    
//    func displayGraphics() {
//        graphicsOverlay = AGSGraphicsOverlay()
//        graphicsOverlay.renderer = AGSSimpleRenderer(symbol: AGSSimpleLineSymbol(style: .solid, color: .red, width: 2))
//        self.mapView.graphicsOverlays.add(graphicsOverlay)
//    }
    @IBOutlet var extentView: UIView! {
        didSet {
            //setup extent view
            extentView.layer.borderColor = UIColor.red.cgColor
            extentView.layer.borderWidth = 3
        }
    }
    @IBOutlet private var generateButton: UIButton!
    @IBOutlet private var syncButton: UIButton!
    @IBOutlet private var progressBar: UIProgressView!
    @IBOutlet private var tapFeatureLabel: UILabel!
    
    private var activeJob: AGSJob?
    private var downloadAreaGraphic: AGSGraphic!
    private var geodatabaseSyncTask: AGSGeodatabaseSyncTask!
    private var geodatabase: AGSGeodatabase!
    private var viewpointChangedListener: UITableViewDropCoordinator!
    private var selectedFeature: AGSFeature!
    private var areaOfInterest: AGSEnvelope!
    
    func extentViewFrameToEnvelope() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        
        //the lower-left corner
        let minPoint = mapView.screen(toLocation: frame.origin)
        
        //the upper-right corner
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        
        //return the envenlope covering the entire extent frame
        return AGSEnvelope(min: minPoint, max: maxPoint)
    }
    
    @IBAction func generateGeodatabase() {
        // Hide the unnecessary items.
        generateButton.isEnabled = false
        extentView.isHidden = true
        
        // Get the area outlined by the extent view.
        areaOfInterest = self.extentViewFrameToEnvelope()
        
        /////////add a progress or loading view//////////////////!!!!!!!!!!!!!!!!!///////////////////!!!!!!!!!!!!!!!!//////////////////
//        let fileManager = FileManager.default
//        let currentDirectory = Bundle.main.resourcePath
//        let temporaryFile = FileManager.createFile(fileManager)
        
        // DON'T FORGET TO DELETE FILE ONCE DONE!!!!!!!!//////////////!!!!!!!!!!!!!!!!//////////////!!!!!!!!!!!!!!!!!
//        let geodatabaseParameters = geodatabaseSyncTask.AGSGenerateGeodatabaseParameters()
//        let generateGeodatabaseJob = geodatabaseSyncTask.generateJob(with: <#T##AGSGenerateGeodatabaseParameters#>, downloadFileURL: <#T##URL#>)
        
        geodatabaseSyncTask.defaultGenerateGeodatabaseParameters(withExtent: areaOfInterest) { [weak self] (params: AGSGenerateGeodatabaseParameters?, error: Error?) in
            if let params = params,
                let self = self {
                //don't include attachments to minimze the geodatabae size
                params.returnAttachments = false
                
                // Create a temporary file for the geodatabase.
                let tempFile = "temporaryFile"
                
                let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let downloadFileURL = documentDirectoryURL
                    .appendingPathComponent(tempFile)
                    .appendingPathExtension("geodatabase")
                
                //request a job to generate the geodatabase
                let generateGeodatabaseJob = self.geodatabaseSyncTask.generateJob(with: params, downloadFileURL: downloadFileURL)
                self.activeJob = generateGeodatabaseJob
                //kick off the job
                generateGeodatabaseJob.start(
                    statusHandler: { (status: AGSJobStatus) in
                        SVProgressHUD.show(withStatus: status.statusString())
                                    },
                    completion: { (object: AnyObject?, error: Error?) in
                        SVProgressHUD.dismiss()
                        
                        if let error = error {
                            self.presentAlert(error: error)
                        } else {
//                            self?.generatedGeodatabase = object as? AGSGeodatabase
//                            self?.displayLayersFromGeodatabase()
                            self.geodatabase = generateGeodatabaseJob.result
                            self.geodatabase.load { (error: Error?) in
                                if let error = error {
                                    self.presentAlert(error: error)
                                    //don't forget to add an error display message here////////////////////!!!!!!!!!!!!!!!!!!//////////////!!!!!!!!!!!!!
                                } else {
                                    self.mapView.map?.operationalLayers.removeAllObjects()
                                    for geodatabaseFeatureTable in self.geodatabase.geodatabaseFeatureTables {
                                        geodatabaseFeatureTable.load { (error: Error?) in
                                            if let error = error {
                                                self.presentAlert(error: error)
                                            } else {
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
//                        self.allowEditing()
                    }
                )
            } else {
                print("Could not generate default parameters: \(error!)")
            }
        } // end of syncTask
    } //end of function
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAndSyncFeaturesViewController"]
    }
}

extension EditAndSyncFeaturesViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if selectedFeature != nil {
            let point = mapView.screen(toLocation: screenPoint)
            if AGSGeometryEngine.geometry(point, intersects: areaOfInterest) {
                selectedFeature.geometry = point
                selectedFeature.featureTable?.update(selectedFeature) { [weak self] (error: Error?) in
                    if let error = error {
                        self!.presentAlert(error: error)
                    } else {
                        self!.syncButton.isEnabled = true
                    }
                }
            } else {
                print("Cannot move feature outside downloaded area.")
            }
        } else { // Identify which feature was clicked and select it.
            mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 5.0, returnPopupsOnly: false, maximumResultsPerLayer: 1) { (results: [AGSIdentifyLayerResult]?, error: Error?) in
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    let identifyLayerResults = results
                    if (identifyLayerResults?.isEmpty != true) {
                        let firstResult = identifyLayerResults!.first
                        let layerContent = firstResult?.layerContent
                        
                        // Check that the result is a feature layer and has elements.
                        ////////////////////////if there's a problem, check here... inconsistencies with sublayers etc/////////////////////
                        if layerContent!.isKind(of: AGSFeatureLayer) && firstResult != nil {
                            let featureLayer = layerContent as? AGSFeatureLayer
                            let identifiedElement = firstResult?.sublayerResults.first
                            if identifiedElement!.isKind(of: AGSFeature) {
                                let feature = identifiedElement as? AGSFeature
                                featureLayer?.select(feature!)
                                let selectedFeature = feature
                            }
                        }
                    }
                }
            }
        }
        
//    func allowEditing() {
//        // Hide the generate button.
//        self.generateButton.isHidden = true
//        // Show instructions.
//        self.tapFeatureLabel.isHidden = false
//    }
    }
}
