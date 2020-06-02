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
import AVFoundation

// MARK: - Navigate the route
class NavigateARNavigatorViewController: UIViewController {
    /// The label to display route-planning status.
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var calibrateButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var startButtonItem: UIBarButtonItem!
    // UI controls
    @IBOutlet weak var arView: ArcGISARView!
    
    lazy var calibrationVC = NavigateARCalibrationViewController(arcgisARView: arView)
    
    // Routing and navigation
    
    var routeResult: AGSRouteResult!
    var routeTask: AGSRouteTask!
    var routeParameters: AGSRouteParameters!
    
    var routeTracker: AGSRouteTracker?
    
    var currentRoute: AGSRoute?
    let trackingLocationDataSource = AGSCLLocationDataSource()
    let speechSynthesizer = AVSpeechSynthesizer()
    // Scene & graphics
    let routeOverlay = AGSGraphicsOverlay()
    let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
    let elevationSurface = AGSSurface()
    var isCalibrating = false {
        didSet {
            if self.isCalibrating {
                self.arView.sceneView.scene?.baseSurface?.opacity = 0.5
            } else {
                self.arView.sceneView.scene?.baseSurface?.opacity = 0
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setStatus(message: "Adjust calibration before starting")
        isCalibrating = false
        self.configureSceneForAR()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.startTracking(.continuous, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.stopTracking()
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    @IBAction func startTurnByTurn(_ sender: UIBarButtonItem) {
        routeTracker = AGSRouteTracker(routeResult: routeResult, routeIndex: 0)
        if routeTask.routeTaskInfo().supportsRerouting {
            routeTracker?.enableRerouting(
                with: self.routeTask,
                routeParameters: self.routeParameters,
                strategy: .toNextStop,
                visitFirstStopOnStart: true
            ) { [weak self] (error: Error?) in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    self.routeTracker?.delegate = self
                }
            }
        } else {
            self.routeTracker?.delegate = self
        }
    }
    
    private func configureSceneForAR() {
        // Create scene with imagery basemap
        let scene = AGSScene(basemapType: .imageryWithLabels)
        
        // Create an elevation source and add it to the scene
        scene.baseSurface = elevationSurface
        elevationSurface.elevationSources.append(elevationSource)
        scene.baseSurface?.navigationConstraint = .none
        
        // Display the scene
        routeOverlay.sceneProperties?.surfacePlacement = .absolute
        arView.sceneView.scene = scene
        arView.locationDataSource = AGSCLLocationDataSource()
        arView.sceneView.graphicsOverlays.add(routeOverlay)
                
        let strokeSymbolLayer = AGSSolidStrokeSymbolLayer(
            width: 1.0,
            color: .yellow,
            geometricEffects: [],
            lineStyle3D: .tube
        )
        let polylineSymbol = AGSMultilayerPolylineSymbol(symbolLayers: [strokeSymbolLayer])
        let polylineRenderer = AGSSimpleRenderer(symbol: polylineSymbol)
        routeOverlay.renderer = polylineRenderer
        
        trackingLocationDataSource.locationChangeHandlerDelegate = self
        trackingLocationDataSource.start(completion: nil)
        
        // Turn the space and atmosphere effects on for an immersive experience
        arView.sceneView.spaceEffect = .transparent
        arView.sceneView.atmosphereEffect = .none
        
        setRoute(route: routeResult.routes.first!)
    }
    
    func setRoute(route: AGSRoute) {
        // set up the elevation source
        // Create an elevation source and add it to the scene
        // for point in line
        let originalPolyline = route.routeGeometry!
        
        self.currentRoute = route
        
        self.elevationSource.load { [weak self] (_: Error?) in
            self?.polylineWithZ(polyine: originalPolyline) { [weak self] (newPolyline: AGSPolyline) in
                guard let self = self else { return }
                
                self.routeOverlay.graphics.removeAllObjects()
                let routeGraphic = AGSGraphic(geometry: newPolyline, symbol: nil, attributes: nil)
                self.routeOverlay.graphics.add(routeGraphic)
            }
        }
    }
    
    private func polylineWithZ(polyine polyineInput: AGSPolyline, withCompletion completion: @escaping (_ result: AGSPolyline) -> Void) {
        // Densify the geometry so the elevation can be adjusted every 0.3 meters
        if let densifiedPolyline = AGSGeometryEngine.densifyGeometry(polyineInput, maxSegmentLength: 0.3) as? AGSPolyline {
            // Create a polyline builder to build the new geometry
            let polylinebuilder = AGSPolylineBuilder(spatialReference: densifiedPolyline.spatialReference)
            let allPoints = densifiedPolyline.parts.array().flatMap { $0.points.array() }
            var elevatedPoints = 0
            
            for point in allPoints {
                self.elevationSurface.elevation(for: point) { (elevation: Double, err: Error?) in
                    if let error = err {
                        polylinebuilder.add(point)
                        print("Error adjusting for elevation: \(error.localizedDescription)")
                    } else {
                        // Put the new point 3 meters above the ground elevation
                        if let newpoint = AGSGeometryEngine.geometry(bySettingZ: elevation + 3,
                                                                     in: point) as? AGSPoint {
                            polylinebuilder.add(newpoint)
                        }
                    }
                    elevatedPoints += 1
                    
                    if elevatedPoints == allPoints.count {
                        completion(polylinebuilder.toGeometry())
                    }
                }
            }
        } else {
            presentAlert(message: "Failed to add elevation to route line…")
            completion(polyineInput)
        }
    }
}

// MARK: - Route navigation status changes

extension NavigateARNavigatorViewController: AGSRouteTrackerDelegate {
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        setSpeakDirection(with: voiceGuidance.text)
    }
    
    func routeTrackerRerouteDidStart(_ routeTracker: AGSRouteTracker) {
        setStatus(message: "Rerouting...")
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        // Display new guidance
        let newGuidance = routeTracker.generateVoiceGuidance()
        statusLabel.text = newGuidance?.text
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, rerouteDidCompleteWith trackingStatus: AGSTrackingStatus?, error: Error?) {
        // Update the graphic if needed
        if let latestRoute = routeTracker.trackingStatus?.routeResult.routes[0] {
            if latestRoute != self.currentRoute {
                setRoute(route: latestRoute)
            }
        }
    }
    
    func setSpeakDirection(with text: String?) {
        speechSynthesizer.stopSpeaking(at: AVSpeechBoundary.word)
        if let text = text {
            let speechUtterance = AVSpeechUtterance(string: text)
            speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate * 0.5
            speechSynthesizer.speak(speechUtterance)
        }
    }
}

// MARK: - Handle location updates - push to route tracker if actively navigating

extension NavigateARNavigatorViewController: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        startButtonItem.isEnabled = true
        routeTracker?.trackLocation(location)
    }
}

// MARK: - Calibration view management

extension NavigateARNavigatorViewController {
    @IBAction func showCalibrationPopup(_ sender: UIBarButtonItem) {
        if self.isCalibrating {
            isCalibrating = false
            calibrationVC.dismiss(animated: true, completion: nil)
        } else {
            isCalibrating = true
            let controller = self.calibrationVC
            controller.preferredContentSize = CGSize(width: 250, height: 50)
            showPopup(controller, sourceButton: sender)
        }
    }
    
    private func showPopup(_ controller: UIViewController, sourceButton: UIBarButtonItem) {
        if let presentationController = NavigateARAlwaysPresentAsPopover.configurePresentation(forController: controller) {
            presentationController.delegate = self
            presentationController.barButtonItem = sourceButton
            presentationController.permittedArrowDirections = [.down, .up]
            self.present(controller, animated: true)
        }
    }
}

extension NavigateARNavigatorViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        isCalibrating = false
    }
}

class NavigateARAlwaysPresentAsPopover: NSObject, UIPopoverPresentationControllerDelegate {
    // Copyright 2018, Ralf Ebert
    // License   https://opensource.org/licenses/MIT
    // License   https://creativecommons.org/publicdomain/zero/1.0/
    // Source    https://www.ralfebert.de/ios-examples/uikit/choicepopover/
    // `sharedInstance` because the delegate property is weak - the delegate instance needs to be retained.
    private static let sharedInstance = NavigateARAlwaysPresentAsPopover()
    
    override private init() {
        super.init()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    static func configurePresentation(forController controller: UIViewController) -> UIPopoverPresentationController? {
        controller.modalPresentationStyle = .popover
        if let presentationController = controller.presentationController as? UIPopoverPresentationController {
            presentationController.delegate = NavigateARAlwaysPresentAsPopover.sharedInstance
            return presentationController
        }
        return nil
    }
}

extension NavigateARNavigatorViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - Calibration view
