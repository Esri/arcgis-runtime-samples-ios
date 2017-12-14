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

class LineOfSightLocationViewController: UIViewController, AGSGeoViewTouchDelegate {
    
    @IBOutlet weak var sceneView: AGSSceneView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    private var lineOfSight: AGSLocationLineOfSight!
    private var observerLocation: AGSPoint?
    
    private let ELEVATION_SERVICE_URL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["LineOfSightLocationViewController"]
        
        //initialize the scene with an imagery basemap
        let scene = AGSScene(basemap: AGSBasemap.imagery())
        
        //initialize the elevation source with the elevation service URL
        let elevationSrc = AGSArcGISTiledElevationSource(url: ELEVATION_SERVICE_URL)
        
        //add the elevation source to the base surface of the scene
        scene.baseSurface?.elevationSources.append(elevationSrc)
        
        //assign the scene to the scene view
        self.sceneView.scene = scene
        
        //set the line width (default 1.0), visible color (default: green), obstructed colors (default: red). These are static properties that apply to all line of sight analyses in the scene view
        AGSLineOfSight.setLineWidth(2.0)
        AGSLineOfSight.setVisibleColor(.cyan)
        AGSLineOfSight.setObstructedColor(.magenta)
        
        //create an analysis overlay for the line of sight
        let analysisOverlay = AGSAnalysisOverlay()
        
        //add the analysis overlay to the scene view
        sceneView.analysisOverlays.add(analysisOverlay)
        
        //initialize a line of sight analysis with arbitrary points (observer and target will be defined by the user)
        self.lineOfSight = AGSLocationLineOfSight(observerLocation: AGSPoint(x: 0.0 , y: 0.0, z: 0.0, spatialReference: AGSSpatialReference.wgs84()), targetLocation: AGSPoint(x: 0.0 , y: 0.0, z: 0.0, spatialReference: AGSSpatialReference.wgs84()))
        
        //add the line of sight to the analysis overlay
        analysisOverlay.analyses.add(self.lineOfSight)
        
        //set the viewpoint with a new camera
        let camera = AGSCamera(location: AGSPoint(x: -73.10861935949697, y: -49.25758493899104, z: 3050, spatialReference: AGSSpatialReference.wgs84()), heading: 106, pitch: 73, roll: 0)
        sceneView.setViewpointCamera(camera)
        
        //set touch delegate on scene view as self
        sceneView.touchDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //set the observer location once-only
        if observerLocation == nil {
            self.observerLocation = mapPoint
            
            //define the observer location
            self.lineOfSight.observerLocation = self.observerLocation!
            
            //update the instruction label
            self.instructionLabel.text = "Press and hold on the map to update target location"
        }
    }
    
    func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //check if user has set the observer location
        guard observerLocation != nil else {
            return
        }
        
        //update the target location
        self.lineOfSight.targetLocation = mapPoint
    }
    
}
