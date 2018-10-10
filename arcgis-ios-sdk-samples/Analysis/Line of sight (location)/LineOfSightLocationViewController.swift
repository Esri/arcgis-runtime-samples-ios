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

class LineOfSightLocationViewController: UIViewController, AGSGeoViewTouchDelegate {
    
    @IBOutlet weak var sceneView: AGSSceneView!
    @IBOutlet weak var observerInstructionLabel: UILabel!
    @IBOutlet weak var targetInstructionLabel: UILabel!
    
    private var lineOfSight: AGSLocationLineOfSight? {
        willSet {
            sceneView.analysisOverlays.removeAllObjects()
        }
        didSet {
            guard let lineOfSight = lineOfSight else {
                targetInstructionLabel.isHidden = true
                return
            }

            targetInstructionLabel.isHidden = false

            // create an analysis overlay using a single Line of Sight and add it to the scene view
            let analysisOverlay = AGSAnalysisOverlay()
            analysisOverlay.analyses.add(lineOfSight)
            sceneView.analysisOverlays.add(analysisOverlay)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["LineOfSightLocationViewController"]
        
        // initialize the scene with an imagery basemap
        let scene = AGSScene(basemap: .imagery())
        
        // assign the scene to the scene view
        sceneView.scene = scene

        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        // initialize the elevation source with the service URL and add it to the base surface of the scene
        let elevationSrc = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        scene.baseSurface?.elevationSources.append(elevationSrc)
        
        // set the viewpoint specified by the camera position
        let camera = AGSCamera(location: AGSPoint(x: -73.0815, y: -49.3272, z: 4059, spatialReference: AGSSpatialReference.wgs84()), heading: 11, pitch: 62, roll: 0)
        sceneView.setViewpointCamera(camera)
        
        // set touch delegate on scene view as self
        sceneView.touchDelegate = self

        // set the line width (default 1.0). This setting is applied to all line of sight analysis in the view
        AGSLineOfSight.setLineWidth(2.0)
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // user tapped to place Line of Sight observer. Create Line of Sight analysis if need be
        if (lineOfSight == nil) {
            // set initial Line of Sight analysis with tapped point
            lineOfSight = AGSLocationLineOfSight(observerLocation: mapPoint, targetLocation: mapPoint)
        } else {
            // update the observer location
            lineOfSight?.observerLocation = mapPoint
        }
    }
    
    func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // update the target location
        lineOfSight?.targetLocation = mapPoint
    }
    
    func geoView(_ geoView: AGSGeoView, didMoveLongPressToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // update the target location
        lineOfSight?.targetLocation = mapPoint
    }
}
