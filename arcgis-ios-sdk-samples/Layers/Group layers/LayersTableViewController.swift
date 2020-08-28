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
        guard let groupLayer = layers[section] as? AGSGroupLayer else { return 0 }
        return groupLayer.layers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! GroupLayersCell
            guard let groupLayer = layers[indexPath.section] as? AGSGroupLayer, let childLayers = groupLayer.layers as? [AGSLayer] else { return cell }
            
            let childLayer = childLayers[indexPath.row]
            
            // Set label.
            cell.layerNameLabel.text = formattedValue(of: childLayer.name)
            
            // Set state of the switch.
            cell.layerVisibilitySwitch.isOn = childLayer.isVisible
            cell.layerVisibilitySwitch.isEnabled = groupLayer.isVisible
            
            // To update the visibility of operational layers on switch toggle.
            cell.delegate = self
            
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "exclusiveCell", for: indexPath) as! GroupLayersCell
            guard let groupLayer = layers[indexPath.section] as? AGSGroupLayer, let childLayers = groupLayer.layers as? [AGSLayer] else { return cell }
            
            let childLayer = childLayers[indexPath.row]
            
            // Set label.
            cell.textLabel?.text = formattedValue(of: childLayer.name)
            
            // Indicate which layer is visible.
            if childLayer.isVisible {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        default:
            fatalError("Unknown cell type")
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: GroupLayersSectionView.reuseIdentifier) as? GroupLayersSectionView else { return nil }
        
        let layer = layers[section]
        
        // Set label.
        headerView.layerNameLabel.text = formattedValue(of: layer.name)
        
        // Set the switch to on or off.
        headerView.layerVisibilitySwitch?.isOn = layer.isVisible
    
        // To update the visibility of operational layers on switch toggle.
        headerView.delegate = self
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect the selected row.
        tableView.deselectRow(at: indexPath, animated: true)
        if let groupLayer = layers[indexPath.section] as? AGSGroupLayer, let childLayers = groupLayer.layers as? [AGSLayer] {
            // Change the visibility according to which cell was tapped.
            childLayers[indexPath.row].isVisible = true
            tableView.reloadData()
        }
    }
    
    // MARK: - GroupLayersCellDelegate
    
    func didToggleSwitch(_ cell: GroupLayersCell, isOn: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        if let groupLayer = layers[indexPath.section] as? AGSGroupLayer, let childLayers = groupLayer.layers as? [AGSLayer] {
            childLayers[indexPath.row].isVisible = isOn
        }
    }
    
    // MARK: - GroupLayersSectionViewDelegate
    
    func didToggleSwitch(_ sectionView: GroupLayersSectionView, isOn: Bool) {
        guard let section = tableView.section(forHeaderView: sectionView) else { return }
        layers[section].isVisible = isOn
        updateCells(in: section, isEnabled: isOn)
    }
    
    // MARK: - Helper methods
    
    /// Ensures we cannot toggle visibility of child layers when the parent is turned off.
    ///
    /// - Parameters:
    ///     - section: Section of the table view.
    ///     - enabled: Indicates if the switch should be enabled or disabled.
    func updateCells(in section: Int, isEnabled: Bool) {
        guard let visibleRows = tableView.indexPathsForVisibleRows else { return }
        switch section {
        case 0:
            visibleRows.lazy.filter { $0.section == section }.forEach { indexPath in
                if let cell = tableView.cellForRow(at: indexPath) as? GroupLayersCell {
                    cell.layerVisibilitySwitch.isEnabled = isEnabled
                }
            }
        case 1:
            visibleRows.lazy.filter { $0.section == section }.forEach { indexPath in
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.isUserInteractionEnabled = isEnabled
                    cell.textLabel?.isEnabled = isEnabled
                    // Change the tint if the cell is enabled.
                    if isEnabled {
                        cell.tintColor = .none
                    } else {
                        cell.tintColor = .gray
                    }
                }
            }
        default:
            return
        }
    }
    /// Modifies name of the layer.
    ///
    /// - Parameter name: Original name of the layer.
    /// - Returns: A modified name or the original name of the layer.
    func formattedValue(of name: String) -> String {
        switch name {
        case "DevA_Trees":
            return "Trees"
        case "DevA_Pathways":
            return "Pathways"
        case "DevA_BuildingShells":
            return "Buildings A"
        case "DevB_BuildingShells":
            return "Buildings B"
        case "DevelopmentProjectArea":
            return "Project area"
        default:
            return name
        }
    }
}

class GroupLayersCell: UITableViewCell {
    @IBOutlet var layerNameLabel: UILabel!
    @IBOutlet var layerVisibilitySwitch: UISwitch!
    weak var delegate: GroupLayersCellDelegate?
    
    @IBAction func switchDidChange(_ sender: UISwitch) {
        delegate?.didToggleSwitch(self, isOn: sender.isOn)
    }
}

protocol GroupLayersCellDelegate: AnyObject {
    func didToggleSwitch(_ cell: GroupLayersCell, isOn: Bool)
}

extension UITableView {
    func section(forHeaderView headerView: UITableViewHeaderFooterView) -> Int? {
        return (0..<numberOfSections).first { self.headerView(forSection: $0) == headerView }
    }
}
