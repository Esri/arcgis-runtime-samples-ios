// Copyright 2018 Esri.
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

class FeatureLayerShapefileViewController: UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!

    var map:AGSMap
    var featureLayer:AGSFeatureLayer

    required init?(coder aDecoder: NSCoder) {
        // Instantiate a map using a basemap.
        map = AGSMap(basemap: .streetsVector())

        // Create a shapefile feature table from a named bundle resource.
        let shapefileTable = AGSShapefileFeatureTable(name: "Public_Art")

        // Create a feature layer for the shapefile feature table.
        featureLayer = AGSFeatureLayer(featureTable: shapefileTable)

        // Add the layer to the map.
        map.operationalLayers.add(featureLayer)

        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Display the map in the map view.
        mapView.map = map
        
        // Zoom the map to the Shapefile's extent.
        zoom(mapView: mapView, to: featureLayer)
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureLayerShapefileViewController"]
    }
    
    func zoom(mapView:AGSMapView, to featureLayer:AGSFeatureLayer) {
        // Ensure the feature layer's metadata is loaded.
        featureLayer.load { error in
            guard error == nil else {
                print("Couldn't load the shapefile \(error!.localizedDescription)")
                return
            }
            
            // Once the layer's metadata has loaded, we can read its full extent.
            if let initialExtent = featureLayer.fullExtent {
                mapView.setViewpointGeometry(initialExtent)
            }
        }
    }
}
