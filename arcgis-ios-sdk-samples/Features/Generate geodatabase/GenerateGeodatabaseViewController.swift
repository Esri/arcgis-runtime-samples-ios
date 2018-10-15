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
    @IBOutlet var downloadBBI:UIBarButtonItem!
    @IBOutlet var extentView:UIView!
    
    private var map:AGSMap!
    private let FEATURE_SERVICE_URL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
    private var syncTask:AGSGeodatabaseSyncTask!
    private var generateJob:AGSGenerateGeodatabaseJob!
    private var generatedGeodatabase:AGSGeodatabase!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GenerateGeodatabaseViewController"]
        
        let path = Bundle.main.path(forResource: "SanFrancisco", ofType: "tpk")!
        let tileCache = AGSTileCache(fileURL: URL(fileURLWithPath: path))
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        self.syncTask = AGSGeodatabaseSyncTask(url: self.FEATURE_SERVICE_URL)
        
        self.addFeatureLayers()

        //setup extent view
        self.extentView.layer.borderColor = UIColor.red.cgColor
        self.extentView.layer.borderWidth = 3
        
        self.mapView.map = self.map
    }
    
    func addFeatureLayers() {
        
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
                    featureLayer.opacity = 0.65
                    weakSelf.map.operationalLayers.add(featureLayer)
                }
                
                //enable download
                weakSelf.downloadBBI.isEnabled = true
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
    
    //MARK: - Actions
    
    @IBAction func downloadAction() {
        
        //generate default param to contain all layers in the service
        self.syncTask.defaultGenerateGeodatabaseParameters(withExtent: self.frameToExtent()) { [weak self] (params: AGSGenerateGeodatabaseParameters?, error: Error?) in
            if let params = params, let weakSelf = self {
                
                //don't include attachments to minimze the geodatabae size
                params.returnAttachments = false
                
                //create a unique name for the geodatabase based on current timestamp
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                
                let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                let fullPath = "\(path)/\(dateFormatter.string(from: Date())).geodatabase"
                
                //request a job to generate the geodatabase
                weakSelf.generateJob = weakSelf.syncTask.generateJob(with: params, downloadFileURL: URL(string: fullPath)!)
                
                //kick off the job
                weakSelf.generateJob.start(statusHandler: { (status: AGSJobStatus) -> Void in
                    SVProgressHUD.show(withStatus: status.statusString())
                }) { [weak self] (object: AnyObject?, error: Error?) -> Void in
                    if let error = error {
                        print(error)
                        self?.presentAlert(error: error)
                    }
                    else {
                        SVProgressHUD.dismiss()
                        self?.generatedGeodatabase = object as? AGSGeodatabase
                        self?.displayLayersFromGeodatabase()
                    }
                }

                
            }
            else{
                print("Could not generate default parameters : \(error!)")
            }
        }
    }
    
    func displayLayersFromGeodatabase() {
        self.generatedGeodatabase.load { [weak self] (error:Error?) -> Void in

            if let error = error {
                self?.presentAlert(error: error)
            }
            else {
                self?.map.operationalLayers.removeAllObjects()
                
                AGSLoadObjects(self!.generatedGeodatabase.geodatabaseFeatureTables) { (success: Bool) in
                    if success {
                        for featureTable in self!.generatedGeodatabase.geodatabaseFeatureTables.reversed() {
                            //check if featureTable has geometry
                            if featureTable.hasGeometry {
                                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                                self?.map.operationalLayers.add(featureLayer)
                            }
                        }
                        self?.presentAlert(message: "Now showing data from geodatabase")
                    }
                }
                
                self?.downloadBBI.isEnabled = false
                
                //unregister geodatabase as the sample wont be editing or syncing features
                self?.unregisterGeodatabase()
                
                //hide the extent view
                self?.extentView.isHidden = true
            }
        }
    }
    
    func unregisterGeodatabase() {
        if generatedGeodatabase != nil {
            syncTask.unregisterGeodatabase(generatedGeodatabase) {[weak self] (error: Error?) -> Void in

                if let error = error {
                    self?.presentAlert(error: error)
                }
                else {
                    self?.presentAlert(message: "Geodatabase unregistered since we wont be editing it in this sample")
                }
            }
        }
    }

}
