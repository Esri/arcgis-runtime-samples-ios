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

class OverrideRendererViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureLayer:AGSFeatureLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OverrideRendererViewController"]
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        //initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -1.30758164047166E7, yMin: 4014771.46954516, xMax: -1.30730056797177E7
            , yMax: 4016869.78617381, spatialReference: AGSSpatialReference.webMercator()))
        //assign map to the map view's map
        self.mapView.map = self.map
        
        //initialize feature table using a url to feature server url
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/PoolPermits/FeatureServer/0")!)
        //initialize feature layer with feature table
        self.featureLayer = AGSFeatureLayer(featureTable: featureTable)
        //add the feature layer to the operational layers on the map view
        self.map.operationalLayers.add(self.featureLayer)
        
    }
    
    @IBAction private func overrideRenderer() {
        //create a symbol to be used in the renderer
        let symbol = AGSSimpleLineSymbol(style: AGSSimpleLineSymbolStyle.solid, color: .blue, width: 2)
        //create a new renderer using the symbol just created
        let renderer = AGSSimpleRenderer(symbol: symbol)
        //assign the new renderer to the feature layer
        self.featureLayer.renderer = renderer
    }
    
    @IBAction private func resetRenderer() {
        //reset the renderer to default
        self.featureLayer.resetRenderer()
    }
}
