// Copyright 2021 Esri
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

class EditAttributesContingentValuesViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
        }
    }
    // The geodatabase used by this sample.
    let geodatabase: AGSGeodatabase!
    var graphicsOverlay = AGSGraphicsOverlay()
    var featureTable: AGSArcGISFeatureTable?
    var mapPoint: AGSPoint?
    
    required init?(coder: NSCoder) {
        // Create a URL leading to the resource.
        let geodatabaseURL = Bundle.main.url(forResource: "ContingentValuesBirdNests", withExtension: "geodatabase")!
        do {
            // Create a temporary directory URL.
            let temporaryDirectoryURL = try FileManager.default.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: geodatabaseURL,
                create: true
            )
            // Create a temporary URL where the geodatabase URL can be copied to.
            let temporaryGeodatabaseURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
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
            try? FileManager.default.removeItem(at: geodatabase.fileURL)
        }
    }
    
    /// Called in response to the geodatabase load operation completing.
    func geodatabaseDidLoad(with result: Result<Void, Error>) {
        switch result {
        case .success:
            // Get the first feature table in the geodatabase.
            featureTable = geodatabase.geodatabaseFeatureTables[0] as AGSArcGISFeatureTable
            // Create and load the feature layer from the feature table.
            let featureLayer = AGSFeatureLayer(featureTable: featureTable!)
            featureLayer.load { [weak self] _ in
                guard let self = self else { return }
                // Add the feature layer to the map.
                self.mapView.map?.operationalLayers.add(featureLayer)
                // Set the map's viewpoint to the feature layer's full extent.
                let extent = featureLayer.fullExtent
                self.mapView.setViewpoint(AGSViewpoint(targetExtent: extent!))
                // Add buffer graphics for the feature layer.
                self.createBufferGraphics()
            }
        case .failure(let error):
            presentAlert(error: error)
        }
    }
    
    /// Add a single feature to the map.
    func addFeature(at mapPoint: AGSPoint) {
        // Create a symbol to represent a bird's nest.
        let symbol = AGSSimpleMarkerSymbol(style: .circle , color: .black, size: 11)
        // Add the graphic to the graphics overlay.
        self.graphicsOverlay.graphics.add(AGSGraphic(geometry: mapPoint, symbol: symbol))
        // Show the attributes table view.
        performSegue(withIdentifier: "AddFeature", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the map view's touch delegate.
        mapView.touchDelegate = self
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "EditAttributesContingentValuesViewController",
            "AddContingentValuesViewController"
        ]
    }
    
    // MARK: - Navigation
    
    /// Prepare for the segue.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Set the controller and its properties.
        if let navigationController = segue.destination as? UINavigationController,
           let controller = navigationController.viewControllers.first as? AddContingentValuesViewController {
            controller.isModalInPresentation = true
            controller.featureTable = featureTable
            controller.graphicsOverlay = graphicsOverlay
            controller.mapPoint = mapPoint
            controller.delegate = self
        }
    }
}

extension EditAttributesContingentValuesViewController: ContingentValuesDelegate {
    /// Create buffer graphics for the features.
    func createBufferGraphics() {
        // Create the query parameters.
        let queryParameters = AGSQueryParameters()
        // Set the where clause to filter for buffer sizes greater than 0.
        queryParameters.whereClause = "BufferSize > 0"
        // Create an array of graphics to add to the graphics overlay.
        var graphics = [AGSGraphic]()
        // Create a graphics overlay.
        let graphicsOverlay = AGSGraphicsOverlay()
        // Create the outline for the buffers.
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 2)
        // Create the buffer symbol.
        let bufferSymbol = AGSSimpleFillSymbol(style: .forwardDiagonal, color: .red, outline: lineSymbol)
        // Query the features with the query parameters.
        featureTable?.queryFeatures(with: queryParameters) { [weak self ] result, error in
            guard let self = self else { return }
            if let error = error {
                // Present an alert if there is an error while querying the features.
                self.presentAlert(error: error)
            } else if let result = result {
                // Get the array of features from the query result.
                let features = result.featureEnumerator().allObjects
                // For each feature, add the buffer symbol according to its buffer size.
                features.forEach { feature in
                    // Get the feature's buffer size.
                    let bufferSize = feature.attributes["BufferSize"] as! Double
                    // Get a polygon using the feature's buffer size and geometry.
                    let polygon = AGSGeometryEngine.bufferGeometry(feature.geometry!, byDistance: bufferSize)
                    // Create an a graphic and add it to the array.
                    let graphic = AGSGraphic(geometry: polygon, symbol: bufferSymbol)
                    graphics.append(graphic)
                }
                // Add the graphics to the graphics overlay.
                graphicsOverlay.graphics.addObjects(from: graphics)
                // Add the graphics overlay to the map view.
                self.mapView.graphicsOverlays.add(graphicsOverlay)
            }
        }
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension EditAttributesContingentValuesViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Get the point on the map where the user tapped.
        self.mapPoint = mapPoint
        addFeature(at: mapPoint)
    }
}
