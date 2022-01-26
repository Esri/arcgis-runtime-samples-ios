// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class OrbitCameraAroundObjectViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The scene view managed by the view controller.
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
            sceneView.graphicsOverlays.add(makeSceneGraphicsOverlay())
            // Create and set the orbit camera controller to the scene view.
            sceneView.cameraController = makeOrbitGeoElementCameraController()
        }
    }
    
    @IBOutlet var changeViewBarButtonItem: UIBarButtonItem! {
        didSet {
            changeViewBarButtonItem.possibleTitles = Set(ChangeViewButtonState.allCases.map(\.title))
        }
    }
    
    // MARK: Properties
    
    /// A graphic of a plane model.
    let planeGraphic: AGSGraphic = {
        let planeSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 1)
        let planePosition = AGSPoint(x: 6.637, y: 45.399, z: 100, spatialReference: .wgs84())
        let planeGraphic = AGSGraphic(geometry: planePosition, symbol: planeSymbol, attributes: ["HEADING": 45.0, "PITCH": 0])
        return planeGraphic
    }()
    
    var moveCameraAnimationCancelable: AGSCancelable?
    
    enum ChangeViewButtonState: CaseIterable {
        case cockpitView
        case centerView
        
        var title: String {
            switch self {
            case .cockpitView:
                return "Cockpit View"
            case .centerView:
                return "Center View"
            }
        }
    }
    
    var changeViewButtonState: ChangeViewButtonState = .cockpitView
    
    // MARK: Instance methods
    
    /// Create a scene.
    func makeScene() -> AGSScene {
        let scene = AGSScene(basemapStyle: .arcGISImagery)
        // Create an elevation source from Terrain3D REST service.
        let elevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationServiceURL)
        let surface = AGSSurface()
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        return scene
    }
    
    /// Create a graphics overlay for the scene.
    func makeSceneGraphicsOverlay() -> AGSGraphicsOverlay {
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .relative
        let renderer = AGSSimpleRenderer()
        renderer.sceneProperties?.headingExpression = "[HEADING]"
        renderer.sceneProperties?.pitchExpression = "[PITCH]"
        graphicsOverlay.renderer = renderer
        graphicsOverlay.graphics.add(planeGraphic)
        return graphicsOverlay
    }
    
    /// Create a controller that allows a scene view's camera to orbit the plane.
    func makeOrbitGeoElementCameraController() -> AGSOrbitGeoElementCameraController {
        let cameraController = AGSOrbitGeoElementCameraController(targetGeoElement: planeGraphic, distance: 50)
        
        // Restrict the camera's heading to stay behind the plane.
        cameraController.minCameraHeadingOffset = -45
        cameraController.maxCameraHeadingOffset = 45
        
        // Restrict the camera's pitch so it doesn't collide with the ground.
        cameraController.minCameraPitchOffset = 10
        cameraController.maxCameraPitchOffset = 100
        
        // Restrict the camera to stay between 10 and 100 meters from the plane.
        cameraController.minCameraDistance = 10
        cameraController.maxCameraDistance = 100
        
        // Position the plane a third from the bottom of the screen.
        cameraController.targetVerticalScreenFactor = 0.33
        
        // Don't pitch the camera when the plane pitches.
        cameraController.isAutoPitchEnabled = false
        return cameraController
    }
    
    // MARK: Actions
    
    @IBAction func changeViewBarButtonItemTapped(_ sender: UIBarButtonItem) {
        moveCameraAnimationCancelable?.cancel()
        switch changeViewButtonState {
        case .cockpitView:
            cockpitViewBarButtonItemTapped(sender)
            changeViewButtonState = .centerView
        case .centerView:
            centerViewBarButtonItemTapped(sender)
            changeViewButtonState = .cockpitView
        }
        sender.title = changeViewButtonState.title
    }
    
    func centerViewBarButtonItemTapped(_ sender: UIBarButtonItem) {
        let cameraController = sceneView.cameraController as! AGSOrbitGeoElementCameraController
        
        cameraController.isCameraDistanceInteractive = true
        cameraController.isAutoPitchEnabled = false
        
        cameraController.targetOffsetX = 0
        cameraController.targetOffsetY = 0
        cameraController.targetOffsetZ = 0
        
        cameraController.cameraHeadingOffset = 0
        
        cameraController.minCameraPitchOffset = 10
        cameraController.maxCameraPitchOffset = 100
        cameraController.cameraPitchOffset = 45
        
        cameraController.minCameraDistance = 10
        cameraController.cameraDistance = 50
    }
    
    func cockpitViewBarButtonItemTapped(_ sender: UIBarButtonItem) {
        let cameraController = sceneView.cameraController as! AGSOrbitGeoElementCameraController
        
        cameraController.isCameraDistanceInteractive = false
        cameraController.minCameraDistance = 0.1
        // Unlock the camera pitch for the rotation animation.
        cameraController.minCameraPitchOffset = -180
        cameraController.maxCameraPitchOffset = 180
        
        // Animate the camera target to the cockpit.
        cameraController.setTargetOffsetX(0, targetOffsetY: -2, targetOffsetZ: 1.1, duration: 1)
        
        // If the camera is already tracking the plane's pitch, subtract it from
        // the delta angle for the animation.
        let pitchDelta = cameraController.isAutoPitchEnabled ? 0 : 90 - cameraController.cameraPitchOffset + (planeGraphic.attributes["PITCH"] as! Double)
        // Animate the camera so that it is at the target (cockpit), facing
        // forward (0 deg heading), and aligned with the horizon (90 deg pitch).
        moveCameraAnimationCancelable = cameraController.moveCamera(
            withDistanceDelta: 0.1 - cameraController.cameraDistance,
            headingDelta: -cameraController.cameraHeadingOffset,
            pitchDelta: pitchDelta,
            duration: 1
        ) { [weak self] animationFinished in
            self?.moveCameraAnimationCancelable = nil
            // If the animation was interrupted, don't lock the camera pitch.
            guard animationFinished else { return }
            // When the animation finishes, lock the camera pitch.
            cameraController.minCameraPitchOffset = 90
            cameraController.maxCameraPitchOffset = 90
            cameraController.isAutoPitchEnabled = true
        }
    }
    
    // MARK: UIViewController
    
    @IBSegueAction
    func makeSettingsViewController(_ coder: NSCoder) -> OrbitCameraSettingsViewController? {
        let settingsViewController = OrbitCameraSettingsViewController(
            coder: coder,
            cameraController: sceneView.cameraController as! AGSOrbitGeoElementCameraController,
            graphic: planeGraphic
        )
        settingsViewController?.modalPresentationStyle = .popover
        settingsViewController?.presentationController?.delegate = self
        return settingsViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["OrbitCameraAroundObjectViewController", "OrbitCameraSettingsViewController"]
    }
}

extension OrbitCameraAroundObjectViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
