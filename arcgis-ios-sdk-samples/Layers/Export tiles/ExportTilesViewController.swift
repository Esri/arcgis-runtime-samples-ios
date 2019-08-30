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
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var extentView: UIView!
    @IBOutlet var visualEffectView: UIVisualEffectView!
    @IBOutlet var previewMapView: AGSMapView!
    @IBOutlet var barButtonItem: UIBarButtonItem!
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var extentGraphic: AGSGraphic!
    
    private var tiledLayer: AGSArcGISTiledLayer!
    private var job: AGSExportTileCacheJob!
    private var exportTask: AGSExportTileCacheTask!
    
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
        let maxPoint = self.mapView.screen(toLocation: CGPoint(x: frame.origin.x + frame.width, y: frame.origin.y + frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    @IBAction func barButtonItemAction() {
        if downloading {
            //cancel download
            job?.progress.cancel()
        } else {
            //download
            initiateDownload()
        }
    }
    
    private func initiateDownload() {
        //get the parameters by specifying the selected area,
        //mapview's current scale as the minScale and tiled layer's max scale as maxScale
        var minScale = mapView.mapScale
        let maxScale = tiledLayer.maxScale
        
        if minScale < maxScale {
            minScale = maxScale
        }
        
        //delete previous existing tpks
        deleteAllTpks()
        
        //initialize the export task
        exportTask = AGSExportTileCacheTask(url: tiledLayer.url!)
        exportTask.exportTileCacheParameters(withAreaOfInterest: frameToExtent(), minScale: minScale, maxScale: maxScale) { [weak self] (params: AGSExportTileCacheParameters?, error: Error?) in
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            } else if let params = params {
                self.exportTilesUsingParameters(params)
            }
        }
    }
    
    private func exportTilesUsingParameters(_ params: AGSExportTileCacheParameters) {
        //destination path for the tpk, including name
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadFileURL = documentDirectoryURL.appendingPathComponent("myTileCache.tpk")
        
        downloading = true
        
        //get the job
        job = exportTask.exportTileCacheJob(with: params, downloadFileURL: downloadFileURL)
        //run the job
        job.start(statusHandler: { (status) in
            //show job status
            SVProgressHUD.show(withStatus: status.statusString())
        }, completion: { [weak self] (result, error) in
            //hide progress view
            SVProgressHUD.dismiss()
            
            guard let self = self else {
                return
            }

            self.job = nil
            self.downloading = false
            
            if let error = error {
                if (error as NSError).code != NSUserCancelledError {
                    self.presentAlert(error: error)
                }
            } else if let tileCache = result {
                self.visualEffectView.isHidden = false
                
                let newTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
                self.previewMapView.map = AGSMap(basemap: AGSBasemap(baseLayer: newTiledLayer))
            }
        })
    }
    
    @IBAction func closeAction() {
        self.visualEffectView.isHidden = true
        
        //release the map in order to free the tiled layer
        self.previewMapView.map = nil
    }
    
    private func deleteAllTpks() {
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: documentDirectoryURL.path)
            for file in files {
                if file.hasSuffix(".tpk") {
                    let url = documentDirectoryURL.appendingPathComponent(file)
                    try FileManager.default.removeItem(at: url)
                }
            }
            print("deleted all local data")
        } catch {
            print(error)
        }
    }
}
