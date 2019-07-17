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

import Foundation
import ArcGIS

class CreateTerrainSurfaceFromLocalRasterViewController: UIViewController {
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            //initialize scene
            let scene = AGSScene(basemapType: .imageryWithLabels)
            sceneView.scene = scene
            //set scene's viewpoint
            let camera = AGSCamera(latitude: 36.525, longitude: -121.80, altitude: 300.0, heading: 180, pitch: 80, roll: 0)
            sceneView.setViewpointCamera(camera)
            
            let surface = AGSSurface()
            //create raster elevation source
            let rasterURL = Bundle.main.url(forResource: "MontereyElevation", withExtension: ".dt2")!
            let rasterElevationSource = AGSRasterElevationSource(fileURLs: [rasterURL])
            //add a raster source to the surface
            surface.elevationSources.append(rasterElevationSource)
            scene.baseSurface = surface
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["CreateTerrainSurfaceFromLocalRasterViewController"]
    }
}
