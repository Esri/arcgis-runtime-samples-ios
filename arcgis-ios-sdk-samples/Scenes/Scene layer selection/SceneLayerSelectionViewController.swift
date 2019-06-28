//
// Copyright © 2018 Esri.
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
//

import UIKit
import ArcGIS

/// A view controller that manages the interface of the Scene Layer Selection
/// sample.
class SceneLayerSelectionViewController: UIViewController {
    /// The scene displayed in the scene view.
    let scene: AGSScene
    let buildingsLayer: AGSArcGISSceneLayer
    
    required init?(coder: NSCoder) {
        scene = AGSScene(basemap: .imagery())
        
        // Create a surface set it as the base surface of the scene.
        let surface = AGSSurface()
        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        surface.elevationSources = [AGSArcGISTiledElevationSource(url: worldElevationServiceURL)]
        scene.baseSurface = surface
        
        /// The url of the scene service for buildings in Brest, France.
        let brestBuildingsServiceURL = URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0")!
        buildingsLayer = AGSArcGISSceneLayer(url: brestBuildingsServiceURL)
        scene.operationalLayers.add(buildingsLayer)
        
        super.init(coder: coder)
    }
    
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Assign the scene to the scene view.
        sceneView.scene = scene
        
        let camera = AGSCamera(latitude: 48.378, longitude: -4.494, altitude: 200, heading: 345, pitch: 65, roll: 0)
        sceneView.setViewpointCamera(camera)
        sceneView.touchDelegate = self
        
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SceneLayerSelectionViewController"]
    }
}

extension SceneLayerSelectionViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        buildingsLayer.clearSelection()
        sceneView.identifyLayer(buildingsLayer, screenPoint: screenPoint, tolerance: 10, returnPopupsOnly: false) { [weak self] (result) in
            if let error = result.error {
                print("\(result.layerContent.name) identify failed: \(error)")
            } else if let feature = result.geoElements.first as? AGSFeature {
                self?.buildingsLayer.select(feature)
            }
        }
    }
}
