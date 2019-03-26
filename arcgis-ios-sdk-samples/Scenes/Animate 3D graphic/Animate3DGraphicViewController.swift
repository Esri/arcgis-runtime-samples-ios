//
// Copyright 2017 Esri.
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

class Animate3DGraphicViewController: UIViewController {
    @IBOutlet private var sceneView: AGSSceneView!
    @IBOutlet private var mapView: AGSMapView!
    @IBOutlet private var playBBI: UIBarButtonItem!
    
    private var missionFileNames = ["GrandCanyon.csv", "Hawaii.csv", "Pyrenees.csv", "Snowdon.csv"]
    private var selectedMissionIndex = 0
    private var sceneGraphicsOverlay = AGSGraphicsOverlay()
    private var mapGraphicsOverlay = AGSGraphicsOverlay()
    private var frames: [Frame] = []
    private var planeModelGraphic: AGSGraphic?
    private var triangleGraphic: AGSGraphic?
    private var routeGraphic: AGSGraphic?
    private var currentFrameIndex = 0
    private var animationTimer: Timer?
    private var animationSpeed = 50
    private var orbitGeoElementCameraController: AGSOrbitGeoElementCameraController?
    private weak var planeStatsViewController: PlaneStatsViewController?
    private weak var missionSettingsViewController: MissionSettingsViewController?
    
    private var isAnimating = false {
        didSet {
            playBBI?.title = isAnimating ? "Pause" : "Play"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["Animate3DGraphicViewController", "MissionSettingsViewController", "CameraSettingsViewController", "PlaneStatsViewController", "OptionsTableViewController"]
        
        //map
        let map = AGSMap(basemap: .streets())
        mapView.map = map
        mapView.interactionOptions.isEnabled = false
        
        mapView.layer.borderColor = UIColor.white.cgColor
        mapView.layer.borderWidth = 2
        
        //hide attribution text for map view
        mapView.isAttributionTextVisible = false
        
        //initalize scene with imagery basemap
        let scene = AGSScene(basemap: .imagery())
        
        //assign scene to scene view
        sceneView.scene = scene
        
        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        //elevation source
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        
        //surface
        let surface = AGSSurface()
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        //graphics overlay for scene view
        sceneGraphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        sceneView.graphicsOverlays.add(sceneGraphicsOverlay)
        
        //renderer for scene graphics overlay
        let renderer = AGSSimpleRenderer()
        
        //expressions
        renderer.sceneProperties?.headingExpression = "[HEADING]"
        renderer.sceneProperties?.pitchExpression = "[PITCH]"
        renderer.sceneProperties?.rollExpression = "[ROLL]"
        
        //set renderer on the overlay
        sceneGraphicsOverlay.renderer = renderer
        
        //graphics overlay for map view
        mapView.graphicsOverlays.add(mapGraphicsOverlay)
        
        //renderer for map graphics overlay
        let renderer2D = AGSSimpleRenderer()
        renderer2D.rotationExpression = "[ANGLE]"
        mapGraphicsOverlay.renderer = renderer2D
        
        //route graphic
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 1)
        let routeGraphic = AGSGraphic(geometry: nil, symbol: lineSymbol, attributes: nil)
        self.routeGraphic = routeGraphic
        mapGraphicsOverlay.graphics.add(routeGraphic)
        
        addPlane2D()
        
        //add the plane model
        addPlane3D()
        
        //setup camera to follow the plane
        setupCamera()
        
        //select the first mission by default
        changeMissionAction()
    }
    
    private func addPlane2D() {
        let triangleSymbol = AGSSimpleMarkerSymbol(style: .triangle, color: .red, size: 10)
        let triangleGraphic = AGSGraphic(geometry: nil, symbol: triangleSymbol, attributes: nil)
        self.triangleGraphic = triangleGraphic
        mapGraphicsOverlay.graphics.add(triangleGraphic)
    }
    
    private func addPlane3D() {
        //model symbol
        let planeModelSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 20)
        planeModelSymbol.anchorPosition = .center
        
        //arbitrary geometry for time being, the geometry will update with animation
        let point = AGSPoint(x: 0, y: 0, z: 0, spatialReference: .wgs84())
        
        //create graphic for the model
        let planeModelGraphic = AGSGraphic()
        self.planeModelGraphic = planeModelGraphic
        planeModelGraphic.geometry = point
        planeModelGraphic.symbol = planeModelSymbol
        
        //add graphic to the graphics overlay
        sceneGraphicsOverlay.graphics.add(planeModelGraphic)
    }
    
    private func setupCamera() {
        guard let planeModelGraphic = planeModelGraphic else {
            return
        }
        
        //AGSOrbitGeoElementCameraController to follow plane graphic
        //initialize object specifying the target geo element and distance to keep from it
        let orbitGeoElementCameraController = AGSOrbitGeoElementCameraController(targetGeoElement: planeModelGraphic, distance: 1000)
        self.orbitGeoElementCameraController = orbitGeoElementCameraController
        
        //set camera to align its heading with the model
        orbitGeoElementCameraController.isAutoHeadingEnabled = true
        
        //will keep the camera still while the model pitches or rolls
        orbitGeoElementCameraController.isAutoPitchEnabled = false
        orbitGeoElementCameraController.isAutoRollEnabled = false
        
        //min and max distance values between the model and the camera
        orbitGeoElementCameraController.minCameraDistance = 500
        orbitGeoElementCameraController.maxCameraDistance = 8000
        
        //set the camera controller on scene view
        sceneView.cameraController = orbitGeoElementCameraController
    }
    
    private func loadMissionData(_ name: String) {
        //get the path of the specified file in the bundle
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            //get content of the file
            if let content = try? String(contentsOfFile: path) {
                //split content into array of lines separated by new line character
                //each line is one frame
                let lines = content.components(separatedBy: CharacterSet.newlines)
                
                //create a frame object for each line
                frames = lines.map { (line) -> Frame in
                    let details = line.components(separatedBy: ",")
                    precondition(details.count == 6)
                    
                    let position = AGSPoint(x: Double(details[0])!,
                                            y: Double(details[1])!,
                                            z: Double(details[2])!,
                                            spatialReference: .wgs84())
                    
                    //load position, heading, pitch and roll for each frame
                    return Frame(position: position,
                                 heading: Measurement(value: Double(details[3])!, unit: UnitAngle.degrees),
                                 pitch: Measurement(value: Double(details[4])!, unit: UnitAngle.degrees),
                                 roll: Measurement(value: Double(details[5])!, unit: UnitAngle.degrees))
                }
            }
        } else {
            print("Mission file not found")
        }
    }
    
    private func startAnimation() {
        //invalidate timer to stop previous ongoing animation
        self.animationTimer?.invalidate()
        
        //duration or interval
        let duration = 1 / Double(animationSpeed)
        
        //new timer
        let animationTimer = Timer(timeInterval: duration, repeats: true) { [weak self] _ in
            self?.animate()
        }
        self.animationTimer = animationTimer
        RunLoop.main.add(animationTimer, forMode: .common)
    }
    
    private func animate() {
        //validations
        guard !frames.isEmpty,
            let planeModelGraphic = planeModelGraphic,
            let triangleGraphic = triangleGraphic else {
            return
        }
        
        //if animation is complete
        if currentFrameIndex >= frames.count {
            //invalidate timer
            animationTimer?.invalidate()
            
            //update state
            isAnimating = false
            
            //reset index
            currentFrameIndex = 0
            
            return
        }
        
        //else get the frame
        let frame = frames[currentFrameIndex]
        
        //update the properties on the model
        planeModelGraphic.geometry = frame.position
        planeModelGraphic.attributes["HEADING"] = frame.heading.value
        planeModelGraphic.attributes["PITCH"] = frame.pitch.value
        planeModelGraphic.attributes["ROLL"] = frame.roll.value
        
        //2D plane
        triangleGraphic.geometry = frame.position
        
        //set viewpoint for map view
        let viewpoint = AGSViewpoint(center: frame.position, scale: 100000, rotation: 360 + frame.heading.value)
        mapView.setViewpoint(viewpoint)
        
        //update progress
        missionSettingsViewController?.progress = Float(currentFrameIndex) / Float(frames.count)
        
        //update stats
        planeStatsViewController?.frame = frame
        
        //increment current frame index
        currentFrameIndex += 1
    }
    
    // MARK: - Actions
    
    @IBAction func changeMissionAction() {
        //invalidate timer
        animationTimer?.invalidate()
        
        //set play button
        isAnimating = false
        
        //new mission name
        let missionFileName = missionFileNames[selectedMissionIndex]
        loadMissionData(missionFileName)
        
        //create a polyline from position in each frame to be used as path
        let points = frames.map { (frame) -> AGSPoint in
            return frame.position
        }
        
        let polylineBuilder = AGSPolylineBuilder(points: points)
        routeGraphic?.geometry = polylineBuilder.toGeometry()
        
        //set current frame to zero
        currentFrameIndex = 0
        
        //animate to first frame
        animate()
    }
    
    @IBAction func playAction(sender: UIBarButtonItem) {
        if isAnimating {
            animationTimer?.invalidate()
        } else {
            startAnimation()
        }
        
        isAnimating.toggle()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // dismiss any shown view controllers
        dismiss(animated: false)
        
        if let controller = segue.destination as? CameraSettingsViewController {
            controller.orbitGeoElementCameraController = orbitGeoElementCameraController
            
            //pop over settings
            controller.presentationController?.delegate = self
            
            //preferred content size
            if traitCollection.horizontalSizeClass == .regular,
                traitCollection.verticalSizeClass == .regular {
                controller.preferredContentSize = CGSize(width: 300, height: 380)
            } else {
                controller.preferredContentSize = CGSize(width: 300, height: 250)
            }
        } else if let planeStatsViewController = segue.destination as? PlaneStatsViewController {
            self.planeStatsViewController = planeStatsViewController
            
            //pop over settings
            planeStatsViewController.presentationController?.delegate = self
        } else if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? MissionSettingsViewController {
            self.missionSettingsViewController = controller
            //initial values
            controller.missionFileNames = missionFileNames
            controller.selectedMissionIndex = selectedMissionIndex
            controller.animationSpeed = animationSpeed
            controller.progress = Float(currentFrameIndex) / Float(frames.count)
            
            //pop over settings
            navController.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            controller.delegate = self
        }
    }
}

extension Animate3DGraphicViewController: MissionSettingsVCDelegate {
    func missionSettingsViewController(_ missionSettingsViewController: MissionSettingsViewController, didSelectMissionAtIndex index: Int) {
        selectedMissionIndex = index
        changeMissionAction()
    }
    
    func missionSettingsViewController(_ missionSettingsViewController: MissionSettingsViewController, didChangeSpeed speed: Int) {
        animationSpeed = speed
        
        if isAnimating {
            animationTimer?.invalidate()
            startAnimation()
        }
    }
}

extension Animate3DGraphicViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        //for popover or non modal presentation
        return .none
    }
}

struct Frame {
    let position: AGSPoint
    let heading: Measurement<UnitAngle>
    let pitch: Measurement<UnitAngle>
    let roll: Measurement<UnitAngle>
    
    init(position: AGSPoint, heading: Measurement<UnitAngle>, pitch: Measurement<UnitAngle>, roll: Measurement<UnitAngle>) {
        self.position = position
        self.heading = heading
        self.pitch = pitch
        self.roll = roll
    }
    
    var altitude: Measurement<UnitLength> {
        return Measurement(value: position.z, unit: UnitLength.meters)
    }
}
