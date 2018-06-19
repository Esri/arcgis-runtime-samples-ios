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

class CameraSettingsViewController: UIViewController {

    weak var orbitGeoElementCameraController:AGSOrbitGeoElementCameraController?
    
    @IBOutlet var headingOffsetSlider:UISlider!
    @IBOutlet var pitchOffsetSlider:UISlider!
    @IBOutlet var distanceSlider:UISlider!
    @IBOutlet var distanceLabel:UILabel!
    @IBOutlet var headingOffsetLabel:UILabel!
    @IBOutlet var pitchOffsetLabel:UILabel!
    @IBOutlet var speedSlider:UISlider!
    @IBOutlet var speedLabel:UILabel!
    @IBOutlet var autoHeadingEnabledSwitch:UISwitch!
    @IBOutlet var autoPitchEnabledSwitch:UISwitch!
    @IBOutlet var autoRollEnabledSwitch:UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //apply initial values to controls
        self.setInitialValues()
        
        //add observers to update the sliders
        self.orbitGeoElementCameraController?.addObserver(self, forKeyPath: "cameraDistance", options: .new, context: nil)
        self.orbitGeoElementCameraController?.addObserver(self, forKeyPath: "cameraHeadingOffset", options: .new, context: nil)
        self.orbitGeoElementCameraController?.addObserver(self, forKeyPath: "cameraPitchOffset", options: .new, context: nil)
    }
    
    private func setInitialValues() {
        
        guard let cameraController = self.orbitGeoElementCameraController else {
            return
        }
        
        self.distanceSlider.value = Float(cameraController.cameraDistance)
        self.distanceLabel.text = "\(Int(cameraController.cameraDistance))"
        
        self.headingOffsetSlider.value = Float(cameraController.cameraHeadingOffset)
        self.headingOffsetLabel.text = "\(Int(cameraController.cameraHeadingOffset))º"
        
        self.pitchOffsetSlider.value = Float(cameraController.cameraPitchOffset)
        self.pitchOffsetLabel.text = "\(Int(cameraController.cameraPitchOffset))º"
        
        self.autoHeadingEnabledSwitch.isOn = cameraController.isAutoHeadingEnabled
        self.autoPitchEnabledSwitch.isOn = cameraController.isAutoPitchEnabled
        self.autoRollEnabledSwitch.isOn = cameraController.isAutoRollEnabled
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        DispatchQueue.main.async { [weak self] in
            
            guard let weakSelf = self, let cameraController = self?.orbitGeoElementCameraController else {
                return
            }
            
            if keyPath == "cameraDistance" {
                weakSelf.distanceSlider.value = Float(cameraController.cameraDistance)
                
                //update label
                weakSelf.distanceLabel.text = "\(Int(weakSelf.distanceSlider.value))"
            }
            else if keyPath == "cameraHeadingOffset" {
                weakSelf.headingOffsetSlider.value = Float(cameraController.cameraHeadingOffset)
                
                //update label
                weakSelf.headingOffsetLabel.text = "\(Int(weakSelf.headingOffsetSlider.value))º"
            }
            else if keyPath == "cameraPitchOffset" {
                weakSelf.pitchOffsetSlider.value = Float(cameraController.cameraPitchOffset)
                
                //update label
                weakSelf.pitchOffsetLabel.text = "\(Int(weakSelf.pitchOffsetSlider.value))º"
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction private func distanceValueChanged(sender:UISlider) {
        
        //update property
        self.orbitGeoElementCameraController?.cameraDistance = Double(sender.value)
        
        //update label
        self.distanceLabel.text = "\(Int(sender.value))"
    }
    
    @IBAction private func headingOffsetValueChanged(sender:UISlider) {
        
        //update property
        self.orbitGeoElementCameraController?.cameraHeadingOffset = Double(sender.value)
        
        //update label
        self.headingOffsetLabel.text = "\(Int(sender.value))"
    }
    
    @IBAction private func pitchOffsetValueChanged(sender:UISlider) {
        
        //update property
        self.orbitGeoElementCameraController?.cameraPitchOffset = Double(sender.value)
        
        //update label
        self.pitchOffsetLabel.text = "\(Int(sender.value))"
    }
    
    @IBAction private func autoHeadingEnabledValueChanged(sender:UISwitch) {
        
        //update property
        self.orbitGeoElementCameraController?.isAutoHeadingEnabled = sender.isOn
    }
    
    @IBAction private func autoPitchEnabledValueChanged(sender:UISwitch) {
        
        //update property
        self.orbitGeoElementCameraController?.isAutoPitchEnabled = sender.isOn
    }
    
    @IBAction private func autoRollEnabledValueChanged(sender:UISwitch) {
        
        //update property
        self.orbitGeoElementCameraController?.isAutoRollEnabled = sender.isOn
    }
    
    @IBAction private func closeAction() {
        
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        
        //remove observers
        self.orbitGeoElementCameraController?.removeObserver(self, forKeyPath: "cameraDistance")
        self.orbitGeoElementCameraController?.removeObserver(self, forKeyPath: "cameraHeadingOffset")
        self.orbitGeoElementCameraController?.removeObserver(self, forKeyPath: "cameraPitchOffset")
    }
}
