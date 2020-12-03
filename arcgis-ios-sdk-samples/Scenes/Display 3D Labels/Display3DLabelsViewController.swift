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
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            // Initialize the scene with imagery basemap.
            sceneView.scene = makeScene()
            
            // Set initial scene viewpoint.
            let camera = AGSCamera(latitude: 40.704883, longitude: -74.01092, altitude: 300.0, heading: 180, pitch: 50, roll: 0)
            sceneView.setViewpointCamera(camera)
        }
    }
    
    var hydrantsLayer: AGSArcGISSceneLayer!
    
    func makeScene() -> AGSScene {
        let sceneURL = URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=850dfee7d30f4d9da0ebca34a533c169")!
        let scene = AGSScene(url: sceneURL)
        // Create a scene layer from buildings REST service.
        let featureTableURL = URL(string: "https://services2.arcgis.com/cFEFS0EWrhfDeVw9/ArcGIS/rest/services/GasMain2D_AOI/FeatureServer/0")!
        // create a feature table from the URL
        let featureTable = AGSServiceFeatureTable(url: featureTableURL)
        // Create an elevation source from Terrain3D REST service.
        let elevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationServiceURL)
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        // create a feature layer from the table
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        // add the layer to the map
//        scene.operationalLayers.add(featureLayer)// turn on labelling
        featureLayer.labelsEnabled = true
//        scene.baseSurface = surface
        // create label definitions for the two groups
        do {
            let labelDefinition = try makeLabelDefinition()
            
            // add the label definitions to the layer
            featureLayer.labelDefinitions.addObjects(from: [labelDefinition])
        } catch {
            presentAlert(error: error)
        }
        return scene!
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
            "labelExpression": "[OBJECTID ]",
            "labelPlacement": "esriServerPointLabelPlacementAboveRight",
            "useCodedValues": true,
            "symbol": textSymbolJSON
        ]
        
        // create and return a label definition from the JSON object
        let result = try AGSLabelDefinition.fromJSON(labelJSONObject)
        if let definition = result as? AGSLabelDefinition {
            return definition
        } else {
            throw labelsError.withDescription("The JSON could not be read as a label definition.")
        }
    }
    
    private enum labelsError: Error {
        case withDescription(String)
    }
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["Display3DLabelsViewController"]
    }
}
