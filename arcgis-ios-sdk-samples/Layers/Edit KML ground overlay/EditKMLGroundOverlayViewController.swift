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
    // MARK: Storyboard views and properties
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene(groundOverlay: overlay)
            // Move the viewpoint to the ground overlay.
            let targetExtent = overlay.geometry as! AGSEnvelope
            let camera = AGSCamera(lookAt: targetExtent.center, distance: 1250, heading: 45, pitch: 60, roll: 0)
            sceneView.setViewpoint(AGSViewpoint(targetExtent: targetExtent, camera: camera))
        }
    }
    // The slider that controls the overlay's opacity.
    @IBOutlet var opacitySlider: UISlider!
    // The label that displays the slider's value.
    @IBOutlet var valueLabel: UILabel!
    
    // A number formatter to format the opacity value.
    let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter
    }()
    
    // The KML ground overlay.
    let overlay: AGSKMLGroundOverlay = {
        // Create a geometry for the ground overlay.
        let overlayGeometry = AGSEnvelope(xMin: -123.066227926904, yMin: 44.04736963555683, xMax: -123.0796942287304, yMax: 44.03878298600624, spatialReference: .wgs84())
        // Create a KML icon for the overlay image.
        let imageURL = URL(string: "https://libapps.s3.amazonaws.com/accounts/55937/images/1944.jpg")!
        let overlayImage = AGSKMLIcon(url: imageURL)
        let overlay = AGSKMLGroundOverlay(geometry: overlayGeometry, icon: overlayImage)!
        // Set the rotation of the ground overlay.
        overlay.rotation = -3.046024799346924
        return overlay
    }()
    
    // MARK: Actions and methods
    @IBAction func sliderValueChanged(_ slider: UISlider) {
        // Change the color of the overlay according to the slider's value.
        let alpha = CGFloat(slider.value)
        overlay.color = UIColor.black.withAlphaComponent(alpha)
        // Update the slider's value label.
        valueLabel.text = numberFormatter.string(from: slider.value as NSNumber)
    }
    
    func makeScene(groundOverlay: AGSKMLGroundOverlay) -> AGSScene {
        // Create a scene for the scene view.
        let scene = AGSScene(basemapType: .imagery)
        // Create a KML dataset with the ground overlay as the root node.
        let dataset = AGSKMLDataset(rootNode: groundOverlay)
        // Create a KML layer for the scene view.
        let layer = AGSKMLLayer(kmlDataset: dataset)
        // Add the layer to the scene.
        scene.operationalLayers.add(layer)
        // Return the scene.
        return scene
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of the navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["EditKMLGroundOverlayViewController"]
    }
}
