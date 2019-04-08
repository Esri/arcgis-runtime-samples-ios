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

class LayersTableViewController: UITableViewController {
    var layers = [AGSLayer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return layers.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return layers[section].name
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let groupLayer = getLayer(from: layers, at: section) as? AGSGroupLayer else { return 0 }
        return groupLayer.layers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "layerCell", for: indexPath)
        configure(cell)
        
        // Set label.
        guard let groupLayer = getLayer(from: layers, at: indexPath.section) as? AGSGroupLayer, let childLayers = groupLayer.layers as? [AGSLayer], let childLayer = getLayer(from: childLayers, at: indexPath.row) else { return cell }
        cell.textLabel?.text = formattedValue(of: childLayer.name)
        
        // Set accessory view.
        cell.accessoryView = makeAccessoryView(section: indexPath.section, row: indexPath.row)
        
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "layerCell")
        let cell = UITableViewCell(style: .default, reuseIdentifier: "layerCell")
        configure(cell, asHeaderView: true)
        
        // Set label.
        guard let layer = getLayer(from: layers, at: section) else { return cell }
        cell.textLabel?.text = formattedValue(of: layer.name)
        
        // Set accessory view.
        cell.accessoryView = makeAccessoryView(section: section)
       
        return cell
    }
    
    // MARK: - Action
    
    @objc
    func switchChanged(_ sender: CustomSwitch) {
        guard let section = sender.section, let layer = getLayer(from: layers, at: section) else { return }
        let isSwitchOn = sender.isOn
        
        if let row = sender.row, let groupLayer = getLayer(from: layers, at: row) as? AGSGroupLayer, let childLayers = groupLayer.layers as? [AGSLayer], let childLayer = getLayer(from: childLayers, at: row) {
            childLayer.isVisible = isSwitchOn
        } else if layer is AGSGroupLayer {
            layer.isVisible = isSwitchOn
            updateSwitchForRows(in: section, enabled: isSwitchOn)
        } else {
            layer.isVisible = isSwitchOn
        }
    }
    
    // MARK: - Helper methods
    
    /// Makes an accessory view for a cell in table view.
    ///
    /// - Parameters:
    ///     - section: Section number of the table view.
    ///     - row: Row number of the table view section.
    /// - Returns: A custom UISwitch.
    func makeAccessoryView(section: Int, row: Int? = nil) -> CustomSwitch? {
        // Create a switch.
        let visibilitySwitch = CustomSwitch(frame: .zero)
        visibilitySwitch.section = section
        visibilitySwitch.addTarget(self, action: #selector(LayersTableViewController.switchChanged(_:)), for: .valueChanged)
        
        // Set the switch to on or off.
        guard let layer = getLayer(from: layers, at: section) else { return nil }
        visibilitySwitch.isOn = layer.isVisible
        
        if let row = row, let groupLayer = layer as? AGSGroupLayer, let childLayers = groupLayer.layers as? [AGSLayer], let childLayer = getLayer(from: childLayers, at: row) {
            visibilitySwitch.row = row
            visibilitySwitch.isOn = childLayer.isVisible
        }
        
        // Disable switch.
        if layer is AGSGroupLayer, !layer.isVisible {
            updateSwitchForRows(in: section, enabled: false)
        }
        
        return visibilitySwitch
    }
    
    /// Ensures we cannot toggle visibility of child layers when the parent is turned off.
    ///
    /// - Parameters:
    ///     - section: Section number of the table view.
    ///     - enabled: Indicates if the switch should be enabled or disabled.
    func updateSwitchForRows(in section: Int, enabled: Bool) {
        guard let groupLayer = getLayer(from: layers, at: section) as? AGSGroupLayer else { return }
        
        for index in 0..<groupLayer.layers.count {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: section))
            
            if let visibilitySwitch = cell?.accessoryView as? CustomSwitch {
                visibilitySwitch.isEnabled = enabled
            }
        }
    }
    
    /// Configures table view cell.
    ///
    /// - Parameters:
    ///     - cell: Table view cell to configure.
    ///     - asHeaderView: Indicates if the cell should be configured for table view section.
    func configure(_ cell: UITableViewCell, asHeaderView: Bool = false) {
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        
        if asHeaderView {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        } else {
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
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
    
    func getLayer(from layers: [AGSLayer], at section: Int) -> AGSLayer? {
        if section >= layers.count { return nil }
        return layers[section]
    }
}

class CustomSwitch: UISwitch {
    var section: Int?
    var row: Int?
}

class ToggleSwitch: UITableViewCell {
    @IBOutlet var toggleSwitch: UISwitch!
}


