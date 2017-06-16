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

class ViewController: UIViewController {

    @IBOutlet weak var exaggerationValue: UILabel!
    @IBOutlet weak var exaggerationSlider: UISlider!
    @IBOutlet weak var sceneView: AGSSceneView!
    let scene = AGSScene(basemapType: .streets)
    let surface = AGSSurface()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["TerrainExaggerationViewController"]
        
        let elevation = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        surface.elevationSources.append(elevation)
        scene.baseSurface = surface
        
        self.sceneView.scene = scene
        
        let initialLocation = AGSPoint(x: -119.94891542688772, y: 46.75792111605992, spatialReference: sceneView.spatialReference)
        let camera = AGSCamera(lookAt: initialLocation, distance: 15000.0, heading: 40.0, pitch: 60.0, roll: 0.0)
        sceneView.setViewpointCamera(camera)
        
        exaggerationSlider.minimumValue = 1
        exaggerationSlider.maximumValue = 10
        exaggerationSlider.isContinuous = true
        exaggerationSlider.value = 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        surface.elevationExaggeration = sender.value
        exaggerationValue.text = String(format: "%.1fx", sender.value)
    }

}

