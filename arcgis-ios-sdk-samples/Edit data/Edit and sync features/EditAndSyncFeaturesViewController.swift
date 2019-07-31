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
    @IBOutlet private var generateButton: UIButton!
    @IBOutlet private var syncButton: UIButton!
    @IBOutlet private var progressBar: UIProgressView!
    
    private var downloadAreaGraphic: AGSGraphic!
    private var geodatabaseSyncTask: AGSGeodatabaseSyncTask!
    private var geodatabase: AGSGeodatabase!
    private var viewpointChangedListener: UITableViewDropCoordinator!
    private var selectedFeature: AGSFeature!
    
    func extentViewFrameToEnvelope() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        
        //the lower-left corner
        let minPoint = mapView.screen(toLocation: frame.origin)
        
        //the upper-right corner
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        
        //return the envenlope covering the entire extent frame
        return AGSEnvelope(min: minPoint, max: maxPoint)
    }
    
    func initialize() {
       
    }
    
    @IBAction func generateOfflineMapAction() {
        // Hide the unnecessary items.
        generateButton.isEnabled = false
        extentView.isHidden = true
        
        // Get the area outlined by the extent view.
        let areaOfInterest = extentViewFrameToEnvelope()
        
        /////////add a progress or loading view//////////////////!!!!!!!!!!!!!!!!!///////////////////!!!!!!!!!!!!!!!!//////////////////
        let fileManager = FileManager.default
//        let currentDirectory = Bundle.main.resourcePath
        let temporaryFile = FileManager.createFile(fileManager)
        // DON'T FORGET TO DELETE FILE ONCE DONE!!!!!!!!//////////////!!!!!!!!!!!!!!!!//////////////!!!!!!!!!!!!!!!!!
//        let geodatabaseParameters = geodatabaseSyncTask.AGSGenerateGeodatabaseParameters()
//        let generateGeodatabaseJob = geodatabaseSyncTask.generateJob(with: <#T##AGSGenerateGeodatabaseParameters#>, downloadFileURL: <#T##URL#>)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAndSyncFeaturesViewController"]
    }
}
