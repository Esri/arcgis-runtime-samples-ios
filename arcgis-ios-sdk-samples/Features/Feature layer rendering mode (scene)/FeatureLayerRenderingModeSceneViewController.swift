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

class FeatureLayerRenderingModeSceneViewController: UIViewController {
    
    @IBOutlet private weak var dynamicSceneView: AGSSceneView!
    @IBOutlet private weak var staticSceneView: AGSSceneView!
    
    private let zoomedOutCamera = AGSCamera(lookAt: AGSPoint(x: -118.37, y: 34.46, spatialReference: .wgs84()), distance: 42000, heading: 0, pitch: 0, roll: 0)
    private let zoomedInCamera = AGSCamera(lookAt: AGSPoint(x: -118.45, y: 34.395, spatialReference: .wgs84()), distance: 2500, heading: 90, pitch: 75, roll: 0)
    
    /// The length of one animation, zooming in or out.
    private let animationDurationInSeconds = 5.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureLayerRenderingModeSceneViewController"]

        // create and assign scenes to the scene views
        dynamicSceneView.scene = AGSScene()
        staticSceneView.scene = AGSScene()
        
        // create service feature tables using point, polygon, and polyline services
        let pointTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/0")!)
        let polylineTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/8")!)
        let polygonTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/9")!)
        
        // loop through all the tables in the order we want to add them, bottom to top
        for featureTable in [polygonTable, polylineTable, pointTable] {
            
            // create a feature layer for the table
            let dynamicFeatureLayer = AGSFeatureLayer(featureTable: featureTable)
            // create a second, identical feature layer from the first
            let staticFeatureLayer = dynamicFeatureLayer.copy() as! AGSFeatureLayer
            
            // set the rendering modes for each layer
            dynamicFeatureLayer.renderingMode = .dynamic
            staticFeatureLayer.renderingMode = .static
            
            // add the layers to their corresponding scenes
            dynamicSceneView.scene?.operationalLayers.add(dynamicFeatureLayer)
            staticSceneView.scene?.operationalLayers.add(staticFeatureLayer)
        }
        
        // set the initial viewpoint cameras with the zoomed out camera
        dynamicSceneView.setViewpointCamera(zoomedOutCamera)
        staticSceneView.setViewpointCamera(zoomedOutCamera)
        
        // start the animation by zooming in
        animateZoom(zoomIn: true)
    }

    private func animateZoom(zoomIn: Bool) {
        
        // toggle between the zoomed in and zoomed out cameras
        let targetCamera = zoomIn ? zoomedInCamera : zoomedOutCamera

        // start the animation to the opposite viewpoint in both scenes
        dynamicSceneView.setViewpointCamera(targetCamera, duration: animationDurationInSeconds)
        staticSceneView.setViewpointCamera(targetCamera, duration: animationDurationInSeconds) { [weak self] _ in
            // Upon completion, start the reverse animation.
            // Only call this for one of the views since it will affect both.
            self?.animateZoom(zoomIn: !zoomIn)
        }
    }
    
}
