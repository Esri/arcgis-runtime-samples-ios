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
            let camera = AGSCamera(latitude: 40.704202, longitude: -74.011586, altitude: 300.0, heading: 180, pitch: 80, roll: 0)
            sceneView.setViewpointCamera(camera)
        }
    }
    
    var hydrantsLayer: AGSArcGISSceneLayer!
    
    func makeScene() -> AGSScene {
        // Create a scene layer from buildings REST service.
        let hydrantsURL = URL(string: "https://services2.arcgis.com/cFEFS0EWrhfDeVw9/ArcGIS/rest/services/NYC_Utilities_Water_Hydrants/SceneServer")!
        hydrantsLayer = AGSArcGISSceneLayer(url: hydrantsURL)
        // Create an elevation source from Terrain3D REST service.
//        let elevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
//        let elevationSource = AGSArcGISTiledElevationSource(url: elevationServiceURL)
//        let surface = AGSSurface()
//        surface.elevationSources = [elevationSource]
        let scene = AGSScene(basemapStyle: .arcGISLightGray)
//        scene.baseSurface = surface
        scene.operationalLayers.add(hydrantsLayer!)
        return scene
        
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
        hydrantsLayer.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else if let layer = self.hydrantsLayer {
                do {
                    let label = try self.makeLabelDefinition()
                    hydrantsLayer.labe
                } catch {
                    self.presentAlert(error: error)
                }
            }
        }
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["Display3DLabelsViewController"]
    }
}
