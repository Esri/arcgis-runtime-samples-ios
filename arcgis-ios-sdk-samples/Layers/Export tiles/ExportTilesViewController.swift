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
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: AGSBasemap(baseLayer: tiledLayer))
            // Set the min scale of the map to avoid requesting a huge download.
            let scale = 1e7
            mapView.map?.minScale = scale
            zoomToViewpoint(mapView: mapView, scale: scale)
        }
    }
    
    /// A view to emphasize the extent of exported tile layer.
    @IBOutlet var extentView: UIView! {
        didSet {
            extentView.layer.borderColor = UIColor.red.cgColor
            extentView.layer.borderWidth = 2
        }
    }
    
    /// A view to provide a dark blurry background to preview the exported tiles.
    @IBOutlet var visualEffectView: UIVisualEffectView!
    /// A map view to preview the exported tiles.
    @IBOutlet var previewMapView: AGSMapView! {
        didSet {
            previewMapView.layer.borderColor = UIColor.white.cgColor
            previewMapView.layer.borderWidth = 8
        }
    }
    /// A bar button to initiate or cancel the download task.
    @IBOutlet var exportTilesBarButtonItem: UIBarButtonItem! {
        didSet {
            exportTilesBarButtonItem.possibleTitles = ["Export tiles", "Cancel"]
        }
    }
    
    // MARK: Properties
    
    /// The tiled layer created from world street map service.
    let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer")!)
    /// An export task to request the tile package.
    var exportTask: AGSExportTileCacheTask!
    /// An export job to download the tile package.
    var job: AGSExportTileCacheJob! {
        didSet {
            exportTilesBarButtonItem.title = job == nil ? "Export tiles" : "Cancel"
        }
    }
    
    /// A URL to the temporary folder to temporarily store the exported tile package.
    let temporaryFolderURL: URL = {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
        // Create and return the full, unique URL to the temporary folder.
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }()
    
    // MARK: Methods
    
    /// Get the extent within the extent view for generating a tile package.
    func frameToExtent() -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: self.view)
        
        let minPoint = mapView.screen(toLocation: frame.origin)
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.origin.x + frame.width, y: frame.origin.y + frame.height))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    /// Zoom the map view to Southern California for demo purposes.
    func zoomToViewpoint(mapView: AGSMapView, scale: Double) {
        let center = AGSPoint(x: -117, y: 34, spatialReference: .wgs84())
        mapView.setViewpoint(AGSViewpoint(center: center, scale: scale), completion: nil)
    }
    
    /// Remove the downloaded tile packages.
    func removeTemporaryTilePackages() {
        // Remove all files in the sample-specific temporary folder.
        guard let files = try? FileManager.default.contentsOfDirectory(at: temporaryFolderURL, includingPropertiesForKeys: nil), !files.isEmpty else { return }
        files.forEach { filePath in
            try? FileManager.default.removeItem(at: filePath)
        }
    }
    
    /// Get destination URL for the tile package.
    func getDownloadURL(fileExtension: String) -> URL {
        // If the downloadFileURL ends with ".tpk", the tile cache will use
        // the legacy compact format. If the downloadFileURL ends with ".tpkx",
        // the tile cache will use the current compact version 2 format.
        // See more in the doc of
        // `AGSExportTileCacheTask.exportTileCacheJob(with:downloadFileURL:)`.
        temporaryFolderURL.appendingPathComponent("myTileCache.\(fileExtension)")
    }
    
    /// Initiate the `AGSExportTileCacheTask` to download a tile package.
    ///
    /// - Parameters:
    ///   - exportTask: An `AGSExportTileCacheTask` to run the export job.
    ///   - downloadFileURL: A URL to where the tile package is saved.
    func initiateDownload(exportTask: AGSExportTileCacheTask, downloadFileURL: URL) {
        // Remove previous existing tile packages.
        removeTemporaryTilePackages()
        
        // Get the parameters by specifying the selected area, map view's
        // current scale as the minScale and tiled layer's max scale as maxScale
        var minScale = mapView.mapScale
        let maxScale = tiledLayer.maxScale
        
        if minScale < maxScale {
            minScale = maxScale
        }
        
        // Get current area of interest marked by the extent view.
        let areaOfInterest = frameToExtent()
        // Get export parameters.
        exportTask.exportTileCacheParameters(withAreaOfInterest: areaOfInterest, minScale: minScale, maxScale: maxScale) { [weak self, unowned exportTask] (params: AGSExportTileCacheParameters?, error: Error?) in
            guard let self = self else { return }
            if let params = params {
                self.exportTiles(exportTask: exportTask, parameters: params, downloadFileURL: downloadFileURL)
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Export tiles with the `AGSExportTileCacheJob` from the export task.
    ///
    /// - Parameters:
    ///   - exportTask: An `AGSExportTileCacheTask` to run the export job.
    ///   - parameters: The parameters of the export task.
    ///   - downloadFileURL: A URL to where the tile package is saved.
    func exportTiles(exportTask: AGSExportTileCacheTask, parameters: AGSExportTileCacheParameters, downloadFileURL: URL) {
        // Get and run the job.
        job = exportTask.exportTileCacheJob(with: parameters, downloadFileURL: downloadFileURL)
        job.start(statusHandler: { (status) in
            SVProgressHUD.show(withStatus: status.statusString())
        }, completion: { [weak self] (result, error) in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            
            self.job = nil
            
            if let tileCache = result {
                self.visualEffectView.isHidden = false
                
                let newTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
                self.previewMapView.map = AGSMap(basemap: AGSBasemap(baseLayer: newTiledLayer))
                self.zoomToViewpoint(mapView: self.previewMapView, scale: 1e7)
            } else if let error = error {
                if (error as NSError).code != NSUserCancelledError {
                    self.presentAlert(error: error)
                }
            }
        })
    }
    
    // MARK: Actions
    
    @IBAction func exportTilesBarButtonTapped(_ sender: UIBarButtonItem) {
        if let exportJob = job {
            // If it is downloading, cancel download.
            exportJob.progress.cancel()
            job = nil
        } else {
            // Otherwise, try to download when exporting tiles is allowed.
            guard let mapServiceInfo = exportTask.mapServiceInfo, mapServiceInfo.exportTilesAllowed else { return }
            // Create an action sheet to choose export format.
            let alertController = UIAlertController(
                title: "Choose Export Format",
                message: nil,
                preferredStyle: .actionSheet
            )
            alertController.addAction(
                UIAlertAction(title: "Compact Cache V1 (.tpk)", style: .default) { [unowned self] _ in
                    self.initiateDownload(exportTask: exportTask, downloadFileURL: self.getDownloadURL(fileExtension: "tpk"))
                }
            )
            if mapServiceInfo.exportTileCacheCompactV2Allowed {
                // Only add the option when tpkx export is allowed.
                alertController.addAction(
                    UIAlertAction(title: "Compact Cache V2 (.tpkx)", style: .default) { _ in
                        self.initiateDownload(exportTask: self.exportTask, downloadFileURL: self.getDownloadURL(fileExtension: "tpkx"))
                    }
                )
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alertController.addAction(cancelAction)
            alertController.popoverPresentationController?.barButtonItem = sender
            present(alertController, animated: true)
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        visualEffectView.isHidden = true
        // Release the map in order to free the tiled layer.
        previewMapView.map = nil
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ExportTilesViewController"]
        // Initialize and load the export task.
        exportTask = AGSExportTileCacheTask(url: tiledLayer.url!)
        exportTask.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.exportTilesBarButtonItem.isEnabled = true
            }
        }
    }
    
    deinit {
        // Remove the temporary folder and all content in it.
        try? FileManager.default.removeItem(at: temporaryFolderURL)
    }
}
