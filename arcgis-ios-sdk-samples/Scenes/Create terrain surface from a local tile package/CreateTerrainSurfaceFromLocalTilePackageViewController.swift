// Copyright 2019 Esri.
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

class CreateTerrainSurfaceFromLocalTilePackageViewController: UIViewController {
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            // Initialize the scene with imagery basemap.
            sceneView.scene = makeScene()
            
            // Set initial scene viewpoint.
            let camera = AGSCamera(latitude: 36.525, longitude: -121.80, altitude: 300.0, heading: 180, pitch: 80, roll: 0)
            sceneView.setViewpointCamera(camera)
        }
    }
    
    func makeScene() -> AGSScene {
        let scene = AGSScene(basemapType: .imageryWithLabels)
        
        // Create an elevation source using the path to the tile package.
        let surface = AGSSurface()
        let tpkURL = Bundle.main.url(forResource: "MontereyElevation", withExtension: ".tpk")!
        let elevationSource = AGSArcGISTiledElevationSource(url: tpkURL)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        return scene
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["CreateTerrainSurfaceFromLocalTilePackageViewController"]
    }
}
