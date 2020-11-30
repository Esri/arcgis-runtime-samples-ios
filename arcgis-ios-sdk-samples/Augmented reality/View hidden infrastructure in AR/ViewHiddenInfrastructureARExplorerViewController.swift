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

class ViewHiddenInfrastructureARExplorerViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The label to display AR status.
    @IBOutlet var statusLabel: UILabel!
    /// A segmented control to choose between roaming and local mode.
    @IBOutlet var realScaleModePicker: UISegmentedControl!
    /// The `ArcGISARView` managed by the view controller.
    @IBOutlet var arView: ArcGISARView! {
        didSet {
            // Configure scene view.
            let sceneView = arView.sceneView
            sceneView.scene = makeScene()
            // Configure overlays.
            shadowsOverlay = makeShadowsOverlay(pipeGraphics: pipeGraphics)
            leadersOverlay = makeLeadersOverlay(pipeGraphics: pipeGraphics)
            sceneView.graphicsOverlays.addObjects(from: [makePipesOverlay(pipeGraphics: pipeGraphics), shadowsOverlay!, leadersOverlay!])
            // Turn the space and atmosphere effects on for an immersive experience.
            sceneView.spaceEffect = .transparent
            sceneView.atmosphereEffect = .none
            // Configure location data source.
            arView.locationDataSource = AGSCLLocationDataSource()
            arView.arSCNViewDelegate = self
        }
    }
    
    // MARK: Properties
    
    /// The graphics for pipe infrastructure passed from pipe placer view controller.
    var pipeGraphics = [AGSGraphic]()
    /// The elevation source with elevation service URL.
    let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
    /// The elevation surface set to the base surface of the scene.
    let elevationSurface = AGSSurface()
    
    /// A reference to the shadows overlay, to show ground level shadows of the underground pipes.
    var shadowsOverlay: AGSGraphicsOverlay!
    /// A reference to the leaders overlay, to show leader lines between ground and pipes.
    var leadersOverlay: AGSGraphicsOverlay!
    
    // MARK: Methods
    
    /// Create a scene.
    ///
    /// - Returns: A new `AGSScene` object.
    func makeScene() -> AGSScene {
        let scene = AGSScene(basemap: .imagery())
        elevationSurface.navigationConstraint = .none
        elevationSurface.opacity = 0
        elevationSurface.elevationSources = [elevationSource]
        scene.baseSurface = elevationSurface
        return scene
    }
    
    /// Create a graphic overlay for pipes and add graphics to it.
    ///
    /// - Parameter pipeGraphics: The graphics of the pipes.
    /// - Returns: An `AGSGraphicsOverlay` object.
    func makePipesOverlay(pipeGraphics: [AGSGraphic]) -> AGSGraphicsOverlay {
        // Configure and add the overlay for showing drawn pipe infrastructure.
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        let strokeSymbolLayer = AGSSolidStrokeSymbolLayer(
            width: 0.3,
            color: .red,
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
    
    /// Create a graphic overlay for shadows and add graphics to it.
    ///
    /// - Parameter pipeGraphics: The graphics of the pipes.
    /// - Returns: An `AGSGraphicsOverlay` object.
    func makeShadowsOverlay(pipeGraphics: [AGSGraphic]) -> AGSGraphicsOverlay {
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .drapedFlat
        let shadowSymbol = AGSSimpleLineSymbol(style: .solid, color: .systemYellow, width: 0.3)
        let shadowRender = AGSSimpleRenderer(symbol: shadowSymbol)
        graphicsOverlay.renderer = shadowRender
        let shadowGraphics: [AGSGraphic] = pipeGraphics.compactMap { graphic in
            if let elevationOffset = graphic.attributes["ElevationOffset"] as? Double, elevationOffset < 0 {
                // Show yellow shadow at ground level for underground pipes.
                return AGSGraphic(geometry: graphic.geometry, symbol: nil)
            } else {
                return nil
            }
        }
        graphicsOverlay.graphics.addObjects(from: shadowGraphics)
        return graphicsOverlay
    }
    
    /// Create a graphic overlay for leader lines and add graphics to it.
    ///
    /// - Parameter pipeGraphics: The graphics of the pipes.
    /// - Returns: An `AGSGraphicsOverlay` object.
    func makeLeadersOverlay(pipeGraphics: [AGSGraphic]) -> AGSGraphicsOverlay {
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        let leadersSymbol = AGSSimpleLineSymbol(style: .dash, color: .systemRed, width: 0.3)
        let leadersRender = AGSSimpleRenderer(symbol: leadersSymbol)
        graphicsOverlay.renderer = leadersRender
        var leadersGraphics = [AGSGraphic]()
        pipeGraphics.forEach { graphic in
            guard let pipePolyline = graphic.geometry as? AGSPolyline, let elevationOffset = graphic.attributes["ElevationOffset"] as? Double else { return }
            pipePolyline.parts.array().forEach { part in
                part.points.array().forEach { point in
                    // Add a leader line to each vertex of the pipe between its elevation and the ground level.
                    let offsetPoint = AGSPoint(x: point.x, y: point.y, z: point.z - elevationOffset, spatialReference: point.spatialReference)
                    let leaderLine = AGSPolyline(points: [point, offsetPoint])
                    leadersGraphics.append(AGSGraphic(geometry: leaderLine, symbol: nil))
                }
            }
        }
        graphicsOverlay.graphics.addObjects(from: leadersGraphics)
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
    
    @IBAction func optionsBarButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Show supplementary graphics to understand parallax effect.",
            message: nil,
            preferredStyle: .actionSheet
        )
        alertController.addAction(
            UIAlertAction(title: "Leaders and shadows", style: .default) { _ in
                self.shadowsOverlay.isVisible = true
                self.leadersOverlay.isVisible = true
            }
        )
        alertController.addAction(
            UIAlertAction(title: "Leaders only", style: .default) { _ in
                self.shadowsOverlay.isVisible = false
                self.leadersOverlay.isVisible = true
            }
        )
        alertController.addAction(
            UIAlertAction(title: "No supplementary graphics", style: .default) { _ in
                self.shadowsOverlay.isVisible = false
                self.leadersOverlay.isVisible = false
            }
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender
        present(alertController, animated: true)
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

extension ViewHiddenInfrastructureARExplorerViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // Don't show anything in roaming mode; constant location tracking reset means
        // ARKit will always be initializing.
        guard realScaleModePicker.selectedSegmentIndex == 1 else { return }
        switch camera.trackingState {
        case .normal:
            break
        case .notAvailable:
            setStatus(message: "ARKit location not available")
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                setStatus(message: "Try moving your phone more slowly")
            case .initializing:
                setStatus(message: "Keep moving your phone")
            case .insufficientFeatures:
                setStatus(message: "Try turning on more lights and moving around")
            case .relocalizing:
                // This won't happen as this sample doesn't use relocalization.
                break
            @unknown default:
                fatalError("Unknown AR tracking state limited reason")
            }
        }
    }
}

// MARK: - Calibration popup

extension ViewHiddenInfrastructureARExplorerViewController {
    @IBAction func showCalibrationPopup(_ sender: UIBarButtonItem) {
        let calibrationViewController = ViewHiddenInfrastructureARCalibrationViewController(arcgisARView: arView, isLocal: realScaleModePicker.selectedSegmentIndex == 1)
        elevationSurface.opacity = 0.5
        showPopup(calibrationViewController, sourceButton: sender)
    }
    
    func showPopup(_ controller: UIViewController, sourceButton: UIBarButtonItem) {
        controller.modalPresentationStyle = .popover
        if let presentationController = controller.popoverPresentationController {
            presentationController.delegate = self
            presentationController.barButtonItem = sourceButton
            presentationController.permittedArrowDirections = [.down, .up]
        }
        realScaleModePicker.isEnabled = false
        present(controller, animated: true)
    }
}

extension ViewHiddenInfrastructureARExplorerViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        elevationSurface.opacity = 0
        realScaleModePicker.isEnabled = true
    }
}

extension ViewHiddenInfrastructureARExplorerViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
