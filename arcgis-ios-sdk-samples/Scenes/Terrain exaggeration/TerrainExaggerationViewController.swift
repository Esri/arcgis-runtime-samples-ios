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

import UIKit
import ArcGIS

class TerrainExaggerationViewController: UIViewController {

    @IBOutlet weak var exaggerationValue: UILabel!
    @IBOutlet weak var exaggerationSlider: UISlider!
    @IBOutlet weak var sceneView: AGSSceneView!
    
    //initialize scene with streets basemap
    let scene = AGSScene(basemapType: .streets)
    
    //initialize surface
    let surface = AGSSurface()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["TerrainExaggerationViewController"]
        
        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        //initialize surface and add it to scene
        let elevation = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        surface.elevationSources.append(elevation)
        scene.baseSurface = surface
        
        //assign scene to scene view
        self.sceneView.scene = scene
        
        //set up initial camera location
        let initialLocation = AGSPoint(x: -119.94891542688772, y: 46.75792111605992, spatialReference: sceneView.spatialReference)
        let camera = AGSCamera(lookAt: initialLocation, distance: 15000.0, heading: 40.0, pitch: 60.0, roll: 0.0)
        sceneView.setViewpointCamera(camera)
        
        //set up initial slider values
        exaggerationSlider.minimumValue = 1
        exaggerationSlider.maximumValue = 10
        exaggerationSlider.isContinuous = true
        exaggerationSlider.value = 1
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        //assign slider value to elevation exaggeration
        surface.elevationExaggeration = sender.value
        
        //display current exaggeration value
        exaggerationValue.text = String(format: "%.1fx", sender.value)
    }

}

