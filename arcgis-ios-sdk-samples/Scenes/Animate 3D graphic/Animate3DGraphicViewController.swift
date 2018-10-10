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

class Animate3DGraphicViewController: UIViewController, MissionSettingsVCDelegate, UIAdaptivePresentationControllerDelegate {

    @IBOutlet private var sceneView:AGSSceneView!
    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var playBBI:UIBarButtonItem!
    
    private var missionFileNames = ["GrandCanyon.csv", "Hawaii.csv", "Pyrenees.csv", "Snowdon.csv"]
    private var selectedMissionIndex = 0
    private var sceneGraphicsOverlay = AGSGraphicsOverlay()
    private var mapGraphicsOverlay = AGSGraphicsOverlay()
    private var frames:[Frame]!
    private var fileNames:[String]!
    private var planeModelSymbol:AGSModelSceneSymbol!
    private var planeModelGraphic:AGSGraphic!
    private var triangleSymbol:AGSSimpleMarkerSymbol!
    private var triangleGraphic:AGSGraphic!
    private var routeGraphic:AGSGraphic!
    private var currentFrameIndex = 0
    private var animationTimer:Timer!
    private var animationSpeed = 50
    private var orbitGeoElementCameraController:AGSOrbitGeoElementCameraController!
    private weak var planeStatsViewController:PlaneStatsViewController?
    private weak var missionSettingsViewController:MissionSettingsViewController?
    
    
    private var isAnimating = false {
        didSet {
            self.playBBI?.title = isAnimating ? "Pause" : "Play"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["Animate3DGraphicViewController", "MissionSettingsViewController", "CameraSettingsViewController", "PlaneStatsViewController"]
        
        //map
        let map = AGSMap(basemap: .streets())
        self.mapView.map = map
        self.mapView.interactionOptions.isEnabled = false
        
        self.mapView.layer.borderColor = UIColor.white.cgColor
        self.mapView.layer.borderWidth = 2
        
        //hide attribution text for map view
        self.mapView.isAttributionTextVisible = false
        
        //initalize scene with imagery basemap
        let scene = AGSScene(basemap: .imagery())
        
        //assign scene to scene view
        self.sceneView.scene = scene
        
        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        //elevation source
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        
        //surface
        let surface = AGSSurface()
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        //graphics overlay for scene view
        self.sceneGraphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        sceneView.graphicsOverlays.add(self.sceneGraphicsOverlay)
        
        //renderer for scene graphics overlay
        let renderer = AGSSimpleRenderer()
        
        //expressions
        renderer.sceneProperties?.headingExpression = "[HEADING]"
        renderer.sceneProperties?.pitchExpression = "[PITCH]"
        renderer.sceneProperties?.rollExpression = "[ROLL]"
        
        //set renderer on the overlay
        self.sceneGraphicsOverlay.renderer = renderer
        
        //graphics overlay for map view
        self.mapView.graphicsOverlays.add(self.mapGraphicsOverlay)
        
        //renderer for map graphics overlay
        let renderer2D = AGSSimpleRenderer()
        renderer2D.rotationExpression = "[ANGLE]"
        self.mapGraphicsOverlay.renderer = renderer2D
        
        //route graphic
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 1)
        self.routeGraphic = AGSGraphic(geometry: nil, symbol: lineSymbol, attributes: nil)
        self.mapGraphicsOverlay.graphics.add(routeGraphic)
        
        self.addPlane2D()
        
        //add the plane model
        self.addPlane3D()
        
        //setup camera to follow the plane
        self.setupCamera()
        
        //select the first mission by default
        self.changeMissionAction()
    }
    
    private func addPlane2D() {
        self.triangleSymbol = AGSSimpleMarkerSymbol(style: .triangle, color: .red, size: 10)
        self.triangleGraphic = AGSGraphic(geometry: nil, symbol: self.triangleSymbol, attributes: nil)
        self.mapGraphicsOverlay.graphics.add(self.triangleGraphic)
    }
    
    private func addPlane3D() {
        //model symbol
        self.planeModelSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 20)
        self.planeModelSymbol.anchorPosition = .center
        
        //arbitrary geometry for time being, the geometry will update with animation
        let point = AGSPoint(x: 0, y: 0, z: 0, spatialReference: AGSSpatialReference.wgs84())
        
        //create graphic for the model
        self.planeModelGraphic = AGSGraphic()
        self.planeModelGraphic.geometry = point
        self.planeModelGraphic.symbol = self.planeModelSymbol
        
        //add graphic to the graphics overlay
        self.sceneGraphicsOverlay.graphics.add(self.planeModelGraphic)
    }
    
    private func setupCamera() {
        
        //AGSOrbitGeoElementCameraController to follow plane graphic
        //initialize object specifying the target geo element and distance to keep from it
        self.orbitGeoElementCameraController = AGSOrbitGeoElementCameraController(targetGeoElement: self.planeModelGraphic, distance: 1000)
        
        //set camera to align its heading with the model
        self.orbitGeoElementCameraController.isAutoHeadingEnabled = true
        
        //will keep the camera still while the model pitches or rolls
        self.orbitGeoElementCameraController.isAutoPitchEnabled = false
        self.orbitGeoElementCameraController.isAutoRollEnabled = false
        
        //min and max distance values between the model and the camera
        self.orbitGeoElementCameraController.minCameraDistance = 500
        self.orbitGeoElementCameraController.maxCameraDistance = 8000
        
        //set the camera controller on scene view
        self.sceneView.cameraController = self.orbitGeoElementCameraController
        
    }
    
    private func loadMissionData(_ name: String) {
        
        //get the path of the specified file in the bundle
        if let path = Bundle.main.path(forResource: name, ofType: nil) {
            
            //get content of the file
            if let content = try? String(contentsOfFile: path) {
                
                //split content into array of lines separated by new line character
                //each line is one frame
                let lines = content.components(separatedBy: CharacterSet.newlines)
                
                //initialize array of frames
                var frames = [Frame]()
                
                //create a frame object for each line
                for line in lines {
                    let details = line.components(separatedBy: ",")
                    
                    //load position, heading, pitch and roll for each frame
                    let frame = Frame()
                    frame.position = AGSPoint(x: Double(details[0])!, y: Double(details[1])!, z: Double(details[2])!, spatialReference: AGSSpatialReference.wgs84())
                    frame.heading = Double(details[3])!
                    frame.pitch = Double(details[4])!
                    frame.roll = Double(details[5])!
                    
                    frames.append(frame)
                }
                
                self.frames = frames
            }
        }
        else {
            print("Mission file not found")
        }
    }
    
    private func startAnimation() {
        
        //invalidate timer to stop previous ongoing animation
        self.animationTimer?.invalidate()
        
        //duration or interval
        let duration = 1 / Double(self.animationSpeed)
        
        //new timer
        self.animationTimer = Timer(timeInterval: duration, target: self, selector: #selector(animate), userInfo: nil, repeats: true)
        RunLoop.main.add(self.animationTimer, forMode: .common)
    }
    
    @objc func animate() {
        
        //validations
        if self.frames == nil || self.planeModelSymbol == nil {
            return
        }
        
        //if animation is complete
        if self.currentFrameIndex >= self.frames.count {
            
            //invalidate timer
            self.animationTimer?.invalidate()
            
            //update state
            self.isAnimating = false
            
            //reset index
            self.currentFrameIndex = 0
            
            return
        }
        
        //else get the frame
        let frame = self.frames[self.currentFrameIndex]
        
        //update the properties on the model
        self.planeModelGraphic.geometry = frame.position
        self.planeModelGraphic.attributes["HEADING"] = frame.heading
        self.planeModelGraphic.attributes["PITCH"] = frame.pitch
        self.planeModelGraphic.attributes["ROLL"] = frame.roll
        
        //2D plane
        self.triangleGraphic.geometry = frame.position
        
        //set viewpoint for map view
        let viewpoint = AGSViewpoint(center: frame.position, scale: 100000, rotation: 360 + Double(frame.heading))
        self.mapView.setViewpoint(viewpoint)
        
        //update progress
        self.missionSettingsViewController?.progress = Float(self.currentFrameIndex) / Float(self.frames.count)
        
        //update labels
        self.planeStatsViewController?.altitudeLabel?.text = "\(Int(frame.position.z))"
        self.planeStatsViewController?.headingLabel?.text = "\(Int(frame.heading))º"
        self.planeStatsViewController?.pitchLabel?.text = "\(Int(frame.pitch))º"
        self.planeStatsViewController?.rollLabel?.text = "\(Int(frame.roll))º"
        
        //increment current frame index
        self.currentFrameIndex += 1
    }
    
    //MARK: - Actions
    
    @IBAction func changeMissionAction() {
        
        //invalidate timer
        self.animationTimer?.invalidate()
        
        //set play button
        self.isAnimating = false
        
        //new mission name
        let missionFileName = self.missionFileNames[self.selectedMissionIndex]
        self.loadMissionData(missionFileName)
        
        //create a polyline from position in each frame to be used as path
        var points = [AGSPoint]()
        
        for frame in self.frames {
            points.append(frame.position)
        }
        
        let polylineBuilder = AGSPolylineBuilder(points: points)
        self.routeGraphic.geometry = polylineBuilder.toGeometry()
        
        //set current frame to zero
        self.currentFrameIndex = 0
        
        //animate to first frame
        self.animate()
    }
    
    @IBAction func playAction(sender:UIBarButtonItem) {
        
        if isAnimating {
            self.animationTimer?.invalidate()
        }
        else {
            self.startAnimation()
        }
        
        self.isAnimating = !self.isAnimating
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        self.dismiss(animated: false, completion: nil)
        
        if segue.identifier == "CameraSettingsSegue" {
            
            //camera settings view controller
            let controller = segue.destination as! CameraSettingsViewController
            controller.orbitGeoElementCameraController = self.orbitGeoElementCameraController
            
            //pop over settings
            controller.presentationController?.delegate = self
            controller.popoverPresentationController?.passthroughViews = [self.sceneView]
            
            //preferred content size
            if self.traitCollection.horizontalSizeClass == .regular && self.traitCollection.verticalSizeClass == .regular {
                controller.preferredContentSize = CGSize(width: 300, height: 380)
            }
            else {
                controller.preferredContentSize = CGSize(width: 300, height: 250)
            }
        }
        else if segue.identifier == "PlaneStatsSegue" {
            
            //plane stats view controller
            self.planeStatsViewController = segue.destination as? PlaneStatsViewController
            
            //pop over settings
            self.planeStatsViewController?.presentationController?.delegate = self
            self.planeStatsViewController?.preferredContentSize = CGSize(width: 220, height: 200)
        }
        else if segue.identifier == "MissionSettingsSegue" {
            
            //mission settings view controller
            self.missionSettingsViewController = segue.destination as? MissionSettingsViewController
            
            //initial values
            self.missionSettingsViewController?.missionFileNames = self.missionFileNames
            self.missionSettingsViewController?.selectedMissionIndex = self.selectedMissionIndex
            self.missionSettingsViewController?.animationSpeed = self.animationSpeed
            self.missionSettingsViewController?.progress = Float(self.currentFrameIndex) / Float(self.frames.count)
            
            //pop over settings
            self.missionSettingsViewController?.presentationController?.delegate = self
            self.missionSettingsViewController?.preferredContentSize = CGSize(width: 300, height: 200)
            self.missionSettingsViewController?.delegate = self
        }
    }
    
    //MARK: - MissionSettingsVCDelegate
    
    func missionSettingsViewController(_ missionSettingsViewController: MissionSettingsViewController, didSelectMissionAtIndex index: Int) {
        
        self.selectedMissionIndex = index
        
        self.changeMissionAction()
    }
    
    func missionSettingsViewController(_ missionSettingsViewController: MissionSettingsViewController, didChangeSpeed speed: Int) {
        
        self.animationSpeed = speed
        
        if self.isAnimating {
            self.animationTimer.invalidate()
            
            self.startAnimation()
        }
    }
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        //for popover or non modal presentation
        return UIModalPresentationStyle.none
    }
}

class Frame {
    var position: AGSPoint!
    var heading: Double = 0.0
    var pitch: Double = 0.0
    var roll: Double = 0.0
}

private extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}
