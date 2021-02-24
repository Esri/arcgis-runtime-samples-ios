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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ViewshedCameraViewController"]
        
        // Initialize the scene with an imagery basemap.
        let scene = AGSScene(basemap: .imagery())
        
        // Assign the scene to the scene view.
        sceneView.scene = scene
        
        // Initialize the camera and set the viewpoint specified by the camera position.
        let camera = AGSCamera(location: AGSPoint(x: 2.82691, y: 41.985, z: 124.987, spatialReference: .wgs84()), heading: 332.131, pitch: 82.4732, roll: 0)
        sceneView.setViewpointCamera(camera)
        
        // The URL of the world elevation image service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        // Initialize the elevation source with the elevation service URL.
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        
        // Add the elevation source to the base surface of the scene.
        scene.baseSurface?.elevationSources.append(elevationSource)
        
        // The URL of the scene service for buildings.
        let gironaBuildingsServiceURL = URL(string: "https://tiles.arcgis.com/tiles/z2tnIkrLQ2BRzr6P/arcgis/rest/services/Girona_Spain/SceneServer")!
        // Initialize the integrated mesh layer with the URL and add it to the scene.
        let buildings = AGSIntegratedMeshLayer(url: gironaBuildingsServiceURL)
        scene.operationalLayers.add(buildings)
        
        // Create a viewshed from the camera with minimum and maximum distance
        // (in meters) from the observer (camera) at which visibility will be evaluated.
        let viewshed = AGSLocationViewshed(camera: camera, minDistance: 1.0, maxDistance: 500.0)
        
        // Create an analysis overlay for the viewshed and to add it to the scene view.
        let analysisOverlay = AGSAnalysisOverlay()
        analysisOverlay.analyses.add(viewshed)
        sceneView.analysisOverlays.add(analysisOverlay)
        
        // Store the viewshed for later use.
        self.viewshed = viewshed
    }
    
    // MARK: - Actions

    @IBAction func updateViewshed(_ sender: Any) {
        // Update the viewshed with the current camera.
        viewshed.update(from: sceneView.currentViewpointCamera())
    }
}
