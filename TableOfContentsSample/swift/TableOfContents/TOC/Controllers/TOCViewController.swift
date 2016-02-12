//
// Copyright 2015 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit
import ArcGIS

protocol TOCViewControllerDelegate:class {
    func dismissTOCViewController(controller:TOCViewController)
}

class TOCViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, LayerInfoCellDelegate {

    @IBOutlet weak var tableView:UITableView!
    
    var itemsArray:[AnyObject]!
    var expandedLayerInfos = [AGSMapContentsLayerInfo]()
    weak var delegate:TOCViewControllerDelegate?
    
    //to hide the status bar for this view controller
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.itemsArray?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let LayerInfoCellIdentifier = "LayerInfoCell"
        let LayerLegendCellIdentifier = "LayerLegendCell"
        
        let tempObject: AnyObject = self.itemsArray[indexPath.row]
        
        //if the object is a layer info  then create a LayerInfoCell
        if tempObject is AGSMapContentsLayerInfo {
            let layerInfo = tempObject as! AGSMapContentsLayerInfo
            let layerInfoCell = tableView.dequeueReusableCellWithIdentifier(LayerInfoCellIdentifier) as! LayerInfoCell
            layerInfoCell.level = layerInfo.level
            layerInfoCell.canChangeVisibility = layerInfo.canChangeVisibility
            layerInfoCell.visibility = layerInfo.visible
            layerInfoCell.expanded = layerInfo.expanded
            
            //assign the title.
            layerInfoCell.valueLabel.text = layerInfo.title
            
            //assign the delegate to call the method when the visibility is changed.
            layerInfoCell.layerInfoCellDelegate = self
            
            //no selection style.
            layerInfoCell.selectionStyle = .None
            
            return layerInfoCell
        }
        //else if it is a legend info class, create a legend info cell.
        else {
            let legendElement = tempObject as! AGSMapContentsLegendElement
            let layerLegendCell = tableView.dequeueReusableCellWithIdentifier(LayerLegendCellIdentifier) as! LayerLegendCell
            layerLegendCell.level = legendElement.level
            
            //assign the title.
            layerLegendCell.legendLabel.text = legendElement.title
            
            //assign the image.
            layerLegendCell.legendImage.image = legendElement.swatch
            
            //no selection style.
            layerLegendCell.selectionStyle = .None
            
            return layerLegendCell;
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44;
    }
    
    //MARK: - table view delegates
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tempObject: AnyObject = self.itemsArray[indexPath.row]
        
        //if the selected row is of type layer info
        //then expand the layerInfo if not already expanded or vice versa
        if tempObject is AGSMapContentsLayerInfo {
            let layerInfo = tempObject as! AGSMapContentsLayerInfo
            if !layerInfo.expanded {
                //add the children to the items array
                //in order to expand the layer info
                self.addChildrenForSelectedLayerInfo(layerInfo)
                layerInfo.expanded = true
                
//                println("sibling index :: \(self.indexOfNextSibling(layerInfo))")
//                println(self.itemsArray)
            }
            else {
                //else remove the children from the items array
                //iin order to collapse the layer info
                self.removeChildrenForSelectedLayerInfo(layerInfo)
                layerInfo.expanded = false
            }
            //reload the tableview to reflect the changes
            self.tableView.reloadData()
        }
    }
    
    //MARK: - LayerInfoCellDelegate
    
    func layerInfoCell(layerInfoCell: LayerInfoCell, didChangeVisibility visibility: Bool) {
        //retrieve the corresponding cell
        if let cellIndexPath = self.tableView.indexPathForCell(layerInfoCell) {
            //get the layer info represented by the cell
            let layerInfo = self.itemsArray[cellIndexPath.row] as! AGSMapContentsLayerInfo
            
            //set the visibility of the layer info.
            layerInfo.visible = visibility
        }
    }
    
    //MARK: - Helper methods
    
    func addChildrenForSelectedLayerInfo(layerInfo:AGSMapContentsLayerInfo) {
        //add the layer info to be expanded, to the expandedLayerInfos array
        //in order to keep track of all the expanded layer infos
        //we will use this array to reset the state of the layer infos
        //before the view controller is de initialized
        self.expandedLayerInfos.append(layerInfo)
        
        //get the index of the layer info in the items array
        if let index = (self.itemsArray as! [NSObject]).indexOf(layerInfo) {
            //check if the layer info has sublayers
            if layerInfo.subLayers.count > 0 {
                //if true add the sublayers after the parent layer info in the items array
                var i = 1
                for subLayerInfo in layerInfo.subLayers as! [AGSMapContentsLayerInfo] {
                    subLayerInfo.level = layerInfo.level + 1
                    self.itemsArray.insert(subLayerInfo, atIndex: index + i)
                    i++
                }
            }
            //else check if the layer info has legend elements
            else if layerInfo.legendItems.count > 0 {
                //if yes, then add those elements after the parent layer info
                var i = 1
                for legendElement in layerInfo.legendItems as! [AGSMapContentsLegendElement] {
                    legendElement.level = layerInfo.level + 1
                    self.itemsArray.insert(legendElement, atIndex: index + i)
                    i++
                }
            }
        }
    }
    
    func removeChildrenForSelectedLayerInfo(layerInfo:AGSMapContentsLayerInfo) {
        //find the index of the layer info in the expandedLayerInfos array
        //and use the index to remove the layer info from that array,
        //as we will be collapsing this layer info
        if let index = self.expandedLayerInfos.indexOf(layerInfo) {
            self.expandedLayerInfos.removeAtIndex(index)
        }
        
        //find the index of the layer info in the items array
        //and remove the sublayers/legendItems following it
        if let layerInfoIndex = (self.itemsArray as! [NSObject]).indexOf(layerInfo) {
        
            //find the index of the next sibling in the items array
            //remove all the items between the layerInfo index and the sibling layerInfoIndex
            //if sibling not present then simply remove all items after layerInfoIndex
            //also update the expanded state property to false for these items
            var endOfRange:Int = 0
            let siblingLayerInfoIndex = self.indexOfNextSibling(layerInfo)
            if siblingLayerInfoIndex == -2 {
                print("Unexpected error while finding siblings")
                return
            }
            else if siblingLayerInfoIndex == -1 { //no sibling found, simply remove all items after the layerInfo
                endOfRange = self.itemsArray.count-1
            }
            else {
                endOfRange = siblingLayerInfoIndex-1
            }
            
            if layerInfoIndex != endOfRange { //to check for items with no children
                //update the expanded state to false
                for i in layerInfoIndex+1...endOfRange {
                    let tempObject: AnyObject = self.itemsArray[i]
                    if tempObject is AGSMapContentsLayerInfo {
                        (tempObject as! AGSMapContentsLayerInfo).expanded = false
                    }
                }
                //remove the items
                self.itemsArray.removeRange(layerInfoIndex+1...endOfRange)
            }
        }
    }
    
    //find the next sibling in the items array
    //if not present then recursively check for the parent node
    //returns -1 if layerInfo is the last node
    //returns -2 unexpected behavior
    func indexOfNextSibling(layerInfo:AGSMapContentsLayerInfo) -> Int {
        var siblingsArray:[AGSMapContentsLayerInfo]
        //get the siblings array
        if layerInfo.parent != nil {
            siblingsArray = layerInfo.parent!.subLayers as! [AGSMapContentsLayerInfo]
        }
        else {
            //use the root as the parent
            return -1
        }
        
        //find the index of the layerInfo in the siblings array
        if let layerInfoIndex = siblingsArray.indexOf(layerInfo) {
            if layerInfoIndex < siblingsArray.count - 1 {
                //get the sibling layerInfo
                let siblingLayerInfo = siblingsArray[layerInfoIndex+1]
                //find the index of sibling in the itemsArray
                if let siblingLayerInfoIndex = (self.itemsArray as! [NSObject]).indexOf(siblingLayerInfo as NSObject) {
                    return siblingLayerInfoIndex
                }
                else {
                    return -2
                }
            }
            else {
                return self.indexOfNextSibling(layerInfo.parent!)
            }
        }
        return -2
    }
    
    //MARK: - actions
    
    @IBAction func doneAction() {
        self.delegate?.dismissTOCViewController(self)
    }
    
    //MARK: - Deinit
    
    deinit {
        for layerInfo in self.expandedLayerInfos {
            layerInfo.expanded = false
        }
    }
}
