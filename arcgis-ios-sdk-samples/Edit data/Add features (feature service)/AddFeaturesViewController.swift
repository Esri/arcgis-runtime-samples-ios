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

class AddFeaturesViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISStreets)
            // Set touch delegate on map view as self.
            mapView.touchDelegate = self
        }
    }
    
    /// The service geodatabase that contains damaged property features.
    var serviceGeodatabase: AGSServiceGeodatabase!
    /// The feature table to add features to.
    var featureTable: AGSServiceFeatureTable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["AddFeaturesViewController"]
        
        // Load the service geodatabase.
        let damageFeatureService = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer")!
        loadServiceGeodatabase(from: damageFeatureService)
    }
    
    /// Load and set a service geodatabase from a feature service URL.
    /// - Parameter serviceURL: The URL to the feature service.
    func loadServiceGeodatabase(from serviceURL: URL) {
        let serviceGeodatabase = AGSServiceGeodatabase(url: serviceURL)
        serviceGeodatabase.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                let featureTable = serviceGeodatabase.table(withLayerID: 0)!
                self.featureTable = featureTable
                self.serviceGeodatabase = serviceGeodatabase
                // Add the feature layer to the operational layers on map.
                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                self.mapView.map?.operationalLayers.add(featureLayer)
                self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: 544871.19, y: 6806138.66, spatialReference: .webMercator()), scale: 2e6))
            }
        }
    }
    
    /// Add a feature at the tapped point.
    /// - Parameter mapPoint: The point where user tapped.
    func addFeature(at mapPoint: AGSPoint) {
        // Disable interaction with map view.
        mapView.isUserInteractionEnabled = false
        
        // Normalize geometry.
        let normalizedGeometry = AGSGeometryEngine.normalizeCentralMeridian(of: mapPoint)!
        
        // Attributes for the new feature.
        let featureAttributes = ["typdamage": "Minor", "primcause": "Earthquake"]
        // Create a new feature.
        let feature = featureTable.createFeature(attributes: featureAttributes, geometry: normalizedGeometry)
        
        // Add the feature to the feature table.
        featureTable.add(feature) { [weak self] (error: Error?) in
            guard let self = self else { return }
            // Enable interaction with map view.
            self.mapView.isUserInteractionEnabled = true
            
            if let error = error {
                self.presentAlert(message: "Error while adding feature: \(error.localizedDescription)")
            } else {
                // Applied edits on success.
                self.applyEdits()
            }
        }
    }
    
    /// Apply local edits to the geodatabase.
    func applyEdits() {
        guard serviceGeodatabase.hasLocalEdits() else { return }
        serviceGeodatabase.applyEdits { [weak self] featureTableEditResults, error in
            if let featureTableEditResults = featureTableEditResults,
               featureTableEditResults.first?.editResults.first?.completedWithErrors == false {
                self?.presentAlert(message: "Edits applied successfully")
            } else if let error = error {
                self?.presentAlert(message: "Error while applying edits: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Add a feature at the tapped location.
        addFeature(at: mapPoint)
    }
}
