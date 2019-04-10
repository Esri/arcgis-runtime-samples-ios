//
// Copyright 2017 Esri.
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

class PlaneStatsViewController: UITableViewController {
    var frame: Frame? {
        didSet {
            updateUI()
        }
    }
    let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    @IBOutlet private var altitudeLabel: UILabel!
    @IBOutlet private var headingLabel: UILabel!
    @IBOutlet private var pitchLabel: UILabel!
    @IBOutlet private var rollLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    private var tableViewContentSizeObservation: NSKeyValueObservation?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableViewContentSizeObservation = tableView.observe(\.contentSize) { [unowned self] (tableView, _) in
            self.preferredContentSize = CGSize(width: self.preferredContentSize.width, height: tableView.contentSize.height)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableViewContentSizeObservation = nil
    }
    
    func updateUI() {
        guard isViewLoaded else { return }
        if let frame = frame {
            measurementFormatter.unitStyle = .medium
            altitudeLabel.text = measurementFormatter.string(from: frame.altitude)
            measurementFormatter.unitStyle = .short
            headingLabel.text = measurementFormatter.string(from: frame.heading)
            pitchLabel.text = measurementFormatter.string(from: frame.pitch)
            rollLabel.text = measurementFormatter.string(from: frame.roll)
        } else {
            altitudeLabel.text = ""
            headingLabel.text = ""
            pitchLabel.text = ""
            rollLabel.text = ""
        }
    }
}
