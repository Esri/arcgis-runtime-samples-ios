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

class AddDeleteRelatedFeaturesViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISStreets)
            // Set touch delegate on map view as self.
            mapView.touchDelegate = self
        }
    }
    
    /// The feature table that contains national park geometries.
    var parksFeatureTable: AGSServiceFeatureTable!
    /// The feature layer created from the feature table.
    var parksFeatureLayer: AGSFeatureLayer!
    /// The service geodatabase for national park species.
    var serviceGeodatabase: AGSServiceGeodatabase!
    /// The currently selected park feature.
    var selectedPark: AGSArcGISFeature!
    /// Last identify operation.
    var lastQuery: AGSCancelable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["AddDeleteRelatedFeaturesViewController", "RelatedFeaturesViewController"]
        
        // Load the service geodatabase.
        let alaskaNationalParksSpeciesFeatureService = URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksSpecies_Add_Delete/FeatureServer")!
        loadServiceGeodatabase(from: alaskaNationalParksSpeciesFeatureService)
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
                let parksFeatureTable = serviceGeodatabase.table(withLayerID: 0)!
                // Species feature table (destination feature table) which
                // relates to the parks feature table in a 1..M relationship.
                let speciesFeatureTable = serviceGeodatabase.table(withLayerID: 1)!
                self.parksFeatureTable = parksFeatureTable
                self.serviceGeodatabase = serviceGeodatabase
                
                let featureLayer = AGSFeatureLayer(featureTable: parksFeatureTable)
                // Store the feature layer for later use.
                self.parksFeatureLayer = featureLayer
                // Add the park feature layer to the operational layers on map.
                self.mapView.map?.operationalLayers.add(featureLayer)
                
                // Add table to the map. To make the related query work,
                // the related table needs to be present in the map.
                self.mapView.map?.tables.add(speciesFeatureTable)
                self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -16507762.575543, y: 9058828.127243, spatialReference: .webMercator()), scale: 36764077))
            }
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let query = lastQuery { query.cancel() }
        // Show progress hud for identify.
        UIApplication.shared.showProgressHUD(message: "Identifying feature")
        
        // Identify features at tapped location.
        lastQuery = mapView.identifyLayer(parksFeatureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult) in
            // Hide progress HUD.
            UIApplication.shared.hideProgressHUD()
            guard let self = self else { return }
            self.lastQuery = nil
            
            if let feature = identifyLayerResult.geoElements.first as? AGSArcGISFeature {
                // Select the first feature.
                self.selectedPark = feature
                // Show related features view controller.
                self.performSegue(withIdentifier: "RelatedFeaturesSegue", sender: self)
            } else if let error = identifyLayerResult.error {
                // show error to user
                self.presentAlert(error: error)
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "RelatedFeaturesSegue",
           let navigationController = segue.destination as? UINavigationController,
           let controller = navigationController.viewControllers.first as? RelatedFeaturesViewController {
            controller.originFeature = selectedPark
            controller.originFeatureTable = parksFeatureTable
            controller.serviceGeodatabase = serviceGeodatabase
        }
    }
}
