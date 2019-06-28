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

class GenerateGeodatabaseViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var downloadBBI: UIBarButtonItem!
    @IBOutlet var extentView: UIView!
    
    private var syncTask: AGSGeodatabaseSyncTask = {
        let featureServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
        return AGSGeodatabaseSyncTask(url: featureServiceURL)
    }()
    private var generatedGeodatabase: AGSGeodatabase?
    // must retain a strong reference to a job while it runs
    private var activeJob: AGSJob?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GenerateGeodatabaseViewController"]
        
        let tpkURL = Bundle.main.url(forResource: "SanFrancisco", withExtension: "tpk")!
        let tileCache = AGSTileCache(fileURL: tpkURL)
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        let map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        mapView.map = map
        
        addFeatureLayers()

        //setup extent view
        extentView.layer.borderColor = UIColor.red.cgColor
        extentView.layer.borderWidth = 3
    }
    
    func addFeatureLayers() {
        syncTask.load { [weak self] (error) in
            if let error = error {
                print("Could not load feature service \(error)")
            } else {
                guard let self = self,
                    let featureServiceInfo = self.syncTask.featureServiceInfo else {
                    return
                }
                
                // For each layer in the service, add a layer to the map.
                let featureLayers = featureServiceInfo.layerInfos.enumerated().map { (offset, layerInfo) -> AGSFeatureLayer in
                    let layerURL = self.syncTask.url!.appendingPathComponent(String(offset))
                    let featureTable = AGSServiceFeatureTable(url: layerURL)
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    featureLayer.name = layerInfo.name
                    featureLayer.opacity = 0.65
                    return featureLayer
                }
                self.mapView.map?.operationalLayers.addObjects(from: featureLayers.reversed())
                
                //enable download
                self.downloadBBI.isEnabled = true
            }
        }
    }
    
    func frameToExtent() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        let minPoint = mapView.screen(toLocation: frame.origin)
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    // MARK: - Actions
    
    @IBAction func downloadAction() {
        //generate default param to contain all layers in the service
        syncTask.defaultGenerateGeodatabaseParameters(withExtent: self.frameToExtent()) { [weak self] (params: AGSGenerateGeodatabaseParameters?, error: Error?) in
            if let params = params,
                let self = self {
                //don't include attachments to minimze the geodatabae size
                params.returnAttachments = false
                
                //create a unique name for the geodatabase based on current timestamp
                let dateFormatter = ISO8601DateFormatter()
                
                let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let downloadFileURL = documentDirectoryURL
                    .appendingPathComponent(dateFormatter.string(from: Date()))
                    .appendingPathExtension("geodatabase")
                
                //request a job to generate the geodatabase
                let generateJob = self.syncTask.generateJob(with: params, downloadFileURL: downloadFileURL)
                self.activeJob = generateJob
                //kick off the job
                generateJob.start(
                    statusHandler: { (status: AGSJobStatus) in
                        SVProgressHUD.show(withStatus: status.statusString())
                    },
                    completion: { [weak self] (object: AnyObject?, error: Error?) in
                        SVProgressHUD.dismiss()
                        
                        if let error = error {
                            self?.presentAlert(error: error)
                        } else {
                            self?.generatedGeodatabase = object as? AGSGeodatabase
                            self?.displayLayersFromGeodatabase()
                        }
                        
                        self?.activeJob = nil
                    }
                )
            } else {
                print("Could not generate default parameters: \(error!)")
            }
        }
    }
    
    func displayLayersFromGeodatabase() {
        guard let generatedGeodatabase = generatedGeodatabase else {
            return
        }
        generatedGeodatabase.load { [weak self] (error: Error?) in
            guard let self = self else {
                return
            }

            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.mapView.map?.operationalLayers.removeAllObjects()
                
                AGSLoadObjects(generatedGeodatabase.geodatabaseFeatureTables) { (success: Bool) in
                    if success {
                        for featureTable in generatedGeodatabase.geodatabaseFeatureTables.reversed() {
                            //check if featureTable has geometry
                            if featureTable.hasGeometry {
                                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                                self.mapView.map?.operationalLayers.add(featureLayer)
                            }
                        }
                        self.presentAlert(message: "Now showing data from geodatabase")
                        
                        // hide the extent view
                        self.extentView.isHidden = true
                        // disable the download button
                        self.downloadBBI.isEnabled = false
                    }
                    // unregister geodatabase as the sample wont be editing or syncing features
                    self.syncTask.unregisterGeodatabase(generatedGeodatabase)
                }
            }
        }
    }
}
