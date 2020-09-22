// Copyright 2020 Esri
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

class EditKMLGroundOverlayViewController: UIViewController {
    // MARK: Storyboard views
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
        }
    }
    @IBOutlet var opacitySlider: UISlider!
    @IBOutlet var valueLabel: UILabel!
    
    var overlay: AGSKMLGroundOverlay?
    
    @IBAction func sliderValueChanged(_ slider: UISlider) {
        let alpha = CGFloat(255 * slider.value)
        overlay?.color = UIColor(red: 0, green: 0, blue: 0, alpha: alpha)
    }
    
    func makeScene() -> AGSScene {
        // Create a scene for the scene view.
        let scene = AGSScene(basemap: .imagery())
        // Create a geometry for the ground overlay.
        let overlayGeometry = AGSEnvelope(xMin: -123.066227926904, yMin: 44.04736963555683, xMax: -123.0796942287304, yMax: 44.03878298600624, spatialReference: .wgs84())
        // Create a KML icon for the overlay image.
        let imageURL = URL(string: "https://libapps.s3.amazonaws.com/accounts/55937/images/1944.jpg")!
        let overlayImage = AGSKMLIcon(url: imageURL)
        //Create the KML ground overlay.
        overlay = AGSKMLGroundOverlay(geometry: overlayGeometry, icon: overlayImage)
        guard let overlay = overlay else { return scene }
        // Set the rotation of the ground overlay.
        overlay.rotation = -3.046024799346924
        // Create a KML dataset with the ground overlay as the root node.
        let dataset = AGSKMLDataset(rootNode: overlay)
        // Create a KML layer for the scene view.
        let layer = AGSKMLLayer(kmlDataset: dataset)
        // Add the layer to the map.
        scene.operationalLayers.add(layer)
        // Move the viewpoint to the ground overlay.
        let overlayCenter = overlay.geometry.extent.center
        let camera = AGSCamera(lookAt: overlayCenter, distance: 1250, heading: 45, pitch: 60, roll: 0)
        let targetExtent = overlay.geometry as! AGSEnvelope
        sceneView.setViewpoint(AGSViewpoint(targetExtent: targetExtent, camera: camera))
        // Make an event handler for the opacity slider.
        
        return scene
    }
}
