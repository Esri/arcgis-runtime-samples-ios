// Copyright 2020 Esri
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
            let scene = makeScene()
            // Load the scene.
            scene.load { [ weak self ] error in
                // Get the feature layer.
                let layers = scene.operationalLayers as! [AGSGroupLayer]
                let groupLayer = layers.first(where: { $0.name == "Gas" })
                let gasFeatureLayer = groupLayer?.layers[0] as! AGSFeatureLayer
                // Enable labels on the feature layer.
                gasFeatureLayer.labelsEnabled = true
                do {
                    guard let labelDefinition = try self?.makeLabelDefinition() else { return }
                    // Add the label definition to the layer.
                    gasFeatureLayer.labelDefinitions.add(labelDefinition)
                    } catch {
                        // If failure to make a label definition, present an error.
                        self?.presentAlert(error: error)
                    }
            }
            // Set the scene to the scene view.
            sceneView.scene = scene
        }
    }
    
    func makeScene() -> AGSScene {
        let sceneURL = URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=850dfee7d30f4d9da0ebca34a533c169")!
        let scene = AGSScene(url: sceneURL)!
       
        return scene
    }
    
    func makeLabelDefinition() throws -> AGSLabelDefinition {
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
            "labelPlacement": "esriServerLinePlacementAboveAlong",
            "useCodedValues": true,
            "symbol": textSymbolJSON
        ]
        
        //  Create and return a label definition from the JSON object.
        let result = try AGSLabelDefinition.fromJSON(labelJSONObject)
        if let definition = result as? AGSLabelDefinition {
            return definition
        } else {
            throw jsonLabelError.withDescription("The JSON could not be read as a label definition.")
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["Display3DLabelsSceneViewController"]
    }
    
    private enum jsonLabelError: Error {
        case withDescription(String)
    }
}
