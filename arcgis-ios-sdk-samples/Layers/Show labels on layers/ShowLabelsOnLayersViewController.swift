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
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            // Create a map with a light gray canvas basemap.
            mapView.map = AGSMap(basemapStyle: .arcGISLightGrayBase)
            // Set the map viewpoint to show the layer.
            mapView.setViewpointCenter(AGSPoint(x: -10840000, y: 4680000, spatialReference: .webMercator()), scale: 20000000)
        }
    }
    
    /// Adds a feature layer and its labels.
    private func addLayerAndLabels() {
        // A URL for a feature service layer.
        let featureTableURL = URL(string: "https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/USA_Congressional_Districts_analysis/FeatureServer/0")!
        
        // Create a feature table from the URL.
        let featureTable = AGSServiceFeatureTable(url: featureTableURL)
        // Create a feature layer from the table.
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        // Add the layer to the map.
        mapView.map?.operationalLayers.add(featureLayer)
        // Turn on labeling.
        featureLayer.labelsEnabled = true
        
        // Create label definitions for the two groups.
        let demDefinition = makeLabelDefinition(party: "Democrat", color: .blue)
        let repDefinition = makeLabelDefinition(party: "Republican", color: .red)
        
        // Add the label definitions to the layer.
        featureLayer.labelDefinitions.addObjects(from: [demDefinition, repDefinition])
    }
    
    /// Creates a label definition for the given PARTY field value and color.
    private func makeLabelDefinition(party: String, color: UIColor) -> AGSLabelDefinition {
        // The styling for the label.
        let textSymbol = AGSTextSymbol()
        textSymbol.size = 12
        textSymbol.haloColor = .white
        textSymbol.haloWidth = 2
        textSymbol.color = color
        
        // An SQL WHERE statement for filtering the features this label applies to.
        let whereStatement = "PARTY = '\(party)'"
        // An expression that specifies the content of the label using the table's attributes.
        let expression = "$feature.NAME + ' (' + left($feature.PARTY,1) + ')\\nDistrict' + $feature.CDFIPS"
        // Make an arcade label expression.
        let arcadeLabelExpression = AGSArcadeLabelExpression(arcadeString: expression)
        let labelDefinition = AGSLabelDefinition(labelExpression: arcadeLabelExpression, textSymbol: textSymbol)
        labelDefinition.placement = .polygonAlwaysHorizontal
        labelDefinition.whereClause = whereStatement
        return labelDefinition
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLayerAndLabels()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ShowLabelsOnLayersViewController"]
    }
}
