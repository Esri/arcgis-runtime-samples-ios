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

protocol HillshadeSettingsDelegate: AnyObject {
    
    func hillshadeSettingsVC(_ hillshadeSettingsVC: HillshadeSettingsVC, selectedAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType)
}

class HillshadeSettingsVC: UITableViewController {
    
    @IBOutlet var altitudeSlider: UISlider!
    @IBOutlet var azimuthSlider: UISlider!
    @IBOutlet var azimuthLabel: UILabel!
    @IBOutlet var altitudeLabel: UILabel!
    @IBOutlet var horizontalPicker: HorizontalPicker!
    
    weak var delegate: HillshadeSettingsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        horizontalPicker.options = ["None", "Degree", "Percent Rise", "Scaled"]
        horizontalPicker.delegate = self
    }
    
    var selectedSlope: AGSSlopeType {
        set {
            guard newValue != selectedSlope else {
                return
            }
            switch newValue {
            case .none:
                horizontalPicker.selectedIndex = 0
            case .degree:
                horizontalPicker.selectedIndex = 1
            case .percentRise:
                horizontalPicker.selectedIndex = 2
            case .scaled:
                horizontalPicker.selectedIndex = 3
            }
        }
        get {
            switch horizontalPicker.selectedIndex {
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
    }
    
    var altitude: Double {
        set {
            guard newValue != altitude else {
                return
            }
            altitudeLabel.text = "\(Int(newValue))"
            altitudeSlider.value = Float(newValue)
        }
        get {
            return Double(altitudeSlider.value)
        }
    }
    
    var azimuth: Double {
        set {
            guard newValue != azimuth else {
                return
            }
            azimuthLabel.text = "\(Int(newValue))"
            azimuthSlider.value = Float(newValue)
        }
        get {
            return Double(azimuthSlider.value)
        }
    }
    
    private func hillshadeParametersChanged() {
        delegate?.hillshadeSettingsVC(self, selectedAltitude: altitude, azimuth: azimuth, slopeType: selectedSlope)
    }
    
    //MARK: - Actions
    
    @IBAction func azimuthSliderValueChanged(_ slider: UISlider) {
        azimuth = Double(slider.value)
        hillshadeParametersChanged()
    }
    
    @IBAction func altitudeSliderValueChanged(_ slider: UISlider) {
        altitude = Double(slider.value)
        hillshadeParametersChanged()
    }
    
}

extension HillshadeSettingsVC: HorizontalPickerDelegate {
    func horizontalPicker(_ horizontalPicker: HorizontalPicker, didUpdateSelectedIndex index: Int) {
         hillshadeParametersChanged()
    }
}
