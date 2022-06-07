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
        
        // Create a unique value with alternate symbols.
        let uniqueValue = AGSUniqueValue(description: "unique values based on request type", label: "unique value", symbol: multiLayerSymbol1, values: ["Damaged Property"], alternateSymbols: alternateSymbols)
        // Create a class breaks renderer.
        let uniqueValueRenderer = AGSUniqueValueRenderer()
        // Create and append class breaks.
        uniqueValueRenderer.uniqueValues.append(uniqueValue)
        uniqueValueRenderer.fieldNames = ["req_type"]
        let defaultSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .purple, size: 15)
        uniqueValueRenderer.defaultSymbol = defaultSymbol.toMultilayerSymbol()
        
        // Set the class breaks renderer on the feature layer.
        featureLayer.renderer = uniqueValueRenderer
    }
    
    func createAlternateSymbols() -> [AGSMultilayerPointSymbol]{
        let alternateSymbol = AGSSimpleMarkerSymbol(style: .square, color: .blue, size: 30)
        let alternateSymbolMultilayer1 = alternateSymbol.toMultilayerSymbol()
        alternateSymbolMultilayer1.referenceProperties = AGSSymbolReferenceProperties(minScale: 10000, maxScale: 5000)
        
        let alternateSymbol2 = AGSSimpleMarkerSymbol(style: .diamond, color: .yellow, size: 30)
        let alternateSymbolMultilayer2 = alternateSymbol2.toMultilayerSymbol()
        alternateSymbolMultilayer2.referenceProperties = AGSSymbolReferenceProperties(minScale: 20000, maxScale: 10000)
        
        return [alternateSymbolMultilayer1, alternateSymbolMultilayer2]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["CreateClassBreaksViewController"]
    }
}
