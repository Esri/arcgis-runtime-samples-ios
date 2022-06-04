// Copyright © 2022 Esri.
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

class CreateClassBreaksViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -13632095.660131, y: 4545009.846004, spatialReference: .webMercator()), scale: 50000))
        }
    }
    
    static let featureServiceURL = URL(string: String("https://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0"))!
    let featureLayer = AGSFeatureLayer(featureTable: AGSServiceFeatureTable(url: featureServiceURL))
    
    func makeMap() {
        createClassBreaksRenderer()
        mapView.map?.operationalLayers.add(featureLayer)
    }
    
    func createClassBreaksRenderer() {
        // Create class breaks renderer using a default symbol and the alternate symbols list.
        let alternateSymbols = createAlternateSymbols()
        let symbol1 = AGSSimpleMarkerSymbol(style: .triangle, color: .red, size: 30)
        let multiLayerSymbol1 = symbol1.toMultilayerSymbol()
        multiLayerSymbol1.referenceProperties = AGSSymbolReferenceProperties(minScale: 5000, maxScale: 0)
        
        // Create a classbreak with alternate symbols.
        let classBreak = AGSClassBreak(description: "classbreak", label: "classbreak", minValue: 0, maxValue: 1, symbol: multiLayerSymbol1, alternateSymbols: alternateSymbols)
        // Create a class breaks renderer.
        let classBreaksRenderer = AGSClassBreaksRenderer()
        // Create and append class breaks.
        classBreaksRenderer.classBreaks.append(classBreak)
        classBreaksRenderer.fieldName = "status"
        let defaultSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .purple, size: 30)
        let defaultMultiSymbol = defaultSymbol.toMultilayerSymbol()
        
        classBreaksRenderer.defaultSymbol = defaultMultiSymbol
        classBreaksRenderer.minValue = 0
        
        // Set the class breaks renderer on the feature layer.
        featureLayer.renderer = classBreaksRenderer
    }
    
    func createAlternateSymbols() {
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["CreateClassBreaksViewController"]
    }
}
