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

/// A view controller that manages the interface of the View Point Cloud Data
/// Offline sample.
class ViewPointCloudDataOfflineViewController: UIViewController {
    /// The scene view managed by the view controller.
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
        }
    }
    
    /// Creates a scene with a point cloud layer.
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
        
        // Create the point cloud layer and add it to the scene.
        if let sceneLayerPackageURL = Bundle.main.url(forResource: "sandiego-north-balboa-pointcloud", withExtension: "slpk") {
            let pointCloudLayer = AGSPointCloudLayer(url: sceneLayerPackageURL)
            pointCloudLayer.load { [weak self, unowned layer = pointCloudLayer] _ in
                self?.pointCloudLayerDidLoad(layer)
            }
            scene.operationalLayers.add(pointCloudLayer)
        }
        
        return scene
    }
    
    /// Called in response to the point cloud layer load operation completing.
    ///
    /// - Parameter layer: The point cloud layer that finished loading.
    func pointCloudLayerDidLoad(_ layer: AGSPointCloudLayer) {
        if let error = layer.loadError {
            presentAlert(error: error)
        } else if let extent = layer.fullExtent {
            let viewpoint = AGSViewpoint(targetExtent: extent)
            sceneView.setViewpoint(viewpoint)
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ViewPointCloudDataOfflineViewController"]
    }
}
