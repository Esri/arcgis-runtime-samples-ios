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

protocol HillshadeSettingsDelegate: class {
    
    func hillshadeSettingsVC(_ hillshadeSettingsVC: HillshadeSettingsVC, selectedAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType)
}

class HillshadeSettingsVC: UIViewController {
    
    @IBOutlet var altitudeSlider: UISlider!
    @IBOutlet var azimuthSlider: UISlider!
    @IBOutlet var azimuthLabel: UILabel!
    @IBOutlet var altitudeLabel: UILabel!
    @IBOutlet var horizontalPicker: HorizontalPicker!
    
    weak var delegate: HillshadeSettingsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.horizontalPicker.options = ["None", "Degree", "Percent Rise", "Scaled"]
        self.view.layer.cornerRadius = 10
    }
    
    func selectedSlope() -> AGSSlopeType {
        switch self.horizontalPicker.selectedIndex {
        case 0:
            return AGSSlopeType.none
        case 1:
            return AGSSlopeType.degree
        case 2:
            return AGSSlopeType.percentRise
        default:
            return AGSSlopeType.scaled
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
        
        self.delegate?.hillshadeSettingsVC(self, selectedAltitude: Double(self.altitudeSlider.value), azimuth: Double(self.azimuthSlider.value), slopeType: self.selectedSlope())
    }
}
