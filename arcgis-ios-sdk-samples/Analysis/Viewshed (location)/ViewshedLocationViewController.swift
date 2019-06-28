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

class ViewshedLocationViewController: UIViewController {
    @IBOutlet weak var sceneView: AGSSceneView!
    @IBOutlet weak var setObserverOnTapInstruction: UILabel!
    @IBOutlet weak var updateObserverOnDragInstruction: UILabel!
    
    private weak var viewshed: AGSLocationViewshed?
    
    private var canMoveViewshed: Bool = false {
        didSet {
            setObserverOnTapInstruction.isHidden = canMoveViewshed
            updateObserverOnDragInstruction.isHidden = !canMoveViewshed
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "ViewshedLocationViewController",
            "ViewshedSettingsVC",
            "ColorPickerViewController"
        ]
        
        // initialize the scene with an imagery basemap
        let scene = AGSScene(basemap: .imagery())
        
        // assign the scene to the scene view
        sceneView.scene = scene
        
        // initialize the camera and set the viewpoint specified by the camera position
        let camera = AGSCamera(lookAt: AGSPoint(x: -4.50, y: 48.4, z: 100.0, spatialReference: .wgs84()), distance: 200, heading: 20, pitch: 70, roll: 0)
        sceneView.setViewpointCamera(camera)
        
        /// The url of the image service for elevation in Brest, France.
        let brestElevationServiceURL = URL(string: "https://scene.arcgis.com/arcgis/rest/services/BREST_DTM_1M/ImageServer")!
        // initialize the elevation source with the service URL and add it to the base surface of the scene
        let elevationSrc = AGSArcGISTiledElevationSource(url: brestElevationServiceURL)
        scene.baseSurface?.elevationSources.append(elevationSrc)
        
        /// The url of the scene service for buildings in Brest, France.
        let brestBuildingsServiceURL = URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer/layers/0")!
        // initialize the scene layer with the scene layer URL and add it to the scene
        let buildings = AGSArcGISSceneLayer(url: brestBuildingsServiceURL)
        scene.operationalLayers.add(buildings)
        
        // initialize a viewshed analysis object with arbitrary location (the location will be defined by the user), heading, pitch, view angles, and distance range (in meters) from which visibility is calculated from the observer location
        let viewshed = AGSLocationViewshed(location: AGSPoint(x: 0.0, y: 0.0, z: 0.0, spatialReference: .wgs84()), heading: 20, pitch: 70, horizontalAngle: 45, verticalAngle: 90, minDistance: 50, maxDistance: 1000)
        self.viewshed = viewshed
        
        // create an analysis overlay for the viewshed and to add it to the scene view
        let analysisOverlay = AGSAnalysisOverlay()
        analysisOverlay.analyses.add(viewshed)
        sceneView.analysisOverlays.add(analysisOverlay)
        
        //set touch delegate on scene view as self
        sceneView.touchDelegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? ViewshedSettingsVC {
            controller.viewshed = viewshed
            controller.preferredContentSize = {
                let height: CGFloat
                if traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
                    height = 340
                } else {
                    height = 240
                }
                return CGSize(width: 375, height: height)
            }()
            navController.presentationController?.delegate = self
        }
    }
}

extension ViewshedLocationViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        canMoveViewshed = true
        // update the observer location from which the viewshed is calculated
        viewshed?.location = mapPoint
    }
    
    func geoView(_ geoView: AGSGeoView, didTouchDownAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint, completion: @escaping (Bool) -> Void) {
        // tell the ArcGIS Runtime if we are going to handle interaction
        canMoveViewshed ? completion(true) : completion(false)
    }
    
    func geoView(_ geoView: AGSGeoView, didTouchDragToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // update the observer location from which the viewshed is calculated
        viewshed?.location = mapPoint
    }
}

extension ViewshedLocationViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // for popover or non modal presentation
        return .none
    }
}
