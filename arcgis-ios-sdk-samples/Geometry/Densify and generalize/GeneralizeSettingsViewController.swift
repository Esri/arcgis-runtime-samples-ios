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

protocol GeneralizeSettingsViewControllerDelegate: AnyObject {
    func generalizeSettingsViewControllerDidUpdate(_ generalizeSettingsViewController: GeneralizeSettingsViewController)
}

class GeneralizeSettingsViewController: UITableViewController {
    @IBOutlet weak var generalizeSwitch: UISwitch!
    @IBOutlet weak var densifySwitch: UISwitch!
    @IBOutlet weak var maxDeviationSlider: UISlider!
    @IBOutlet weak var maxSegmentLengthSlider: UISlider!
    @IBOutlet weak var maxSegmentLabel: UILabel!
    @IBOutlet weak var maxDeviationLabel: UILabel!
    
    var shouldGeneralize = false
    var maxDeviation = 10.0
    var shouldDensify = false
    var maxSegmentLength = 100.0
    
    weak var delegate: GeneralizeSettingsViewControllerDelegate?
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.roundingIncrement = 1
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIForValues()
    }
    
    private func updateMaxDeviationLabel() {
         maxDeviationLabel.text = formatter.string(from: maxDeviation as NSNumber)
    }
    
    private func updateMaxSegmentLengthLabel() {
        maxSegmentLabel.text = formatter.string(from: maxSegmentLength as NSNumber)
    }
    
    private func updateUIForValues() {
        generalizeSwitch.isOn = shouldGeneralize
        densifySwitch.isOn = shouldDensify
        maxDeviationSlider.value = Float(maxDeviation)
        maxSegmentLengthSlider.value = Float(maxSegmentLength)
        
        updateMaxDeviationLabel()
        updateMaxSegmentLengthLabel()
    }
    
    @IBAction func sliderAction(_ sender: UISlider) {
        switch sender {
        case maxSegmentLengthSlider:
            maxSegmentLength = Double(sender.value)
            updateMaxSegmentLengthLabel()
        case maxDeviationSlider:
            maxDeviation = Double(sender.value)
            updateMaxDeviationLabel()
        default:
            break
        }
        notifyDelegateOfUpdate()
    }
    
    @IBAction func switchAction(_ sender: UISwitch) {
        switch sender {
        case generalizeSwitch:
            shouldGeneralize = sender.isOn
            if shouldGeneralize {
                tableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
            } else {
                tableView.deleteRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
            }
        case densifySwitch:
            shouldDensify = sender.isOn
            if shouldDensify {
                tableView.insertRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
            } else {
                tableView.deleteRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
            }
        default:
            break
        }
        notifyDelegateOfUpdate()
    }
    
    private func notifyDelegateOfUpdate() {
        delegate?.generalizeSettingsViewControllerDidUpdate(self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if !shouldGeneralize {
                return 1
            }
        case 1:
            if !shouldDensify {
                return 1
            }
        default:
            break
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
}
