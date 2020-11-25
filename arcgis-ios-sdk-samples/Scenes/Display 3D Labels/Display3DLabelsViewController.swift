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

class Display3DLabelsViewController: UIViewController {
    var sublayer: AGSSubtypeSublayer!
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            let url = URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=850dfee7d30f4d9da0ebca34a533c169")!
            sceneView.scene = AGSScene(url: url)
            sceneView.labeling = AGSViewLabelProperties(animationEnabled: true, labelingEnabled: true)
            
        }
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
            "labelPlacement": "esriServerPointLabelPlacementAboveRight",
            "useCodedValues": true,
            "symbol": textSymbolJSON
        ]
        
        let result = try AGSLabelDefinition.fromJSON(labelJSONObject)
        return result as! AGSLabelDefinition
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["Display3DLabelsViewController"]
    }
}
