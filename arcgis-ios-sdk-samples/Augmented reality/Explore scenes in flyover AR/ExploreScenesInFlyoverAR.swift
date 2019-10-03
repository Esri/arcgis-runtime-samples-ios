// Copyright 2019 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ARKit
import ArcGISToolkit
import ArcGIS

class ExploreScenesInFlyoverAR: UIViewController {
    @IBOutlet var arView: ArcGISARView!
    @IBOutlet var arKitStatusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for tracking state changes
        arView.arSCNViewDelegate = self

        configureSceneForAR()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ExploreScenesInFlyoverAR"]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.startTracking(.ignore)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.stopTracking()
    }

    private func configureSceneForAR() {
        // Create scene with imagery basemap
        let scene = AGSScene(basemapType: .imagery)

        // Create an integrated mesh layer
        let meshLayer = AGSIntegratedMeshLayer(url:
            URL(string: "https://www.arcgis.com/home/item.html?id=dbc72b3ebb024c848d89a42fe6387a1b")!)
        
        // Add the mesh layer to our scene
        scene.operationalLayers.add(meshLayer)

        // Display the scene
        arView.sceneView.scene = scene

        // Wait for the layer to load, then set the AR camera
        meshLayer.load { [weak self, weak meshLayer] (err: Error?) in
            guard let self = self else { return }
            guard let `meshLayer` = meshLayer else { return }
            if let error = err {
                self.presentAlert(error: error)
            } else if let envelope = meshLayer.fullExtent {
                let camera = AGSCamera(latitude: envelope.center.y,
                                       longitude: envelope.center.x,
                                       altitude: 600,
                                       heading: 0,
                                       pitch: 90,
                                       roll: 0)
                self.arView.originCamera = camera
            }
        }

        // Set the translation factor to enable rapid movement through the scene
        arView.translationFactor = 1000

        // Turn the space and atmosphere effects on for an immersive experience
        arView.sceneView.spaceEffect = .stars
        arView.sceneView.atmosphereEffect = .realistic
    }
}

// MARK: - tracking status display
extension ExploreScenesInFlyoverAR: ARSCNViewDelegate {
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            arKitStatusLabel.isHidden = true
        case .notAvailable:
            arKitStatusLabel.text = "ARKit location not available"
            arKitStatusLabel.isHidden = false
        case .limited(let reason):
            arKitStatusLabel.isHidden = false
            switch reason {
            case .excessiveMotion:
                arKitStatusLabel.text = "Try moving your phone more slowly"
                arKitStatusLabel.isHidden = false
            case .initializing:
                arKitStatusLabel.text = "Keep moving your phone"
                arKitStatusLabel.isHidden = false
            case .insufficientFeatures:
                arKitStatusLabel.text = "Try turning on more lights and moving around"
                arKitStatusLabel.isHidden = false
            case .relocalizing:
                // this won't happen as this sample doesn't use relocalization
                break
            @unknown default:
                break
            }
        }
    }
}
