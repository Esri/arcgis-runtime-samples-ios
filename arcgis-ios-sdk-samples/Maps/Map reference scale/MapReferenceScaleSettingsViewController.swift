//
// Copyright © 2019 Esri.
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
//

import UIKit
import ArcGIS

/// The delegate of a `MapReferenceScaleSettingsViewController`.
protocol MapReferenceScaleSettingsViewControllerDelegate: AnyObject {
    /// Tells the delegate that the user changed the map scale.
    ///
    /// - Parameter controller: The controller sending the message.
    func mapReferenceScaleSettingsViewControllerDidChangeMapScale(_ controller: MapReferenceScaleSettingsViewController)
    /// Tells the delegate that the user finished changing settings.
    ///
    /// - Parameter controller: The controller sending the message.
    func mapReferenceScaleSettingsViewControllerDidFinish(_ controller: MapReferenceScaleSettingsViewController)
}

/// A view controller that provides an interface for adjusting the reference
/// scale and scale of a map.
class MapReferenceScaleSettingsViewController: UITableViewController {
    /// The map whose settings should be adjusted.
    var map: AGSMap!
    /// The scale of the map. The default it `0`.
    var mapScale = 0.0
    /// The delegate of the view controller.
    weak var delegate: MapReferenceScaleSettingsViewControllerDelegate?
    
    @IBOutlet weak var referenceScaleLabel: UILabel!
    @IBOutlet weak var referenceScalePickerView: UIPickerView!
    @IBOutlet weak var layersCell: UITableViewCell!
    
    @IBOutlet weak var mapScaleLabel: UILabel!
    @IBOutlet weak var setMapScaleToReferenceScaleButton: UITableViewCell!
    
    /// The formatter used to generate strings from scale values.
    private let scaleFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    /// The scale values displayed in the reference scale picker view.
    private let possibleReferenceScales = [500_000, 250_000, 100_000, 50_000]
    
    /// Returns a string containing the formatted value of the provided scale.
    ///
    /// - Parameter scale: A scale value.
    /// - Returns: A string.
    func string(fromScale scale: Double) -> String {
        return String(format: "1:%@", scaleFormatter.string(from: scale as NSNumber)!)
    }
    
    /// Called in response to the Done button being tapped.
    @IBAction func done() {
        delegate?.mapReferenceScaleSettingsViewControllerDidFinish(self)
    }
    
    /// Indicates whether the reference scale picker is currently hidden.
    private var referenceScalePickerHidden = true
    
    /// Toggles visisbility of the reference scale picker.
    func toggleReferenceScalePickerVisibility() {
        tableView.performBatchUpdates({
        if referenceScalePickerHidden {
            referenceScaleLabel.textColor = view.tintColor
            tableView.insertRows(at: [.referenceScalePicker], with: .fade)
            referenceScalePickerHidden = false
        } else {
            referenceScaleLabel.textColor = nil
            tableView.deleteRows(at: [.referenceScalePicker], with: .fade)
            referenceScalePickerHidden = true
        }
        }, completion: nil)
    }
    
    /// The observer of the reference scale of the map.
    private var referenceScaleObserver: NSObjectProtocol?
    /// The observer of the scale of the map.
    private var scaleObserver: NSObjectProtocol?
    
    // MARK: UIViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        precondition(map != nil)
        
        // Update Reference Scale section.
        
        referenceScaleObserver = map.observe(\.referenceScale, options: .initial) { [unowned self] (_, _) in
            DispatchQueue.main.async {
                self.referenceScaleLabel.text = self.string(fromScale: self.map.referenceScale)
            }
        }
        
        if let row = possibleReferenceScales.firstIndex(of: Int(map.referenceScale.rounded(.toNearestOrAwayFromZero))) {
            referenceScalePickerView.selectRow(row, inComponent: 0, animated: false)
        }
        
        let selectedLayers = map.operationalFeatureLayers.filter { $0.scaleSymbols }
        layersCell.detailTextLabel?.text = String(format: "%lu", Int64(selectedLayers.count))
        
        // Update Map Scale section.
        
        mapScaleLabel.text = string(fromScale: mapScale)
        setMapScaleToReferenceScaleButton.textLabel?.textColor = view.tintColor
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        referenceScaleObserver = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let layerSelectionViewController = segue.destination as? MapReferenceScaleLayerSelectionViewController {
            let layers = map.operationalFeatureLayers
            layerSelectionViewController.layers = layers
            let layersToSelect = layers.filter { $0.scaleSymbols }
            layersToSelect.forEach { layerSelectionViewController.selectLayer($0) }
            layerSelectionViewController.delegate = self
        }
    }
}

extension MapReferenceScaleSettingsViewController: MapReferenceScaleLayerSelectionViewControllerDelegate {
    func mapReferenceScaleLayerSelectionViewController(_ controller: MapReferenceScaleLayerSelectionViewController, didSelect layer: AGSLayer) {
        (layer as? AGSFeatureLayer)?.scaleSymbols = true
    }
    
    func mapReferenceScaleLayerSelectionViewController(_ controller: MapReferenceScaleLayerSelectionViewController, didDeselect layer: AGSLayer) {
        (layer as? AGSFeatureLayer)?.scaleSymbols = false
    }
}

private extension IndexPath {
    static let referenceScale = IndexPath(row: 0, section: 0)
    static let referenceScalePicker = IndexPath(row: 1, section: 0)
    static let setToReferenceScaleButton = IndexPath(row: 1, section: 1)
}

extension MapReferenceScaleSettingsViewController /* UITableViewDataSource */ {
    func adjustedIndexPath(_ indexPath: IndexPath) -> IndexPath {
        switch indexPath.section {
        case 0:
            var adjustedRow = indexPath.row
            if indexPath.row >= 1 && referenceScalePickerHidden {
                adjustedRow += 1
            }
            return IndexPath(row: adjustedRow, section: indexPath.section)
        default:
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = super.tableView(tableView, numberOfRowsInSection: section)
        if section == 0 && referenceScalePickerHidden {
            return numberOfRows - 1
        } else {
            return numberOfRows
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return super.tableView(tableView, cellForRowAt: adjustedIndexPath(indexPath))
    }
}

extension MapReferenceScaleSettingsViewController /* UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case .referenceScale:
            tableView.deselectRow(at: indexPath, animated: true)
            toggleReferenceScalePickerVisibility()
        case .setToReferenceScaleButton:
            tableView.deselectRow(at: indexPath, animated: true)
            mapScale = map.referenceScale
            mapScaleLabel.text = string(fromScale: mapScale)
            delegate?.mapReferenceScaleSettingsViewControllerDidChangeMapScale(self)
        default:
            break
        }
    }
}

extension MapReferenceScaleSettingsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return possibleReferenceScales.count
    }
}

extension MapReferenceScaleSettingsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return string(fromScale: Double(possibleReferenceScales[row]))
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        map.referenceScale = Double(possibleReferenceScales[row])
    }
}

private extension AGSMap {
    var operationalFeatureLayers: [AGSFeatureLayer] {
        return operationalLayers.compactMap { $0 as? AGSFeatureLayer }
    }
}
