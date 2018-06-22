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

import UIKit
import ArcGIS

class UniqueValueRendererViewController: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    
    private var featureLayer:AGSFeatureLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["UniqueValueRendererViewController"]

        //instantiate map with basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //create feature layer
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer/3")!)
        self.featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        //add the layer to the map as operational layer
        map.operationalLayers.add(self.featureLayer)
        
        //assign map to the map view
        self.mapView.map = map
        
        //set initial viewpoint
        let center = AGSPoint(x: -12966000.5, y: 4441498.5, spatialReference: AGSSpatialReference.webMercator())
        self.mapView.setViewpoint(AGSViewpoint(center: center, scale: 4e7))
        
        //add unique value renderer
        self.addUniqueValueRenderer()
    }

    private func addUniqueValueRenderer() {
        //instantiate a new unique value renderer
        let renderer = AGSUniqueValueRenderer()
        
        //set the field to use for the unique values
        //You can add multiple fields to be used for the renderer in the form of a list, in this case we are only adding a single field
        renderer.fieldNames = ["STATE_ABBR"]
        
        //create symbols to be used in the renderer
        let defaultSymbol = AGSSimpleFillSymbol(style: .null, color: .clear, outline: AGSSimpleLineSymbol(style: .solid, color: .gray, width: 2))
        let californiaSymbol = AGSSimpleFillSymbol(style: .solid, color: .red, outline: AGSSimpleLineSymbol(style: .solid, color: .red, width: 2))
        let arizonaSymbol = AGSSimpleFillSymbol(style: .solid, color: .green, outline: AGSSimpleLineSymbol(style: .solid, color: .green, width: 2))
        let nevadaSymbol = AGSSimpleFillSymbol(style: .solid, color: .blue, outline: AGSSimpleLineSymbol(style: .solid, color: .blue, width: 2))
        
        //set the default symbol
        renderer.defaultSymbol = defaultSymbol
        renderer.defaultLabel = "Other"
        
        //create unique values
        let californiaValue = AGSUniqueValue(description: "State of California", label: "California", symbol: californiaSymbol, values: ["CA"])
        let arizonaValue = AGSUniqueValue(description: "State of Arizona", label: "Arizona", symbol: arizonaSymbol, values: ["AZ"])
        let nevadaValue = AGSUniqueValue(description: "State of Nevada", label: "Nevada", symbol: nevadaSymbol, values: ["NV"])
        
        //add the values to the renderer
        renderer.uniqueValues.append(contentsOf: [californiaValue, arizonaValue, nevadaValue])
        
        //assign the renderer to the feature layer
        self.featureLayer.renderer = renderer
    }
}
