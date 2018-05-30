// Copyright 2018 Esri.
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

class ViewshedCameraViewController: UIViewController {

    @IBOutlet weak var sceneView: AGSSceneView!
    
    private var viewshed: AGSLocationViewshed!
    
    private let ELEVATION_SERVICE_URL = URL(string: "https://scene.arcgis.com/arcgis/rest/services/BREST_DTM_1M/ImageServer")!
    private let SCENE_LAYER_URL = URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ViewshedCameraViewController"]
        
        // initialize the scene with an imagery basemap
        let scene = AGSScene(basemap: AGSBasemap.imagery())
        
        // assign the scene to the scene view
        sceneView.scene = scene
        
        // initialize the camera and set the viewpoint specified by the camera position
        let camera = AGSCamera(location: AGSPoint(x: -4.49492, y: 48.3808, z: 48.2511, spatialReference: AGSSpatialReference.wgs84()), heading: 344.488, pitch: 74.1212, roll: 0)
        sceneView.setViewpointCamera(camera)
        
        // initialize the elevation source with the elevation service URL
        let elevationSrc = AGSArcGISTiledElevationSource(url: ELEVATION_SERVICE_URL)
        
        // add the elevation source to the base surface of the scene
        scene.baseSurface?.elevationSources.append(elevationSrc)
        
        // initialize the scene layer with the scene layer URL and add it to the scene
        let buildings = AGSArcGISSceneLayer(url: SCENE_LAYER_URL)
        scene.operationalLayers.add(buildings)
        
        // create a viewshed from the camera with minimum and maximum distance (in meters) from the observer (camera) at which visibility will be evaluated
        viewshed = AGSLocationViewshed(camera: camera, minDistance: 1.0, maxDistance: 500.0)
        
        // create an analysis overlay for the viewshed and to add it to the scene view
        let analysisOverlay = AGSAnalysisOverlay()
        analysisOverlay.analyses.add(viewshed)
        sceneView.analysisOverlays.add(analysisOverlay)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions

    @IBAction func updateViewshed(_ sender: Any) {
        // update the viewshed with the current camera
        viewshed.update(from: sceneView.currentViewpointCamera())
    }
    
}
