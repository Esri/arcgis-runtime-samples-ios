//
// Copyright 2017 Esri.
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

class SceneLayerURLViewController: UIViewController {

    @IBOutlet var sceneView:AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SceneLayerURLViewController"]
        
        //initialize scene with topographic basemap
        let scene = AGSScene(basemap: .imagery())
        
        //assign scene to the scene view
        self.sceneView.scene = scene
        
        //set the viewpoint camera
        let point = AGSPoint(x: -4.49779155626782, y: 48.38282454039932, z: 62.013264927081764, spatialReference: AGSSpatialReference(wkid: 4326))
        let camera = AGSCamera(location: point, heading: 41.64729875588979, pitch: 71.2017391571523, roll: 0)
        self.sceneView.setViewpointCamera(camera)
        
        // add base surface for elevation data
        let surface = AGSSurface()
        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        /// The url of the scene service for buildings in Brest, France.
        let brestBuildingsServiceURL = URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0")!
        //scene layer
        let sceneLayer = AGSArcGISSceneLayer(url: brestBuildingsServiceURL)
        self.sceneView.scene?.operationalLayers.add(sceneLayer)
    }

}
