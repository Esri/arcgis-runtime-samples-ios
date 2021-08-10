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
    
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var pitchLabel: UILabel!
    @IBOutlet var headingSlider: UISlider!
    @IBOutlet var pitchSlider: UISlider!
    @IBOutlet var distanceInteractionSwitch: UISwitch!
    
    // MARK: Properties
    
    let orbitGeoElementCameraController: AGSOrbitGeoElementCameraController
    let planeGraphic: AGSGraphic
    var headingObservation: NSKeyValueObservation?
    var isCameraDistanceInteractiveObservation: NSKeyValueObservation?
    var tableViewContentSizeObservation: NSKeyValueObservation?
    
    let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.unitStyle = .short
        return formatter
    }()
    
    // MARK: Initializers
    
    init?(
        coder: NSCoder,
        cameraController: AGSOrbitGeoElementCameraController,
        graphic: AGSGraphic
    ) {
        orbitGeoElementCameraController = cameraController
        planeGraphic = graphic
        super.init(coder: coder)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Actions
    
    func updateUIForHeading() {
        headingSlider.value = Float(orbitGeoElementCameraController.cameraHeadingOffset)
        let measurement = Measurement(value: orbitGeoElementCameraController.cameraHeadingOffset, unit: UnitAngle.degrees)
        headingLabel.text = measurementFormatter.string(from: measurement)
    }
    
    func updateUIForPitch() {
        let pitch = planeGraphic.attributes["PITCH"] as! Float
        pitchSlider.value = pitch
        let measurement = Measurement(value: Double(pitch), unit: UnitAngle.degrees)
        pitchLabel.text = measurementFormatter.string(from: measurement)
    }
    
    @IBAction func headingValueChanged(_ sender: UISlider) {
        orbitGeoElementCameraController.cameraHeadingOffset = Double(sender.value)
        updateUIForHeading()
    }
    
    @IBAction func pitchValueChanged(_ sender: UISlider) {
        planeGraphic.attributes["PITCH"] = sender.value
        updateUIForPitch()
    }
    
    @IBAction func distanceInteractionSwitchValueChanged(_ sender: UISwitch) {
        orbitGeoElementCameraController.isCameraDistanceInteractive = sender.isOn
    }
    
    // MARK: UIViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableViewContentSizeObservation = tableView.observe(\.contentSize) { [unowned self] tableView, _ in
            self.preferredContentSize = CGSize(width: self.preferredContentSize.width, height: tableView.contentSize.height)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableViewContentSizeObservation = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Apply initial values to controls.
        updateUIForHeading()
        updateUIForPitch()
        distanceInteractionSwitch.isOn = orbitGeoElementCameraController.isCameraDistanceInteractive
        // Add an observer to sync the UI for camera heading.
        headingObservation = orbitGeoElementCameraController.observe(\.cameraHeadingOffset) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateUIForHeading()
            }
        }
        isCameraDistanceInteractiveObservation = orbitGeoElementCameraController.observe(\.isCameraDistanceInteractive) { [weak self] cameraController, _ in
            DispatchQueue.main.async {
                self?.distanceInteractionSwitch.isOn = cameraController.isCameraDistanceInteractive
            }
        }
    }
}
