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

protocol MMLLayersViewControllerDelegate: AnyObject {
    func layersViewControllerWantsToClose(_ layersViewController: MMLLayersViewController, withDeletedLayers layers: [AGSLayer])
}

class MMLLayersViewController: UITableViewController {
    var layers: NSMutableArray!
    var deletedLayers: [AGSLayer]!
    
    weak var delegate: MMLLayersViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.isEditing = true
    }
    
    func dataSourceIndexForIndexPath(_ dataSource: NSMutableArray, indexPath: IndexPath) -> Int {
        return dataSource.count - indexPath.row - 1
    }
    
    enum Section: Int {
        case added
        case removed
        
        init(_ rawValue: Int) {
            self.init(rawValue: rawValue)!
        }
    }
    
    //MARK: - table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(section) {
        case .added:
            return layers?.count ?? 0
        case .removed:
            return deletedLayers?.count ?? 0
        }
    }
    
    //MARK: - table view delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(section) {
        case .added:
            return "Added layers"
        case .removed:
            return "Removed layers"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerCell", for: indexPath)
        switch Section(indexPath.section) {
        case .added:
            //layers in reverse order
            let index = dataSourceIndexForIndexPath(layers, indexPath: indexPath)
            cell.textLabel?.text = (layers[index] as AnyObject).name
        case .removed:
            let layer = deletedLayers[indexPath.row]
            cell.textLabel?.text = layer.name
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch Section(indexPath.section) {
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
        let sourceIndex = dataSourceIndexForIndexPath(layers, indexPath: sourceIndexPath)
        let destinationIndex = dataSourceIndexForIndexPath(layers, indexPath: destinationIndexPath)
        
        let layer = layers[sourceIndex] as! AGSLayer
        
        layers.removeObject(at: sourceIndex)
        layers.insert(layer, at:destinationIndex)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        defer { tableView.endUpdates() }
        switch editingStyle {
        case .delete:
            //layers in reverse order
            let index = dataSourceIndexForIndexPath(layers, indexPath: indexPath)
            
            //save the object in the deleted layers array
            let layer = layers[index] as! AGSLayer
            
            //remove the layer from the data source array
            layers.removeObject(at: index)
            //delete the row
            tableView.deleteRows(at: [indexPath], with:.automatic)
            //insert the row in the deleteLayers array
            deletedLayers.append(layer)
            //insert the new row
            let newIndexPath = IndexPath(row: deletedLayers.count-1, section: 1)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .insert:
            let layer = deletedLayers[indexPath.row]
            tableView.deleteRows(at: [indexPath], with: .fade)
            deletedLayers.remove(at: indexPath.row)
            
            layers.add(layer)
            let newIndexPath = IndexPath(row: 0, section: 0)
            tableView.insertRows(at: [newIndexPath], with: .fade)
        case .none:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        switch Section(sourceIndexPath.section) {
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
    
    //MARK: - Actions
    
    @IBAction func doneAction() {
        delegate?.layersViewControllerWantsToClose(self, withDeletedLayers: deletedLayers)
    }
}
