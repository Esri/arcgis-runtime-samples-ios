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
    private var calibrationVC: ViewHiddenInfrastructureARCalibrationViewController
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
        calibrationVC = ViewHiddenInfrastructureARCalibrationViewController(arcgisARView: arView)
        isCalibrating = false
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        arView.startTracking(.continuous)
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
            arView.startTracking(.continuous)
//            arView.startTracking(useLocationDataSourceOnce: false, completion: nil)
            helpLabel.text = "Using CoreLocation + ARKit"
        } else {
            // Local - only update once, then manually calibrate
            arView.stopTracking()
            arView.startTracking(.initial)
//            arView.startTracking(useLocationDataSourceOnce: true, completion: nil)
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
