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
    var tableViewContentSizeObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(GroupLayersSectionView.nib, forHeaderFooterViewReuseIdentifier: GroupLayersSectionView.reuseIdentifier)
    }
    
    // Adjust the size of the table view according to its contents.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableViewContentSizeObservation = tableView.observe(\.contentSize) { [unowned self] (tableView, _) in
            self.preferredContentSize = CGSize(width: self.preferredContentSize.width, height: tableView.contentSize.height)
        }
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
        guard let groupLayer = layers[indexPath.section] as? AGSGroupLayer else { fatalError("Unknown cell type") }
        switch groupLayer.visibilityMode {
        case .independent:
            let cell = tableView.dequeueReusableCell(withIdentifier: "switchCell", for: indexPath) as! GroupLayersCell
            let childLayers = groupLayer.layers as! [AGSLayer]
            let childLayer = childLayers[indexPath.row]
            
            // Set label.
            cell.layerNameLabel.text = formattedValue(of: childLayer.name)
            
            // Set state of the cell and switch.
            cell.isUserInteractionEnabled = groupLayer.isVisible
            cell.layerVisibilitySwitch.isOn = childLayer.isVisible
            cell.layerVisibilitySwitch.isEnabled = groupLayer.isVisible
            
            // To update the visibility of operational layers on switch toggle.
            cell.delegate = self
            
            return cell
        case .exclusive:
            let cell = tableView.dequeueReusableCell(withIdentifier: "exclusiveCell", for: indexPath)
            guard let childLayers = groupLayer.layers as? [AGSLayer] else { return cell }
            
            let childLayer = childLayers[indexPath.row]
            
            // Set label.
            cell.textLabel?.text = formattedValue(of: childLayer.name)
            // Enable or disable the cell accordingly.
            cell.isUserInteractionEnabled = groupLayer.isVisible
            cell.textLabel?.isEnabled = groupLayer.isVisible
            // Adjust the tint if the cell is enabled.
            if groupLayer.isVisible {
                cell.tintAdjustmentMode = .automatic
            } else {
                cell.tintAdjustmentMode = .dimmed
            }
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
        let groupLayer = layers[indexPath.section] as! AGSGroupLayer
        let childLayers = groupLayer.layers as! [AGSLayer]
        
        var indexPathsToReload = [indexPath]
        if let indexOfPreviouslyVisibleLayer = childLayers.firstIndex(where: { $0.isVisible }) {
            indexPathsToReload.append(IndexPath(row: indexOfPreviouslyVisibleLayer, section: indexPath.section))
        }
        childLayers[indexPath.row].isVisible = true
        tableView.reloadRows(at: indexPathsToReload, with: .automatic)
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
        tableView.reloadSections([section], with: .automatic)
    }
    
    // MARK: - Helper methods
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
            return "Project Area"
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
