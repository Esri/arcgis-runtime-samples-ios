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

    /// A bar button to initiate the download task.
    @IBOutlet var exportVectorTilesButton: UIBarButtonItem!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var progressLabel: UILabel!
    @IBOutlet var progressParentView: UIView!
    @IBOutlet var cancelButton: UIButton!
    
    // MARK: Properties
    
    var vectorTiledLayer: AGSArcGISVectorTiledLayer?
    var extent: AGSEnvelope?
    /// The export task to request the tile package with the same URL as the tile layer.
    var exportVectorTilesTask: AGSExportVectorTilesTask?
    /// An export job to download the tile package.
    var job: AGSExportVectorTilesJob? {
        didSet {
            // Remove key-value observation.
            progressObservation = nil
            exportVectorTilesButton.isEnabled = job == nil
            updateProgressViewUI()
            progressView.observedProgress = job?.progress
            progressObservation = job?.progress.observe(\.localizedDescription, options: .initial) { [weak self] progress, _ in
                DispatchQueue.main.async {
                    // Update the progress label.
                    self?.progressLabel.text = progress.localizedDescription
                }
            }
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
        let areaOfInterest = envelope(for: extentView)
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
        // Create the job with the parameters and download URLs.
        let job = exportTask.exportVectorTilesJob(with: parameters, vectorTileCacheDownloadFileURL: vtpkTemporaryURL, itemResourceCacheDownloadDirectory: styleTemporaryURL)
        self.job = job
        // Start the job.
        job.start(statusHandler: nil) { [weak self] (result, error) in
            guard let self = self else { return }
            self.job = nil
            if let result = result,
               let tileCache = result.vectorTileCache,
               let itemResourceCache = result.itemResourceCache {
                // Create the vector tiled layer with the tile cache and item resource cache.
                self.vectorTiledLayer = AGSArcGISVectorTiledLayer(vectorTileCache: tileCache, itemResourceCache: itemResourceCache)
                // Set the extent.
                self.extent = parameters.areaOfInterest as? AGSEnvelope
                self.performSegue(withIdentifier: "showResult", sender: nil)
            } else if let error = error {
                let nsError = error as NSError
                if !(nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError) {
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
        } else {
            // Show the progress parent view.
            progressParentView.isHidden = false
        }
    }
    
    func removeDirectories() {
        // Remove the temporary directories and all content in it.
        try? FileManager.default.removeItem(at: vtpkTemporaryURL)
        try? FileManager.default.removeItem(at: styleTemporaryURL)
    }
    
    // MARK: Actions
    
    @IBAction func exportTilesBarButtonTapped(_ sender: UIBarButtonItem) {
        if let exportVectorTilesTask = exportVectorTilesTask,
           let vectorTileSourceInfo = exportVectorTilesTask.vectorTileSourceInfo,
           vectorTileSourceInfo.exportTilesAllowed {
            // Try to download when exporting tiles is allowed.
            initiateDownload(exportTask: exportVectorTilesTask, vectorTileCacheURL: vtpkTemporaryURL)
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
        removeDirectories()
    }
    
    @IBAction func cancelAction() {
        // Cancel export vector tiles job and update the UI.
        job?.progress.cancel()
        updateProgressViewUI()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
           let rootController = navController.viewControllers.first as? VectorTilePackageViewController {
            rootController.tiledLayerResult = vectorTiledLayer
            rootController.extent = extent
        }
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
        removeDirectories()
    }
}

extension ExportVectorTilesViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // Ensure that the settings are shown in a popover on small displays.
        return .formSheet
    }
}
