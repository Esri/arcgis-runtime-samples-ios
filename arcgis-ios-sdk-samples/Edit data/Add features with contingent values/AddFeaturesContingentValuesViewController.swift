// Copyright 2022 Esri
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

class AddFeaturesContingentValuesViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            // Add the graphics overlay to the map view.
            mapView.graphicsOverlays.add(graphicsOverlay)
            // Set the map view's touch delegate.
            mapView.touchDelegate = self
        }
    }
    
    let geodatabase: AGSGeodatabase!
    /// The graphics overlay to add the feature to.
    let graphicsOverlay = AGSGraphicsOverlay()
    /// The geodatabase's feature table.
    var featureTable: AGSArcGISFeatureTable?
    /// The map point to add the feature to.
    var mapPoint: AGSPoint?
    
    required init?(coder: NSCoder) {
        let geodatabaseURL = Bundle.main.url(forResource: "ContingentValuesBirdNests", withExtension: "geodatabase")!
        do {
            // Create a temporary directory.
            let temporaryDirectoryURL = try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: geodatabaseURL, create: true)
            // Create a temporary URL where the geodatabase URL can be copied to.
            let temporaryGeodatabaseURL = temporaryDirectoryURL.appendingPathComponent("birdsNestGDB", isDirectory: false).appendingPathExtension("geodatabase")
            // Copy the item to the temporary URL.
            try FileManager.default.copyItem(at: geodatabaseURL, to: temporaryGeodatabaseURL)
            // Create the geodatabase with the URL.
            geodatabase = AGSGeodatabase(fileURL: temporaryGeodatabaseURL)
        } catch {
            print("Error setting up geodatabase: \(error)")
            geodatabase = nil
        }
        
        super.init(coder: coder)
        
        // Load the geodatabase.
        geodatabase?.load { [weak self] (error) in
            let result: Result<Void, Error>
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
            self?.geodatabaseDidLoad(with: result)
        }
    }
    
    deinit {
        if let geodatabase = geodatabase {
            geodatabase.close()
            // Remove all of the temporary files.
            try? FileManager.default.removeItem(at: geodatabase.fileURL)
            // Remove the temporary directory.
            let temporaryGeodatabaseURL = geodatabase.fileURL.deletingLastPathComponent()
            try? FileManager.default.removeItem(at: temporaryGeodatabaseURL)
        }
    }
    
    /// Called in response to the geodatabase load operation completing.
    func geodatabaseDidLoad(with result: Result<Void, Error>) {
        switch result {
        case .success:
            // Get and load the first feature table in the geodatabase.
            let featureTable = geodatabase.geodatabaseFeatureTables[0] as AGSArcGISFeatureTable
            self.featureTable = featureTable
            featureTable.load { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    // Create and load the feature layer from the feature table.
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    // Add the feature layer to the map.
                    self.mapView.map?.operationalLayers.add(featureLayer)
                    // Set the map's viewpoint to the feature layer's full extent.
                    let extent = featureLayer.fullExtent
                    self.mapView.setViewpoint(AGSViewpoint(targetExtent: extent!))
                    // Add buffer graphics for the feature layer.
                    self.queryFeatures()
                }
            }
        case .failure(let error):
            presentAlert(error: error)
        }
    }
    
    /// Create a map with a vector tiled layer basemap.
    func makeMap() -> AGSMap {
        // Get the vector tiled layer by name.
        let fillmoreVectorTiledLayer = AGSArcGISVectorTiledLayer(name: "FillmoreTopographicMap")
        // Use the vector tiled layer as a basemap.
        let basemap = AGSBasemap(baseLayer: fillmoreVectorTiledLayer)
        let map = AGSMap(basemap: basemap)
        return map
    }
    
    /// Create buffer graphics for the features.
    func queryFeatures() {
        guard let featureTable = featureTable else { return }
        // Create the query parameters.
        let queryParameters = AGSQueryParameters()
        // Set the where clause to filter for buffer sizes greater than 0.
        queryParameters.whereClause = "BufferSize > 0"
        // Query the features with the query parameters.
        featureTable.queryFeatures(with: queryParameters) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                // Present an alert if there is an error while querying the features.
                self.presentAlert(error: error)
            } else if let result = result {
                // Creates buffer symbol for each feature according to its buffer size.
                let newGraphics = result.featureEnumerator().allObjects.map(self.makeGraphic(feature:))
                // Replace existing graphics with the new graphics.
                self.graphicsOverlay.graphics.setArray(newGraphics)
            }
        }
    }
    
    /// Add a single feature to the map.
    func addFeature(at mapPoint: AGSPoint) {
        // Create a symbol to represent a bird's nest.
        let symbol = AGSSimpleMarkerSymbol(style: .circle, color: .black, size: 11)
        // Add the graphic to the graphics overlay.
        graphicsOverlay.graphics.add(AGSGraphic(geometry: mapPoint, symbol: symbol))
        // Show the attributes table view.
        performSegue(withIdentifier: "AddFeature", sender: self)
    }
    
    /// Create a graphic for the given feature.
    func makeGraphic(feature: AGSFeature) -> AGSGraphic {
        // Get the feature's buffer size.
        let bufferSize = feature.attributes["BufferSize"] as! Double
        // Get a polygon using the feature's buffer size and geometry.
        let polygon = AGSGeometryEngine.bufferGeometry(feature.geometry!, byDistance: bufferSize)
        // Create the outline for the buffers.
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 2)
        // Create the buffer symbol.
        let bufferSymbol = AGSSimpleFillSymbol(style: .forwardDiagonal, color: .red, outline: lineSymbol)
        // Create an a graphic and add it to the array.
        return AGSGraphic(geometry: polygon, symbol: bufferSymbol)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "AddFeaturesContingentValuesViewController",
            "ContingentValuesTableViewController"
        ]
    }
    
    // MARK: Navigation
    
    /// Prepare for the segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Set the controller and its properties.
        if let navigationController = segue.destination as? UINavigationController,
           let controller = navigationController.viewControllers.first as? ContingentValuesTableViewController {
            controller.isModalInPresentation = true
            controller.featureTable = featureTable
            controller.graphicsOverlay = graphicsOverlay
            controller.delegate = self
        }
    }
}

extension AddFeaturesContingentValuesViewController: ContingentValuesDelegate {
    func contingentValuesTableViewController(_ controller: ContingentValuesTableViewController, didFinishWith feature: AGSFeature) {
        feature.geometry = mapPoint
        // Add the feature to the feature table.
        featureTable?.add(feature) { [weak self] _ in
            guard let self = self else { return }
            let graphic = self.makeGraphic(feature: feature)
            // Add the graphic to the graphics overlay.
            self.graphicsOverlay.graphics.add(graphic)
        }
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension AddFeaturesContingentValuesViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Get the point on the map where the user tapped.
        self.mapPoint = mapPoint
        addFeature(at: mapPoint)
    }
}
