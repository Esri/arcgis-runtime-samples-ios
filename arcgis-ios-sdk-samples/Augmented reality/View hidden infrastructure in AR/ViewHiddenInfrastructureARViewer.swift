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
import ARKit
import ArcGIS
import ArcGISToolkit

class ViewHiddenInfrastructureARViewer: UIViewController {
    // MARK: Storyboard views
    
    /// The label to display route-planning status.
    @IBOutlet var statusLabel: UILabel!
    /// The bar button to calibrate navigation heading.
    @IBOutlet var calibrateButtonItem: UIBarButtonItem!
    /// A segmented control to choose between roaming and local mode.
    @IBOutlet var realScaleModePicker: UISegmentedControl!
    /// The `ArcGISARView` managed by the view controller.
    @IBOutlet weak var arView: ArcGISARView! {
        didSet {
            // Configure scene view.
            let sceneView = arView.sceneView
            sceneView.scene = makeScene()
            sceneView.graphicsOverlays.add(makePipeOverlay())
            // Turn the space and atmosphere effects on for an immersive experience.
            sceneView.spaceEffect = .transparent
            sceneView.atmosphereEffect = .none
            // Configure location data source.
            arView.locationDataSource = AGSCLLocationDataSource()
            arView.arSCNViewDelegate = self
        }
    }
    
    // MARK: Properties
    
    /// The graphics for pipe infrastructure passed from pipe planner view controller.
    var pipeGraphics = [AGSGraphic]()
    /// The elevation source with elevation service URL.
    let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
    /// The elevation surface set to the base surface of the scene.
    let elevationSurface = AGSSurface()
    
    // MARK: Methods
    
    /// Create a scene.
    ///
    /// - Returns: A new `AGSScene` object.
    func makeScene() -> AGSScene {
        let scene = AGSScene(basemapType: .imagery)
        elevationSurface.navigationConstraint = .none
        elevationSurface.opacity = 0
        elevationSurface.elevationSources = [elevationSource]
        elevationSurface.navigationConstraint = .none
        scene.baseSurface = elevationSurface
        return scene
    }
    
    /// Create a graphic overlay and add graphics to it.
    ///
    /// - Returns: An `AGSGraphicsOverlay` object.
    func makePipeOverlay() -> AGSGraphicsOverlay {
        // Configure and add the overlay for showing drawn pipe infrastructure.
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        let strokeSymbolLayer = AGSSolidStrokeSymbolLayer(
            width: 0.3,
            color: .yellow,
            geometricEffects: [],
            lineStyle3D: .tube
        )
        let polylineSymbol = AGSMultilayerPolylineSymbol(symbolLayers: [strokeSymbolLayer])
        let polylineRenderer = AGSSimpleRenderer(symbol: polylineSymbol)
        graphicsOverlay.renderer = polylineRenderer
        let infrastructureGraphics = pipeGraphics.map { AGSGraphic(geometry: $0.geometry, symbol: nil) }
        graphicsOverlay.graphics.addObjects(from: infrastructureGraphics)
        return graphicsOverlay
    }
    
    // MARK: Action
    
    @IBAction func realScaleModePickerValueChanged(_ sender: UISegmentedControl) {
        arView.stopTracking()
        if sender.selectedSegmentIndex == 0 {
            // Roaming - continuous update
            arView.startTracking(.continuous)
            setStatus(message: "Using CoreLocation + ARKit")
        } else {
            // Local - only update once, then manually calibrate
            arView.startTracking(.initial)
            setStatus(message: "Using ARKit only")
        }
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    // MARK: UIViewController
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Set tracking mode.
        realScaleModePickerValueChanged(realScaleModePicker)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.stopTracking()
    }
}

// MARK: - ARKit camera tracking status

extension ViewHiddenInfrastructureARViewer: ARSCNViewDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // Don't show anything in roaming mode; constant location tracking reset means
        // ARKit will always be initializing
        if realScaleModePicker.selectedSegmentIndex == 0 {
//            arKitStatusLabel.isHidden = true
            return
        }
        switch camera.trackingState {
        case .normal:
//            arKitStatusLabel.isHidden = true
            break
        case .notAvailable:
            setStatus(message: "ARKit location not available")
//            arKitStatusLabel.text = "ARKit location not available"
//            arKitStatusLabel.isHidden = false
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                setStatus(message: "Try moving your phone more slowly")
//                arKitStatusLabel.text = "Try moving your phone more slowly"
//                arKitStatusLabel.isHidden = false
            case .initializing:
                setStatus(message: "Keep moving your phone")
//                arKitStatusLabel.text = "Keep moving your phone"
//                arKitStatusLabel.isHidden = false
            case .insufficientFeatures:
                setStatus(message: "Try turning on more lights and moving around")
//                arKitStatusLabel.text = "Try turning on more lights and moving around"
//                arKitStatusLabel.isHidden = false
            case .relocalizing:
                // this won't happen as this sample doesn't use relocalization
                break
            @unknown default:
                fatalError("Unknown AR tracking state limited reason")
            }
        }
    }
}

// MARK: - Calibration popup

extension ViewHiddenInfrastructureARViewer {
    @IBAction func showCalibrationPopup(_ sender: UIBarButtonItem) {
        let calibrationVC = ViewHiddenInfrastructureARCalibrationViewController(arcgisARView: arView)
        elevationSurface.opacity = 0.6
        showPopup(calibrationVC, sourceButton: sender)
    }
    
    private func showPopup(_ controller: UIViewController, sourceButton: UIBarButtonItem) {
        controller.modalPresentationStyle = .popover
        if let presentationController = controller.popoverPresentationController {
            presentationController.delegate = self
            presentationController.barButtonItem = sourceButton
            presentationController.permittedArrowDirections = [.down, .up]
        }
        present(controller, animated: true)
    }
}

extension ViewHiddenInfrastructureARViewer: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        elevationSurface.opacity = 0
    }
}

extension ViewHiddenInfrastructureARViewer: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
