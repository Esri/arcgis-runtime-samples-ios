// Copyright 2020 Esri.
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

class DisplaySubtypeSettingsViewController: UITableViewController {
    // The map whose settings should be adjusted.
    var map: AGSMap!
    var mapScale: Double!
    var minScale: Double!
    var originalRenderer: AGSRenderer!
    var subtypeSublayer: AGSSubtypeSublayer!
    let currentToMinButtonPath = IndexPath(row: 1, section: 1)
    private var tableViewContentSizeObservation: NSKeyValueObservation?
    
    @IBOutlet weak var sublayerSwitch: UISwitch!
    @IBOutlet weak var rendererSwitch: UISwitch!
    @IBOutlet weak var minScaleLabel: UILabel!
    
    // Change the visibility of the sublayer.
    @IBAction func sublayerSwitchAction(_ sender: UISwitch) {
        subtypeSublayer.isVisible = sender.isOn
    }
    
    // Toggle the type of renderer
    @IBAction func rendererSwitchAction(_ sender: UISwitch) {
        if sender.isOn {
            subtypeSublayer.renderer = originalRenderer
        } else {
            let symbol = AGSSimpleMarkerSymbol(style: .diamond, color: .systemPink, size: 20)
            let alternativeRenderer = AGSSimpleRenderer(symbol: symbol)
            subtypeSublayer.renderer = alternativeRenderer
        }
    }
    
    // The formatter used to generate strings from scale values.
    private let scaleFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    
    // Returns a string containing the formatted value of the provided scale.
    private func string(fromScale scale: Double) -> String {
        return String(format: "1:%@", scaleFormatter.string(from: scale as NSNumber)!)
    }
    
    // Preserve the states of the switches
    private func preserveSwitchStates() {
        sublayerSwitch.isOn = subtypeSublayer.isVisible
        rendererSwitch.isOn = subtypeSublayer.renderer == originalRenderer
    }
    
    // Adjust the size of the table view according to its contents.
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preserveSwitchStates()
        let minScale = subtypeSublayer.minScale
        if !minScale.isNaN {
            minScaleLabel.text = string(fromScale: minScale)
        } else {
            minScaleLabel.text = "Not set"
        }
    }
}

// Enable actions when the table view cell is selected.
extension DisplaySubtypeSettingsViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath == currentToMinButtonPath {
            tableView.deselectRow(at: indexPath, animated: true)
            minScaleLabel.text = string(fromScale: mapScale)
            subtypeSublayer.minScale = mapScale
        }
    }
}
