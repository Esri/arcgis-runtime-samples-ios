// Copyright 2021 Esri
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

class Display3DLabelsSceneViewController: UIViewController {
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            // Set the scene to the scene view.
            sceneView.scene = makeScene()
        }
    }
    
    func makeScene() -> AGSScene {
        let scene = AGSScene(
            item: AGSPortalItem(
                portal: AGSPortal.arcGISOnline(withLoginRequired: false),
                itemID: "850dfee7d30f4d9da0ebca34a533c169")
        )
        // Load the scene.
        scene.load { [weak self] error in
            // Get the feature layer.
            if let layers = scene.operationalLayers as? [AGSGroupLayer],
               let groupLayer = layers.first(where: { $0.name == "Gas" }),
               let gasFeatureLayer = groupLayer.layers.firstObject as? AGSFeatureLayer {
                do {
                    guard let labelDefinition = try self?.makeLabelDefinition() else { return }
                    // Enable labels on the feature layer.
                    gasFeatureLayer.labelsEnabled = true
                    gasFeatureLayer.labelDefinitions.removeAllObjects()
                    // Add the label definition to the layer.
                    gasFeatureLayer.labelDefinitions.add(labelDefinition)
                } catch {
                    // If failure to make a label definition, present an error.
                    print(error)
                }
            }
        }
        return scene
    }
    
    func makeLabelDefinition() throws -> AGSLabelDefinition? {
        // Make and stylize the text symbol.
        let textSymbol = AGSTextSymbol()
        textSymbol.angle = 0
        textSymbol.backgroundColor = .clear
        textSymbol.outlineColor = .white
        textSymbol.color = .orange
        textSymbol.haloColor = .white
        textSymbol.haloWidth = 2
        textSymbol.horizontalAlignment = .center
        textSymbol.verticalAlignment = .middle
        textSymbol.isKerningEnabled = false
        textSymbol.offsetX = 0
        textSymbol.offsetY = 0
        textSymbol.fontDecoration = .none
        textSymbol.size = 14
        textSymbol.fontStyle = .normal
        textSymbol.fontWeight = .normal
        let textSymbolJSON = try textSymbol.toJSON()

        // Make a JSON object.
        let labelJSONObject: [String: Any] = [
            "labelExpressionInfo": [
                "expression": "$feature.INSTALLATIONDATE"
            ],
            "labelPlacement": "esriServerPointLabelPlacementAboveCenter",
            "useCodedValues": true,
            "symbol": textSymbolJSON
        ]
        
        //  Create and return a label definition from the JSON object.
        let result = try AGSLabelDefinition.fromJSON(labelJSONObject) as! AGSLabelDefinition
        return result
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["Display3DLabelsSceneViewController"]
    }
}
