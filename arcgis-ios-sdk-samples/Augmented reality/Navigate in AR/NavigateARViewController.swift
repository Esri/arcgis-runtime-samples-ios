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

//import ARKit
//import UIKit
//import ArcGIS
//
//class NavigateARViewController: UIViewController {
//
//}

import UIKit
import ARKit
import ArcGISToolkit
import ArcGIS
import AVFoundation

// MARK: - Plan the route
class NavigateARRoutePlanner: UIViewController {
    // UI controls
    private let mapView = AGSMapView()
    private let toolbar = UIToolbar()
    private let viewBBI = UIBarButtonItem(
        barButtonSystemItem: .camera,
        target: self,
        action: #selector(startExperience(_:))
    )
    private let helpLabel = UILabel()
    
    // Routing
    private var generatedRoute: AGSRouteResult? {
        willSet(newValue) {
            if newValue != nil {
                viewBBI.isEnabled = true
            }
        }
    }
    private let routeTask = AGSRouteTask(url:
        URL(string: "https://route.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World")!)
    private var routeParameters: AGSRouteParameters!
    private var hasInitialLocation = false
    private var startPoint: AGSPoint? {
        didSet {
            let startImage = UIImage(named: "StopA")
            let marker = AGSPictureMarkerSymbol(image: startImage!)
            let startStopGraphic = AGSGraphic(geometry: self.startPoint, symbol: marker, attributes: nil)
            stopGraphicsOverlay.graphics.add(startStopGraphic)
        }
    }
    
    private var endPoint: AGSPoint? {
        didSet {
            let startImage = UIImage(named: "StopB")
            let marker = AGSPictureMarkerSymbol(image: startImage!)
            let endStopGraphic = AGSGraphic(geometry: self.endPoint, symbol: marker, attributes: nil)
            stopGraphicsOverlay.graphics.add(endStopGraphic)
        }
    }
    
    // Map content and graphics
    private let map = AGSMap(basemap: .imageryWithLabelsVector())
    private let elevationSurface = AGSSurface()
    private let elevationSource = AGSArcGISTiledElevationSource(url:
        URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
    private let locationDataSource = AGSCLLocationDataSource()
    private let graphicsOverlay = AGSGraphicsOverlay()
    private let stopGraphicsOverlay = AGSGraphicsOverlay()
    private let routeGraphicsOverlay = AGSGraphicsOverlay()
    
    // State
    private let initialText = "Tap to set a start point"
    private var isElevationReady = false {
        didSet {
            if isReadyToRoute {
                // Wait for the user to tap the map to plan a route
                mapView.touchDelegate = self
                helpLabel.text = initialText
            }
        }
    }
    private var isRouteTaskReady = false {
        didSet {
            if isReadyToRoute {
                // Wait for the user to tap the map to plan a route
                mapView.touchDelegate = self
                helpLabel.text = initialText
            }
        }
    }
    private var isReadyToRoute: Bool {
        return isElevationReady && isRouteTaskReady
    }
    
    // MARK: - View initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.text = "Preparing services…"
        helpLabel.textAlignment = .center
        helpLabel.textColor = .white
        helpLabel.backgroundColor = UIColor(white: 0, alpha: 0.6)
        
        viewBBI.isEnabled = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            viewBBI
        ]
        
        view.backgroundColor = .white
        view.addSubview(mapView)
        view.addSubview(toolbar)
        view.addSubview(helpLabel)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            helpLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            helpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            helpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            helpLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Configure the authentication manager to show the OAuth dialog
        AGSAuthenticationManager.shared().delegate = self
        
        // Configure the map
        configureMap()
    }
    
    private func configureMap() {
        // Configure the map and location display
        mapView.map = map
        
        routeGraphicsOverlay.renderer = AGSSimpleRenderer(symbol:
            AGSSimpleLineSymbol(style: .solid, color: .yellow, width: 5))
        mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, stopGraphicsOverlay])
        
        locationDataSource.start { [weak self] (err: Error?) in
            guard let self = self else { return }
            if let err = err {
                self.presentAlert(error: err)
            }
        }
        mapView.locationDisplay.dataSource = locationDataSource
        mapView.locationDisplay.autoPanMode = .recenter
        
        // Configure elevation - used to position the route in the scene when navigating
        elevationSurface.elevationSources.append(self.elevationSource)
        elevationSource.load { [weak self](err: Error?) in
            guard let self = self else { return }
            if let error = err {
                self.presentAlert(error: error)
            } else {
                self.isElevationReady = true
            }
        }
        
        // Configure routing
        routeTask.load { [weak self] (err: Error?) in
            guard let self = self else { return }
            if let error = err {
                self.presentAlert(error: error)
            } else {
                self.getDefaultParameters { [weak self] (params: AGSRouteParameters?) in
                    guard let self = self else { return }
                    
                    if let generatedRouteParams = params {
                        self.routeParameters = generatedRouteParams
                        self.isRouteTaskReady = true
                    } else {
                        self.isRouteTaskReady = false
                        self.presentAlert(message: "Failed to configure routing")
                    }
                }
            }
        }
    }
    
    @objc
    func startExperience(_ sender: UIBarButtonItem) {
        if let routeToStart = generatedRoute {
            let navigatorVC = NavigateARRouteNavigator(
                route: routeToStart,
                routeTask: routeTask,
                routeParameters: routeParameters
            )
            navigationController?.pushViewController(navigatorVC, animated: true)
        } else {
            self.presentAlert(message: "Wait for the route to display")
        }
    }
}

// MARK: - Set route start and end on touch
extension NavigateARRoutePlanner: AGSGeoViewTouchDelegate {
    public func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if startPoint == nil {
            startPoint = mapPoint
            helpLabel.text = "Tap to place destination"
        } else if endPoint == nil {
            endPoint = mapPoint
            helpLabel.text = "You're ready to start navigating!"
            route()
        }
    }
}

// MARK: - Show OAuth dialog for route service
extension NavigateARRoutePlanner: AGSAuthenticationManagerDelegate {
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager,
                               wantsToShow viewController: UIViewController) {
        viewController.modalPresentationStyle = .formSheet
        self.present(viewController, animated: true)
    }
    
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager,
                               wantsToDismiss viewController: UIViewController) {
        dismiss(animated: true)
    }
}

// MARK: - Configure routing and generate routes
extension NavigateARRoutePlanner {
    func getDefaultParameters(with completion: @escaping (_ parameters: AGSRouteParameters?) -> Void) {
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
                completion(nil)
            } else if let routeParameters = params {
                // set the travel mode to the first one matching 'walking'
                routeParameters.travelMode = self.routeTask.routeTaskInfo().travelModes.first { $0.name.contains("Walking") }
                
                // Each of these parameters is needed for navigation to work
                routeParameters.returnStops = true
                routeParameters.returnDirections = true
                routeParameters.returnRoutes = true
                
                completion(routeParameters)
            } else {
                completion(nil)
            }
        }
    }
    
    @IBAction func route() {
        // route only if default parameters are fetched successfully
        if routeParameters == nil {
            print("Default route parameters not loaded")
            presentAlert(message: "Default route params not loaded")
            return
        }
        
        // clear previous routes and stops
        routeGraphicsOverlay.graphics.removeAllObjects()
        routeParameters.clearStops()
        
        // set the stops
        let stop1 = AGSStop(point: self.startPoint!)
        stop1.name = "Origin"
        let stop2 = AGSStop(point: self.endPoint!)
        stop2.name = "Destination"
        routeParameters.setStops([stop1, stop2])
        
        self.routeTask.solveRoute(with: self.routeParameters) { [weak self] (routeResult: AGSRouteResult?, error: Error?) in
            guard let self = self else { return }
            
            if let error = error {
                print(error)
            } else if let route = routeResult {
                self.generatedRoute = route
                let routeGraphic = AGSGraphic(geometry: route.routes[0].routeGeometry, symbol: nil, attributes: nil)
                self.routeGraphicsOverlay.graphics.add(routeGraphic)
            }
        }
    }
}

// MARK: - Navigate the route
class NavigateARRouteNavigator: UIViewController {
    // UI controls
    let arView = ArcGISARView()
    let cameraController = AGSTransformationMatrixCameraController()
    private var calibrationVC: NavigateARCalibrationViewController
    private let toolbar = UIToolbar()
    private let helpLabel = UILabel()
    private let calibrationBBI = UIBarButtonItem(
        title: "Calibrate",
        style: .plain,
        target: self,
        action: #selector(showCalibrationPopup(_:))
    )
    private let routeGuidanceBBI = UIBarButtonItem(
        title: "Start",
        style: .plain,
        target: self,
        action: #selector(startTurnByTurn(_:))
    )
    // Routing and navigation
    private var route: AGSRouteResult
    private var routeTracker: AGSRouteTracker?
    private var routeTask: AGSRouteTask
    private var routeParameters: AGSRouteParameters
    private var currentRoute: AGSRoute?
    private let trackingLocationDataSource = AGSCLLocationDataSource()
    private let synthesizer = AVSpeechSynthesizer()
    // Scene & graphics
    private let routeOverlay = AGSGraphicsOverlay()
    private let elevationSource = AGSArcGISTiledElevationSource(url:
        URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
    private let elevationSurface = AGSSurface()
    private var isCalibrating = false {
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
        
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        arView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(arView)
        view.addSubview(helpLabel)
        view.addSubview(toolbar)
        
        routeGuidanceBBI.isEnabled = false
        
        toolbar.items = [
            calibrationBBI,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            routeGuidanceBBI
        ]
        
        helpLabel.textAlignment = .center
        helpLabel.textColor = .white
        helpLabel.backgroundColor = UIColor(white: 0, alpha: 0.6)
        helpLabel.text = "Adjust calibration before starting"
        
        NSLayoutConstraint.activate([
            arView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arView.topAnchor.constraint(equalTo: view.topAnchor),
            arView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            helpLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            helpLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            helpLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            helpLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        self.configureSceneForAR()
    }
    
    init(route: AGSRouteResult, routeTask: AGSRouteTask, routeParameters: AGSRouteParameters) {
        self.route = route
        self.routeTask = routeTask
        self.routeParameters = routeParameters
        calibrationVC = NavigateARCalibrationViewController(
            sceneView: arView.sceneView,
            cameraController: cameraController
        )
        isCalibrating = false
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.startTracking(.continuous, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.stopTracking()
    }
    
    @objc
    func startTurnByTurn(_ sender: UIBarButtonItem) {
        routeTracker = AGSRouteTracker(routeResult: route, routeIndex: 0)
        if routeTask.routeTaskInfo().supportsRerouting {
            routeTracker?.enableRerouting(
                with: self.routeTask,
                routeParameters: self.routeParameters,
                strategy: .toNextStop,
                visitFirstStopOnStart: true
            ) { [weak self] (err: Error?) in
                guard let self = self else { return }
                if let error = err {
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
        arView.sceneView.scene = scene
        arView.locationDataSource = AGSCLLocationDataSource()
        arView.sceneView.graphicsOverlays.add(self.routeOverlay)
        routeOverlay.sceneProperties?.surfacePlacement = .absolute
        let strokeSymbolLayer = AGSSolidStrokeSymbolLayer()
        strokeSymbolLayer.capStyle = .round
        strokeSymbolLayer.lineStyle3D = .tube
        strokeSymbolLayer.width = 1
        strokeSymbolLayer.color = .yellow
        let polylineSymbol = AGSMultilayerPolylineSymbol(symbolLayers: [strokeSymbolLayer])
        let polylineRenderer = AGSSimpleRenderer(symbol: polylineSymbol)
        routeOverlay.renderer = polylineRenderer
        
        trackingLocationDataSource.locationChangeHandlerDelegate = self
        trackingLocationDataSource.start(completion: nil)
        
        // Turn the space and atmosphere effects on for an immersive experience
        arView.sceneView.spaceEffect = .transparent
        arView.sceneView.atmosphereEffect = .none
        
        setRoute(route: route.routes.first!)
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
    
    private func polylineWithZ(polyine polyineInput: AGSPolyline,
                               withCompletion completion: @escaping (_ result: AGSPolyline) -> Void) {
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
extension NavigateARRouteNavigator: AGSRouteTrackerDelegate {
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        // Update the label with the new text
        helpLabel.text = voiceGuidance.text
        
        // Speak the text out loud
        let utterance = AVSpeechUtterance(string: voiceGuidance.text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
    
    func routeTrackerRerouteDidStart(_ routeTracker: AGSRouteTracker) {
        helpLabel.text = "Rerouting…"
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        // Display new guidance
        let newGuidance = routeTracker.generateVoiceGuidance()
        helpLabel.text = newGuidance?.text
    }
    
    func routeTracker(
        _ routeTracker: AGSRouteTracker,
        rerouteDidCompleteWith trackingStatus: AGSTrackingStatus?,
        error: Error?
    ) {
        // Update the graphic if needed
        if let latestRoute = routeTracker.trackingStatus?.routeResult.routes[0] {
            if latestRoute != self.currentRoute {
                setRoute(route: latestRoute)
            }
        }
    }
}

// MARK: - Handle location updates - push to route tracker if actively navigating
extension NavigateARRouteNavigator: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        routeGuidanceBBI.isEnabled = true
        if let tracker = self.routeTracker {
            tracker.trackLocation(location, completion: nil)
        }
    }
}

// MARK: - Calibration view management
extension NavigateARRouteNavigator {
    @objc
    func showCalibrationPopup(_ sender: UIBarButtonItem) {
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

extension NavigateARRouteNavigator: UIPopoverPresentationControllerDelegate {
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

extension NavigateARRouteNavigator: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - Calibration view
class NavigateARCalibrationViewController: UIViewController {
    // The scene view displaying the scene.
    private let sceneView: AGSSceneView
    
    /// The camera controller used to adjust user interactions.
    private let cameraController: AGSTransformationMatrixCameraController
    
    /// The UISlider used to adjust heading.
    private let headingSlider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.minimumValue = -10.0
        slider.maximumValue = 10.0
        return slider
    }()
    
    /// The last elevation slider value.
    var lastElevationValue: Float = 0
    
    // The last heading slider value.
    var lastHeadingValue: Float = 0
    
    /// Initialized a new calibration view with the given scene view and camera controller.
    ///
    /// - Parameters:
    ///   - sceneView: The scene view displaying the scene.
    ///   - cameraController: The camera controller used to adjust user interactions.
    init(sceneView: AGSSceneView, cameraController: AGSTransformationMatrixCameraController) {
        self.cameraController = cameraController
        self.sceneView = sceneView
        super.init(nibName: nil, bundle: nil)
        
        // Add the heading label and slider.
        let headingLabel = UILabel(frame: .zero)
        headingLabel.text = "Heading:"
        headingLabel.textColor = view.tintColor
        view.addSubview(headingLabel)
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headingLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            headingLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        view.addSubview(headingSlider)
        headingSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headingSlider.leadingAnchor.constraint(equalTo: headingLabel.trailingAnchor, constant: 16),
            headingSlider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            headingSlider.centerYAnchor.constraint(equalTo: headingLabel.centerYAnchor)
        ])
        
        // Setup actions for the two sliders. The sliders operate as "joysticks",
        // where moving the slider thumb will start a timer
        // which roates or elevates the current camera when the timer fires.  The elevation and heading delta
        // values increase the further you move away from center.  Moving and holding the thumb a little bit from center
        // will roate/elevate just a little bit, but get progressively more the further from center the thumb is moved.
        headingSlider.addTarget(self, action: #selector(headingChanged(_:)), for: .valueChanged)
        headingSlider.addTarget(self, action: #selector(touchUpHeading(_:)), for: [.touchUpInside, .touchUpOutside])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // The timers for the "joystick" behavior.
    private var elevationTimer: Timer?
    private var headingTimer: Timer?
    
    /// Handle an heading slider value-changed event.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc
    func headingChanged(_ sender: UISlider) {
        if headingTimer == nil {
            // Create a timer which rotates the camera when fired.
            headingTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] (_) in
                let delta = self?.joystickHeading() ?? 0.0
                //                print("rotate delta = \(delta)")
                self?.rotate(delta)
            }
            
            // Add the timer to the main run loop.
            guard let timer = headingTimer else { return }
            RunLoop.main.add(timer, forMode: .default)
        }
    }
    
    /// Handle an elevation slider touchUp event.  This will stop the timer.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc
    func touchUpElevation(_ sender: UISlider) {
        elevationTimer?.invalidate()
        elevationTimer = nil
        sender.value = 0.0
    }
    
    /// Handle a heading slider touchUp event.  This will stop the timer.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc
    func touchUpHeading(_ sender: UISlider) {
        headingTimer?.invalidate()
        headingTimer = nil
        sender.value = 0.0
    }
    
    /// Rotates the camera by `deltaHeading`.
    ///
    /// - Parameter deltaHeading: The amount to rotate the camera.
    private func rotate(_ deltaHeading: Double) {
        let camera = cameraController.originCamera
        let newHeading = camera.heading + deltaHeading
        cameraController.originCamera = camera.rotate(toHeading: newHeading, pitch: camera.pitch, roll: camera.roll)
    }
    
    /// Change the cameras altitude by `deltaAltitude`.
    ///
    /// - Parameter deltaAltitude: The amount to elevate the camera.
    private func elevate(_ deltaAltitude: Double) {
        let camera = cameraController.originCamera
        cameraController.originCamera = camera.elevate(withDeltaAltitude: deltaAltitude)
    }
    
    /// Calculates the heading delta amount based on the heading slider value.
    ///
    /// - Returns: The heading delta.
    private func joystickHeading() -> Double {
        let deltaHeading = Double(headingSlider.value)
        return pow(deltaHeading, 2) / 25.0 * (deltaHeading < 0 ? -1.0 : 1.0)
    }
}
