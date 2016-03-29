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
    func layersViewControllerWantsToClose(layersViewController:MMLLayersViewController, withDeletedLayers layers:[AGSLayer])
}

class MMLLayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet private weak var tableView:UITableView!
    
    var layers:NSMutableArray!
    var deletedLayers:[AGSLayer]!
    
    weak var delegate:MMLLayersViewControllerDelegate?
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.editing = true
        self.tableView.allowsSelectionDuringEditing = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func dataSourceIndexForIndexPath(dataSource:NSMutableArray, indexpath:NSIndexPath) -> Int {
        return dataSource.count - indexpath.row - 1
    }
    
    //MARK: - table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? (self.layers?.count ?? 0) : (self.deletedLayers?.count ?? 0)
    }
    
    //MARK: - table view delegate
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Added layers" : "Removed layers"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell
        
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("MMLLayersCell")!
            //layers in reverse order
            let index = self.dataSourceIndexForIndexPath(self.layers, indexpath: indexPath)
            cell.textLabel?.text = self.layers[index].name
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier("MMLDeletedLayersCell")!
            let layer = self.deletedLayers[indexPath.row]
            cell.textLabel?.text = layer.name
            let plusButton = UIButton(type: UIButtonType.ContactAdd)
            plusButton.enabled = false
            cell.accessoryView = plusButton
            
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            //put back
            tableView.beginUpdates()
            let layer = self.deletedLayers[indexPath.row]
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            self.deletedLayers.removeAtIndex(indexPath.row)
            
            self.layers.addObject(layer)
            let newIndexPath = NSIndexPath(forRow: 0, inSection: 0)
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            tableView.endUpdates()
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    //update the order of layers in the array
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        //layers in reverse order
        let sourceIndex = self.dataSourceIndexForIndexPath(self.layers, indexpath: sourceIndexPath)
        let destinationIndex = self.dataSourceIndexForIndexPath(self.layers, indexpath: destinationIndexPath)
        
        let layer = self.layers[sourceIndex] as! AGSLayer
        
        self.layers.removeObjectAtIndex(sourceIndex)
        self.layers.insertObject(layer, atIndex:destinationIndex)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        //check if the editing style is Delete
        if editingStyle == .Delete {
            //layers in reverse order
            let index = self.dataSourceIndexForIndexPath(self.layers, indexpath: indexPath)
            
            //save the object in the deleted layers array
            let layer = self.layers[index] as! AGSLayer
            
            tableView.beginUpdates()
            //remove the layer from the data source array
            self.layers.removeObjectAtIndex(index)
            //delete the row
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Automatic)
            //insert the row in the deleteLayers array
            self.deletedLayers.append(layer)
            //insert the new row
            let newIndexPath = NSIndexPath(forRow: self.deletedLayers.count-1, inSection: 1)
            self.tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            //end update
            self.tableView.endUpdates()
        }
        else {
            print("Editing style other than delete")
        }
    }
    
    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
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
