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

protocol HillshadeSettingsViewControllerDelegate: AnyObject {
    func hillshadeSettingsViewController(_ controller: HillshadeSettingsViewController, selectedAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType)
}

class HillshadeSettingsViewController: UITableViewController {
    @IBOutlet weak var altitudeSlider: UISlider?
    @IBOutlet weak var azimuthSlider: UISlider?
    @IBOutlet weak var azimuthLabel: UILabel?
    @IBOutlet weak var altitudeLabel: UILabel?
    @IBOutlet weak var slopeTypeCell: UITableViewCell?
    
    weak var delegate: HillshadeSettingsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSlopeTypeUI()
        updateAltitudeUI()
        updateAzimuthUI()
    }
    
    private var slopeTypeOptions: [AGSSlopeType] = [.none, .degree, .percentRise, .scaled]
    
    private let numberFormatter = NumberFormatter()
    
    private func labelForSlopeType(_ slopeType: AGSSlopeType) -> String {
        switch slopeType {
        case .none: return "None"
        case .degree: return "Degree"
        case .percentRise: return "Percent Rise"
        case .scaled: return "Scaled"
        @unknown default: return "Unknown"
        }
    }
    
    var slopeType: AGSSlopeType = .none {
        didSet {
            updateSlopeTypeUI()
        }
    }
    
    private func updateSlopeTypeUI() {
        slopeTypeCell?.detailTextLabel?.text = labelForSlopeType(slopeType)
    }
    
    var altitude: Double = 0 {
        didSet {
            updateAltitudeUI()
        }
    }
    
    private func updateAltitudeUI() {
        altitudeLabel?.text = numberFormatter.string(from: altitude as NSNumber)
        altitudeSlider?.value = Float(altitude)
    }
    
    var azimuth: Double = 0 {
        didSet {
            updateAzimuthUI()
        }
    }
    
    private func updateAzimuthUI() {
        azimuthLabel?.text = numberFormatter.string(from: azimuth as NSNumber)
        azimuthSlider?.value = Float(azimuth)
    }
    
    private func hillshadeParametersChanged() {
        delegate?.hillshadeSettingsViewController(self, selectedAltitude: altitude, azimuth: azimuth, slopeType: slopeType)
    }
    
    // MARK: - Actions
    
    @IBAction func azimuthSliderValueChanged(_ slider: UISlider) {
        azimuth = Double(slider.value)
        hillshadeParametersChanged()
    }
    
    @IBAction func altitudeSliderValueChanged(_ slider: UISlider) {
        altitude = Double(slider.value)
        hillshadeParametersChanged()
    }
    
    // UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) == slopeTypeCell else {
            return
        }
        let labels = slopeTypeOptions.map { (slopeType) -> String in
            return labelForSlopeType(slopeType)
        }
        let selectedIndex = slopeTypeOptions.firstIndex(of: slopeType)!
        let optionsViewController = OptionsTableViewController(labels: labels, selectedIndex: selectedIndex) { (newIndex) in
            self.slopeType = self.slopeTypeOptions[newIndex]
            self.hillshadeParametersChanged()
        }
        optionsViewController.title = "Slope Type"
        show(optionsViewController, sender: self)
    }
}
