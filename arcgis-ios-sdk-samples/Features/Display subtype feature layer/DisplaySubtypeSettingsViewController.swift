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

protocol DisplaySubtypeSettingsViewControllerDelegate: AnyObject {
    /// Tells the delegate that the user changed the map scale.
    ///
    /// - Parameter controller: The controller sending the message.
    func displaySubtypeSettingsViewControllerDidChangeMapScale(_ controller: DisplaySubtypeSettingsViewController)
    /// Tells the delegate that the user finished changing settings.
    ///
    /// - Parameter controller: The controller sending the message.
    func displaySubtypeSettingsViewControllerDidFinish(_ controller: DisplaySubtypeSettingsViewController)
}

class DisplaySubtypeSettingsViewController: UITableViewController {
    /// The map whose settings should be adjusted.
    var map: AGSMap!
    /// The scale of the map. The default it `0`.
    var mapScale: Double!

    weak var delegate: DisplaySubtypeSettingsViewControllerDelegate?
    
    @IBOutlet weak var sublayerSwitch: UISwitch!
    @IBOutlet weak var rendererSwitch: UISwitch!
    @IBOutlet weak var scaleLabel: UILabel!
    @IBOutlet weak var minScaleLabel: UILabel!
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
    private var originalRenderer: AGSRenderer!
    private var alternativeRenderer: AGSSimpleRenderer!
    private var subtypeSublayer: AGSSubtypeSublayer!
    private var minScale: Double!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Update Map Scale section.
        makeSubtype()
        makeRenderers()
        scaleLabel.text = string(fromScale: mapScale)
        if minScale != nil {
            minScaleLabel.text = string(fromScale: minScale)
        } else {
            minScaleLabel.text = "None"
        }
        
        delegate?.displaySubtypeSettingsViewControllerDidChangeMapScale(self)
    }
    
    private func makeSubtype() {
        let layers = map.operationalLayers as? [AGSSubtypeFeatureLayer]
        subtypeSublayer = (layers?.first?.sublayer(withName: "Street Light"))!
    }
    
    private func makeRenderers() {
        originalRenderer = subtypeSublayer.renderer!
        let symbol = AGSSimpleMarkerSymbol(style: .diamond, color: .systemPink, size: 20)
        alternativeRenderer = AGSSimpleRenderer(symbol: symbol)
    }
    
    @IBAction func sublayerSwitchAction(_ sender: UISwitch) {
        if sender.isOn {
            subtypeSublayer.isVisible = true
        } else {
            subtypeSublayer.isVisible = false
        }
    }
    
    @IBAction func rendererSwitchAction(_ sender: UISwitch) {
        if sender.isOn {
            subtypeSublayer.renderer = originalRenderer
        } else {
            subtypeSublayer.renderer = alternativeRenderer
        }
    }
    
    @IBAction func currentToMinAction() {
        minScaleLabel.text = string(fromScale: mapScale)
        subtypeSublayer.minScale = mapScale
//        map.minScale = mapScale
    }
}
