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

//class ViewHiddenInfrastructureARViewController: UIViewController {
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Add the source code button item to the right of navigation bar.
//        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["ViewHiddenInfrastructureARViewController"]
//    }
//}

class ViewHiddenInfrastructureARPipePlacer: UIViewController {
    // UI controls
    private let mapView = AGSMapView()
    private let toolbar = UIToolbar()
    private let addBBI = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(startSketch(_:)))
    private let undoBBI = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(undo(_:)))
    private let redoBBI = UIBarButtonItem(barButtonSystemItem: .redo, target: self, action: #selector(redo(_:)))
    private let viewBBI = UIBarButtonItem(barButtonSystemItem: .camera,
                                          target: self,
                                          action: #selector(startExperience(_:)))
    private let elevationSlider = UISlider()
    private let helpLabel = UILabel()

    // Map and data
    private let map = AGSMap(basemap: .imageryWithLabelsVector())
    let elevationSource = AGSArcGISTiledElevationSource(url:
        URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
    let elevationSurface = AGSSurface()
    private let sketchEditor = AGSSketchEditor()
    private let locationDataSource = AGSCLLocationDataSource()
    private let pipesOverlay = AGSGraphicsOverlay()
    private var hasInitialLocation = false

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.translatesAutoresizingMaskIntoConstraints = false

        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.text = "Sketch pipes to visualize in AR"
        helpLabel.textAlignment = .center
        helpLabel.textColor = .white
        helpLabel.backgroundColor = UIColor(white: 0, alpha: 0.6)

        let elevationButton = UIBarButtonItem(customView: elevationSlider)
        elevationSlider.minimumValue = -10
        elevationSlider.maximumValue = 10

        viewBBI.isEnabled = false
        addBBI.isEnabled = false
        undoBBI.isEnabled = false
        redoBBI.isEnabled = false

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.items = [
            addBBI,
            undoBBI,
            redoBBI,
            elevationButton,
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

        configureMap()
    }

    private func configureMap() {
        mapView.map = map
        mapView.sketchEditor = sketchEditor

        // Configure the graphics overlay for showing the pipes
        mapView.graphicsOverlays.add(pipesOverlay)
        pipesOverlay.renderer = AGSSimpleRenderer(symbol: AGSSimpleLineSymbol(style: .solid,
                                                                                 color: .red, width: 2))
        // Configure location display
        locationDataSource.locationChangeHandlerDelegate = self
        locationDataSource.start { [weak self] (err: Error?) in
            guard let self = self else { return }
            if let error = err {
                self.presentAlert(error: error)
            }
        }

        // Stop the location updates upon user interaction
        mapView.touchDelegate = self

        // Configure the elevation surface used to place drawn graphics relative to the ground
        elevationSurface.elevationSources.append(elevationSource)
        elevationSource.load {[weak self](err: Error?) in
            guard let self = self else { return }
            if let error = err {
                self.presentAlert(error: error)
            } else {
                self.addBBI.isEnabled = true
            }
        }
    }

    @objc func startExperience(_ sender: UIBarButtonItem) {
        if let graphicsArray = pipesOverlay.graphics as? [AGSGraphic] {
            let viewerVC = HiddenInfrastructureARViewer(pipeGraphics: graphicsArray)
            navigationController?.pushViewController(viewerVC, animated: true)
        } else {
            presentAlert(message: "Couldn't show pipe graphics...")
        }
    }
}

// MARK: - sketching infrastructure graphics

extension ViewHiddenInfrastructureARPipePlacer {
    @objc func respondToGeomChanged() {
        //Enable/disable UI elements appropriately
        undoBBI.isEnabled = self.sketchEditor.undoManager.canUndo
        redoBBI.isEnabled = self.sketchEditor.undoManager.canRedo
    }

    @objc func undo(_ sender: UIBarButtonItem) {
        if sketchEditor.undoManager.canUndo { //extra check, just to be sure
            sketchEditor.undoManager.undo()
        }
        respondToGeomChanged()
    }

    @objc func redo(_ sender: UIBarButtonItem) {
        if sketchEditor.undoManager.canRedo { //extra check, just to be sure
            sketchEditor.undoManager.redo()
        }
        respondToGeomChanged()
    }

    @objc func startSketch(_ sender: UIBarButtonItem) {
        let elevationOffset = (Double)(elevationSlider.value)
        if let geometry = sketchEditor.geometry as? AGSPolyline {
            guard let firstpoint = geometry.parts.array().first?.startPoint else { return }

            elevationSurface.elevation(for: firstpoint) { [weak self] (elevation: Double, err: Error?) in
                guard let self = self else { return }

                if let error = err {
                    let graphic = AGSGraphic(geometry: geometry, symbol: nil, attributes: nil)
                    self.pipesOverlay.graphics.add(graphic)
                    self.viewBBI.isEnabled = true
                    self.helpLabel.text = "Pipe added without elevation"
                    print("Error adding elevation to pipe: \(error.localizedDescription)")
                } else {
                    let elevatedGeometry = AGSGeometryEngine.geometry(bySettingZ: elevation + elevationOffset,
                                                                      in: geometry)
                    let graphic = AGSGraphic(geometry: elevatedGeometry, symbol: nil, attributes: nil)
                    self.pipesOverlay.graphics.add(graphic)
                    self.viewBBI.isEnabled = true

                    if elevationOffset < 0 {
                        self.helpLabel.text = String(format: "Pipe added %.2fm below surface", elevationOffset * -1)
                    } else if elevationOffset == 0 {
                        self.helpLabel.text = "Pipe added at ground level"
                    } else {
                        self.helpLabel.text = String(format: "Pipe added %.2fm above surface", elevationOffset)
                    }
                }
                self.respondToGeomChanged()
            }
        }
        self.sketchEditor.start(with: nil, creationMode: .polyline)
    }
}

// MARK: - respond to location changes
extension ViewHiddenInfrastructureARPipePlacer: AGSLocationChangeHandlerDelegate {
    public func locationDataSource(_ locationDataSource: AGSLocationDataSource,
                                   locationDidChange location: AGSLocation) {
        let newViewpoint = AGSViewpoint(center: location.position!, scale: 1000)
        self.mapView.setViewpoint(newViewpoint)

        if location.horizontalAccuracy < 20 {
            locationDataSource.locationChangeHandlerDelegate = nil
            locationDataSource.stop()
        }
    }
}

extension ViewHiddenInfrastructureARPipePlacer: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTouchDownAtScreenPoint screenPoint: CGPoint,
                 mapPoint: AGSPoint, completion: @escaping (Bool) -> Void) {
        // Stop updating the location
        locationDataSource.locationChangeHandlerDelegate = nil
        locationDataSource.stop()
        completion(false)
    }
}

class HiddenInfrastructureARViewer: UIViewController, ARSCNViewDelegate {
    // UI controls
    public let arView = ArcGISARView()
    private let toolbar = UIToolbar()
    private let helpLabel = UILabel()
    private let arKitStatusLabel = UILabel()
    private var calibrationVC: ARRealScaleRoamingCalibrator
    private let realScaleModePicker = UISegmentedControl(items: ["Roaming", "Local"])
    private let calibrationBBI = UIBarButtonItem(title: "Calibrate",
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(showCalibrationPopup(_:)))
    // Scene and graphics
    private let scene = AGSScene(basemapType: .imageryWithLabels)
    private var pipeGraphics: [AGSGraphic]
    private let infrastructureOverlay = AGSGraphicsOverlay()

    private var isCalibrating: Bool {
        didSet {
            if isCalibrating {
                arView.sceneView.scene?.baseSurface?.opacity = 0.5
                calibrationBBI.title = "Finish calibrating"
            } else {
                arView.sceneView.scene?.baseSurface?.opacity = 0
                calibrationBBI.title = "Calibrate"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        toolbar.translatesAutoresizingMaskIntoConstraints = false
        helpLabel.translatesAutoresizingMaskIntoConstraints = false
        arKitStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        arView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(arView)
        view.addSubview(helpLabel)
        view.addSubview(arKitStatusLabel)
        view.addSubview(toolbar)

        toolbar.items = [
            calibrationBBI,
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil),
            UIBarButtonItem(customView: realScaleModePicker)
        ]

        realScaleModePicker.selectedSegmentIndex = 0
        realScaleModePicker.addTarget(self, action: #selector(setRealScaleMode(_:)), for: UIControl.Event.valueChanged)

        helpLabel.textAlignment = .center
        helpLabel.textColor = .white
        helpLabel.backgroundColor = UIColor(white: 0, alpha: 0.6)
        helpLabel.text = "Tap calibrate to start"

        arKitStatusLabel.textAlignment = .center
        arKitStatusLabel.textColor = .black
        arKitStatusLabel.backgroundColor = UIColor(white: 1, alpha: 0.6)
        arKitStatusLabel.text = "Setting up ARKit"

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
            helpLabel.heightAnchor.constraint(equalToConstant: 40),
            arKitStatusLabel.topAnchor.constraint(equalTo: helpLabel.bottomAnchor),
            arKitStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            arKitStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            arKitStatusLabel.heightAnchor.constraint(equalToConstant: 40)
            ])

        configureSceneForAR()
    }

    private func configureSceneForAR() {
        // Display the scene and set scene view properties
        arView.sceneView.scene = scene
        arView.sceneView.spaceEffect = .transparent
        arView.sceneView.atmosphereEffect = .none
        arView.arSCNViewDelegate = self

        // Create an elevation source and add it to the scene
        let elevationSource = AGSArcGISTiledElevationSource(url:
            URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        scene.baseSurface?.elevationSources.append(elevationSource)
        scene.baseSurface?.navigationConstraint = .none

        // Configure and add the overlay for showing drawn infrastructure
        let strokeSymbolLayer = AGSSolidStrokeSymbolLayer()
        strokeSymbolLayer.capStyle = .round
        strokeSymbolLayer.lineStyle3D = .tube
        strokeSymbolLayer.width = 0.3
        strokeSymbolLayer.color = .red
        let polylineSymbol = AGSMultilayerPolylineSymbol(symbolLayers: [strokeSymbolLayer])
        let polylineRenderer = AGSSimpleRenderer(symbol: polylineSymbol)
        infrastructureOverlay.renderer = polylineRenderer
        infrastructureOverlay.sceneProperties?.surfacePlacement = .absolute
        arView.sceneView.graphicsOverlays.add(infrastructureOverlay)

        let infrastructureGraphics = pipeGraphics.map { AGSGraphic (geometry: $0.geometry, symbol: nil)}
        infrastructureOverlay.graphics.addObjects(from: infrastructureGraphics)

        // Configure location data source
        arView.locationDataSource = AGSCLLocationDataSource()
    }

    public init(pipeGraphics: [AGSGraphic]) {
        self.pipeGraphics = pipeGraphics
        calibrationVC = ARRealScaleRoamingCalibrator(sceneView:
            arView.sceneView, cameraController: arView.cameraController)
        isCalibrating = false
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.startTracking(useLocationDataSourceOnce: false, completion: nil)
        showCalibrationPopup(calibrationBBI)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.stopTracking()
    }
}

// MARK: - Calibration view management

extension HiddenInfrastructureARViewer {
    @objc func setRealScaleMode(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // Roaming - continuous update
            arView.stopTracking()
            arView.startTracking(useLocationDataSourceOnce: false, completion: nil)
            helpLabel.text = "Using CoreLocation + ARKit"
        } else {
            // Local - only update once, then manually calibrate
            arView.stopTracking()
            arView.startTracking(useLocationDataSourceOnce: true, completion: nil)
            helpLabel.text = "Using ARKit only"
        }
    }

    @objc func showCalibrationPopup(_ sender: UIBarButtonItem) {
        if isCalibrating {
            isCalibrating = false
            calibrationVC.dismiss(animated: true, completion: nil)
        } else {
            isCalibrating = true
            let controller = self.calibrationVC
            controller.preferredContentSize = CGSize(width: 250, height: 100)
            showPopup(controller, sourceButton: sender)
        }
    }

    private func showPopup(_ controller: UIViewController, sourceButton: UIBarButtonItem) {
        if let presentationController = AlwaysPresentAsPopover.configurePresentation(forController: controller) {
            presentationController.barButtonItem = sourceButton
            presentationController.permittedArrowDirections = [.down, .up]
            self.present(controller, animated: true)
        } else {
            presentAlert(message: "Error showing calibration view")
        }
    }
}

extension HiddenInfrastructureARViewer: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

class AlwaysPresentAsPopover: NSObject, UIPopoverPresentationControllerDelegate {
    // Copyright 2018, Ralf Ebert
    // License   https://opensource.org/licenses/MIT
    // License   https://creativecommons.org/publicdomain/zero/1.0/
    // Source    https://www.ralfebert.de/ios-examples/uikit/choicepopover/
    // `sharedInstance` because the delegate property is weak - the delegate instance needs to be retained.
    private static let sharedInstance = AlwaysPresentAsPopover()

    private override init() {
        super.init()
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    static func configurePresentation(forController controller: UIViewController) -> UIPopoverPresentationController? {
        controller.modalPresentationStyle = .popover
        if let presentationController = controller.presentationController as? UIPopoverPresentationController {
            presentationController.delegate = AlwaysPresentAsPopover.sharedInstance
            return presentationController
        }
        return nil
    }
}

class ARRealScaleRoamingCalibrator: UIViewController {
    // The scene view displaying the scene.
    private let sceneView: AGSSceneView

    /// The camera controller used to adjust user interactions.
    private let cameraController: AGSTransformationMatrixCameraController

    /// The UISlider used to adjust elevation.
    private let elevationSlider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.minimumValue = -50.0
        slider.maximumValue = 50.0
        return slider
    }()

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

        // Add the elevation label and slider.
        let elevationLabel = UILabel(frame: .zero)
        elevationLabel.text = "Elevation:"
        elevationLabel.textColor = view.tintColor
        view.addSubview(elevationLabel)
        elevationLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            elevationLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            elevationLabel.bottomAnchor.constraint(equalTo: headingLabel.topAnchor, constant: -24)
            ])

        view.addSubview(elevationSlider)
        elevationSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            elevationSlider.leadingAnchor.constraint(equalTo: elevationLabel.trailingAnchor, constant: 16),
            elevationSlider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            elevationSlider.centerYAnchor.constraint(equalTo: elevationLabel.centerYAnchor)
            ])

        // Setup actions for the two sliders. The sliders operate as "joysticks",
        // where moving the slider thumb will start a timer
        // which roates or elevates the current camera when the timer fires.  The elevation and heading delta
        // values increase the further you move away from center.  Moving and holding the thumb a little bit from center
        // will roate/elevate just a little bit, but get progressively more the further from center the thumb is moved.
        headingSlider.addTarget(self, action: #selector(headingChanged(_:)), for: .valueChanged)
        headingSlider.addTarget(self, action: #selector(touchUpHeading(_:)), for: [.touchUpInside, .touchUpOutside])
        elevationSlider.addTarget(self, action: #selector(elevationChanged(_:)), for: .valueChanged)
        elevationSlider.addTarget(self, action: #selector(touchUpElevation(_:)), for: [.touchUpInside, .touchUpOutside])
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // The timers for the "joystick" behavior.
    private var elevationTimer: Timer?
    private var headingTimer: Timer?

    /// Handle an elevation slider value-changed event.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc func elevationChanged(_ sender: UISlider) {
        if elevationTimer == nil {
            // Create a timer which elevates the camera when fired.
            elevationTimer = Timer(timeInterval: 0.25, repeats: true, block: { [weak self] (_) in
                let delta = self?.joystickElevation() ?? 0.0
                //                print("elevate delta = \(delta)")
                self?.elevate(delta)
            })

            // Add the timer to the main run loop.
            guard let timer = elevationTimer else { return }
            RunLoop.main.add(timer, forMode: .default)
        }
    }

    /// Handle an heading slider value-changed event.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc func headingChanged(_ sender: UISlider) {
        if headingTimer == nil {
            // Create a timer which rotates the camera when fired.
            headingTimer = Timer(timeInterval: 0.1, repeats: true, block: { [weak self] (_) in
                let delta = self?.joystickHeading() ?? 0.0
                //                print("rotate delta = \(delta)")
                self?.rotate(delta)
            })
            // Add the timer to the main run loop.
            guard let timer = headingTimer else { return }
            RunLoop.main.add(timer, forMode: .default)
        }
    }

    /// Handle an elevation slider touchUp event.  This will stop the timer.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc func touchUpElevation(_ sender: UISlider) {
        elevationTimer?.invalidate()
        elevationTimer = nil
        sender.value = 0.0
    }

    /// Handle a heading slider touchUp event.  This will stop the timer.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc func touchUpHeading(_ sender: UISlider) {
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

    /// Calculates the elevation delta amount based on the elevation slider value.
    ///
    /// - Returns: The elevation delta.
    private func joystickElevation() -> Double {
        let deltaElevation = Double(elevationSlider.value)
        return pow(deltaElevation, 2) / 50.0 * (deltaElevation < 0 ? -1.0 : 1.0)
    }

    /// Calculates the heading delta amount based on the heading slider value.
    ///
    /// - Returns: The heading delta.
    private func joystickHeading() -> Double {
        let deltaHeading = Double(headingSlider.value)
        return pow(deltaHeading, 2) / 25.0 * (deltaHeading < 0 ? -1.0 : 1.0)
    }
}

// MARK: - tracking status display
extension HiddenInfrastructureARViewer {
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // Don't show anything in roaming mode; constant location tracking reset means
        // ARKit will always be initializing
        if realScaleModePicker.selectedSegmentIndex == 0 {
            arKitStatusLabel.isHidden = true
            return
        }
        switch camera.trackingState {
        case .normal:
            arKitStatusLabel.isHidden = true
        case .notAvailable:
            arKitStatusLabel.text = "ARKit location not available"
            arKitStatusLabel.isHidden = false
        case .limited(let reason):
            arKitStatusLabel.isHidden = false
            switch reason {
            case .excessiveMotion:
                arKitStatusLabel.text = "Try moving your phone more slowly"
                arKitStatusLabel.isHidden = false
            case .initializing:
                arKitStatusLabel.text = "Keep moving your phone"
                arKitStatusLabel.isHidden = false
            case .insufficientFeatures:
                arKitStatusLabel.text = "Try turning on more lights and moving around"
                arKitStatusLabel.isHidden = false
            case .relocalizing:
                // this won't happen as this sample doesn't use relocalization
                break
            @unknown default:
                fatalError("Unknown AR tracking state limited reason")
            }
        }
    }
}
