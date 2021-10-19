// Copyright 2021 Esri.
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

class ExportVectorTilesViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: AGSBasemap(style: .arcGISStreetsNight))
            // Set the viewpoint.
            mapView.setViewpoint(AGSViewpoint(latitude: 34.049, longitude: -117.181, scale: 1e4))
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
    /// A bar button to initiate the download task.
    @IBOutlet var exportVectorTilesButton: UIBarButtonItem!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressParentView: UIView!
    @IBOutlet var cancelButton: UIButton!
    
    // MARK: Properties
    
    /// The export task to request the tile package with the same URL as the tile layer.
    var exportVectorTilesTask: AGSExportVectorTilesTask?
    /// An export job to download the tile package.
    var job: AGSExportVectorTilesJob? {
        didSet {
            exportVectorTilesButton.isEnabled = job == nil
        }
    }
    
    /// A URL to the temporary directory to temporarily store the exported vector tile package.
    let vtpkTemporaryURL = makeVTPKDirectory()
    
    static func makeVTPKDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
            .appendingPathComponent("myTileCache", isDirectory: false)
            .appendingPathExtension("vtpk")
    }

    /// A URL to the temporary directory to temporarily store the style item resources.
    let styleTemporaryURL = makeStyleDirectory()
    
    static func makeStyleDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        return url
            .appendingPathComponent("styleItemResources", isDirectory: true)
    }

    /// Observation to track the export vector tiles job.
    private var progressObservation: NSKeyValueObservation?
    
    // MARK: Methods
    
    /// Initiate the `AGSExportVectorTilesTask` to download a tile package.
    /// - Parameters:
    ///   - exportTask: An `AGSExportVectorTilesTask` to run the export job.
    ///   - vectorTileCacheURL: A URL to where the tile package should be saved.
    func initiateDownload(exportTask: AGSExportVectorTilesTask, vectorTileCacheURL: URL) {
        // Set the max scale parameter to 10% of the map's scale to limit the
        // number of tiles exported to within the vector tiled layer's max tile export limit.
        let maxScale = mapView.mapScale * 0.1
        // Get current area of interest marked by the extent view.
        let areaOfInterest = envelope(for: self.view)
        // Get the parameters by specifying the selected area and vector tiled layer's max scale as maxScale.
        exportTask.defaultExportVectorTilesParameters(withAreaOfInterest: areaOfInterest, maxScale: maxScale) { [weak self] parameters, error  in
            guard let self = self, let exportVectorTilesTask = self.exportVectorTilesTask else { return }
            if let params = parameters {
                // Start exporting the tiles with the resulting parameters.
                self.exportVectorTiles(exportTask: exportVectorTilesTask, parameters: params, vectorTileCacheURL: vectorTileCacheURL)
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    /// Export vector tiles with the `AGSExportVectorTilesJob` from the export task.
    /// - Parameters:
    ///   - exportTask: An `AGSExportVectorTilesTask` to run the export job.
    ///   - parameters: The parameters of the export task.
    ///   - vectorTileCacheURL: A URL to where the tile package is saved.
    func exportVectorTiles(exportTask: AGSExportVectorTilesTask, parameters: AGSExportVectorTilesParameters, vectorTileCacheURL: URL) {
        // Create a download URL for the item resource cache.
        let itemResourceURL = makeDownloadURL(isDirectory: true)
        // Create the job with the parameters and download URLs.
        let job = exportTask.exportVectorTilesJob(with: parameters, vectorTileCacheDownloadFileURL: vectorTileCacheURL, itemResourceCacheDownloadDirectory: itemResourceURL)
        self.job = job
        updateProgressViewUI()
        // Start the job.
        job.start(statusHandler: nil) { [weak self] (result, error) in
            guard let self = self else { return }
            // Remove key-value observation.
            self.progressObservation = nil
            self.job = nil
            
            if let result = result,
               let tileCache = result.vectorTileCache,
               let itemResourceCache = result.itemResourceCache {
                // Show the visual effect view.
                self.visualEffectView.isHidden = false
                // Create the vector tiled layer with the tile cache and item resource cache.
                let newTiledLayer = AGSArcGISVectorTiledLayer(vectorTileCache: tileCache, itemResourceCache: itemResourceCache)
                // Set the preview to the new vector tiled layer.
                self.previewMapView.map = AGSMap(basemap: AGSBasemap(baseLayer: newTiledLayer))
                // Set the viewpoint with the extent.
                let extent = parameters.areaOfInterest as! AGSEnvelope
                self.previewMapView.setViewpoint(AGSViewpoint(targetExtent: extent))
            } else if let error = error {
                if (error as NSError).code != NSUserCancelledError {
                    self.presentAlert(error: error)
                }
            }
        }
    }
    
    /// Get the extent within the extent view for generating a vector tile package.
    func envelope(for view: UIView) -> AGSEnvelope {
        let frame = mapView.convert(extentView.frame, from: view)
        
        let minPoint = mapView.screen(toLocation: CGPoint(x: frame.minX, y: frame.minY))
        let maxPoint = mapView.screen(toLocation: CGPoint(x: frame.maxX, y: frame.maxY))
        let extent = AGSEnvelope(min: minPoint, max: maxPoint)
        return extent
    }
    
    /// Update the progress view accordingly.
    func updateProgressViewUI() {
        if job == nil || job!.progress.isCancelled {
            // Close and reset the progress view.
            progressParentView.isHidden = true
            progressView.progress = 0
            progressLabel.text = ""
        } else {
            progressObservation = job?.progress.observe(\.fractionCompleted, options: .initial) { [weak self] progress, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    // Update the progress label.
                    self.progressLabel.text = progress.localizedDescription
                    // Update progress view.
                    self.progressView.progress = Float(progress.fractionCompleted)
                }
            }
            // Show the progress parent view.
            progressParentView.isHidden = false
        }
    }
    
    // MARK: Actions
    
    @IBAction func exportTilesBarButtonTapped(_ sender: UIBarButtonItem) {
        if let exportVectorTilesTask = exportVectorTilesTask,
           let vectorTileSourceInfo = exportVectorTilesTask.vectorTileSourceInfo,
           vectorTileSourceInfo.exportTilesAllowed {
            // Try to download when exporting tiles is allowed.
            initiateDownload(exportTask: exportVectorTilesTask, vectorTileCacheURL: makeDownloadURL(isDirectory: false))
        } else {
            presentAlert(title: "Error", message: "Exporting tiles is not supported for the service.")
        }
    }
    
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        // Hide the preview and background.
        visualEffectView.isHidden = true
        // Release the map in order to free the tiled layer.
        previewMapView.map = nil
        updateProgressViewUI()
        // Remove the sample-specific temporary directory and all content in it.
        try? FileManager.default.removeItem(at: vtpkTemporaryURL)
        try? FileManager.default.removeItem(at: styleTemporaryURL)
    }
    
    @IBAction func cancelAction() {
        // Cancel export vector tiles job and update the UI.
        job?.progress.cancel()
        updateProgressViewUI()
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.map?.load { [weak self] _ in
            guard let self = self else { return }
            // Obtain the vector tiled layer and its URL from the baselayers.
            guard let vectorTiledLayer = self.mapView.map?.basemap.baseLayers.firstObject as? AGSArcGISVectorTiledLayer,
                  let vectorTiledLayerURL = vectorTiledLayer.url else { return }
            // The export task to request the tile package with the same URL as the tile layer.
            self.exportVectorTilesTask = AGSExportVectorTilesTask(url: vectorTiledLayerURL)
            self.exportVectorTilesTask?.load { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    self.exportVectorTilesButton.isEnabled = true
                }
            }
        }
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ExportVectorTilesViewController"]
    }
    
    deinit {
        // Remove the temporary directories and all content in it.
        try? FileManager.default.removeItem(at: vtpkTemporaryURL)
        try? FileManager.default.removeItem(at: styleTemporaryURL)
    }
}
