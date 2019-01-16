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

import UIKit
import ArcGIS

class ShowLabelsOnLayersViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ShowLabelsOnLayersViewController"]
        
        // create a map with a light gray canvas basemap.
        let map = AGSMap(basemap: .lightGrayCanvas())
        // assign the map to the map view
        mapView.map = map
        
        /// A URL for a feature service layer.
        let featureTableURL = URL(string: "https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/USA_Congressional_Districts_analysis/FeatureServer/0")!
        
        // create a feature table from the URL
        let featureTable = AGSServiceFeatureTable(url: featureTableURL)
        
        // set the map viewpoint to show the layer
        mapView.setViewpointCenter(AGSPoint(x: -10840000, y: 4680000, spatialReference: .webMercator()), scale: 20000000)
        
        // create a feature layer from the table
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        // add the layer to the map
        map.operationalLayers.add(featureLayer)
        
        // turn on labelling
        featureLayer.labelsEnabled = true
       
        do {
            // create label definitions for the two groups
            let demDefinition = try makeLabelDefinition(party: "Democrat", color: .blue)
            let repDefinition = try makeLabelDefinition(party: "Republican", color: .red)
            
            // add the label definitions to the layer
            featureLayer.labelDefinitions.addObjects(from: [demDefinition, repDefinition])
        } catch {
            presentAlert(error: error)
        }
    }
    
    /// Creates a label definition for the given PARTY field value and color.
    private func makeLabelDefinition(party: String, color: UIColor) throws -> AGSLabelDefinition {
        // The JSON syntax reference for AGSLabelDefinition.fromJSON(_:) can be found here:
        // https://developers.arcgis.com/web-map-specification/objects/labelingInfo/
        
        /// The styling for the label.
        let textSymbol = AGSTextSymbol()
        textSymbol.size = 12
        textSymbol.haloColor = .white
        textSymbol.haloWidth = 2
        textSymbol.color = color
        
        // the object must be converted to a JSON object
        let textSymbolJSON = try textSymbol.toJSON()
        
        /// A SQL WHERE statement for filtering the features this label applies to.
        let whereStatement = "PARTY = '\(party)'"
        
        /// An expression that specifies the content of the label using the table's attributes.
        let expression = "$feature.NAME + ' (' + left($feature.PARTY,1) + ')\\nDistrict' + $feature.CDFIPS"
        
        /// The root JSON object defining the label.
        let labelJSONObject: [String: Any] = [
            // see https://developers.arcgis.com/web-map-specification/objects/labelExpressionInfo/
            "labelExpressionInfo": [
                "expression": expression
            ],
            "labelPlacement": "esriServerPolygonPlacementAlwaysHorizontal",
            "where": whereStatement,
            "symbol": textSymbolJSON
        ]
        
        // create and return a label definition from the JSON object
        let result = try AGSLabelDefinition.fromJSON(labelJSONObject)
        if let definition = result as? AGSLabelDefinition {
            return definition
        } else {
            throw ShowLabelsOnLayersError.withDescription("The JSON could not be read as a label definition.")
        }
    }
    
    private enum ShowLabelsOnLayersError: Error {
        case withDescription(String)
    }
}
