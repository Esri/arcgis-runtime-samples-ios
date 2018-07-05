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
        
        self.tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer")!)
        let map = AGSMap(basemap: AGSBasemap(baseLayer: self.tiledLayer))
        
        self.mapView.map = map
        
        //add the graphics overlay to the map view
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        self.setupExtentView()
        
        self.previewMapView.layer.borderColor = UIColor.white.cgColor
        self.previewMapView.layer.borderWidth = 8
    }
    
    func setupExtentView() {
        self.extentView.layer.borderColor = UIColor.red.cgColor
        self.extentView.layer.borderWidth = 2
    }
    
    func frameToExtent() -> AGSEnvelope {
        let frame = self.mapView.convert(self.extentView.frame, from: self.view)
        
        let minPoint = self.mapView.screen(toLocation: frame.origin)
        let maxPoint = self.mapView.screen(toLocation: CGPoint(x: frame.origin.x+frame.width, y: frame.origin.y+frame.height))
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
            self.visualEffectView.isHidden = true
        }
    }
    
    private func initiateDownload() {
        
        //get the parameters by specifying the selected area,
        //mapview's current scale as the minScale and tiled layer's max scale as maxScale
        let minScale = self.mapView.mapScale
        let maxScale = self.self.tiledLayer.maxScale
        
        //TODO: Remove this code once design has been udpated
        if minScale == maxScale {
            SVProgressHUD.showError(withStatus: "Min scale and max scale cannot be the same")
            return
        }
        
        //set the state
        self.downloading = true
        
        //delete previous existing tpks
        self.deleteAllTpks()
        
        //initialize the export task
        self.exportTask = AGSExportTileCacheTask(url: self.tiledLayer.url!)
        self.exportTask.exportTileCacheParameters(withAreaOfInterest: self.frameToExtent(), minScale: self.mapView.mapScale, maxScale: self.tiledLayer.maxScale) { [weak self] (params: AGSExportTileCacheParameters?, error: Error?) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            else {
                self?.exportTilesUsingParameters(params!)
            }
        }
    }
    
    private func exportTilesUsingParameters(_ params: AGSExportTileCacheParameters) {
        //destination path for the tpk, including name
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let destinationPath = "\(path)/myTileCache.tpk"
        
        //get the job
        self.job = self.exportTask.exportTileCacheJob(with: params, downloadFileURL: URL(string: destinationPath)!)
        //run the job
        self.job.start(statusHandler: { (status: AGSJobStatus) -> Void in
            //show job status
            SVProgressHUD.show(withStatus: status.statusString())
        }) { [weak self] (result: AnyObject?, error: Error?) -> Void in
            self?.downloading = false
            
            if let error = error {
                SVProgressHUD.showError(withStatus: (error as NSError).localizedFailureReason)
            }
            else {
                
                //hide progress view
                SVProgressHUD.dismiss()
                self?.visualEffectView.isHidden = false
                
                let tileCache = result as! AGSTileCache
                let newTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
                self?.previewMapView.map = AGSMap(basemap: AGSBasemap(baseLayer: newTiledLayer))
            }
        }
    }
    
    @IBAction func closeAction() {
        self.visualEffectView.isHidden = true
        
        //release the map in order to free the tiled layer
        self.previewMapView.map = nil
    }
    
    private func deleteAllTpks() {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: path)
            for file in files {
                if file.hasSuffix(".tpk") {
                    try FileManager.default.removeItem(atPath: (path as NSString).appendingPathComponent(file))
                }
            }
            print("deleted all local data")
        }
        catch {
            print(error)
        }
    }
}
