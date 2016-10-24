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
    private let FEATURE_SERVICE_URL = NSURL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
    private var syncTask:AGSGeodatabaseSyncTask!
    private var generateJob:AGSGenerateGeodatabaseJob!
    private var generatedGeodatabase:AGSGeodatabase!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GenerateGeodatabaseViewController"]
        
        let path = NSBundle.mainBundle().pathForResource("SanFrancisco", ofType: "tpk")!
        let tileCache = AGSTileCache(fileURL: NSURL(fileURLWithPath: path))
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        self.syncTask = AGSGeodatabaseSyncTask(URL: self.FEATURE_SERVICE_URL)
        
        self.addFeatureLayers()

        //setup extent view
        self.extentView.layer.borderColor = UIColor.redColor().CGColor
        self.extentView.layer.borderWidth = 3
        
        self.mapView.map = self.map
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addFeatureLayers() {
        
        self.syncTask.loadWithCompletion { [weak self] (error) -> Void in
            if let error = error {
                print("Could not load feature service \(error)")
                
            } else {
                guard let weakSelf = self else {
                    return
                }
                
                for (index, layerInfo) in weakSelf.syncTask.featureServiceInfo!.layerInfos.enumerate().reverse() {
                    
                    //For each layer in the serice, add a layer to the map
                    let layerURL = weakSelf.FEATURE_SERVICE_URL.URLByAppendingPathComponent(String(index))
                    let featureTable = AGSServiceFeatureTable(URL:layerURL)
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    featureLayer.name = layerInfo.name
                    featureLayer.opacity = 0.65
                    weakSelf.map.operationalLayers.addObject(featureLayer)
                }
                
                //enable download
                weakSelf.downloadBBI.enabled = true
            }
        }
    }
    
    func frameToExtent() -> AGSEnvelope {
        let frame = self.mapView.convertRect(self.extentView.frame, fromView: self.view)
        
        let minPoint = self.mapView.screenToLocation(frame.origin)
        let maxPoint = self.mapView.screenToLocation(CGPoint(x: frame.origin.x+frame.width, y: frame.origin.y+frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    //MARK: - Actions
    
    @IBAction func downloadAction() {
        
        //generate default param to contain all layers in the service
        self.syncTask.defaultGenerateGeodatabaseParametersWithExtent(self.frameToExtent()) { [weak self] (params: AGSGenerateGeodatabaseParameters?, error: NSError?) in
            if let params = params, weakSelf = self {
                
                //don't include attachments to minimze the geodatabae size
                params.returnAttachments = false
                
                //create a unique name for the geodatabase based on current timestamp
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                
                let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                let fullPath = "\(path)/\(dateFormatter.stringFromDate(NSDate())).geodatabase"
                
                //request a job to generate the geodatabase
                weakSelf.generateJob = weakSelf.syncTask.generateJobWithParameters(params, downloadFileURL: NSURL(string: fullPath)!)
                
                //kick off the job
                weakSelf.generateJob.startWithStatusHandler({ (status: AGSJobStatus) -> Void in
                    SVProgressHUD.showWithStatus(status.statusString(), maskType: SVProgressHUDMaskType.Gradient)
                }) { [weak self] (object: AnyObject?, error: NSError?) -> Void in
                    if let error = error {
                        print(error)
                        SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                    }
                    else {
                        SVProgressHUD.dismiss()
                        self?.generatedGeodatabase = object as! AGSGeodatabase
                        self?.displayLayersFromGeodatabase()
                    }
                }

                
            }else{
                print("Could not generate default parameters : \(error!)")
            }
        }
    }
    
    func displayLayersFromGeodatabase() {
        self.generatedGeodatabase.loadWithCompletion({ [weak self] (error:NSError?) -> Void in

            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription)
            }
            else {
                self?.map.operationalLayers.removeAllObjects()
                
                AGSLoadObjects(self!.generatedGeodatabase.geodatabaseFeatureTables, { (success: Bool) in
                    if success {
                        for featureTable in self!.generatedGeodatabase.geodatabaseFeatureTables.reverse() {
                            //check if featureTable has geometry
                            if featureTable.hasGeometry {
                                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                                self?.map.operationalLayers.addObject(featureLayer)
                            }
                        }
                        SVProgressHUD.showSuccessWithStatus("Now showing data from geodatabase")
                    }
                })
                
                self?.downloadBBI.enabled = false
                
                //unregister geodatabase as the sample wont be editing or syncing features
                self?.unregisterGeodatabase()
                
                //hide the extent view
                self?.extentView.hidden = true
            }
        })
    }
    
    func unregisterGeodatabase() {
        if self.generatedGeodatabase != nil {
            self.syncTask.unregisterGeodatabase(self.generatedGeodatabase) { (error: NSError?) -> Void in

                if let error = error {
                    SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                }
                else {
                    SVProgressHUD.showInfoWithStatus("Geodatabase unregistered since we wont be editing it in this sample")
                }
            }
        }
    }

}
