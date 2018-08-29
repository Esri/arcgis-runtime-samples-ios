// Copyright 2018 Esri.
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

protocol ViewshedSettingsVCDelegate:class {
    
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateAnalysisOverlayVisibility analysisOverlayVisibility:Bool)
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateFrustumOutlineVisibility frustumOutlineVisibility:Bool)
   
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateObstructedAreaColor obstructedAreaColor:UIColor)
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateVisibleAreaColor visibleAreaColor:UIColor)
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateFrustumOutlineColor frustumOutlineColor:UIColor)
    
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateHeading heading:Double)
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdatePitch pitch:Double)
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateHorizontalAngle horizontalAngle:Double)
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateVerticalAngle verticalAngle:Double)
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateMinDistance minDistance:Double)
    func viewshedSettingsVC(_ viewshedSettingsVC:ViewshedSettingsVC, didUpdateMaxDistance maxDistance:Double)
    
}

class ViewshedSettingsVC: UIViewController, HorizontalColorPickerDelegate {
    
    @IBOutlet weak var headingSlider: UISlider!
    @IBOutlet weak var headingLabel: UILabel!
    
    @IBOutlet weak var pitchSlider: UISlider!
    @IBOutlet weak var pitchLabel: UILabel!
    
    @IBOutlet weak var horizontalAngleSlider: UISlider!
    @IBOutlet weak var horizontalAngleLabel: UILabel!
    
    @IBOutlet weak var verticalAngleSlider: UISlider!
    @IBOutlet weak var verticalAngleLabel: UILabel!
    
    @IBOutlet weak var minDistanceSlider: UISlider!
    @IBOutlet weak var minDistanceLabel: UILabel!
    
    @IBOutlet weak var maxDistanceSlider: UISlider!
    @IBOutlet weak var maxDistanceLabel: UILabel!
    
    @IBOutlet weak var visibleAreaColorPicker: HorizontalColorPicker!
    @IBOutlet weak var obstructedAreaColorPicker: HorizontalColorPicker!
    @IBOutlet weak var frustumOutlineColorPicker: HorizontalColorPicker!
    
    @IBOutlet weak var frustumOutlineVisibilitySwitch: UISwitch!
    @IBOutlet weak var analysisOverlayVisibilitySwitch: UISwitch!
    
    weak var delegate:ViewshedSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set picker delegates
        visibleAreaColorPicker.delegate = self
        obstructedAreaColorPicker.delegate = self
        frustumOutlineColorPicker.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func closeAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func analysisOverlayVisibilityAction(_ sender: Any) {
        delegate?.viewshedSettingsVC(self, didUpdateAnalysisOverlayVisibility: analysisOverlayVisibilitySwitch.isOn)
    }
    
    @IBAction func frustumOutlineVisibilityAction(_ sender: Any) {
        delegate?.viewshedSettingsVC(self, didUpdateFrustumOutlineVisibility: frustumOutlineVisibilitySwitch.isOn)
    }
    
    @IBAction private func sliderValueChanged(sender:UISlider) {
        if sender == headingSlider {
            headingLabel.text = "\(Int(sender.value))"
            delegate?.viewshedSettingsVC(self, didUpdateHeading: Double(sender.value))
        }
        else if sender == pitchSlider {
            pitchLabel.text = "\(Int(sender.value))"
            delegate?.viewshedSettingsVC(self, didUpdatePitch: Double(sender.value))
        }
        else if sender == horizontalAngleSlider {
            horizontalAngleLabel.text = "\(Int(sender.value))"
            delegate?.viewshedSettingsVC(self, didUpdateHorizontalAngle: Double(sender.value))
        }
        else if sender == verticalAngleSlider {
            verticalAngleLabel.text = "\(Int(sender.value))"
            delegate?.viewshedSettingsVC(self, didUpdateVerticalAngle: Double(sender.value))
        }
        else if sender == minDistanceSlider {
            minDistanceLabel.text = "\(Int(sender.value))"
            delegate?.viewshedSettingsVC(self, didUpdateMinDistance: Double(sender.value))
        }
        else if sender == maxDistanceSlider {
            maxDistanceLabel.text = "\(Int(sender.value))"
            delegate?.viewshedSettingsVC(self, didUpdateMaxDistance: Double(sender.value))
        }
    }
    
    // MARK: - HorizontalColorPickerDelegate
    
    func horizontalColorPicker(_ horizontalColorPicker: HorizontalColorPicker, didUpdateSelectedColor selectedColor: UIColor) {
        if horizontalColorPicker == visibleAreaColorPicker {
            delegate?.viewshedSettingsVC(self, didUpdateVisibleAreaColor: selectedColor)
        }
        else if horizontalColorPicker == obstructedAreaColorPicker {
            delegate?.viewshedSettingsVC(self, didUpdateObstructedAreaColor: selectedColor)
        }
        else if horizontalColorPicker == frustumOutlineColorPicker {
            delegate?.viewshedSettingsVC(self, didUpdateFrustumOutlineColor: selectedColor)
        }
    }
    
}
