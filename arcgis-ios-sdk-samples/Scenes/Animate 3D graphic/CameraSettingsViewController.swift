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

class CameraSettingsViewController: UITableViewController {

    weak var orbitGeoElementCameraController: AGSOrbitGeoElementCameraController?
    
    @IBOutlet var headingOffsetSlider: UISlider!
    @IBOutlet var pitchOffsetSlider: UISlider!
    @IBOutlet var distanceSlider: UISlider!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var headingOffsetLabel: UILabel!
    @IBOutlet var pitchOffsetLabel: UILabel!
    @IBOutlet var autoHeadingEnabledSwitch: UISwitch!
    @IBOutlet var autoPitchEnabledSwitch: UISwitch!
    @IBOutlet var autoRollEnabledSwitch: UISwitch!
    
    private var distanceObservation: NSKeyValueObservation?
    private var headingObservation: NSKeyValueObservation?
    private var pitchObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let cameraController = orbitGeoElementCameraController else {
            return
        }
        
        // apply initial values to controls
        updateUIForDistance()
        updateUIForHeadingOffset()
        updateUIForPitchOffset()
        autoHeadingEnabledSwitch.isOn = cameraController.isAutoHeadingEnabled
        autoPitchEnabledSwitch.isOn = cameraController.isAutoPitchEnabled
        autoRollEnabledSwitch.isOn = cameraController.isAutoRollEnabled
        
        // add observers to the values we want to show in the UI
        distanceObservation = cameraController.observe(\.cameraDistance) {[weak self] (controller, change) in
            self?.updateUIForDistance()
        }
        headingObservation = cameraController.observe(\.cameraHeadingOffset) {[weak self] (controller, change) in
            self?.updateUIForHeadingOffset()
        }
        pitchObservation = cameraController.observe(\.cameraPitchOffset) {[weak self] (controller, change) in
            self?.updateUIForPitchOffset()
        }
    }
    
    private let numberFormatter = NumberFormatter()
    
    private func updateUIForDistance() {
        guard let cameraController = orbitGeoElementCameraController else {
            return
        }
        distanceSlider.value = Float(cameraController.cameraDistance)
        distanceLabel.text = numberFormatter.string(from: cameraController.cameraDistance as NSNumber)!
    }
    private func updateUIForHeadingOffset() {
        guard let cameraController = orbitGeoElementCameraController else {
            return
        }
        headingOffsetSlider.value = Float(cameraController.cameraHeadingOffset)
        headingOffsetLabel.text = numberFormatter.string(from: cameraController.cameraHeadingOffset as NSNumber)!
    }
    private func updateUIForPitchOffset() {
        guard let cameraController = orbitGeoElementCameraController else {
            return
        }
        pitchOffsetSlider.value = Float(cameraController.cameraPitchOffset)
        pitchOffsetLabel.text = numberFormatter.string(from: cameraController.cameraPitchOffset as NSNumber)!
    }
    
    //MARK: - Actions
    
    @IBAction private func distanceValueChanged(sender:UISlider) {
        
        //update property
        orbitGeoElementCameraController?.cameraDistance = Double(sender.value)
        
        //update label
        updateUIForDistance()
    }
    
    @IBAction private func headingOffsetValueChanged(sender:UISlider) {
        
        //update property
        orbitGeoElementCameraController?.cameraHeadingOffset = Double(sender.value)
        
        //update label
        updateUIForHeadingOffset()
    }
    
    @IBAction private func pitchOffsetValueChanged(sender:UISlider) {
        
        //update property
        orbitGeoElementCameraController?.cameraPitchOffset = Double(sender.value)
        
        //update label
        updateUIForPitchOffset()
    }
    
    @IBAction private func autoHeadingEnabledValueChanged(sender:UISwitch) {
        
        //update property
        orbitGeoElementCameraController?.isAutoHeadingEnabled = sender.isOn
    }
    
    @IBAction private func autoPitchEnabledValueChanged(sender:UISwitch) {
        
        //update property
        orbitGeoElementCameraController?.isAutoPitchEnabled = sender.isOn
    }
    
    @IBAction private func autoRollEnabledValueChanged(sender:UISwitch) {
        
        //update property
        orbitGeoElementCameraController?.isAutoRollEnabled = sender.isOn
    }
    
}
