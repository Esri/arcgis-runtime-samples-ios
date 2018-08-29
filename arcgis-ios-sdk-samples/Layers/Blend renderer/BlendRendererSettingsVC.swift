//
// Copyright 2016 Esri.
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

protocol BlendRendererSettingsVCDelegate: AnyObject {
    
    func blendRendererSettingsVC(_ blendRendererSettingsVC: BlendRendererSettingsVC, selectedAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType, colorRampType: AGSPresetColorRampType)
}

class BlendRendererSettingsVC: UIViewController {

    @IBOutlet var altitudeSlider:UISlider!
    @IBOutlet var altitudeLabel:UILabel!
    @IBOutlet var azimuthSlider:UISlider!
    @IBOutlet var azimuthLabel:UILabel!
    @IBOutlet var slopeTypePicker:HorizontalPicker!
    @IBOutlet var colorRampPicker:HorizontalPicker!
    
    weak var delegate:BlendRendererSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.slopeTypePicker.options = ["None", "Degree", "Percent Rise", "Scaled"]
        self.colorRampPicker.options = ["None", "Elevation", "DEMLight", "DEMScreen"]
        self.view.layer.cornerRadius = 10
    }

    func selectedSlope() -> AGSSlopeType {
        switch self.slopeTypePicker.selectedIndex {
        case 0:
            return .none
        case 1:
            return .degree
        case 2:
            return .percentRise
        default:
            return .scaled
        }
    }
    
    func selectedColorRamp() -> AGSPresetColorRampType {
        switch self.colorRampPicker.selectedIndex {
        case 0:
            return .none
        case 1:
            return .elevation
        case 2:
            return .demLight
        default:
            return .demScreen
        }
    }
    
    //MARK: - Actions
    
    @IBAction func azimuthSliderValueChanged(_ slider: UISlider) {
        self.azimuthLabel.text = "\(Int(slider.value))"
    }
    
    @IBAction func altitudeSliderValueChanged(_ slider: UISlider) {
        self.altitudeLabel.text = "\(Int(slider.value))"
    }
    
    @IBAction func rendererAction() {
        
        self.delegate?.blendRendererSettingsVC(self, selectedAltitude: Double(self.altitudeSlider.value), azimuth: Double(self.azimuthSlider.value), slopeType: self.selectedSlope(), colorRampType: self.selectedColorRamp())
    }
}
