//
// Copyright 2014 ESRI
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

let kBufferViewControllerIdentifier = "BufferViewController"
let kCutterViewControllerIdentifier = "CutterViewController"
let kDensifyViewControllerIdentifier = "DensifyViewController"
let kUnionDifferenceViewControllerIdentifier = "UnionDifferenceViewController"
let kOffsetViewControllerIdentifier = "OffsetViewController"
let kProjectViewControllerIdentifier = "ProjectViewController"
let kRelationshipViewControllerIdentifier = "RelationshipViewController"
let kMeasureViewControllerIdentifier = "MeasureViewController"

class RootViewController: UITableViewController, UISplitViewControllerDelegate {

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Operations"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "RootViewControllerCellIdentifier"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
        }
        
        // Set appropriate labels for the cells.
        if (indexPath.row == 0) {
            cell?.textLabel?.text = "Buffer"
        }
        else if (indexPath.row == 1) {
            cell?.textLabel?.text = "Cut"
        }
        else if(indexPath.row == 2) {
            cell?.textLabel?.text = "Densify"
        }
        else if(indexPath.row == 3) {
            cell?.textLabel?.text = "Union & Difference"
        }
        else if(indexPath.row == 4) {
            cell?.textLabel?.text = "Offset"
        }
        else if (indexPath.row == 5) {
            cell?.textLabel?.text = "Project"
        }
        else if (indexPath.row == 6) {
            cell?.textLabel?.text = "Spatial Relationships"
        }
        else {
            cell?.textLabel?.text = "Measure"
        }
        
        return cell!
    }
    
    //MARK: - table view selection
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let row = indexPath.row
        
        //Obtain an instance of storyboard to create an object of the desired view controller
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        var desiredViewControllerIdentifier:String!
        
        // Create and configure a new detail view controller appropriate for the selection.
        var detailViewController: UIViewController!
        
        if (row == 0) {
            desiredViewControllerIdentifier = kBufferViewControllerIdentifier
        }
        else if (row == 1) {
            desiredViewControllerIdentifier = kCutterViewControllerIdentifier
        }
        else if (row == 2) {
            desiredViewControllerIdentifier = kDensifyViewControllerIdentifier
        }
        else if (row == 3) {
            desiredViewControllerIdentifier = kUnionDifferenceViewControllerIdentifier
        }
        else if (row == 4) {
            desiredViewControllerIdentifier = kOffsetViewControllerIdentifier
        }
        else if (row == 5) {
            desiredViewControllerIdentifier = kProjectViewControllerIdentifier
        }
        else if (row == 6) {
            desiredViewControllerIdentifier = kRelationshipViewControllerIdentifier
        }
        else {
            desiredViewControllerIdentifier = kMeasureViewControllerIdentifier
        }
        
        //instantiate the desired view controller
        detailViewController = storyboard.instantiateViewControllerWithIdentifier(desiredViewControllerIdentifier)
        
        // Update the split view controller's view controllers array.
        let splitViewController = self.navigationController?.splitViewController
        let viewControllers = [self.navigationController!, detailViewController!]
        splitViewController?.viewControllers = viewControllers
    }
}
