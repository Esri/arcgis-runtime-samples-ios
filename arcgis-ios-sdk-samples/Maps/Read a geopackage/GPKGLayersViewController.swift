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
import ArcGIS

class GPKGLayersViewController: UITableViewController {
    var map: AGSMap?
    var allLayers: [AGSLayer] = [] {
        didSet {
            var rasterCount = 1
            for layer in allLayers where layer is AGSRasterLayer &&
                                         layer.name.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty {
                // Give raster layers a name
                layer.name = "Raster Layer \(rasterCount)"
                rasterCount += 1
            }
        }
    }
    
    private var layersInMap: [AGSLayer] {
        // 0 is the bottom-most layer on the map, but first cell in a table.
        // By reversing the layer order from the map, we match the UITableView order.
        return map?.operationalLayers.reversed() as? [AGSLayer] ?? []
    }

    private var layersNotInMap: [AGSLayer] {
        guard map != nil else {
            return allLayers
        }
        
        return allLayers.filter { !layersInMap.contains($0) }
    }
    
    /// Returns the layer for the row at the given index path.
    ///
    /// - Parameter indexPath: An index path of a row in the table view.
    /// - Returns: The layer corresponding to the row.
    func layerForRow(at indexPath: IndexPath) -> AGSLayer {
        if indexPath.section == 0 {
            return layersInMap[indexPath.row]
        } else {
            return layersNotInMap[indexPath.row]
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.isEditing = true
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? layersInMap.count : layersNotInMap.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Layers on the map" : "Layers not on the map"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GPKGLayersCell", for: indexPath)
        cell.textLabel?.text = layerForRow(at: indexPath).name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // A row for a layer that's on the map was dragged in the table view.
        // Update the map's layers to reflect the change in order.
        
        // Get the layer that was dragged.
        let layer = layerForRow(at: sourceIndexPath)
        if let layers = map?.operationalLayers {
            // Remove the layer from the map.
            layers.remove(layer)
            
            // Re-insert it at the position it was dragged to.
            layers.insert(layer, at: layers.count - destinationIndexPath.row)
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        if indexPath.section == 0 {
            return "Remove from map"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch indexPath.section {
        case 0:
            return .delete
        case 1:
            return .insert
        default:
            return .none
        }
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let layer = layerForRow(at: indexPath)
        
        switch editingStyle {
        case .delete:
            tableView.beginUpdates()
            
            // Remove the layer from the map.
            map?.operationalLayers.remove(layer)
            
            // Remove the row from the section of layers in the map.
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // Insert the removed row back in the section for layers not in the map.
            if let index = layersNotInMap.firstIndex(of: layer) {
                let newIndexPath = IndexPath(row: index, section: 1)
                tableView.insertRows(at: [newIndexPath], with: .automatic)
            }
            
            tableView.endUpdates()
        case .insert:
            tableView.beginUpdates()
            
            // Add it on top of any other layers.
            map?.operationalLayers.add(layer)
            
            // Remove the row representing the layer before it was added to the map.
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Add a row representing the layer now it's at the top of the map's layers.
            let newIndexPath = IndexPath(row: 0, section: 0)
            tableView.insertRows(at: [newIndexPath], with: .fade)
            
            tableView.endUpdates()
        default:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
}
