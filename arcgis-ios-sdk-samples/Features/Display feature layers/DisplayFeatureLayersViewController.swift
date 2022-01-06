// Copyright 2021 Esri
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
            let map = AGSMap(basemapStyle: .arcGISTerrain)
            
            // Assign map to the map view.
            self.mapView.map = map
            self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -13176752, y: 4090404, spatialReference: .webMercator()), scale: 300000))
        }
    }
    
    @IBOutlet var changeFeatureLayerBarButtonItem: UIBarButtonItem!
    var geodatabase: AGSGeodatabase!
    var geoPackage: AGSGeoPackage?
    
    @IBAction func changeFeatureLayer() {
        let alertController = UIAlertController(title: "Select a feature layer source", message: nil, preferredStyle: .actionSheet)
        let featureServiceURLAction = UIAlertAction(title: "Feature service URL", style: .default) { (_) in
            self.loadFeatureServiceURL()
        }
        alertController.addAction(featureServiceURLAction)
        let portalItemAction = UIAlertAction(title: "Portal item", style: .default) { (_) in
            self.loadPortalItem()
        }
        alertController.addAction(portalItemAction)
        let geodatabaseAction = UIAlertAction(title: "Geodatabase", style: .default) { (_) in
            self.loadGeodatabase()
        }
        alertController.addAction(geodatabaseAction)
        let geopackageAction = UIAlertAction(title: "Geopackage", style: .default) { (_) in
            self.loadGeopackage()
        }
        alertController.addAction(geopackageAction)
        let shapefileAction = UIAlertAction(title: "Shapefile", style: .default) { (_) in
            self.loadShapefile()
        }
        alertController.addAction(shapefileAction)
        
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        alertController.popoverPresentationController?.barButtonItem = changeFeatureLayerBarButtonItem
        present(alertController, animated: true)
    }
    
    func loadFeatureServiceURL() {
        // initialize service feature table using url
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/9")!)

        // create a feature layer
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        // initialize map with basemap
        let map = AGSMap(basemapStyle: .arcGISTerrain)
        // add the feature layer to the operational layers
        map.operationalLayers.add(featureLayer)
        // assign map to the map view
        self.mapView.map = map
        self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -13176752, y: 4090404, spatialReference: .webMercator()), scale: 300000))
    }
    
    func loadPortalItem() {
        let portal = AGSPortal.arcGISOnline(withLoginRequired: false)
        let item = AGSPortalItem(portal: portal, itemID: "1759fd3e8a324358a0c58d9a687a8578")
        let featureLayer = AGSFeatureLayer(item: item, layerID: 0)
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        map.operationalLayers.add(featureLayer)
        self.mapView.map = map
        mapView.setViewpoint(AGSViewpoint(latitude: 45.5266, longitude: -122.6219, scale: 6000))
    }
    
    func loadGeodatabase() {
        // instantiate map with basemap
        let map = AGSMap(basemapStyle: .arcGISImagery)
        
        // assign map to the map view
        mapView.map = map
        mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -13214155, y: 4040194, spatialReference: .webMercator()), scale: 35e4))
        
        // instantiate geodatabase with name
        self.geodatabase = AGSGeodatabase(name: "LA_Trails")
        
        // load the geodatabase for feature tables
        self.geodatabase.load { [weak self] (error: Error?) in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                let featureTable = self!.geodatabase.geodatabaseFeatureTable(withName: "Trailheads")!
                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                self?.mapView.map?.operationalLayers.add(featureLayer)
            }
        }
    }
    
    func loadGeopackage() {
        // Instantiate a map.
        let map = AGSMap(basemapStyle: .arcGISLightGrayBase)
        
        // Display the map in the map view.
        mapView.map = map
        mapView.setViewpoint(AGSViewpoint(latitude: 39.7294, longitude: -104.8319, scale: 577790.554289))
        
        // Create a geopackage from a named bundle resource.
        geoPackage = AGSGeoPackage(name: "AuroraCO")
        
        // Load the geopackage.
        geoPackage?.load { [weak self] error in
            guard error == nil else {
                self?.presentAlert(message: "Error opening Geopackage: \(error!.localizedDescription)")
                return
            }
            
            // Add the first feature layer from the geopackage to the map.
            if let featureTable = self?.geoPackage?.geoPackageFeatureTables.first {
                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                map.operationalLayers.add(featureLayer)
            }
        }
    }
    
    func loadShapefile() {
        // Instantiate a map using a basemap.
        let map = AGSMap(basemapStyle: .arcGISStreets)

        // Create a shapefile feature table from a named bundle resource.
        let shapefileTable = AGSShapefileFeatureTable(name: "Public_Art")

        // Create a feature layer for the shapefile feature table.
        let featureLayer = AGSFeatureLayer(featureTable: shapefileTable)

        // Add the layer to the map.
        map.operationalLayers.add(featureLayer)
        mapView.map = map
        // Ensure the feature layer's metadata is loaded.
        featureLayer.load { error in
            guard error == nil else {
                print("Couldn't load the shapefile \(error!.localizedDescription)")
                return
            }
            
            // Once the layer's metadata has loaded, we can read its full extent.
            if let initialExtent = featureLayer.fullExtent {
                self.mapView.setViewpointGeometry(initialExtent)
            }
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayFeatureLayersViewController"]
    }
}
