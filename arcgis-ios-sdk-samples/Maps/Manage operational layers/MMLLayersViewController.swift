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

protocol MMLLayersViewControllerDelegate:class {
    func layersViewControllerWantsToClose(_ layersViewController:MMLLayersViewController, withDeletedLayers layers:[AGSLayer])
}

class MMLLayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet private weak var tableView:UITableView!
    
    var layers:NSMutableArray!
    var deletedLayers:[AGSLayer]!
    
    weak var delegate:MMLLayersViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.isEditing = true
        self.tableView.allowsSelectionDuringEditing = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dataSourceIndexForIndexPath(_ dataSource:NSMutableArray, indexpath:IndexPath) -> Int {
        return dataSource.count - (indexpath as NSIndexPath).row - 1
    }
    
    //MARK: - table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? (self.layers?.count ?? 0) : (self.deletedLayers?.count ?? 0)
    }
    
    //MARK: - table view delegate
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Added layers" : "Removed layers"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        if (indexPath as NSIndexPath).section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "MMLLayersCell")!
            //layers in reverse order
            let index = self.dataSourceIndexForIndexPath(self.layers, indexpath: indexPath)
            cell.textLabel?.text = (self.layers[index] as AnyObject).name
        }
        else {
            cell = tableView.dequeueReusableCell(withIdentifier: "MMLDeletedLayersCell")!
            let layer = self.deletedLayers[(indexPath as NSIndexPath).row]
            cell.textLabel?.text = layer.name
            let plusButton = UIButton(type: UIButtonType.contactAdd)
            plusButton.isEnabled = false
            cell.accessoryView = plusButton
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == 1 {
            //put back
            tableView.beginUpdates()
            let layer = self.deletedLayers[(indexPath as NSIndexPath).row]
            tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            self.deletedLayers.remove(at: (indexPath as NSIndexPath).row)
            
            self.layers.add(layer)
            let newIndexPath = IndexPath(row: 0, section: 0)
            tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return (indexPath as NSIndexPath).section == 0
    }
    
    //update the order of layers in the array
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        //layers in reverse order
        let sourceIndex = self.dataSourceIndexForIndexPath(self.layers, indexpath: sourceIndexPath)
        let destinationIndex = self.dataSourceIndexForIndexPath(self.layers, indexpath: destinationIndexPath)
        
        let layer = self.layers[sourceIndex] as! AGSLayer
        
        self.layers.removeObject(at: sourceIndex)
        self.layers.insert(layer, at:destinationIndex)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        //check if the editing style is Delete
        if editingStyle == .delete {
            //layers in reverse order
            let index = self.dataSourceIndexForIndexPath(self.layers, indexpath: indexPath)
            
            //save the object in the deleted layers array
            let layer = self.layers[index] as! AGSLayer
            
            tableView.beginUpdates()
            //remove the layer from the data source array
            self.layers.removeObject(at: index)
            //delete the row
            self.tableView.deleteRows(at: [indexPath], with:.automatic)
            //insert the row in the deleteLayers array
            self.deletedLayers.append(layer)
            //insert the new row
            let newIndexPath = IndexPath(row: self.deletedLayers.count-1, section: 1)
            self.tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.automatic)
            //end update
            self.tableView.endUpdates()
        }
        else {
            print("Editing style other than delete")
        }
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if (sourceIndexPath as NSIndexPath).section != (proposedDestinationIndexPath as NSIndexPath).section {
            return sourceIndexPath
        }
        else {
            return proposedDestinationIndexPath
        }
    }
    
    //MARK: - Actions
    
    @IBAction func doneAction() {
        self.delegate?.layersViewControllerWantsToClose(self, withDeletedLayers: self.deletedLayers)
    }
}
