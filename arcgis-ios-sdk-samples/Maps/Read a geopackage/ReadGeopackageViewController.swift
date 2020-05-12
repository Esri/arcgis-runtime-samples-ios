// Copyright 2017 Esri.
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

import ArcGIS

class ReadGeopackageViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }

    func makeMap() -> AGSMap {
        // Instantiate and display a map using a basemap, location, and zoom level.
        let map = AGSMap(basemapType: .streets, latitude: 39.7294, longitude: -104.8319, levelOfDetail: 11)
        
        // Create a geopackage from a named bundle resource.
        let geoPackage = AGSGeoPackage(name: "AuroraCO")
        
        // Load the geopackage.
        geoPackage.load { [weak self] error in
            guard error == nil else {
                self?.presentAlert(message: "Error opening Geopackage: \(error!.localizedDescription)")
                return
            }

            // Create feature layers for each feature table in the geopackage.
            let featureLayers = geoPackage.geoPackageFeatureTables.map { AGSFeatureLayer(featureTable: $0) }
            
            // Create raster layers for each raster in the geopackage.
            let rasterLayers = geoPackage.geoPackageRasters.map { raster -> AGSLayer in
                let rasterLayer = AGSRasterLayer(raster: raster)
                //make it semi-transparent so it doesn't obscure the contents under it
                rasterLayer.opacity = 0.55
                return rasterLayer
            }
            
            // Add the arrays of feature and raster layers to the map.
            map.operationalLayers.addObjects(from: rasterLayers)
            map.operationalLayers.addObjects(from: featureLayers)
        }
        return map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ReadGeopackageViewController"]
    }
}
