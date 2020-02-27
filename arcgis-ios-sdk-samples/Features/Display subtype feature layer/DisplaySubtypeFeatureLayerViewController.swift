// Copyright 2020 Esri.
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

class DisplaySubtypeFeatureLayerViewController: UIViewController {
    // The map view managed by the view controller.
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    var subtypeSublayer: AGSSubtypeSublayer!
    var originalRenderer: AGSRenderer!
    
    var subtypeFeatureLayer: AGSSubtypeFeatureLayer? {
        didSet {
            if let subtype = subtypeFeatureLayer {
                subtype.load { [weak self] (_) in 
                    self?.subtypeSublayer = subtype.sublayer(withName: "Street Light")
                    self?.originalRenderer = self?.subtypeSublayer?.renderer
                    self?.subtypeSublayer?.labelsEnabled = true
                    do {
                        let label = try self?.makeLabelDefinition()
                        self?.subtypeSublayer?.labelDefinitions.append(label!)
                    } catch {
                        self?.presentAlert(error: error)
                    }
                }
            }
        }
    }
    
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .streetsNightVector())
        map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -9812691.11079696, yMin: 5128687.20710657, xMax: -9812377.9447607, yMax: 5128865.36767282, spatialReference: .webMercator()))

        // Create a subtype feature layer from a service feature table.
        let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer/100")
        let featureTable = AGSServiceFeatureTable(url: featureServiceURL!)
        subtypeFeatureLayer = AGSSubtypeFeatureLayer(featureTable: featureTable)
        subtypeFeatureLayer?.scaleSymbols = false
        map.operationalLayers.add(subtypeFeatureLayer!)
        return map
    }
    
    private func makeLabelDefinition() throws -> AGSLabelDefinition {
        // Make and stylize the text symbol.
        let textSymbol = AGSTextSymbol()
        textSymbol.angle = 0
        textSymbol.backgroundColor = .clear
        textSymbol.outlineColor = .white
        textSymbol.color = .blue
        textSymbol.haloColor = .white
        textSymbol.haloWidth = 2
        textSymbol.horizontalAlignment = .center
        textSymbol.verticalAlignment = .middle
        textSymbol.isKerningEnabled = false
        textSymbol.offsetX = 0
        textSymbol.offsetY = 0
        textSymbol.fontDecoration = .none
        textSymbol.size = 10.5
        textSymbol.fontStyle = .normal
        textSymbol.fontWeight = .normal
        let textSymbolJSON = try textSymbol.toJSON()

        // Make a JSON object.
        let labelJSONObject: [String: Any] = [
            "labelExpression": "[nominalvoltage]",
            "labelPlacement": "esriServerPointLabelPlacementAboveRight",
            "useCodedValues": true,
            "symbol": textSymbolJSON
        ]
        
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
    
     override func viewDidLoad() {
            super.viewDidLoad()
            // Add the source code button item to the right of navigation bar.
            (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplaySubtypeFeatureLayerViewController", "DisplaySubtypeSettingsViewController"]
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.topViewController as? DisplaySubtypeSettingsViewController {
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            controller.map = mapView?.map
            controller.mapScale = mapView.mapScale
            controller.minScale = subtypeSublayer.minScale
            controller.subtypeSublayer = subtypeSublayer
            controller.originalRenderer = self.originalRenderer
            navController.presentationController?.delegate = self
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension DisplaySubtypeFeatureLayerViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // Ensure that the settings show in a popover even on small displays.
        return .none
    }
}
