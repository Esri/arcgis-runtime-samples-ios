// Copyright 2015 Esri.
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

class ContentTableViewController: UITableViewController {

    var nodesArray:[Node]!
    private var expandedRowIndex:Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100
        
        //if content not set then start from scratch as root node
        if self.nodesArray == nil {
            self.populateTree()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func populateTree() {
        
        let path = NSBundle.mainBundle().pathForResource("ContentPList", ofType: "plist")
        let content = NSArray(contentsOfFile: path!)
        self.nodesArray = self.populateNodesArray(content! as [AnyObject])
        self.tableView.reloadData()
    }
    
    func populateNodesArray(array:[AnyObject]) -> [Node] {
        var nodesArray = [Node]()
        for object in array {
            let node = self.populateNode(object as! [String:AnyObject])
            nodesArray.append(node)
        }
        return nodesArray
    }
    
    func populateNode(dict:[String:AnyObject]) -> Node {
        let node = Node()
        if let displayName = dict["displayName"] as? String {
            node.displayName = displayName
        }
        if let descriptionText = dict["descriptionText"] as? String {
            node.descriptionText = descriptionText
        }
        if let storyboardName = dict["storyboardName"] as? String {
            node.storyboardName = storyboardName
        }
        if let children = dict["children"] as? [AnyObject] {
            node.children = self.populateNodesArray(children)
        }
//        if let readmeURLString = dict["readmeURLString"] as? String {
//            println("Populate \(readmeURLString)")
//            node.readmeURLString = readmeURLString
//        }
        return node
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nodesArray?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! UITableViewCell

        let node = self.nodesArray[indexPath.row]
        if let titleLabel = cell.viewWithTag(1) as? UILabel {
            titleLabel.text = node.displayName
        }
        if let detailLabel = cell.viewWithTag(2) as? UILabel {
            if self.expandedRowIndex == indexPath.row {
                detailLabel.text = node.descriptionText
            }
            else {
                detailLabel.text = nil
            }
        }
        cell.accessoryType = node.children != nil ? .DisclosureIndicator : .DetailButton
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let node = self.nodesArray[indexPath.row]
        
        if node.children != nil { //sub content view
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("ContentTableViewController") as! ContentTableViewController
            controller.nodesArray = node.children
            controller.title = node.displayName
            self.navigationController?.showViewController(controller, sender: self)
        }
        else {  //detail view controller
            //expand the selected cell
            self.updateExpandedRow(indexPath, collapseIfSelected: false)
            
            let storyboard = UIStoryboard(name: node.storyboardName, bundle: NSBundle.mainBundle())
            let controller = storyboard.instantiateInitialViewController() as! UIViewController
            controller.title = node.displayName
            let navController = UINavigationController(rootViewController: controller)
            
            self.splitViewController?.showDetailViewController(navController, sender: self)
            
            //add the button on the left on the detail view controller
            if let splitViewController = self.view.window?.rootViewController as? UISplitViewController {
                controller.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
            
            //create the info button and
            //assign the readme url
            let infoBBI = SourceCodeBarButtonItem()
            infoBBI.folderName = node.displayName
            infoBBI.navController = navController
            controller.navigationItem.rightBarButtonItem = infoBBI
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        self.updateExpandedRow(indexPath, collapseIfSelected: true)
    }
    
    func updateExpandedRow(indexPath:NSIndexPath, collapseIfSelected:Bool) {
        //if same row selected then hide the detail view
        if indexPath.row == self.expandedRowIndex {
            if collapseIfSelected {
                self.expandedRowIndex = -1
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            else {
                return
            }
        }
        else {
            //get the two cells and update
            let previouslyExpandedIndexPath = NSIndexPath(forRow: self.expandedRowIndex, inSection: 0)
            self.expandedRowIndex = indexPath.row
            tableView.reloadRowsAtIndexPaths([previouslyExpandedIndexPath, indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }

}
