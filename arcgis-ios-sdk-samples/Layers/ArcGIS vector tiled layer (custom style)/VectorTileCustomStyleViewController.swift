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
//

import UIKit
import ArcGIS

class VectorTileCustomStyleViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap()
        }
    }
    /// The button to change vector tile style.
    @IBOutlet var changeStyleBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    /// A list of portal item IDs for the online layers.
    let onlineItemIDs = [
        "1349bfa0ed08485d8a92c442a3850b06",
        "bd8ac41667014d98b933e97713ba8377",
        "02f85ec376084c508b9c8e5a311724fa",
        "1bf0cc4a4380468fbbff107e100f65a5"
    ]
    
    /// A list of portal item IDs for the layers which custom style is applied from local resources.
    let offlineItemIDs = [
        // A vector tiled layer created by the local VTPK and day custom style.
        "e01262ef2a4f4d91897d9bbd3a9b1075",
        // A vector tiled layer created by the local VTPK and night custom style.
        "ce8a34e5d4ca4fa193a097511daa8855"
    ]
    /// A URL to the temporary directory to store the exported tile packages.
    let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
    /// The item ID of the currently showing layer.
    var currentItemID: String?
    /// A dictionary to cache loaded vector tiled layers.
    var vectorTiledLayers = [String: AGSArcGISVectorTiledLayer]()
    /// An export job to export the item resource cache.
    var exportVectorTilesJob: AGSExportVectorTilesJob!
    
    // MARK: Methods
    
    /// Get the URL to a portal item specific temporary directory.
    ///
    /// - Parameter itemID: The portal item ID.
    /// - Returns: A URL to the temporary directory.
    func getDownloadDirectoryURL(itemID: String) -> URL {
        let directoryURL = temporaryDirectoryURL.appendingPathComponent(itemID)
        // Create and return the full, unique URL to the temporary directory.
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }
    
    /// Get the vector tiled layer's portal URL.
    func getPortalURL(itemID: String) -> URL {
        return URL(string: "https://www.arcgis.com/home/item.html?id=\(itemID)")!
    }
    
    /// Load vector tiled layer with offline custom styles in VTPK.
    ///
    /// - Parameters:
    ///   - itemID: The portal item ID.
    ///   - completion: A closure to pass back the layer with custom style.
    func loadVectorTiledLayerWithOfflineCustomStyle(itemID: String, completion: @escaping (AGSArcGISVectorTiledLayer) -> Void) {
        // The portal item from the URL.
        let portalItem = AGSPortalItem(url: getPortalURL(itemID: itemID))!
        // An export task to export the custom style resources.
        let task = AGSExportVectorTilesTask(portalItem: portalItem)
        // The job to export the item resource cache.
        let job = task.exportStyleResourceCacheJob(withDownloadDirectory: getDownloadDirectoryURL(itemID: itemID))
        // Hold a strong reference to the job until it finishes.
        exportVectorTilesJob = job
        
        job.start(
            statusHandler: { (status: AGSJobStatus) in
                SVProgressHUD.show(withStatus: status.statusString())
            }, completion: { [weak self] result, error in
                SVProgressHUD.dismiss()
                guard let self = self else { return }
                if let result = result {
                    // The vector tile cache created from the local vector tile package.
                    let vectorTileCache = AGSVectorTileCache(name: "dodge_city")
                    // Create a vector tiled layer with the vector tiled cache and the item resource cache.
                    let layer = AGSArcGISVectorTiledLayer(vectorTileCache: vectorTileCache, itemResourceCache: result.itemResourceCache)
                    // Pass back the exported layer.
                    completion(layer)
                } else if let error = error {
                    // Handle errors.
                    self.presentAlert(error: error)
                }
                // De-reference the job.
                self.exportVectorTilesJob = nil
            }
        )
    }
    
    // MARK: UI
    
    func showSelectedItem(_ itemID: String) {
        // Record currently showing layer's item ID.
        currentItemID = itemID
        
        if onlineItemIDs.contains(itemID) {
            // The vector tiled layer with custom style is stored online.
            let vectorTiledLayer: AGSArcGISVectorTiledLayer
            if let layer = vectorTiledLayers[itemID] {
                // Retrieve cached layer if it exists.
                vectorTiledLayer = layer
            } else {
                // Create a vector tiled layer from the URL.
                vectorTiledLayer = AGSArcGISVectorTiledLayer(url: getPortalURL(itemID: itemID))
                vectorTiledLayers[itemID] = vectorTiledLayer
            }
            // Set the layer to the map.
            let viewpoint = AGSViewpoint(center: AGSPoint(x: 1990591.559979, y: 794036.007991, spatialReference: .webMercator()), scale: 1e8)
            setMap(layer: vectorTiledLayer, viewpoint: viewpoint)
        } else if offlineItemIDs.contains(itemID) {
            // The custom style is stored offline in a VTPK.
            
            // The viewpoint to display Dodge City, KS.
            let dodgeViewpoint = AGSViewpoint(center: AGSPoint(x: -100.01766, y: 37.76528, spatialReference: .wgs84()), scale: 4e4)
            if let layer = vectorTiledLayers[itemID] {
                // Retrieve cached layer if it exists.
                setMap(layer: layer, viewpoint: dodgeViewpoint)
            } else {
                // Load the custom style from a local VTPK.
                loadVectorTiledLayerWithOfflineCustomStyle(itemID: itemID) { [weak self, viewpoint = dodgeViewpoint] layer in
                    guard let self = self else { return }
                    self.vectorTiledLayers[itemID] = layer
                    self.setMap(layer: layer, viewpoint: viewpoint)
                }
            }
        }
    }
    
    func setMap(layer: AGSArcGISVectorTiledLayer, viewpoint: AGSViewpoint) {
        // Reset the map to release resources.
        mapView.map = nil
        // Assign a new map created from the base layer.
        mapView.map = AGSMap(basemap: AGSBasemap(baseLayer: layer))
        // Set viewpoint without animation.
        mapView.setViewpoint(viewpoint)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["VectorTileCustomStyleViewController", "VectorStylesViewController"]
        
        // Show the first vector tiled layer.
        showSelectedItem(onlineItemIDs.first!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? VectorStylesViewController {
            controller.delegate = self
            controller.itemIDs = onlineItemIDs + offlineItemIDs
            controller.selectedItemID = currentItemID
            controller.presentationController?.delegate = self
            let height = controller.itemIDs.count * 45
            controller.preferredContentSize = CGSize(width: 300, height: height)
        }
    }
    
    deinit {
        // Remove the temporary directory and all content in it.
        try? FileManager.default.removeItem(at: temporaryDirectoryURL)
    }
}

// MARK: - VectorStylesVCDelegate

extension VectorTileCustomStyleViewController: VectorStylesVCDelegate {
    func vectorStylesViewController(_ vectorStylesViewController: VectorStylesViewController, didSelectItemWithID itemID: String) {
        // Show the newly selected vector layer.
        showSelectedItem(itemID)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension VectorTileCustomStyleViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // Show presented controller as a popover.
        return .none
    }
}
