// Copyright 2016 Esri.
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

class MMLLayersViewController: UITableViewController {
    
    /// Every layer on the map or that could be added to the map.
    var allLayers: [AGSLayer] = []
    
    /// The layers attached to the map.
    var operationalLayers: NSMutableArray?
    
    /// The layers present in `allLayers` but not in `operationalLayers`.
    private var deletedLayers: [AGSLayer] {
        if let operationalLayers = operationalLayers as? [AGSLayer] {
            return allLayers.filter({ (layer) -> Bool in
                return !operationalLayers.contains(layer)
            })
        }
        return []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.isEditing = true
    }
    
    private func dataSourceIndexForIndexPath(_ dataSource: NSMutableArray, indexPath: IndexPath) -> Int {
        return dataSource.count - indexPath.row - 1
    }
    
    private enum Section: Int {
        case added
        case removed
    }
    
    //MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .added:
            return operationalLayers!.count
        case .removed:
            return deletedLayers.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerCell", for: indexPath)
        switch Section(rawValue: indexPath.section)! {
        case .added:
            //layers in reverse order
            let index = dataSourceIndexForIndexPath(operationalLayers!, indexPath: indexPath)
            cell.textLabel?.text = (operationalLayers![index] as AnyObject).name
        case .removed:
            let layer = deletedLayers[indexPath.row]
            cell.textLabel?.text = layer.name
        }
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .added:
            return "Added Layers"
        case .removed:
            return "Removed Layers"
        }
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch Section(rawValue: indexPath.section)! {
        case .added:
            return .delete
        case .removed:
            return .insert
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == Section.added.rawValue
    }
    
    //update the order of layers in the array
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard destinationIndexPath != sourceIndexPath else { return }
        //layers in reverse order
        let sourceIndex = dataSourceIndexForIndexPath(operationalLayers!, indexPath: sourceIndexPath)
        let destinationIndex = dataSourceIndexForIndexPath(operationalLayers!, indexPath: destinationIndexPath)
        
        let layer = operationalLayers?[sourceIndex] as! AGSLayer
        
        operationalLayers?.removeObject(at: sourceIndex)
        operationalLayers?.insert(layer, at: destinationIndex)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        defer { tableView.endUpdates() }
        switch editingStyle {
        case .delete:
            //layers in reverse order
            let index = dataSourceIndexForIndexPath(operationalLayers!, indexPath: indexPath)
            
            //remove the layer from the data source array
            operationalLayers?.removeObject(at: index)
            //delete the row
            tableView.deleteRows(at: [indexPath], with:.automatic)

            //insert the new row
            let newIndexPath = IndexPath(row: deletedLayers.count-1, section: 1)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .insert:
            let layer = deletedLayers[indexPath.row]
            tableView.deleteRows(at: [indexPath], with: .fade)

            operationalLayers?.add(layer)
            let newIndexPath = IndexPath(row: 0, section: 0)
            tableView.insertRows(at: [newIndexPath], with: .fade)
        case .none:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        switch Section(rawValue: sourceIndexPath.section)! {
        case .added:
            if proposedDestinationIndexPath.section == sourceIndexPath.section {
                return proposedDestinationIndexPath
            } else {
                return sourceIndexPath
            }
        case .removed:
            return sourceIndexPath
        }
    }

}
