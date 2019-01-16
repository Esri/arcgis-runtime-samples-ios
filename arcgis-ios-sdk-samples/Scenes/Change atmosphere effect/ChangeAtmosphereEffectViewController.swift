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

class ChangeAtmosphereEffectViewController: UIViewController {
    /// The view for displaying the scene.
    @IBOutlet private weak var sceneView: AGSSceneView!
    
    /// The labels for the atmosphere effect options, corresponding to the cases of
    /// `AGSAtmosphereEffect` in the order of their raw values.
    private let atmosphereEffectOptionLabels = ["None", "Horizon Only", "Realistic"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// The scene for the scene view.
        let scene = AGSScene(basemapType: .imagery)
        // add the scene to the scene view
        sceneView.scene = scene
        
        /// The surface for the scene.
        let surface = AGSSurface()
        
        /// The URL of the remote service serving elevation data.
        let elevationURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        
        /// The elevation source for the 3D terrain effect.
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationURL)
        
        // add the elevation source to the surface
        surface.elevationSources.append(elevationSource)
        // add the surface to the scene
        scene.baseSurface = surface
        
        /// The initial camera position for the scene view.
        let camera = AGSCamera(
            latitude: 64.416919,
            longitude: -14.483728,
            altitude: 100,
            heading: 318,
            pitch: 105,
            roll: 0
        )
        
        // set the camera for the scene view
        sceneView.setViewpointCamera(camera)

        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "ChangeAtmosphereEffectViewController",
            "OptionsTableViewController"
        ]
    }
    
    /// The action handler for the "Change Effect" bar button item.
    @IBAction func changeEffectAction(_ sender: UIBarButtonItem) {
        // The raw values of the AGSAtmosphereEffect cases are 0 through 2, so we
        // can use `rawValue` as the selection index.
        let selectedIndex = sceneView.atmosphereEffect.rawValue
        
        /// A table view controller allowing selection between the provided options.
        let controller = OptionsTableViewController(labels: atmosphereEffectOptionLabels, selectedIndex: selectedIndex) { [weak self] (selectedIndex) in
            /// The effect for the selected option.
            let selectedEffect = AGSAtmosphereEffect(rawValue: selectedIndex)!
            
            // update the `atmosphereEffect` of the scene view with the selected effect
            self?.sceneView.atmosphereEffect = selectedEffect
        }
        
        // configure the options controller to be a popover anchored to the bar button item
        controller.modalPresentationStyle = .popover
        controller.presentationController?.delegate = self
        controller.popoverPresentationController?.barButtonItem = sender
        controller.popoverPresentationController?.passthroughViews = [sceneView]
        controller.preferredContentSize = CGSize(width: 300, height: 150)
        
        // show the options controller
        present(controller, animated: true)
    }
}

extension ChangeAtmosphereEffectViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // return none to ensure the options controller is shown as a popover even on small displays
        return .none
    }
}
