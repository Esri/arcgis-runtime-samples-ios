// Copyright 2019 Esri.
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

class ChooseCameraControllerViewController: UIViewController {
    @IBOutlet private var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
            
            let point = AGSPoint(x: -109.937516, y: 38.456714, spatialReference: .wgs84())
            let camera = AGSCamera(lookAt: point, distance: 5500, heading: 150, pitch: 20, roll: 0)
            sceneView.setViewpointCamera(camera)
        }
    }
    
    @IBOutlet var cameraControllersBarButtonItem: UIBarButtonItem!

    lazy var planeSymbol: AGSModelSceneSymbol = { [unowned self] in
        let planeSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 100.0)
        planeSymbol.load { _ in
            DispatchQueue.main.async {
                self.planeSymbolDidLoad()
            }
        }
        return planeSymbol
    }()

    lazy var planeGraphic: AGSGraphic = {
        let planePosition = AGSPoint(x: -109.937516, y: 38.456714, z: 5000, spatialReference: .wgs84())
        let planeGraphic = AGSGraphic(geometry: planePosition, symbol: planeSymbol, attributes: nil)
        return planeGraphic
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ChooseCameraControllerViewController"]

        // Add graphics overlay to the scene view.
        sceneView.graphicsOverlays.add(makeGraphicsOverlay())
    }

    /// Called when the plane model scene symbol loads successfully or fails to load.
    func planeSymbolDidLoad() {
        if let error = planeSymbol.loadError {
            presentAlert(error: error)
        } else {
            planeSymbol.heading = 45
            cameraControllersBarButtonItem.isEnabled = true
        }
    }

    /// Returns a scene with imagery basemap and elevation data.
    func makeScene() -> AGSScene {
        let scene = AGSScene(basemap: .imagery())

        // Add base surface to the scene for elevation data.
        let surface = AGSSurface()
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface

        return scene
    }

    /// Returns a graphics overlay containing the plane graphic.
    func makeGraphicsOverlay() -> AGSGraphicsOverlay {
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        graphicsOverlay.graphics.add(planeGraphic)
        return graphicsOverlay
    }

    /// Returns a controller that allows a scene view's camera to orbit the Upheaval Dome crater structure.
    func makeOrbitLocationCameraController() -> AGSOrbitLocationCameraController {
        let targetLocation = AGSPoint(x: -109.929589, y: 38.437304, z: 1700, spatialReference: .wgs84())
        let cameraController = AGSOrbitLocationCameraController(targetLocation: targetLocation, distance: 5000)
        cameraController.cameraPitchOffset = 3
        cameraController.cameraHeadingOffset = 150
        return cameraController
    }

    /// Returns a controller that allows a scene view's camera to orbit the plane.
    func makeOrbitGeoElementCameraController() -> AGSOrbitGeoElementCameraController {
        let cameraController = AGSOrbitGeoElementCameraController(targetGeoElement: planeGraphic, distance: 5000)
        cameraController.cameraPitchOffset = 30
        cameraController.cameraHeadingOffset = 150
        return cameraController
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CameraControllersPopover" {
            guard let controller = segue.destination as? CameraControllerTableViewController else { return }
            controller.delegate = self
            controller.cameraControllers = [makeOrbitLocationCameraController(), makeOrbitGeoElementCameraController(), AGSGlobeCameraController()]
            controller.selectedCameraController = sceneView.cameraController

            // Popover presentation logic.
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 130)
        }
    }
}

extension ChooseCameraControllerViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // For popover or non modal presentation.
        return .none
    }
}

extension ChooseCameraControllerViewController: CameraControllerTableViewControllerDelagate {
    func selectedCameraControllerChanged(_ tableViewController: CameraControllerTableViewController) {
        sceneView.cameraController = tableViewController.selectedCameraController
    }
}
