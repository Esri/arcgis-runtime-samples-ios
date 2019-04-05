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
    
    @IBOutlet private var sceneView: AGSSceneView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var visualEffectView: UIVisualEffectView!
    
    var cameraControllers = [AGSCameraController]()
    let longitude = -109.937516, latitude = 38.456714
    
    lazy var planeSymbol: AGSModelSceneSymbol = {[unowned self] in
        let planeSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 100.0)
        planeSymbol.load{ _ in
            DispatchQueue.main.async {
                self.planeSymbolDidLoad()
            }
        }
        return planeSymbol
    }()
    
    lazy var planeGraphic: AGSGraphic = {
        let planePosition = AGSPoint(x: longitude, y: latitude, z: 5000, spatialReference: AGSSpatialReference.wgs84())
        let planeGraphic = AGSGraphic(geometry: planePosition, symbol: planeSymbol, attributes: nil)
        return planeGraphic
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ChooseCameraControllerViewController"]
        
        // Constraint visual effect view to the scene view's attribution label.
        visualEffectView.bottomAnchor.constraint(equalTo: sceneView.attributionTopAnchor, constant: -10).isActive = true
        
        // Assign the scene to the scene view.
        sceneView.scene = makeScene()
    
        // Zoom scene view to the viewpoint specified by the camera position.
        let point = AGSPoint(x: longitude, y: latitude, spatialReference: AGSSpatialReference.wgs84())
        let camera = AGSCamera(lookAt: point, distance: 5500, heading: 150, pitch: 20, roll: 0)
        sceneView.setViewpointCamera(camera)
        
        // Add graphics overlay to the scene
        sceneView.graphicsOverlays.add(makeGraphicsOverlay())
        
        cameraControllers.append(contentsOf: [makeOrbitLocationCameraController(), makeOrbitGeoElementCameraController(), AGSGlobeCameraController()])
    }
    
    /// Called when the plane model scene symbol loads successfully or fails to load.
    func planeSymbolDidLoad() {
        if let error = planeSymbol.loadError {
            presentAlert(error: error)
        }
        else {
            planeSymbol.heading = 45
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
    
    /// Returns a graphics overlay that contains a graphic.
    func makeGraphicsOverlay() -> AGSGraphicsOverlay {
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        graphicsOverlay.graphics.add(planeGraphic)
        return graphicsOverlay
    }
    
    /// Returns a controller that allows a scene view's camera to orbit
    /// the Upheaval Dome crater structure.
    func makeOrbitLocationCameraController() -> AGSOrbitLocationCameraController {
        let targetLocation = AGSPoint(x: -109.929589, y: 38.437304, z: 1700, spatialReference: AGSSpatialReference.wgs84())
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
}


extension ChooseCameraControllerViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cameraControllers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = .clear
        
        // Set label.
        cell.textLabel?.text = getDescription(of: cameraControllers[indexPath.row])
        
        // Set accessory type.
        if indexPath.row == 2 {
            cell.accessoryType = .checkmark
            
            // Select global camera controller by default.
            tableView.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .none)
            tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
        }
        else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    /// Gets description for a specified camera controller.
    ///
    /// - Parameter cameraController: Camera controller of scene view.
    /// - Returns: A text description of the camera controller.
    func getDescription(of cameraController: AGSCameraController) -> String {
        if cameraController is AGSOrbitGeoElementCameraController {
            return "Orbit camera around plane"
        }
        else if cameraController is AGSOrbitLocationCameraController {
            return "Orbit camera around crater"
        }
        else {
            return "Free pan round the globe"
        }
    }
}


extension ChooseCameraControllerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        
        selectedCell?.accessoryType = .checkmark
        sceneView.cameraController = cameraControllers[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let unselectedCell = tableView.cellForRow(at: indexPath)

        unselectedCell?.accessoryType = .none
    }
}
