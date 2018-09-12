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

import ArcGIS

class GPKGLayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet private weak var tableView:UITableView!
    
    var map:AGSMap?
    var allLayers:[AGSLayer] = [] {
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
    
    private var layersInMap:[AGSLayer] {
        // 0 is the bottom-most layer on the map, but first cell in a table.
        // By reversing the layer order from the map, we match the UITableView order.
        return map?.operationalLayers.reversed() as? [AGSLayer] ?? []
    }

    private var layersNotInMap:[AGSLayer] {
        guard map != nil else {
            return allLayers
        }
        
        return allLayers.filter({ layer -> Bool in
            return !layersInMap.contains(layer)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.isEditing = true
        self.tableView.allowsSelectionDuringEditing = true
    }
    
    //MARK: - table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? layersInMap.count : layersNotInMap.count
    }
    
    //MARK: - table view delegate
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Layers on the map" : "Layers not on the map"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        if indexPath.section == 0 {
            // Set up the cell for a layer that is on the map.
            cell = tableView.dequeueReusableCell(withIdentifier: "GPKGLayersCell", for: indexPath)
            if let layerCell = cell as? GPKGLayerTableCell {
                layerCell.agsLayer = layersInMap[indexPath.row]
            }
        } else {
            // Set up the cell for a layer that is NOT on the map.
            cell = tableView.dequeueReusableCell(withIdentifier: "GPKGRemovedLayersCell", for: indexPath)
            if let layerCell = cell as? GPKGLayerTableCell {
                layerCell.agsLayer = layersNotInMap[indexPath.row]
            }
            let plusButton = UIButton(type: .contactAdd)
            plusButton.isEnabled = false
            cell.accessoryView = plusButton
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            // Selected a layer in the "Not on the map" section.
            tableView.beginUpdates()

            // Get the layer to add to the map.
            if let layer = layer(forTableView: tableView, andIndexPath: indexPath) {
                // Add it on top of any other layers.
                map?.operationalLayers.add(layer)

                // Remove the row representing the layer before it was added to the map.
                tableView.deleteRows(at: [indexPath], with: .fade)
                
                // Add a row representing the layer now it's at the top of the map's layers.
                let newIndexPath = IndexPath(row: 0, section: 0)
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
            
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Only rows for layers on the map (in Section 0 of the Table View) can be edited.
        return indexPath.section == 0
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // A row for a layer that's on the map was dragged in the table view.
        // Update the map's layers to reflect the change in order.
        
        // Get the layer that was dragged.
        if let layer = layer(forTableView: tableView, andIndexPath: sourceIndexPath),
           let layers = map?.operationalLayers {
            // Remove the layer from the map.
            layers.remove(layer)
            
            // Re-insert it at the position it was dragged to.
            layers.insert(layer, at: layers.count - destinationIndexPath.row)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        if indexPath.section == 0 {
            return "Remove from map"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // If not deleting a row, ignore the edit.
        guard editingStyle == .delete else {
            print("Editing style other than delete")
            return
        }
        
        // Ensure we are able to get the AGSLayer from the row.
        guard let layer = layer(forTableView: tableView, andIndexPath: indexPath) else {
            print("Could not get layer for index path")
            return
        }

        tableView.beginUpdates()
        
        // Remove the layer from the map.
        map?.operationalLayers.remove(layer)
        
        // Remove the row from the section of layers in the map.
        self.tableView.deleteRows(at: [indexPath], with:.automatic)
        
        // Insert the removed row back in the section for layers not in the map.
        if let index = layersNotInMap.index(of: layer) {
            let newIndexPath = IndexPath(row: index, section: 1)
            self.tableView.insertRows(at: [newIndexPath], with: .automatic)
        }
        
        self.tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        }
        else {
            return proposedDestinationIndexPath
        }
    }
    
    private func layer(forTableView tableView: UITableView, andIndexPath indexPath: IndexPath) -> AGSLayer? {
        return (tableView.cellForRow(at: indexPath) as? GPKGLayerTableCell)?.agsLayer
    }
}
