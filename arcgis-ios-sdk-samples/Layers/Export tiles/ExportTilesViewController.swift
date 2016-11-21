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

class ExportTilesViewController: UIViewController {
    
    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var extentView:UIView!
    @IBOutlet var visualEffectView:UIVisualEffectView!
    @IBOutlet var previewMapView:AGSMapView!
    @IBOutlet var barButtonItem:UIBarButtonItem!
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var extentGraphic:AGSGraphic!
    
    private var tiledLayer:AGSArcGISTiledLayer!
    private var job:AGSExportTileCacheJob!
    private var exportTask:AGSExportTileCacheTask!
    
    private var downloading = false {
        didSet {
            self.barButtonItem?.title = self.downloading ? "Cancel" : "Export tiles"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ExportTilesViewController"]
        
        self.tiledLayer = AGSArcGISTiledLayer(URL: NSURL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer")!)
        let map = AGSMap(basemap: AGSBasemap(baseLayer: self.tiledLayer))
        
        self.mapView.map = map
        
        //add the graphics overlay to the map view
        self.mapView.graphicsOverlays.addObject(self.graphicsOverlay)
        
        self.setupExtentView()
        
        self.previewMapView.layer.borderColor = UIColor.whiteColor().CGColor
        self.previewMapView.layer.borderWidth = 8
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupExtentView() {
        self.extentView.layer.borderColor = UIColor.redColor().CGColor
        self.extentView.layer.borderWidth = 2
    }
    
    func frameToExtent() -> AGSEnvelope {
        let frame = self.mapView.convertRect(self.extentView.frame, fromView: self.view)
        
        let minPoint = self.mapView.screenToLocation(frame.origin)
        let maxPoint = self.mapView.screenToLocation(CGPoint(x: frame.origin.x+frame.width, y: frame.origin.y+frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    @IBAction func barButtonItemAction() {
        if downloading {
            //cancel download
            self.cancelDownload()
        }
        else {
            //download
            self.initiateDownload()
        }
    }
    
    private func cancelDownload() {
        if self.job != nil {
            SVProgressHUD.dismiss()
            //TODO: Cancel the job when the API is available
            //self.job.cancel
            self.job = nil
            self.downloading = false
            self.visualEffectView.hidden = true
        }
    }
    
    private func initiateDownload() {
        
        //get the parameters by specifying the selected area,
        //mapview's current scale as the minScale and tiled layer's max scale as maxScale
        let minScale = self.mapView.mapScale
        let maxScale = self.self.tiledLayer.maxScale
        
        //TODO: Remove this code once design has been udpated
        if minScale == maxScale {
            SVProgressHUD.showErrorWithStatus("Min scale and max scale cannot be the same", maskType: .Gradient)
            return
        }
        
        //set the state
        self.downloading = true
        
        //delete previous existing tpks
        self.deleteAllTpks()
        
        //initialize the export task
        self.exportTask = AGSExportTileCacheTask(URL: self.tiledLayer.URL!)
        self.exportTask.exportTileCacheParametersWithAreaOfInterest(self.frameToExtent(), minScale: self.mapView.mapScale, maxScale: self.tiledLayer.maxScale) { [weak self] (params: AGSExportTileCacheParameters?, error: NSError?) in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
            }
            else {
                self?.exportTilesUsingParameters(params!)
            }
        }
    }
    
    private func exportTilesUsingParameters(params: AGSExportTileCacheParameters) {
        //destination path for the tpk, including name
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let destinationPath = "\(path)/myTileCache.tpk"
        
        //get the job
        self.job = self.exportTask.exportTileCacheJobWithParameters(params, downloadFileURL: NSURL(string: destinationPath)!)
        //run the job
        self.job.startWithStatusHandler({ (status: AGSJobStatus) -> Void in
            //show job status
            SVProgressHUD.showWithStatus(status.statusString(), maskType: .Gradient)
        }) { [weak self] (result: AnyObject?, error: NSError?) -> Void in
            self?.downloading = false
            
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedFailureReason, maskType: .Gradient)
            }
            else {
                
                //hide progress view
                SVProgressHUD.dismiss()
                self?.visualEffectView.hidden = false
                
                let tileCache = result as! AGSTileCache
                let newTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
                self?.previewMapView.map = AGSMap(basemap: AGSBasemap(baseLayer: newTiledLayer))
            }
        }
    }
    
    @IBAction func closeAction() {
        self.visualEffectView.hidden = true
        
        //release the map in order to free the tiled layer
        self.previewMapView.map = nil
    }
    
    private func deleteAllTpks() {
        
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        do {
            let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
            for file in files {
                if file.hasSuffix(".tpk") {
                    try NSFileManager.defaultManager().removeItemAtPath((path as NSString).stringByAppendingPathComponent(file))
                }
            }
            print("deleted all local data")
        }
        catch {
            print(error)
        }
    }
}
