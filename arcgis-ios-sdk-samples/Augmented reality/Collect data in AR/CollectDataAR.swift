// Copyright 2019 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import UIKit
import ARKit
import ArcGISToolkit
import ArcGIS

class CollectDataAR: UIViewController {
    // UI controls and state
    @IBOutlet var addBBI: UIBarButtonItem!

    @IBOutlet var arView: ArcGISARView!
    @IBOutlet var arKitStatusLabel: UILabel!
    @IBOutlet var calibrationBBI: UIBarButtonItem!
    @IBOutlet var helpLabel: UILabel!
    @IBOutlet var realScaleModePicker: UISegmentedControl!
    @IBOutlet var toolbar: UIToolbar!

    private var calibrationVC: CollectDataARCalibrationViewController?
    private var isCalibrating = false {
        didSet {
            if isCalibrating {
                arView.sceneView.scene?.baseSurface?.opacity = 0.5
                if realScaleModePicker.selectedSegmentIndex == 1 {
                    helpLabel.text = "Pan the map to finish calibrating"
                    calibrationBBI.title = "Finish calibrating"
                }
            } else {
                arView.sceneView.scene?.baseSurface?.opacity = 0
                calibrationBBI.title = "Calibrate"
                
                // Dismiss popover
                if let calibrationVC = calibrationVC {
                    calibrationVC.dismiss(animated: true)
                }
            }
        }
    }

    // Feature service
    private let featureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/AR_Tree_Survey/FeatureServer/0")!)
    private var featureLayer: AGSFeatureLayer?
    private var lastEditedFeature: AGSArcGISFeature?
    
    // Graphics and symbology
    private var featureGraphic: AGSGraphic?
    private let graphicsOverlay = AGSGraphicsOverlay()
    private let tappedPointSymbol = AGSSimpleMarkerSceneSymbol(style: .diamond,
                                                               color: .orange,
                                                               height: 0.5,
                                                               width: 0.5,
                                                               depth: 0.5,
                                                               anchorPosition: .center)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Constrain toolbar to the scene view's attribution label
        toolbar.bottomAnchor.constraint(equalTo: arView.sceneView.attributionTopAnchor).isActive = true

        // Create and prep the calibration view controller
        calibrationVC = CollectDataARCalibrationViewController(arView)
        calibrationVC?.preferredContentSize = CGSize(width: 250, height: 100)
        calibrationVC?.setIsUsingContinuousPositioning(true)

        // Set delegates and configure arView
        arView.sceneView.touchDelegate = self
        arView.arSCNView.debugOptions = .showFeaturePoints
        arView.arSCNViewDelegate = self
        arView.locationDataSource = AGSCLLocationDataSource()
        configureSceneForAR()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["CollectDataAR"]
    }

    private func configureSceneForAR() {
        // Create scene with imagery basemap
        let scene = AGSScene(basemapType: .imageryWithLabels)

        // Create an elevation source and add it to the scene
        let elevationSource = AGSArcGISTiledElevationSource(url:
            URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        scene.baseSurface?.elevationSources.append(elevationSource)

        // Allow camera to go beneath the surface
        scene.baseSurface?.navigationConstraint = .none

        // Create a feature layer and add it to the scene
        featureLayer = AGSFeatureLayer(featureTable: featureTable)
        scene.operationalLayers.add(featureLayer!)
        featureLayer?.sceneProperties?.surfacePlacement = .absolute

        // Display the scene
        arView.sceneView.scene = scene

        // Create and add the graphics overlay for showing WIP new features
        arView.sceneView.graphicsOverlays.add(graphicsOverlay)
        graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        graphicsOverlay.renderer = AGSSimpleRenderer(symbol: tappedPointSymbol)
    }

    // MARK: - View lifecycle management
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Start AR tracking; if we're local, only use the data source to get the initial position
        arView.startTracking(realScaleModePicker.selectedSegmentIndex == 1 ? .initial : .continuous)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        arView.stopTracking()
    }

    @IBAction func showCalibrationPopup(_ sender: UIBarButtonItem) {
        if let controller = calibrationVC {
            if realScaleModePicker.selectedSegmentIndex == 0 { // Roaming
                isCalibrating = true
            } else { // Local
                isCalibrating.toggle()
            }

            if isCalibrating {
                showPopup(controller, sourceButton: sender)
            } else {
                helpLabel.text = "Tap to record a feature"
            }
        }
    }

    @IBAction func addFeature(_ sender: UIBarButtonItem) {
        if graphicsOverlay.graphics.count < 1 {
            presentAlert(message: "You need to tap an object before you can save.")
            return
        }

        if let coreVideoBuffer = arView.arSCNView.session.currentFrame?.capturedImage {
            // Get image as useful object
            // NOTE: everything here assumes photo is taken in portrait layout (not landscape)
            var coreImage = CIImage(cvImageBuffer: coreVideoBuffer)
            let transform = coreImage.orientationTransform(for: .right)
            coreImage = coreImage.transformed(by: transform)
            let ciContext = CIContext()
            let imageHeight = CVPixelBufferGetHeight(coreVideoBuffer)
            let imageWidth = CVPixelBufferGetWidth(coreVideoBuffer)
            let imageRef = ciContext.createCGImage(coreImage,
                                                   from: CGRect(x: 0, y: 0, width: imageHeight, height: imageWidth))
            let rotatedImage = UIImage(cgImage: imageRef!)

            getTreeHealthValue { [weak self] (healthValue: Int16) in
                self?.createFeatureWith(rotatedImage, healthState: healthValue)
            }
        } else {
            presentAlert(message: "Didn't get image for tap")
        }
    }

    @IBAction func setRealScaleMode(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            // Roaming - continuous update
            arView.stopTracking()
            arView.startTracking(.continuous)
            helpLabel.text = "Using CoreLocation + ARKit"
            calibrationVC?.setIsUsingContinuousPositioning(true)
        } else {
            // Local - only update once, then manually calibrate
            arView.stopTracking()
            arView.startTracking(.initial)
            helpLabel.text = "Using ARKit only"
            calibrationVC?.setIsUsingContinuousPositioning(false)
        }
        
        // Turn off calibration when switching modes
        isCalibrating = false
    }
}

// MARK: - Add and identify features on tap
extension CollectDataAR: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Remove any existing graphics
        graphicsOverlay.graphics.removeAllObjects()

        // Try to get the real-world position of that tapped AR plane
        if let planeLocation = arView.arScreenToLocation(screenPoint: screenPoint) {
            // If a plane was found, use that
            let graphic = AGSGraphic(geometry: planeLocation, symbol: nil)
            graphicsOverlay.graphics.add(graphic)
            addBBI.isEnabled = true
            helpLabel.text = "Placed relative to ARKit plane"
        } else {
            presentAlert(message: "Didn't find anything. Try again.")

            // No point found - disable adding the feature
            addBBI.isEnabled = false
        }
    }
}

// MARK: - Feature management
extension CollectDataAR {
    private func getTreeHealthValue(with completion: @escaping (_ healthValue: Int16) -> Void) {
        // Display an alert allowing users to select tree health
        let healthStatusMenu = UIAlertController(title: "Take picture and add tree",
                                                 message: "How healthy is this tree?",
                                                 preferredStyle: .actionSheet)

        let deadAction = UIAlertAction(title: "Dead", style: .default) { (_) in
            completion(0)
        }

        let distressedAction = UIAlertAction(title: "Distressed", style: .default) { (_) in
            completion(5)
        }

        let healthyAction = UIAlertAction(title: "Healthy", style: .default) { (_) in
            completion(10)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        healthStatusMenu.addAction(healthyAction)
        healthStatusMenu.addAction(distressedAction)
        healthStatusMenu.addAction(deadAction)
        healthStatusMenu.addAction(cancelAction)

        healthStatusMenu.popoverPresentationController?.barButtonItem = addBBI

        self.present(healthStatusMenu, animated: true, completion: nil)
    }

    func applyEdits() {
        featureTable.applyEdits { [weak self] (featureEditResults: [AGSFeatureEditResult]?, error: Error?) in
            if let error = error {
                self?.presentAlert(message: "Error while applying edits :: \(error.localizedDescription)")
            } else {
                if let featureEditResults = featureEditResults,
                    featureEditResults.first?.completedWithErrors == false {
                    self?.presentAlert(message: "Edits applied successfully")
                }
            }
        }
    }

    private func createFeatureWith(_ capturedImage: UIImage, healthState healthValue: Int16) {
        guard let featureGraphic = graphicsOverlay.graphics.firstObject as? AGSGraphic,
            let featurePoint = featureGraphic.geometry as? AGSPoint else { return }
        
        // Update the help label
        helpLabel.text = "Adding feature"
        
        // Create attributes for the new feature
        let featureAttributes = ["Health": healthValue, "Height": 3.2, "Diameter": 1.2] as [String: Any]
        
        if let newFeature =
            featureTable.createFeature(attributes: featureAttributes, geometry: featurePoint) as? AGSArcGISFeature {
            lastEditedFeature = newFeature
            //add the feature to the feature table
            featureTable.add(newFeature) { [weak self] (error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    self.presentAlert(message: "Error while adding feature: \(error.localizedDescription)")
                } else {
                    self.featureTable.applyEdits { [weak self] (_: [AGSFeatureEditResult]?, err: Error?) in
                        guard let self = self else { return }
                        
                        if let error = err {
                            self.presentAlert(error: error)
                            return
                        }
                        
                        newFeature.refresh()
                        if let data = capturedImage.jpegData(compressionQuality: 1) {
                            newFeature.addAttachment(withName: "ARCapture.jpg", contentType: "jpg", data: data) { (_: AGSAttachment?, err: Error?) in
                                if err != nil {
                                    self.presentAlert(error: err!)
                                }
                                self.featureTable.applyEdits(completion: nil)
                            }
                        }
                    }
                }
            }
            
            // enable interaction with map view
            helpLabel.text = "Tap to create a feature"
            graphicsOverlay.graphics.removeAllObjects()
            addBBI.isEnabled = false
        } else {
            presentAlert(message: "Error creating feature")
        }
    }
}

// MARK: - Calibration view management
extension CollectDataAR {
    private func showPopup(_ controller: UIViewController, sourceButton: UIBarButtonItem) {
        controller.modalPresentationStyle = .popover
        if let presentationController = controller.presentationController as? UIPopoverPresentationController {
            presentationController.delegate = self
            presentationController.barButtonItem = sourceButton
            presentationController.permittedArrowDirections = [.down, .up]
            present(controller, animated: true)
        } else {
            presentAlert(message: "Error showing calibration view")
        }
    }
}

extension CollectDataAR: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        // Detect when the popover closes and stop calibrating, but only if in roaming mode
        // In local mode, the user should have an opportunity to adjust the basemap
        if realScaleModePicker.selectedSegmentIndex == 0 {
            isCalibrating = false
            helpLabel.text = "Tap to record a feature"
        }
    }
}

extension CollectDataAR: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // show presented controller as popovers even on small displays
        return .none
    }
}

// MARK: - Calibration view controller
class CollectDataARCalibrationViewController: UIViewController {
    /// The camera controller used to adjust user interactions.
    private let arcgisARView: ArcGISARView
    
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
    ///   - arcgisARView: The ArcGISARView we are calibrating..
    init(_ arcgisARView: ArcGISARView) {
        self.arcgisARView = arcgisARView
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
    @objc
    func elevationChanged(_ sender: UISlider) {
        if elevationTimer == nil {
            // Create a timer which elevates the camera when fired.
            elevationTimer = Timer(timeInterval: 0.25, repeats: true) { [weak self] (_) in
                let delta = self?.joystickElevation() ?? 0.0
                //                print("elevate delta = \(delta)")
                self?.elevate(delta)
            }
            
            // Add the timer to the main run loop.
            guard let timer = elevationTimer else { return }
            RunLoop.main.add(timer, forMode: .default)
        }
    }
    
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
        let camera = arcgisARView.originCamera
        let newHeading = camera.heading + deltaHeading
        arcgisARView.originCamera = camera.rotate(toHeading: newHeading, pitch: camera.pitch, roll: camera.roll)
    }
    
    /// Change the cameras altitude by `deltaAltitude`.
    ///
    /// - Parameter deltaAltitude: The amount to elevate the camera.
    private func elevate(_ deltaAltitude: Double) {
        let camera = arcgisARView.originCamera
        arcgisARView.originCamera = camera.elevate(withDeltaAltitude: deltaAltitude)
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
    
    /// Set whether continuous positioning is in use
    /// Showing a heading slider is only appropriate when using local positioning
    func setIsUsingContinuousPositioning(_ isContinuous: Bool) {
        if isContinuous {
            elevationSlider.isEnabled = false
            elevationSlider.removeTarget(self, action: #selector(elevationChanged(_:)), for: .valueChanged)
            elevationSlider.removeTarget(self, action: #selector(touchUpElevation(_:)), for: [.touchUpInside, .touchUpOutside])
        } else {
            elevationSlider.isEnabled = true
            
            // Set up events for the heading slider
            elevationSlider.addTarget(self, action: #selector(elevationChanged(_:)), for: .valueChanged)
            elevationSlider.addTarget(self, action: #selector(touchUpElevation(_:)), for: [.touchUpInside, .touchUpOutside])
        }
    }
}

// MARK: - tracking status display
extension CollectDataAR: ARSCNViewDelegate {
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
                break
            }
        }
    }
}
