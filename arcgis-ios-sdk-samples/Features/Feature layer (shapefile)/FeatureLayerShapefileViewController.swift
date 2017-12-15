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

class FeatureLayerShapefileViewController: UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    var featureLayer:AGSFeatureLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Instantiate a map using a basemap.
        let map = AGSMap(basemap: AGSBasemap.streetsVector())
        
        // Create a shapefile feature table from a named bundle resource.
        let shapefileTable = AGSShapefileFeatureTable(name: "Subdivisions")
        
        // Create a feature layer for the shapefile feature table.
        let shapefileLayer = AGSFeatureLayer(featureTable: shapefileTable)
        
        // Add the layer to the map.
        map.operationalLayers.add(shapefileLayer)
        
        // Display the map in the map view.
        mapView.map = map
        
        // Zoom the map to the Shapefile's extent.
        zoom(mapView: mapView, to: shapefileLayer)
        
        // Hold on to the layer to set its symbology later.
        featureLayer = shapefileLayer
        
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
    
    @IBAction func setShapefileSymbol(_ sender: Any) {
        if let layer = featureLayer {
            // Create a new yellow fill symbol with a red outline.
            let outlineSymbol = AGSSimpleLineSymbol(style: .solid, color: .red, width: 1)
            let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: .yellow, outline: outlineSymbol)
            
            // Create a new renderer using this symbol and set it on the layer.
            layer.renderer = AGSSimpleRenderer(symbol: fillSymbol)
        }
    }
    
}
