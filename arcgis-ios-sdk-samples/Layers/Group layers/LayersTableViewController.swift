// Copyright 2019 Esri.
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

class LayersTableViewController: UITableViewController, GroupLayersCellDelegate, GroupLayersSectionViewDelegate {
    var layers = [AGSLayer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(GroupLayersSectionView.nib, forHeaderFooterViewReuseIdentifier: GroupLayersSectionView.reuseIdentifier)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return layers.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let groupLayer = getLayer(from: layers, at: section) as? AGSGroupLayer else { return 0 }
        return groupLayer.layers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? GroupLayersCell else {
            return UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        guard let groupLayer = getLayer(from: layers, at: indexPath.section) as? AGSGroupLayer, let childLayers = groupLayer.layers as? [AGSLayer], let childLayer = getLayer(from: childLayers, at: indexPath.row) else { return cell }
        // Set label.
        cell.textLabel?.text = formattedValue(of: childLayer.name)
        
        // Set the switch to on or off.
        cell.layerVisibilitySwitch.isOn = childLayer.isVisible
        
        // To update the visibility of operational layers on switch toggle.
        cell.delegate = self
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: GroupLayersSectionView.reuseIdentifier) as? GroupLayersSectionView else { return nil }
        
        guard let layer = getLayer(from: layers, at: section) else { return nil }
        // Set label.
        headerView.layerNameLabel.text = formattedValue(of: layer.name)
        
        // Set the switch to on or off.
        headerView.layerVisibilitySwitch?.isOn = layer.isVisible
        if !layer.isVisible {
            // Disable switch of child layers if the parent is not visible.
            updateSwitchForRows(in: section, isEnabled: false)
        }
        
        // To update the visibility of operational layers on switch toggle.
        headerView.layerVisibilitySwitch?.tag = section
        headerView.delegate = self
        
        return headerView
    }
    
    // MARK: - GroupLayersCellDelegate
    
    func didToggleSwitch(_ cell: GroupLayersCell, isOn: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        if let groupLayer = getLayer(from: layers, at: indexPath.section) as? AGSGroupLayer, let childLayers = groupLayer.layers as? [AGSLayer], let childLayer = getLayer(from: childLayers, at: indexPath.row) {
            childLayer.isVisible = isOn
        }
    }
    
    // MARK: - GroupLayersSectionViewDelegate
    
    func didToggleSwitch(_ sectionView: GroupLayersSectionView, section: Int, isOn: Bool) {
        let layer = getLayer(from: layers, at: section)
        layer?.isVisible = isOn
        updateSwitchForRows(in: section, isEnabled: isOn)
    }
    
    // MARK: - Helper methods
    
    /// Ensures we cannot toggle visibility of child layers when the parent is turned off.
    ///
    /// - Parameters:
    ///     - section: Section number of the table view.
    ///     - enabled: Indicates if the switch should be enabled or disabled.
    func updateSwitchForRows(in section: Int, isEnabled: Bool) {
        guard let visibleRows = tableView.indexPathsForVisibleRows else { return }
        let visibleRowsForSection = visibleRows.filter { $0.section == section }
        for indexPath in visibleRowsForSection {
            if indexPath.section == section, let cell = tableView.cellForRow(at: indexPath) as? GroupLayersCell {
                cell.layerVisibilitySwitch.isEnabled = isEnabled
            }
        }
    }
    
    /// Modifies name of the layer.
    ///
    /// - Parameter name: Original name of the layer.
    /// - Returns: A modified name or the original name of the layer.
    func formattedValue(of name: String) -> String {
        switch name {
        case "DevA_Trees":
            return "Dev A: Trees"
        case "DevA_Pathways":
            return "Dev A: Pathways"
        case "DevA_BuildingShell_Textured":
            return "Dev A: Building Shell Textured"
        case "PlannedDemo_BuildingShell":
            return "Planned Demo Building Shell"
        case "DevelopmentProjectArea":
            return "Development Project Area"
        default:
            return name
        }
    }
    
    /// To get layer from a list.
    ///
    /// - Parameters:
    ///     - layers: List of layers.
    ///     - section: Position of layer on the layers list.
    /// - Returns: A layer if it exists else it returns nil.
    func getLayer(from layers: [AGSLayer], at section: Int) -> AGSLayer? {
        if section >= layers.count { return nil }
        return layers[section]
    }
}

class GroupLayersCell: UITableViewCell {
    @IBOutlet var layerVisibilitySwitch: UISwitch!
    weak var delegate: GroupLayersCellDelegate?
    
    @IBAction func switchDidChange(_ sender: UISwitch) {
        delegate?.didToggleSwitch(self, isOn: sender.isOn)
    }
}

protocol GroupLayersCellDelegate: AnyObject {
    func didToggleSwitch(_ cell: GroupLayersCell, isOn: Bool)
}
