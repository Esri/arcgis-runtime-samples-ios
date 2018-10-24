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

    @IBOutlet private weak var altitudeSlider: UISlider?
    @IBOutlet private weak var altitudeLabel: UILabel?
    @IBOutlet private weak var azimuthSlider: UISlider?
    @IBOutlet private weak var azimuthLabel: UILabel?
    @IBOutlet private weak var slopeTypeCell: UITableViewCell?
    @IBOutlet private weak var colorRampTypeCell: UITableViewCell?
    @IBOutlet private weak var slopeTypeLabel: UILabel?
    @IBOutlet private weak var colorRampTypeLabel: UILabel?
    
    weak var delegate: BlendRendererSettingsVCDelegate?
    
    private let numberFormatter = NumberFormatter()
    
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
    private var slopeTypeID: Int {
        set {
            slopeType = {
                switch newValue {
                case 0: return .none
                case 1: return .degree
                case 2: return .percentRise
                default: return .scaled
                }
            }()
        }
        get {
            switch slopeType {
            case .none: return 0
            case .degree: return 1
            case .percentRise: return 2
            case .scaled: return 3
            }
        }
    }
    private let slopeTypeLabels = ["None", "Degree", "Percent Rise", "Scaled"]
    private func updateSlopeTypeControls() {
        slopeTypeLabel?.text = slopeTypeLabels[slopeTypeID]
    }
    
    var colorRampType: AGSPresetColorRampType = .none {
        didSet {
            guard colorRampType != oldValue else {
                return
            }
            updateColorRampTypeControls()
        }
    }
    private var colorRampTypeID: Int {
        set {
            colorRampType = {
                switch newValue {
                case 0: return .none
                case 1: return .elevation
                case 2: return .demLight
                default: return .demScreen
                }
            }()
        }
        get {
            switch colorRampType {
            case .none: return 0
            case .elevation: return 1
            case .demLight: return 2
            case .demScreen: return 3
            }
        }
    }
    private let colorRampLabels = ["None", "Elevation", "DEMLight", "DEMScreen"]
    private func updateColorRampTypeControls() {
        colorRampTypeLabel?.text = colorRampLabels[colorRampTypeID]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateAltitudeControls()
        updateAzimuthControls()
        updateSlopeTypeControls()
        updateColorRampTypeControls()
    }
    
    //MARK: - Actions
    
    @IBAction func azimuthSliderValueChanged(_ slider: UISlider) {
        azimuth = Double(slider.value)
        blendRendererParametersChanged()
    }
    
    @IBAction func altitudeSliderValueChanged(_ slider: UISlider) {
        altitude = Double(slider.value)
        blendRendererParametersChanged()
    }
    
    private func blendRendererParametersChanged() {
        delegate?.blendRendererSettingsVC(self, selectedAltitude: altitude, azimuth: azimuth, slopeType: slopeType, colorRampType: colorRampType)
    }
    
    // UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if cell == slopeTypeCell {
            let optionsViewController = OptionsTableViewController(labels: slopeTypeLabels, selectedIndex: slopeTypeID) { (newIndex) in
                self.slopeTypeID = newIndex
                self.blendRendererParametersChanged()
            }
            optionsViewController.title = "Slope Type"
            show(optionsViewController, sender: self)
        }
        else if cell == colorRampTypeCell {
            let optionsViewController = OptionsTableViewController(labels: colorRampLabels, selectedIndex: colorRampTypeID) { (newIndex) in
                self.colorRampTypeID = newIndex
                self.blendRendererParametersChanged()
            }
            optionsViewController.title = "Color Ramp Type"
            show(optionsViewController, sender: self)
        }
    }
}
