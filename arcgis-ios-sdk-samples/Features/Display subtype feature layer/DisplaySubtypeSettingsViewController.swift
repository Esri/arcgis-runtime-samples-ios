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
    /// The map whose settings should be adjusted.
    var map: AGSMap! //maybe not working bc haven't assigned map to anything?
    /// The scale of the map. The default it `0`.
    var mapScale = 0.0
    /// The delegate of the view controller.
    weak var delegate: MapReferenceScaleSettingsViewControllerDelegate?

    @IBOutlet weak var sublayerSwitch: UISwitch!
    @IBOutlet weak var rendererSwitch: UISwitch!
    @IBOutlet weak var scaleLabel: UILabel!
    @IBOutlet weak var setCurrentToMinScale: UITableViewCell!
    
    /// The formatter used to generate strings from scale values.
    private let scaleFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    
    /// Returns a string containing the formatted value of the provided scale.
    ///
    /// - Parameter scale: A scale value.
    /// - Returns: A string.
    func string(fromScale scale: Double) -> String {
        return String(format: "1:%@", scaleFormatter.string(from: scale as NSNumber)!)
    }
    
    /// The observer of the scale of the map.
    private var scaleObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Update Map Scale section.
        
        scaleLabel.text = string(fromScale: mapScale)
        setCurrentToMinScale.textLabel?.textColor = view.tintColor
    }
    
    @IBAction func sublayerSwitchAction(_ sender: UISwitch) {
        if let layers = map.operationalLayers as? [AGSSubtypeFeatureLayer] {
            let subtypeSublayer = layers.first?.sublayer(withName: "Street Light")
            if sender.isOn {
                subtypeSublayer?.isVisible = true
            } else {
                subtypeSublayer?.isVisible = false
            }
        }
    }
    
    @IBAction func rendererSwitchAction(_ sender: UISwitch) {
        if let layers = map.operationalLayers as? [AGSSubtypeFeatureLayer] {
            let subtypeSublayer = layers.first?.sublayer(withName: "Street Light")
            if sender.isOn {
                let symbol = AGSSimpleMarkerSymbol(style: .diamond, color: .systemPink, size: 20)
                let alternativeRenderer = AGSSimpleRenderer(symbol: symbol)
                subtypeSublayer?.renderer = alternativeRenderer
            } else {
            }
        }
    }
}

extension DisplaySubtypeSettingsViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            mapScale = map.referenceScale
            scaleLabel.text = string(fromScale: mapScale)
    }
}
