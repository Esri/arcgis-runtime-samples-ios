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
    private let FEATURE_SERVICE_URL = NSURL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer")!
    private var featureServiceInfo:AGSArcGISFeatureServiceInfo!
    private var featureLayerInfos:[AGSArcGISFeatureLayerInfo]!
    private var syncTask:AGSGeodatabaseSyncTask!
    private var generateJob:AGSJob!
    private var generatedGeodatabase:AGSGeodatabase!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GenerateGeodatabaseViewController"]
        
        let path = NSBundle.mainBundle().pathForResource("SanFrancisco", ofType: "tpk")!
        let tileCache = AGSTileCache(path: path)
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        self.featureServiceInfo = AGSArcGISFeatureServiceInfo(URL: self.FEATURE_SERVICE_URL)
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
        self.featureServiceInfo.loadWithCompletion { [weak self] (error) -> Void in
            if let error = error {
                print(error)
            }
            else {
                if let featureLayerInfos = self?.featureServiceInfo.featureLayerInfos {
                    self?.featureLayerInfos = featureLayerInfos
                    for featureLayerInfo in featureLayerInfos {
                        let featureTable = AGSServiceFeatureTable(URL: featureLayerInfo.URL!)
                        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                        self?.map.operationalLayers.addObject(featureLayer)
                    }
                }
                //enable download
                self?.downloadBBI.enabled = true
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
        
        var layerOptions = [AGSGenerateLayerOption]()
        for layerInfo in self.featureLayerInfos {
            let layerOption = AGSGenerateLayerOption(layerID: layerInfo.serviceLayerID)
            layerOptions.append(layerOption)
        }
        
        let params = AGSGenerateGeodatabaseParameters()
        params.extent = self.frameToExtent()
        params.returnAttachments = false
        params.layerOptions = layerOptions
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        self.syncTask = AGSGeodatabaseSyncTask(URL: self.FEATURE_SERVICE_URL)
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        
        self.generateJob = self.syncTask.generateJobWithParameters(params, downloadFilePath: "\(path)/\(dateFormatter.stringFromDate(NSDate())).geodatabase")
        self.generateJob.startWithStatusHandler({ (status: AGSJobStatus) -> Void in
            SVProgressHUD.showWithStatus(status.statusString(), maskType: SVProgressHUDMaskType.Gradient)
        }) { [weak self] (object: AnyObject?, error: NSError?) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription)
            }
            else {
                SVProgressHUD.dismiss()
                self?.generatedGeodatabase = object as! AGSGeodatabase
                self?.displayLayersFromGeodatabase(object as! AGSGeodatabase)
            }
        }
    }
    
    func displayLayersFromGeodatabase(geodatabase:AGSGeodatabase) {
        self.generatedGeodatabase.loadWithCompletion({ [weak self] (error:NSError?) -> Void in

            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription)
            }
            else {
                self?.map.operationalLayers.removeAllObjects()
                for featureTable in geodatabase.geodatabaseFeatureTables {
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    self?.map.operationalLayers.addObject(featureLayer)
                }
                
                SVProgressHUD.showSuccessWithStatus("Now showing data from geodatabase")
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
