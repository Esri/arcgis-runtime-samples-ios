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

class DisplayScenesInTabletopAR: UIViewController {
    // UI controls
    @IBOutlet var arView: ArcGISARView!
    @IBOutlet var helpLabel: UILabel!
    
    // State
    private var hasPlacedScene = false {
        didSet {
            helpLabel.isHidden = hasPlacedScene
        }
    }

    // Create the package from local data - philadelphia.mspk
    let package = AGSMobileScenePackage(name: "philadelphia")

    // Wait for at least one detected plane before allowing user to place map
    var hasFoundPlane = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure a starting invisible scene with a tiling scheme matching that of the scene that will be used
        arView.sceneView.scene = AGSScene(tilingScheme: .geographic)
        arView.sceneView.scene?.baseSurface?.opacity = 0

        // Listen for tracking state changes
        arView.arSCNViewDelegate = self
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayScenesInTabletopAR"]
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
        // Load the package
        package.load { [weak self] (err: Error?) in
            guard let self = self else { return }

            if let error = err {
                self.presentAlert(error: error)
            } else if let scene = self.package.scenes.first {
                // Display the scene
                self.arView.sceneView.scene = scene

                // Remember that the scene has already been placed
                self.hasPlacedScene = true

                // Configure scene surface opacity and navigation constraint
                if let surface = scene.baseSurface {
                    surface.opacity = 0
                    surface.navigationConstraint = .none
                }

                self.updateTranslationFactorAndOriginCamera(scene)
            }
        }
    }

    private func updateTranslationFactorAndOriginCamera(_ scene: AGSScene) {
        // Create the origin camera to be at the bottom and in the center of the scene
        // and set the pitch to be 90.0, to match ARKit tracking values
        let newCam = AGSCamera(latitude: 39.95787000283599,
                               longitude: -75.16996728256345,
                               altitude: 8.813445091247559,
                               heading: 0,
                               pitch: 90,
                               roll: 0)

        // Set the origin camera
        arView.originCamera = newCam

        // Scene width is about 800m
        let geographicContentWidth = 800.0

        // Physical width of the table area the scene will be placed on in meters
        let tableContainerWidth = 1.0

        // Set the translation factor based on scene content width and desired physical size
        arView.translationFactor = geographicContentWidth / tableContainerWidth
    }
}

// MARK: - position the scene on touch
extension DisplayScenesInTabletopAR: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Only let the user place the scene once
        guard !hasPlacedScene else { return }
        
        // Use a screen point to set the initial transformation on the view.
        if self.arView.setInitialTransformation(using: screenPoint) {
            configureSceneForAR()
        } else {
            presentAlert(message: "Failed to place scene, try again")
        }
    }

    private func enableTapToPlace() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.helpLabel.isHidden = false
            self.helpLabel.text = "Tap a surface to place the scene"

            // Wait for the user to tap to place the scene
            self.arView.sceneView.touchDelegate = self
        }
    }
}

// MARK: - tracking status display
extension DisplayScenesInTabletopAR: ARSCNViewDelegate {
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            if hasPlacedScene {
                helpLabel.isHidden = true
            } else if !hasFoundPlane {
                helpLabel.isHidden = false
                helpLabel.text = "Keep moving your phone"
            }
        case .notAvailable:
            helpLabel.text = "Location not available"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                helpLabel.text = "Try moving your phone more slowly"
                helpLabel.isHidden = false
            case .initializing:
                helpLabel.text = "Keep moving your phone"
                helpLabel.isHidden = false
            case .insufficientFeatures:
                helpLabel.text = "Try turning on more lights and moving around"
                helpLabel.isHidden = false
            case .relocalizing:
                // this won't happen as this sample doesn't use relocalization
                break
            @unknown default:
               break
            }
        }
    }

    // MARK: - Wait for plane before enabling scene
    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor as? ARPlaneAnchor != nil else { return }

        // If we haven't placed a scene yet, enable tapping to place a scene and draw the ARKit plane found
        if !hasPlacedScene {
            hasFoundPlane = true
            enableTapToPlace()
            visualizePlane(renderer, didAdd: node, for: anchor)
        }
    }

    // MARK: - Plane visualization
    private func visualizePlane(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Create a custom object to visualize the plane geometry and extent.
        if #available(iOS 11.3, *) {
            // Place content only for anchors found by plane detection.
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

            let arGeometry = planeAnchor.geometry

            let arPlaneSceneGeometry = ARSCNPlaneGeometry(device: renderer.device!)

            arPlaneSceneGeometry?.update(from: arGeometry)

            let newNode = SCNNode(geometry: arPlaneSceneGeometry)

            node.addChildNode(newNode)

            let newMaterial = SCNMaterial()

            newMaterial.isDoubleSided = true

            newMaterial.diffuse.contents = UIColor(red: 0.5, green: 0, blue: 0, alpha: 0.3)

            arPlaneSceneGeometry?.materials = [newMaterial]

            node.geometry = arPlaneSceneGeometry
        }
    }

    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if hasPlacedScene {
            // Remove plane visualization
            node.removeFromParentNode()
            return
        }

        // Create a custom object to visualize the plane geometry and extent.
        if #available(iOS 11.3, *) {
            // Place content only for anchors found by plane detection.
            guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

            let arGeometry = planeAnchor.geometry

            let arPlaneSceneGeometry = ARSCNPlaneGeometry(device: renderer.device!)

            arPlaneSceneGeometry?.update(from: arGeometry)

            node.childNodes[0].geometry = arPlaneSceneGeometry

            if let material = node.geometry?.materials {
                arPlaneSceneGeometry?.materials = material
            }
        }
    }
}
