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

class RealisticLightingAndShadowsViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The label to display the date time set by the slider.
    @IBOutlet weak var dateTimeLabel: UILabel!
    /// The slider to change the time of the day.
    @IBOutlet weak var minuteSlider: UISlider!
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
            sceneView.atmosphereEffect = .realistic
            sceneView.sunLighting = .lightAndShadows
            sceneView.setViewpointCamera(AGSCamera(latitude: 45.54605, longitude: -122.69033, altitude: 941.00021, heading: 162.58544, pitch: 60.0, roll: 0))
        }
    }
    
    // MARK: Instance properties
    
    /// A date formatter to format date time output.
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: Instance methods
    
    /// Create a scene.
    ///
    /// - Returns: A new `AGSScene` object.
    func makeScene() -> AGSScene {
        // Create a scene layer from buildings REST service.
        let buildingsURL = URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/DevA_BuildingShells/SceneServer")!
        let buildingsLayer = AGSArcGISSceneLayer(url: buildingsURL)
        // Create an elevation source from Terrain3D REST service.
        let elevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationServiceURL)
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        let scene = AGSScene(basemap: .topographic())
        scene.baseSurface = surface
        scene.operationalLayers.add(buildingsLayer)
        return scene
    }
    
    // MARK: - Actions
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        // A DateComponents struct to encapsulate the minute value from the slider.
        let dateComponents = DateComponents(minute: Int(sender.value))
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let date = Calendar.current.date(byAdding: dateComponents, to: startOfToday)!
        dateTimeLabel.text = dateFormatter.string(from: date)
        sceneView.sunTime = date
    }
    
    @IBAction func modeButtonTapped(_ button: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose a lighting mode for the scene view.",
            message: nil,
            preferredStyle: .actionSheet
        )
        let modes: KeyValuePairs<String, AGSLightingMode> = [
            "Light and shadows": .lightAndShadows,
            "Light only": .light,
            "No light": .noLight
        ]
        modes.forEach { name, lightingMode in
            let action = UIAlertAction(title: name, style: .default) { _ in
                self.sceneView.sunLighting = lightingMode
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = button
        present(alertController, animated: true)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["RealisticLightingAndShadowsViewController"]
        // Initialize the date time.
        sliderValueChanged(minuteSlider)
    }
}
