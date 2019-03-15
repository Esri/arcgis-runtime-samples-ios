//
// Copyright © 2019 Esri.
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

/// A view controller that manages the interface of the Add an Integrated Mesh
/// Layer sample.
class AddIntegratedMeshLayerViewController: UIViewController {
    /// The scene view managed by the view controller.
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
            
            let location = AGSPoint(x: -119.622075, y: 37.720650, z: 2_104.901239, spatialReference: .wgs84())
            let camera = AGSCamera(location: location, heading: 315.50368761552056, pitch: 78.09465920130114, roll: 0)
            sceneView.setViewpointCamera(camera)
        }
    }
    
    /// Creates a scene with an integrated mesh layer.
    ///
    /// - Returns: A new `AGSScene` object.
    func makeScene() -> AGSScene {
        let scene = AGSScene(basemapType: .imagery)
        
        // Create the elevation source.
        let elevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationServiceURL)
        
        // Create the surface and add it to the scene.
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        scene.baseSurface = surface
        
        // Create the integrated mesh layer and add it to the scene.
        let integratedMeshLayerURL = URL(string: "https://tiles.arcgis.com/tiles/FQD0rKU8X5sAQfh8/arcgis/rest/services/VRICON_Yosemite_Sample_Integrated_Mesh_scene_layer/SceneServer")!
        let integratedMeshLayer = AGSIntegratedMeshLayer(url: integratedMeshLayerURL)
        scene.operationalLayers.add(integratedMeshLayer)
        
        return scene
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["AddIntegratedMeshLayerViewController"]
    }
}
