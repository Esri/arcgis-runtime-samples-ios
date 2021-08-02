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

class OrbitCameraSettingsViewController: UITableViewController {
    // MARK: Storyboard views
    
    @IBOutlet private var headingLabel: UILabel!
    @IBOutlet private var pitchLabel: UILabel!
    @IBOutlet private var headingSlider: UISlider!
    @IBOutlet private var pitchSlider: UISlider!
    @IBOutlet private var distanceInteractionSwitch: UISwitch!
    
    // MARK: Properties
    
    weak var orbitGeoElementCameraController: AGSOrbitGeoElementCameraController?
    weak var planeGraphic: AGSGraphic?
    
    private var headingObservation: NSKeyValueObservation?
    
    private let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.unitStyle = .short
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    // MARK: Actions
    
    func updateUIForHeading() {
        guard let cameraController = orbitGeoElementCameraController else { return }
        headingSlider.value = Float(cameraController.cameraHeadingOffset)
        let measurement = Measurement(value: cameraController.cameraHeadingOffset, unit: UnitAngle.degrees)
        headingLabel.text = measurementFormatter.string(from: measurement)
    }
    
    func updateUIForPitch() {
        guard let graphic = planeGraphic,
              let pitch = graphic.attributes["PITCH"] as? NSNumber else { return }
        pitchSlider.value = pitch.floatValue
        let measurement = Measurement(value: pitch.doubleValue, unit: UnitAngle.degrees)
        pitchLabel.text = measurementFormatter.string(from: measurement)
    }
    
    @IBAction func headingValueChanged(_ sender: UISlider) {
        orbitGeoElementCameraController?.cameraHeadingOffset = Double(sender.value)
        updateUIForHeading()
    }
    
    @IBAction func pitchValueChanged(_ sender: UISlider) {
        planeGraphic?.attributes["PITCH"] = NSNumber(value: sender.value)
        updateUIForPitch()
    }
    
    @IBAction func distanceInteractionSwitchValueChanged(_ sender: UISwitch) {
        orbitGeoElementCameraController?.isCameraDistanceInteractive = sender.isOn
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Apply initial values to controls.
        updateUIForHeading()
        updateUIForPitch()
        guard let cameraController = orbitGeoElementCameraController else { return }
        distanceInteractionSwitch.isOn = cameraController.isCameraDistanceInteractive
        // Add an observer to sync the UI for camera heading.
        headingObservation = cameraController.observe(\.cameraHeadingOffset) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateUIForHeading()
            }
        }
    }
}
