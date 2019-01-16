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

protocol BufferOptionsViewControllerDelegate: AnyObject {
    func bufferOptionsViewController(_ bufferOptionsViewController: BufferOptionsViewController, bufferDistanceChangedTo bufferDistance: Measurement<UnitLength>)
}

class BufferOptionsViewController: UITableViewController {
    @IBOutlet private weak var distanceSlider: UISlider?
    @IBOutlet private weak var distanceLabel: UILabel?
    
    weak var delegate: BufferOptionsViewControllerDelegate?
    
    private let measurementFormatter: MeasurementFormatter = {
        // use a measurement formatter so the value is automatically localized
        let formatter = MeasurementFormatter()
        // don't show decimal places
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var bufferDistance = Measurement(value: 0, unit: UnitLength.miles) {
        didSet {
            updateUIForBufferRadius()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIForBufferRadius()
    }
    
    private func updateUIForBufferRadius() {
        // update the slider and label to match the buffer distance
        distanceSlider?.value = Float(bufferDistance.value)
        distanceLabel?.text = measurementFormatter.string(from: bufferDistance)
    }

    @IBAction func bufferSliderAction(_ sender: UISlider) {
        // update the buffer distance for the slider value
        bufferDistance.value = Double(sender.value)
        // notify the delegate with the new value
        delegate?.bufferOptionsViewController(self, bufferDistanceChangedTo: bufferDistance)
    }
}
