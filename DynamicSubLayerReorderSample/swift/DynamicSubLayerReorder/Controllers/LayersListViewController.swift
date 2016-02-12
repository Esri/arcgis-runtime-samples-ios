/*
Copyright 2015 Esri

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import UIKit
import ArcGIS

let POPOVER_WIDTH:CGFloat = 200
let POPOVER_HEIGHT:CGFloat = 200

protocol LayersListDelegate:class {
    func layersListViewController(layersListViewController:LayersListViewController, didUpdateLayerInfos dynamicLayerInfos:[AGSDynamicLayerInfo])
}

class LayersListViewController: UIViewController, OptionsDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var layerInfos:[AGSLayerInfo]! {
        didSet {
            //initialize the deleted infos array if done already
            if self.deletedLayerInfos == nil {
                self.deletedLayerInfos = [AGSDynamicLayerInfo]()
            }
            //relaod the table view to reflect the layer info changes
            self.tableView.reloadData()
        }
    }
    weak var delegate:LayersListDelegate?
    
    @IBOutlet weak var addButton:UIBarButtonItem!
    @IBOutlet weak var editButton:UIBarButtonItem!
    @IBOutlet weak var tableView:UITableView!
    
    var deletedLayerInfos:[AGSLayerInfo]!
    var optionsViewController:OptionsViewController!
    var popover:UIPopoverController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize the optionsViewController
        self.optionsViewController = OptionsViewController()
        self.optionsViewController.delegate = self
        
        //initialize the popover controller
        self.popover = UIPopoverController(contentViewController: self.optionsViewController)
        self.popover.popoverContentSize = CGSizeMake(POPOVER_WIDTH, POPOVER_HEIGHT)
        
        //enable editing on tableview
        self.tableView.editing = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - table view datasource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.layerInfos != nil {
            return self.layerInfos.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reusableIdentifier = "LayersListCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(reusableIdentifier)!
        
        let layerInfo = self.layerInfos[indexPath.row]
        cell.textLabel?.text = layerInfo.name
        //enable reordering on each cell
        cell.showsReorderControl = true
        return cell
    }
    
    //enable re ordering on each row
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    //MARK: - table view delegates
    
    //update the order of layer infos in the array
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        //get the layer info being moved
        let layerInfo = self.layerInfos[sourceIndexPath.row]
        //remove the layerInfo from the previous index
        self.layerInfos.removeAtIndex(sourceIndexPath.row)
        //add the layer info at the new index
        self.layerInfos.insert(layerInfo, atIndex:destinationIndexPath.row)
        //notify the delegate to update the dynamic service layer
        self.updateDynamicServiceLayer()
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        //check if the editing style is Delete
        if editingStyle == .Delete {
            //save the object in the deleted layer infos array
            let layerInfo = self.layerInfos[indexPath.row]
            self.deletedLayerInfos.append(layerInfo)
            tableView.beginUpdates()
            //remove the layer info from the data source array
            self.layerInfos.removeAtIndex(indexPath.row)
            //delete the row
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation:.Automatic)
            tableView.endUpdates()
            //update dynamic service
            self.updateDynamicServiceLayer()
            //update the add button status
            self.updateAddButtonStatus()
        }
        else {
            print("Editing style other than delete")
        }
    }
    
    //MARK: -
    
    //the method creates an array of AGSDynamicLayerInfo from the array of AGSLayerInfo
    //the AGSDynamicLayerInfo array can be assigned to the AGSDynamicMapService to update
    //the ordering or add or delete a layer
    func createDynamicLayerInfos(layerInfos:[AGSLayerInfo]) -> [AGSDynamicLayerInfo] {
        //instantiate a new mutable array
        var dynamicLayerInfos = [AGSDynamicLayerInfo]()
        //loop through the layer infos array and create a corresponding
        //dynamic layer info
        for layerInfo in layerInfos {
            let dynamicLayerInfo = AGSDynamicLayerInfo(layerID: layerInfo.layerId)
            dynamicLayerInfos.append(dynamicLayerInfo)
        }
        return dynamicLayerInfos
    }
    
    //the method notifies the delegate about the changes in the layerInfos
    func updateDynamicServiceLayer() {
        //create dynamic layer infos from the layer infos
        let dynamicLayerInfos = self.createDynamicLayerInfos(self.layerInfos)
        //notify the delegate
        self.delegate?.layersListViewController(self, didUpdateLayerInfos: dynamicLayerInfos)
    }
    
    //this method enables/disables the Add bar button item based on the
    //count of values in the deletedLayerInfos array
    func updateAddButtonStatus() {
        self.addButton.enabled = self.deletedLayerInfos.count > 0
    }
    
    //MARK: - Actions
    
    @IBAction func addAction(sender:UIBarButtonItem) {
        //update the options array with the current layerInfos array
        self.optionsViewController.options = self.deletedLayerInfos
        //present the popover controller
        self.popover.presentPopoverFromBarButtonItem(sender, permittedArrowDirections:.Down, animated:true)
    }
    
    //MARK: - OptionsDelegate
    
    func optionsViewController(optionsViewController: OptionsViewController, didSelectOption option: AGSLayerInfo) {
        //hide the popover controller
        self.popover.dismissPopoverAnimated(true)
        //remove the layer info from deleted layer Infos
        if let index = self.deletedLayerInfos.indexOf(option) {
            self.deletedLayerInfos.removeAtIndex(index)
        }
        //and add it to the layer infos
        self.layerInfos.insert(option, atIndex:0)
        //reload tableview
        self.tableView.reloadData()
        //notify the delegate to update the dynamic service
        self.updateDynamicServiceLayer()
        //update the status of the add button
        self.updateAddButtonStatus()
    }
}
