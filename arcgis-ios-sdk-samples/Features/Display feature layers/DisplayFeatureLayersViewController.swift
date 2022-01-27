// Copyright 2022 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class DisplayFeatureLayersViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize map with basemap.
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
        }
    }
    
    @IBOutlet var changeFeatureLayerBarButtonItem: UIBarButtonItem!
    
    // MARK: Instance properties
    enum FeatureLayerSource {
        case serviceFeatureTable
        case portalItem
        case geodatabase
        case geopackage
        case shapefile
    }
    
    var selectedFeatureLayerSource: FeatureLayerSource?
    var geodatabase: AGSGeodatabase!
    var geoPackage: AGSGeoPackage!
    
    
    // MARK: Actions
    
    @IBAction func changeFeatureLayer() {
        let alertController = UIAlertController(title: "Select a feature layer source", message: nil, preferredStyle: .actionSheet)
        // Add an action to load a feature layer from a URL.
        let featureServiceURLAction = UIAlertAction(title: "Service Feature Table", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.selectedFeatureLayerSource = .serviceFeatureTable
            self.loadFeatureServiceURL()
        }
        alertController.addAction(featureServiceURLAction)
        featureServiceURLAction.isEnabled = selectedFeatureLayerSource != .serviceFeatureTable
        // Add an action to load a feature layer from a portal item.
        let portalItemAction = UIAlertAction(title: "Portal Item", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.selectedFeatureLayerSource = .portalItem
            self.loadPortalItem()
        }
        portalItemAction.isEnabled = selectedFeatureLayerSource != .portalItem
        alertController.addAction(portalItemAction)
        // Add an action to load a feature layer from a geodatabase.
        let geodatabaseAction = UIAlertAction(title: "Geodatabase", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.selectedFeatureLayerSource = .geodatabase
            self.loadGeodatabase()
        }
        geodatabaseAction.isEnabled = selectedFeatureLayerSource != .geodatabase
        alertController.addAction(geodatabaseAction)
        // Add an action to load a feature layer from a shapefile.
        let geopackageAction = UIAlertAction(title: "Geopackage", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.selectedFeatureLayerSource = .geopackage
            self.loadGeopackage()
        }
        geopackageAction.isEnabled = selectedFeatureLayerSource != .geopackage
        alertController.addAction(geopackageAction)
        // Add an action to load a feature layer from a shapefile.
        let shapefileAction = UIAlertAction(title: "Shapefile", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            self.selectedFeatureLayerSource = .shapefile
            self.loadShapefile()
        }
        shapefileAction.isEnabled = selectedFeatureLayerSource != .shapefile
        alertController.addAction(shapefileAction)
        
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = changeFeatureLayerBarButtonItem
        present(alertController, animated: true)
    }
    
    // MARK: Helper functions
    
    /// Load a feature layer with a URL.
    func loadFeatureServiceURL() {
        // Initialize the service feature table using a URL.
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver7.arcgisonline.com/server/rest/services/DamageAssessment/FeatureServer/0")!)
        // Create a feature layer with the feature table.
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        // Set the viewpoint to the Los Angeles National Forest.
        let viewpoint = AGSViewpoint(latitude: 41.773519, longitude: -88.143104, scale: 4e3)
        setFeatureLayer(featureLayer, viewpoint: viewpoint)
    }
    
    /// Load a feature layer with a portal item.
    func loadPortalItem() {
        // Set the portal.
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        // Create the portal item with the item ID for the Portland tree service data.
        let item = AGSPortalItem(portal: portal, itemID: "1759fd3e8a324358a0c58d9a687a8578")
        // Create the feature layer with the item and layer ID.
        let featureLayer = AGSFeatureLayer(item: item, layerID: 0)
        // Set the viewpoint to Portland, Oregon.
        let viewpoint = AGSViewpoint(latitude: 45.5266, longitude: -122.6219, scale: 6e3)
        setFeatureLayer(featureLayer, viewpoint: viewpoint)
    }
    
    /// Load a feature layer with a local geodatabase.
    func loadGeodatabase() {
        // Instantiate the geodatabase with the file name.
        geodatabase = AGSGeodatabase(name: "LA_Trails")
        
        // Load the geodatabase for feature tables.
        geodatabase.load { [weak self] (error: Error?) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Get the feature table with the name.
                let featureTable = self.geodatabase.geodatabaseFeatureTable(withName: "Trailheads")!
                // Create a feature layer with the feature table.
                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                // Set the viewpoint to Malibu, California.
                let viewpoint = AGSViewpoint(latitude: 34.0772, longitude: -118.7989, scale: 6e5)
                self.setFeatureLayer(featureLayer, viewpoint: viewpoint)
            }
        }
    }
    
    /// Load a feature layer with a local geopackage.
    func loadGeopackage() {
        // Create a geopackage from a named bundle resource.
        geoPackage = AGSGeoPackage(name: "AuroraCO")
        
        // Load the geopackage.
        geoPackage.load { [weak self] (error: Error?) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Add the first feature layer from the geopackage to the map.
                if let featureTable = self.geoPackage?.geoPackageFeatureTables.first {
                    // Create the feature layer with the feature table.
                    let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                    // Set the viewpoint to Aurora, Colorado.
                    let viewpoint = AGSViewpoint(latitude: 39.7294, longitude: -104.8319, scale: 5e5)
                    self.setFeatureLayer(featureLayer, viewpoint: viewpoint)
                }
            }
        }
    }
    
    /// Load a feature layer with a local shapefile.
    func loadShapefile() {
        // Create a shapefile feature table from a named bundle resource.
        let shapefileTable = AGSShapefileFeatureTable(name: "ScottishWildlifeTrust_ReserveBoundaries_20201102")
        
        // Create a feature layer for the shapefile feature table.
        let featureLayer = AGSFeatureLayer(featureTable: shapefileTable)
        // Set the viewpoint to Scotland.
        let viewpoint = AGSViewpoint(latitude: 56.641344, longitude: -3.889066, scale: 6e6)
        setFeatureLayer(featureLayer, viewpoint: viewpoint)
    }
    
    /// Add the feature layer to the map and set the viewpoint.
    /// - Parameters:
    ///   - featureLayer: The `AGSFeatureLayer` to display and add to the map.
    ///   - viewpoint: The `AGSViewpoint` to change the map to.
    func setFeatureLayer(_ featureLayer: AGSFeatureLayer, viewpoint: AGSViewpoint) {
        mapView.map?.operationalLayers.setArray([featureLayer])
        mapView.setViewpoint(viewpoint)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AGSAuthenticationManager.shared().delegate = self
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayFeatureLayersViewController"]
    }
}

/// Set the credentials to allow access for the Naperville damage assessment feature service.
extension DisplayFeatureLayersViewController: AGSAuthenticationManagerDelegate {
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, didReceive challenge: AGSAuthenticationChallenge) {
        // NOTE: Never hardcode login information in a production application. This is done solely for the sake of the sample.
        let credential = AGSCredential(user: "viewer01", password: "I68VGU^nMurF")
        challenge.continue(with: credential)
    }
}
