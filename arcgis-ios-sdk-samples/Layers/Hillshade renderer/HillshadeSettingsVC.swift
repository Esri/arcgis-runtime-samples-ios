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
    @IBOutlet weak var slopeTypeLabel: UILabel!
    @IBOutlet weak var slopeTypeCell: UITableViewCell!
    
    weak var delegate: HillshadeSettingsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateSlopeTypeLabel()
    }
    
    var slopeType: AGSSlopeType = .none {
        didSet {
            updateSlopeTypeLabel()
        }
    }
    
    private func updateSlopeTypeLabel() {
        slopeTypeLabel?.text = slopeType.title
    }
    
    var altitude: Double = 0 {
        didSet {
            altitudeLabel.text = "\(Int(altitude))"
            altitudeSlider.value = Float(altitude)
        }
    }
    
    var azimuth: Double = 0 {
        didSet {
            azimuthLabel.text = "\(Int(azimuth))"
            azimuthSlider.value = Float(azimuth)
        }
    }
    
    private func hillshadeParametersChanged() {
        delegate?.hillshadeSettingsVC(self, selectedAltitude: altitude, azimuth: azimuth, slopeType: slopeType)
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
    
    // UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) == slopeTypeCell else {
            return
        }
        let optionsTableViewController = OptionsTableViewController(options: AGSSlopeType.allCases, selectedOption: slopeType) { (newOption) in
            self.slopeType = newOption
            self.hillshadeParametersChanged()
            
        }
        optionsTableViewController.title = "Slope Type"
        show(optionsTableViewController, sender: self)
    }
    
}

extension AGSSlopeType: CaseIterable {
    public static var allCases: [AGSSlopeType] {
        return [.none, .degree, .percentRise, .scaled]
    }
}

extension AGSSlopeType: OptionProtocol {
    var title: String {
        switch self {
        case .none: return "None"
        case .degree: return "Degree"
        case .percentRise: return "Percent Rise"
        case .scaled: return "Scaled"
        }
    }
}
