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

class BlendRendererSettingsVC: UITableViewController {

    @IBOutlet var altitudeSlider: UISlider?
    @IBOutlet var altitudeLabel: UILabel?
    @IBOutlet var azimuthSlider: UISlider?
    @IBOutlet var azimuthLabel: UILabel?
    @IBOutlet var slopeTypePicker: HorizontalPicker?
    @IBOutlet var colorRampPicker: HorizontalPicker?
    
    let numberFormatter = NumberFormatter()
    
    var azimuth: Double = 0 {
        didSet {
           updateAzimuthControls()
        }
    }
    private func updateAzimuthControls() {
        azimuthSlider?.value = Float(azimuth)
        azimuthLabel?.text = numberFormatter.string(from: azimuth as NSNumber)
    }
    
    var altitude: Double = 0 {
        didSet {
            updateAltitudeControls()
        }
    }
    private func updateAltitudeControls() {
        altitudeSlider?.value = Float(altitude)
        altitudeLabel?.text = numberFormatter.string(from: altitude as NSNumber)
    }

    var slopeType: AGSSlopeType = .none {
        didSet {
            guard slopeType != oldValue else {
                return
            }
            updateSlopeTypeControls()
        }
    }
    private func updateSlopeTypeControls() {
        switch slopeType {
        case .none:
            slopeTypePicker?.selectedIndex = 0
        case .degree:
            slopeTypePicker?.selectedIndex = 1
        case .percentRise:
            slopeTypePicker?.selectedIndex = 2
        case .scaled:
            slopeTypePicker?.selectedIndex = 3
        }
    }
    
    var colorRampType: AGSPresetColorRampType = .none {
        didSet {
            guard colorRampType != oldValue else {
                return
            }
            updateColorRampControls()
        }
    }
    private func updateColorRampControls() {
        switch colorRampType {
        case .none:
            colorRampPicker?.selectedIndex = 0
        case .elevation:
            colorRampPicker?.selectedIndex = 1
        case .demLight:
            colorRampPicker?.selectedIndex = 2
        case .demScreen:
            colorRampPicker?.selectedIndex = 3
        }
    }
    
    weak var delegate: BlendRendererSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slopeTypePicker?.delegate = self
        colorRampPicker?.delegate = self
        slopeTypePicker?.options = ["None", "Degree", "Percent Rise", "Scaled"]
        colorRampPicker?.options = ["None", "Elevation", "DEMLight", "DEMScreen"]
        
        updateAltitudeControls()
        updateAzimuthControls()
        updateSlopeTypeControls()
        updateColorRampControls()
    }
    
    //MARK: - Actions
    
    @IBAction func azimuthSliderValueChanged(_ slider: UISlider) {
        azimuth = Double(slider.value)
        rendererAction()
    }
    
    @IBAction func altitudeSliderValueChanged(_ slider: UISlider) {
        altitude = Double(slider.value)
        rendererAction()
    }
    
    private func rendererAction() {
        delegate?.blendRendererSettingsVC(self, selectedAltitude: altitude, azimuth: azimuth, slopeType: slopeType, colorRampType: colorRampType)
    }
}

extension BlendRendererSettingsVC: HorizontalPickerDelegate {
    
    func horizontalPicker(_ horizontalPicker: HorizontalPicker, didUpdateSelectedIndex index: Int) {
        if horizontalPicker == slopeTypePicker {
            slopeType = {
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
            }()
        }
        else if horizontalPicker == colorRampPicker {
            colorRampType = {
                switch horizontalPicker.selectedIndex {
                case 0:
                    return .none
                case 1:
                    return .elevation
                case 2:
                    return .demLight
                default:
                    return .demScreen
                }
            }()
        }
        rendererAction()
    }
    
}
