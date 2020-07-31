// Copyright 2020 Esri
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

protocol BufferListSettingsViewControllerDelegate: AnyObject {
    func bufferListSettingsViewController(_ bufferListSettingsViewController: BufferListSettingsViewController, bufferDistanceChangedTo bufferDistance: Measurement<UnitLength>, areBuffersUnioned: Bool)
}

class BufferListSettingsViewController: UITableViewController {
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var distanceSlider: UISlider!
    @IBOutlet var unionSwitch: UISwitch!
    
    weak var delegate: BufferListSettingsViewControllerDelegate?
    
    let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.unitOptions = .naturalScale
        return formatter
    }()
    
    var bufferDistance: Measurement<UnitLength> = Measurement(value: 50, unit: .miles) {
        didSet {
            updateDistanceUI()
        }
    }
    
    @IBAction func distanceSliderValueChanged(_ sender: UISlider) {
        // Update the buffer distance for the slider value.
        bufferDistance.value = Double(sender.value)
    }
    
    func updateDistanceUI() {
        distanceSlider.value = Float(bufferDistance.value)
        distanceLabel.text = measurementFormatter.string(from: bufferDistance)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDistanceUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Notify the delegate with the new values.
        delegate?.bufferListSettingsViewController(self, bufferDistanceChangedTo: bufferDistance, areBuffersUnioned: unionSwitch.isOn)
    }
}
