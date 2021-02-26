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
            guard let self = self else { return }
            // Get the feature layer.
            if let operationalLayers = scene.operationalLayers as? [AGSGroupLayer],
               let groupLayer = operationalLayers.first(where: { $0.name == "Gas" }),
               let layers = groupLayer.layers as? [AGSLayer],
               let gasFeatureLayer = layers.first(where: { $0.name == "Gas Main" }) as? AGSFeatureLayer {
                let labelDefinition = self.makeLabelDefinition()
                // Enable labels on the feature layer.
                gasFeatureLayer.labelsEnabled = true
                gasFeatureLayer.labelDefinitions.removeAllObjects()
                // Add the label definition to the layer.
                gasFeatureLayer.labelDefinitions.add(labelDefinition)
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
        return scene
    }
    
    func makeLabelDefinition() -> AGSLabelDefinition {
        // Make and stylize the text symbol.
        let textSymbol = AGSTextSymbol()
        textSymbol.color = .orange
        textSymbol.haloColor = .white
        textSymbol.haloWidth = 2
        textSymbol.size = 16
        
        // Create and return a label definition using the text symbol.
        let labelDefinition = AGSLabelDefinition()
        labelDefinition.expression = AGSArcadeLabelExpression(arcadeExpression: "Text($feature.INSTALLATIONDATE, `DD MMM YY`)")
        labelDefinition.placement = .lineAboveAlong
        labelDefinition.useCodedValues = true
        labelDefinition.textSymbol = textSymbol
        
        return labelDefinition
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["Display3DLabelsSceneViewController"]
    }
}
