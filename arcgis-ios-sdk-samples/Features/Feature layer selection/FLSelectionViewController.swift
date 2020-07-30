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

class FLSelectionViewController: UIViewController {
    // MARK: Storyboard views
    
    /// A label to show the selection status.
    @IBOutlet weak var statusLabel: UILabel!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.touchDelegate = self
            mapView.selectionProperties.color = .cyan
        }
    }
    
    // MARK: Properties and methods
    
    /// An array of selected features.
    var selectedFeatures = [AGSFeature]()
    
    /// The feature layer created from a feature service.
    let featureLayer: AGSFeatureLayer = {
        // Create feature table using a url.
        let featureServiceURL = URL(string: "https://services1.arcgis.com/4yjifSiIG17X0gW4/arcgis/rest/services/GDP_per_capita_1960_2016/FeatureServer/0")!
        let featureTable = AGSServiceFeatureTable(url: featureServiceURL)
        // Create feature layer using this feature table.
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        return featureLayer
    }()
    
    /// Create a map.
    ///
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        // Initialize map with topographic basemap.
        let map = AGSMap(basemap: .streets())
        // Set initial viewpoint.
        map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -180, yMin: -90, xMax: 180, yMax: 90, spatialReference: .wgs84()))
        // Add feature layer to the map.
        map.operationalLayers.add(featureLayer)
        return map
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["FLSelectionViewController"]
        // Load the feature layer.
        featureLayer.load { [weak self] (error) in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                self?.mapView.setViewpointScale(2e8)
            }
        }
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension FLSelectionViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Identify features at the tapped location.
        mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 12.0, returnPopupsOnly: false, maximumResults: 10) { [weak self] result in
            guard let self = self else { return }
            if let error = result.error {
                self.presentAlert(error: error)
                return
            }
            // Un-select previous results.
            self.featureLayer.unselectFeatures(self.selectedFeatures)
            // Select current results.
            self.selectedFeatures = result.geoElements.map { $0 as! AGSFeature }
            self.featureLayer.select(self.selectedFeatures)
            // Show status.
            self.statusLabel.text = "\(result.geoElements.count) feature(s) selected."
        }
    }
}
